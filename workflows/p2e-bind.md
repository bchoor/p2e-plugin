# P2E Bind Workflow

This workflow anchors the current repo to a P2E project by writing `.p2e/project.json`.
It is a shared behavior spec consumed by both the Claude wrapper (`commands/p2e-bind.md`)
and the Codex entrypoint (`skills/p2e-bind/SKILL.md`).

## Purpose

- Detect which P2E project the current repo belongs to without requiring the user to remember or pass a slug by hand.
- Write the binding file `.p2e/project.json` so the SessionStart and PreToolUse hooks can self-calibrate.
- The binding file is the **only** source of truth; hooks must not fall back to inference, env vars, or git remote guesses at runtime.

## Preconditions

- The current directory must be inside a git repo with a remote named `origin`.
- The user must be authenticated with the P2E MCP (`mcp__p2e__projects op=list` must return results).
- `git` must be available in PATH.

## Workflow

1. **Derive `owner/name` from git remote.**
   Run:
   ```
   git remote get-url origin
   ```
   Normalize the result to `owner/name`:
   - SSH form `git@github.com:owner/name.git` → strip prefix and `.git` suffix.
   - HTTPS form `https://github.com/owner/name.git` or `https://github.com/owner/name` → strip prefix and optional `.git` suffix.
   - Any other host: use as-is but warn that matching may not work.
   If the command fails (not a git repo, no origin remote), print a clear error and stop.

2. **List projects the user is a member of.**
   Call:
   ```
   mcp__p2e__projects op=list
   ```
   This returns all projects the authenticated user belongs to.

3. **Match on `githubRepo`.**
   Find the project(s) whose `githubRepo` field equals the normalized `owner/name` derived in step 1.
   - **Exactly one match**: proceed to step 4.
   - **No match**: print an error listing all candidate projects with their `slug` and `githubRepo` values so the user can investigate. Do not write anything. Stop.
   - **Multiple matches**: print an error listing the matching projects and ask the user to pick one by re-invoking with additional context. Do not write anything. Stop.

4. **Write `.p2e/project.json`.**
   Write to `<git-repo-root>/.p2e/project.json`:
   ```json
   {
     "slug": "<matched-project-slug>",
     "github_repo": "<owner/name>"
   }
   ```
   Create the `.p2e/` directory if it does not exist.

5. **Confirm and advise.**
   Print a confirmation message:
   ```
   Bound: project_slug="<slug>" → .p2e/project.json
   GitHub repo: <owner/name>

   Next steps:
     git add .p2e/project.json && git commit -m "chore: bind repo to P2E project <slug>"
   ```
   Remind the user to commit the file so all team members share the same binding.

## Error cases

- **Not a git repo or no origin remote**: exit with a clear message. Do not write anything.
- **No matching project**: list candidate projects (slug + githubRepo) so the user can debug the mismatch.
- **Multiple matching projects**: list them and ask the user to pick.
- **MCP error**: surface the raw error and suggest re-authenticating.
- **Write failure**: surface the OS error. Do not partially write.

## Non-goals

- Does not create the P2E project — the project must already exist.
- Does not push or commit the binding file — that is the user's responsibility.
- Does not modify any existing `project_slug` defaults in other commands.
