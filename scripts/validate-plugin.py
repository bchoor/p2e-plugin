#!/usr/bin/env python3

import json
import pathlib
import sys


ROOT = pathlib.Path(__file__).resolve().parent.parent


def read_json(path: pathlib.Path):
    with path.open() as f:
        return json.load(f)


def read_text(path: pathlib.Path) -> str:
    return path.read_text()


def assert_true(condition: bool, message: str):
    if not condition:
        raise AssertionError(message)


def assert_equal(actual, expected, message: str):
    if actual != expected:
        raise AssertionError(f"{message}: expected {expected!r}, got {actual!r}")


def validate_json_files():
    codex_manifest = read_json(ROOT / ".codex-plugin" / "plugin.json")
    claude_plugin = read_json(ROOT / ".claude-plugin" / "plugin.json")
    marketplace = read_json(ROOT / ".claude-plugin" / "marketplace.json")
    mcp = read_json(ROOT / ".mcp.json")

    assert_equal(codex_manifest["name"], "p2e", "Codex plugin name mismatch")
    assert_equal(codex_manifest["skills"], "./skills/", "Codex skills path mismatch")
    assert_equal(
        codex_manifest["mcpServers"], "./.mcp.json", "Codex MCP path mismatch"
    )
    assert_equal(
        codex_manifest["interface"]["composerIcon"],
        "./assets/p2e-icon.svg",
        "Codex composer icon mismatch",
    )
    assert_equal(
        codex_manifest["interface"]["logo"],
        "./assets/p2e-icon.svg",
        "Codex logo mismatch",
    )

    plugin_entry = marketplace["plugins"][0]
    assert_equal(plugin_entry["name"], "p2e", "Marketplace plugin name mismatch")
    assert_equal(
        plugin_entry["version"],
        codex_manifest["version"],
        "Marketplace and Codex versions must stay in sync",
    )

    assert_true(
        "p2e-mode" in claude_plugin["description"],
        "Claude plugin description should reference p2e-mode",
    )
    assert_true("mcpServers" in mcp and "p2e" in mcp["mcpServers"], "Missing p2e MCP server")


def validate_expected_files():
    assert_true(
        not (ROOT / "commands").exists(),
        "commands/ must be removed — p2e-mode is the sole entry point",
    )
    assert_true(
        not (ROOT / "workflows").exists(),
        "workflows/ must be removed — guidance lives in p2e-mode skill",
    )

    expected_codex_skill_paths = {
        ROOT / "skills" / "p2e-mode" / "SKILL.md",
    }
    actual_codex_skill_paths = set((ROOT / "skills").glob("*/SKILL.md"))
    assert_equal(
        actual_codex_skill_paths, expected_codex_skill_paths, "Unexpected Codex skill set"
    )

    expected_cursor_skill_paths = {
        ROOT / ".cursor" / "skills" / "p2e-mode" / "SKILL.md",
    }
    actual_cursor_skill_paths = set((ROOT / ".cursor" / "skills").glob("*/SKILL.md"))
    assert_equal(
        actual_cursor_skill_paths,
        expected_cursor_skill_paths,
        "Unexpected Cursor skill set",
    )

    assert_true(
        (ROOT / ".cursor" / "rules" / "p2e-policy.mdc").exists(),
        "Missing .cursor/rules/p2e-policy.mdc",
    )

    for ref_file in (
        "README.md",
        "claude-code-plugins.md",
        "codex-plugins.md",
        "cursor-skills-rules.md",
        "cross-platform-pattern.md",
    ):
        assert_true(
            (ROOT / "reference" / ref_file).exists(),
            f"Missing reference/{ref_file}",
        )

    assert_true((ROOT / "CLAUDE.md").exists(), "Missing project-level CLAUDE.md")
    assert_true((ROOT / "AGENTS.md").exists(), "Missing AGENTS.md")
    assert_true((ROOT / "assets" / "p2e-icon.svg").exists(), "Missing p2e icon asset")

    install_script = ROOT / "scripts" / "install-p2e-cursor-skills.sh"
    assert_true(install_script.exists(), "Missing scripts/install-p2e-cursor-skills.sh")
    script_text = read_text(install_script)
    for required_phrase in (
        "repositoryDependencies",
        "--update",
        ".cursor/skills",
        "github.com/bchoor/p2e-plugin",
        "p2e-mode",
    ):
        assert_true(
            required_phrase in script_text,
            f"scripts/install-p2e-cursor-skills.sh missing {required_phrase}",
        )


def validate_p2e_mode_skill():
    for rel_path in (
        "skills/p2e-mode/SKILL.md",
        ".cursor/skills/p2e-mode/SKILL.md",
    ):
        content = read_text(ROOT / rel_path)
        for required_phrase in (
            "name: p2e-mode",
            "criteria op=propose",
            "Coder→Verifier→Auditor→Human",
            "Legacy `/p2e-*`",
        ):
            assert_true(
                required_phrase in content,
                f"{rel_path} missing required phrase: {required_phrase}",
            )


def validate_agents():
    expected_agents = {
        "p2e-architect.md",
        "p2e-staff-engineer.md",
        "p2e-story-lead.md",
        "p2e-verifier.md",
        "p2e-auditor.md",
    }
    actual_agents = {p.name for p in (ROOT / "agents").glob("*.md")}
    assert_equal(actual_agents, expected_agents, "Unexpected agent set")

    verifier = read_text(ROOT / "agents" / "p2e-verifier.md")
    auditor = read_text(ROOT / "agents" / "p2e-auditor.md")
    for required_phrase in (
        "criteria op=propose",
        "role: VERIFIER",
        "Do **not** Mark DONE",
    ):
        assert_true(
            required_phrase in verifier,
            f"agents/p2e-verifier.md missing: {required_phrase}",
        )
    for required_phrase in (
        "viewer_role: AUDITOR",
        "criteria op=propose",
        "verifier blind",
    ):
        assert_true(
            required_phrase in auditor.lower() or required_phrase in auditor,
            f"agents/p2e-auditor.md missing: {required_phrase}",
        )


def validate_policy_rule():
    policy = read_text(ROOT / ".cursor" / "rules" / "p2e-policy.mdc")
    for required_phrase in (
        "p2e-mode",
        "MCP is authoritative",
        ".p2e/project.json",
    ):
        assert_true(
            required_phrase in policy,
            f".cursor/rules/p2e-policy.mdc missing: {required_phrase}",
        )
    assert_true(
        "workflows/" not in policy or "deprecated" in policy.lower(),
        "p2e-policy.mdc should not require workflows/ as active surface",
    )


def main():
    validate_json_files()
    validate_expected_files()
    validate_p2e_mode_skill()
    validate_agents()
    validate_policy_rule()
    print("plugin validation passed")


if __name__ == "__main__":
    try:
        main()
    except AssertionError as exc:
        print(f"validation failed: {exc}", file=sys.stderr)
        sys.exit(1)
