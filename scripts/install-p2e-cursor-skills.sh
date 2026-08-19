#!/usr/bin/env bash
# Install (or refresh) P2E Cursor skills into the current workspace so Cloud Agents
# can invoke /p2e-* without vendoring this plugin into the product git tree.
#
# Designed to run from a product repo's `.cursor/environment.json`:
#
#   {
#     "install": "... && git clone --depth 1 https://github.com/bchoor/p2e-plugin.git \"$HOME/p2e-plugin\" && bash \"$HOME/p2e-plugin/scripts/install-p2e-cursor-skills.sh\"",
#     "start": "bash \"$HOME/p2e-plugin/scripts/install-p2e-cursor-skills.sh\" --update",
#     "repositoryDependencies": ["github.com/bchoor/p2e-plugin"]
#   }
#
# `--update` fetches the plugin ref (default: origin/main) then re-links. `install`
# is snapshotted into the Cloud Agent Build; `start` is what makes new sessions
# pick up plugin changes without a rebuild.
set -euo pipefail

UPDATE=0
if [[ "${1:-}" == "--update" ]]; then
  UPDATE=1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
PLUGIN_REPO="${P2E_PLUGIN_REPO:-https://github.com/bchoor/p2e-plugin.git}"
PLUGIN_REF="${P2E_PLUGIN_REF:-main}"
PLUGIN_HOME="${P2E_PLUGIN_HOME:-$HOME/p2e-plugin}"

is_plugin_repo() {
  # Product-repo installs symlink workflows/ and .cursor/skills/ into the
  # workspace; only the real plugin checkout has the Claude/Codex manifests.
  [[ -f "$1/.claude-plugin/plugin.json" && -f "$1/workflows/p2e-policy.md" && -f "$1/.cursor/skills/p2e/SKILL.md" ]]
}

# Already inside p2e-plugin itself — skills are already at the workspace root.
if is_plugin_repo "$WORKSPACE"; then
  echo "p2e-cursor-skills: workspace is p2e-plugin; nothing to install."
  exit 0
fi

# If this script was copied without the rest of the plugin, clone it.
if ! is_plugin_repo "$PLUGIN_ROOT"; then
  PLUGIN_ROOT="$PLUGIN_HOME"
fi

plugin_home_resolved() {
  cd "$PLUGIN_HOME" 2>/dev/null && pwd
}

clone_or_update_plugin() {
  if [[ ! -d "$PLUGIN_ROOT/.git" ]]; then
    mkdir -p "$(dirname "$PLUGIN_ROOT")"
    git clone --depth 1 --branch "$PLUGIN_REF" "$PLUGIN_REPO" "$PLUGIN_ROOT"
    return
  fi
  # Only pull the dedicated $P2E_PLUGIN_HOME clone. Never reset some other
  # checkout of p2e-plugin that merely provided this script.
  if [[ "$UPDATE" -eq 1 ]]; then
    local home_resolved
    home_resolved="$(plugin_home_resolved || true)"
    if [[ "$PLUGIN_ROOT" == "$PLUGIN_HOME" || "$PLUGIN_ROOT" == "$home_resolved" ]]; then
      git -C "$PLUGIN_ROOT" fetch --depth 1 origin "$PLUGIN_REF"
      git -C "$PLUGIN_ROOT" checkout -q -B "$PLUGIN_REF" "origin/$PLUGIN_REF"
    else
      echo "p2e-cursor-skills: --update skipped (plugin root is not \$P2E_PLUGIN_HOME); relinking only"
    fi
  fi
}

clone_or_update_plugin

if ! is_plugin_repo "$PLUGIN_ROOT"; then
  echo "p2e-cursor-skills: $PLUGIN_ROOT is not a p2e-plugin checkout" >&2
  exit 1
fi

mkdir -p "$WORKSPACE/.cursor/skills" "$WORKSPACE/.cursor/rules" "$WORKSPACE/.cursor"

git_exclude() {
  local pattern="$1"
  local exclude_file="$WORKSPACE/.git/info/exclude"
  [[ -d "$WORKSPACE/.git" ]] || return 0
  mkdir -p "$WORKSPACE/.git/info"
  touch "$exclude_file"
  grep -qxF "$pattern" "$exclude_file" 2>/dev/null || echo "$pattern" >> "$exclude_file"
}

link_into() {
  local src="$1"
  local dest="$2"
  local exclude_pattern="$3"
  if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ -L "$dest" ]]; then
      ln -sfn "$src" "$dest"
    else
      echo "p2e-cursor-skills: skip $dest (already exists and is not a symlink)"
      return 0
    fi
  else
    ln -sfn "$src" "$dest"
  fi
  git_exclude "$exclude_pattern"
}

# Stable workspace-relative pointer so agents can Read workflows without $HOME paths.
link_into "$PLUGIN_ROOT" "$WORKSPACE/.cursor/p2e-plugin" ".cursor/p2e-plugin"

for skill_dir in "$PLUGIN_ROOT/.cursor/skills"/*/; do
  [[ -d "$skill_dir" ]] || continue
  name="$(basename "$skill_dir")"
  link_into "${skill_dir%/}" "$WORKSPACE/.cursor/skills/$name" ".cursor/skills/$name"
done

link_into \
  "$PLUGIN_ROOT/.cursor/rules/p2e-policy.mdc" \
  "$WORKSPACE/.cursor/rules/p2e-policy.mdc" \
  ".cursor/rules/p2e-policy.mdc"

# Wrappers say `Read: workflows/<name>.md`. Symlink that tree when the product
# repo does not already have a top-level workflows/ directory.
if [[ ! -e "$WORKSPACE/workflows" ]]; then
  link_into "$PLUGIN_ROOT/workflows" "$WORKSPACE/workflows" "workflows"
fi

# writing-rich-docs Cursor wrapper points at skills/writing-rich-docs/.
if [[ ! -e "$WORKSPACE/skills/writing-rich-docs" ]]; then
  mkdir -p "$WORKSPACE/skills"
  link_into \
    "$PLUGIN_ROOT/skills/writing-rich-docs" \
    "$WORKSPACE/skills/writing-rich-docs" \
    "skills/writing-rich-docs"
fi

# Merge the P2E MCP server into .cursor/mcp.json when missing. Does not overwrite
# an existing `p2e` entry (the product repo's URL/auth wins).
python3 - "$WORKSPACE" "$PLUGIN_ROOT/.cursor/mcp.json" <<'PY'
import json
import pathlib
import sys

workspace = pathlib.Path(sys.argv[1])
plugin_mcp = pathlib.Path(sys.argv[2])
dest = workspace / ".cursor" / "mcp.json"
incoming = json.loads(plugin_mcp.read_text())
if dest.exists():
    current = json.loads(dest.read_text())
else:
    current = {"mcpServers": {}}
servers = current.setdefault("mcpServers", {})
changed = False
for name, cfg in incoming.get("mcpServers", {}).items():
    if name not in servers:
        servers[name] = cfg
        changed = True
if changed:
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(json.dumps(current, indent=2) + "\n")
    print(f"p2e-cursor-skills: merged MCP servers into {dest}")
else:
    print(f"p2e-cursor-skills: MCP already has p2e at {dest}")
PY

echo "p2e-cursor-skills: installed from $PLUGIN_ROOT into $WORKSPACE"
echo "p2e-cursor-skills: invoke /p2e, /p2e-work-on-next, /p2e-bind, … in Agent chat"
