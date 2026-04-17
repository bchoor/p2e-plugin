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
        "description" in claude_plugin and "/p2e-work-on-next" in claude_plugin["description"],
        "Claude plugin description should reference /p2e-work-on-next",
    )
    assert_true("mcpServers" in mcp and "p2e" in mcp["mcpServers"], "Missing p2e MCP server")


def validate_expected_files():
    expected_commands = {
        "p2e-add-story.md",
        "p2e-archaeology.md",
        "p2e-bind.md",
        "p2e-bootstrap.md",
        "p2e-sync-labels.md",
        "p2e-update-story.md",
        "p2e-work-on-next.md",
    }
    actual_commands = {p.name for p in (ROOT / "commands").glob("*.md")}
    assert_equal(actual_commands, expected_commands, "Unexpected Claude command set")

    expected_workflows = {
        "p2e-add-story.md",
        "p2e-archaeology.md",
        "p2e-bind.md",
        "p2e-bootstrap.md",
        "p2e-first-turn-briefing.md",
        "p2e-policy.md",
        "p2e-sync-labels.md",
        "p2e-update-story.md",
        "p2e-work-on-next.md",
    }
    actual_workflows = {p.name for p in (ROOT / "workflows").glob("*.md")}
    assert_equal(actual_workflows, expected_workflows, "Unexpected shared workflow set")

    expected_skill_paths = {
        ROOT / "skills" / "p2e" / "SKILL.md",
        ROOT / "skills" / "p2e-add-story" / "SKILL.md",
        ROOT / "skills" / "p2e-archaeology" / "SKILL.md",
        ROOT / "skills" / "p2e-bind" / "SKILL.md",
        ROOT / "skills" / "p2e-bootstrap" / "SKILL.md",
        ROOT / "skills" / "p2e-sync-labels" / "SKILL.md",
        ROOT / "skills" / "p2e-update-story" / "SKILL.md",
        ROOT / "skills" / "p2e-work-on-next" / "SKILL.md",
    }
    actual_skill_paths = set((ROOT / "skills").glob("*/SKILL.md"))
    assert_equal(actual_skill_paths, expected_skill_paths, "Unexpected Codex skill set")

    assert_true((ROOT / "assets" / "p2e-icon.svg").exists(), "Missing p2e icon asset")


def validate_wrapper_references():
    workflow_map = {
        "commands/p2e-add-story.md": "workflows/p2e-add-story.md",
        "commands/p2e-archaeology.md": "workflows/p2e-archaeology.md",
        "commands/p2e-bind.md": "workflows/p2e-bind.md",
        "commands/p2e-bootstrap.md": "workflows/p2e-bootstrap.md",
        "commands/p2e-sync-labels.md": "workflows/p2e-sync-labels.md",
        "commands/p2e-update-story.md": "workflows/p2e-update-story.md",
        "commands/p2e-work-on-next.md": "workflows/p2e-work-on-next.md",
        "skills/p2e-add-story/SKILL.md": "workflows/p2e-add-story.md",
        "skills/p2e-archaeology/SKILL.md": "workflows/p2e-archaeology.md",
        "skills/p2e-bind/SKILL.md": "workflows/p2e-bind.md",
        "skills/p2e-bootstrap/SKILL.md": "workflows/p2e-bootstrap.md",
        "skills/p2e-sync-labels/SKILL.md": "workflows/p2e-sync-labels.md",
        "skills/p2e-update-story/SKILL.md": "workflows/p2e-update-story.md",
        "skills/p2e-work-on-next/SKILL.md": "workflows/p2e-work-on-next.md",
    }

    for rel_path, workflow_ref in workflow_map.items():
        content = read_text(ROOT / rel_path)
        assert_true(
            "workflows/p2e-policy.md" in content,
            f"{rel_path} must reference workflows/p2e-policy.md",
        )
        assert_true(
            workflow_ref in content,
            f"{rel_path} must reference {workflow_ref}",
        )

    router = read_text(ROOT / "skills" / "p2e" / "SKILL.md")
    for workflow_ref in (
        "workflows/p2e-policy.md",
        "workflows/p2e-bootstrap.md",
        "workflows/p2e-add-story.md",
        "workflows/p2e-update-story.md",
        "workflows/p2e-work-on-next.md",
        "workflows/p2e-sync-labels.md",
    ):
        assert_true(workflow_ref in router, f"Router skill missing {workflow_ref}")


def validate_add_story_contract():
    add_story_skill = read_text(ROOT / "skills" / "p2e-add-story" / "SKILL.md")
    add_story_workflow = read_text(ROOT / "workflows" / "p2e-add-story.md")

    for required_phrase in (
        "ALWAYS show a preview",
        "NEVER silently create",
        "stop and report the concrete blocker briefly",
    ):
        assert_true(
            required_phrase in add_story_skill,
            f"skills/p2e-add-story/SKILL.md missing add-story guardrail: {required_phrase}",
        )

    for required_phrase in (
        "Never write the story",
        "## Required preview contents",
        "## Required confirm step",
        "accept and write",
        "If the user does not accept, do not write.",
        "GitHub issue will be created with the `ready` label",
    ):
        assert_true(
            required_phrase in add_story_workflow,
            f"workflows/p2e-add-story.md missing add-story contract phrase: {required_phrase}",
        )


def validate_update_story_contract():
    update_story_skill = read_text(ROOT / "skills" / "p2e-update-story" / "SKILL.md")
    update_story_workflow = read_text(ROOT / "workflows" / "p2e-update-story.md")
    add_story_command = read_text(ROOT / "commands" / "p2e-add-story.md")
    add_story_workflow = read_text(ROOT / "workflows" / "p2e-add-story.md")

    for required_phrase in (
        "ALWAYS show an annotated preview",
        "NEVER silently mutate",
        "stop and report the concrete blocker briefly",
    ):
        assert_true(
            required_phrase in update_story_skill,
            f"skills/p2e-update-story/SKILL.md missing update-story guardrail: {required_phrase}",
        )

    for required_phrase in (
        "## Required preview contents",
        "## Required confirm step",
        "## Thicken rules",
        "## Steer rules",
        "## Thick-gate on DRAFT → OPEN",
        "## GitHub issue reconciliation",
        "Accept and write",
        "If the user does not accept, do not write.",
        "failingClauses",
    ):
        assert_true(
            required_phrase in update_story_workflow,
            f"workflows/p2e-update-story.md missing update-story contract phrase: {required_phrase}",
        )

    for surface, content in (
        ("commands/p2e-add-story.md", add_story_command),
        ("workflows/p2e-add-story.md", add_story_workflow),
    ):
        assert_true(
            "/p2e-update-story" in content,
            f"{surface} must document the --fill deprecation shim pointing at /p2e-update-story",
        )


def main():
    validate_json_files()
    validate_expected_files()
    validate_wrapper_references()
    validate_add_story_contract()
    validate_update_story_contract()
    print("plugin validation passed")


if __name__ == "__main__":
    try:
        main()
    except AssertionError as exc:
        print(f"validation failed: {exc}", file=sys.stderr)
        sys.exit(1)
