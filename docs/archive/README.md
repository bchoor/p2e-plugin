# Archive — pre-v0.12 historical docs

These documents describe architecture and features from before v0.12, when the plugin shipped 15+ granular `/p2e-*` workflows backed by a shared `workflows/` tree.

**v0.12 consolidated all guidance into the single `p2e-mode` skill.** These files are kept for historical reference only — agents should not pattern-match against them as current operating instructions.

| Directory | Topic |
|---|---|
| [`feat-work-on-next-v2/`](feat-work-on-next-v2/) | v2 supervisor architecture (parallel story-lead waves) |
| [`feat-rich-html-docs/`](feat-rich-html-docs/) | Rich HTML doc rendering (`writing-rich-docs`, `/p2e-html`) |
| [`feat-task-ladder/`](feat-task-ladder/) | TaskCreate progress ladder for multi-story runs |
| [`superpowers/`](superpowers/) | Codex compatibility design notes |

Current entry point: [`skills/p2e-mode/SKILL.md`](../skills/p2e-mode/SKILL.md).

Orchestration contracts salvaged for subagents: [`agents/CONTRACTS.md`](../agents/CONTRACTS.md).
