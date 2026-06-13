<!--
Copilot repository instructions. Read by every Copilot Chat / agent-mode
interaction in this repo. Keep this short and project-specific; the
cross-cutting rulebook lives in AGENTS.md.
-->

# 🐙 Copilot repo instructions

These rules apply to every GitHub Copilot Chat / agent-mode interaction in
this repository. The authoritative cross-cutting rulebook is
[`AGENTS.md`](../AGENTS.md) — when this file and `AGENTS.md` disagree,
**`AGENTS.md` wins** for non-project rules.

## 🔍 Discoverability index — read before searching or creating

| Concern | Path |
|---|---|
| Top-level rulebook | [`AGENTS.md`](../AGENTS.md) |
| Claude / Gemini / Aider entry points | [`CLAUDE.md`](../CLAUDE.md), [`GEMINI.md`](../GEMINI.md), [`CONVENTIONS.md`](../CONVENTIONS.md) |
| Copilot chat modes | [`.github/chatmodes/`](chatmodes) |
| Copilot slash-command prompts | [`.github/prompts/`](prompts) |
| **Project plan** | **[`docs/planning/ROADMAP.md`](../docs/planning/ROADMAP.md)** — tick boxes as you complete deliverables per [ROADMAP_DISCIPLINE.md](../.agents/instructions/ROADMAP_DISCIPLINE.md) |
| Tracking model | [`ai/tracking.schema.md`](../ai/tracking.schema.md), [`docs/tracking/README.md`](../docs/tracking/README.md) |
| Curated skills | [`.agents/skills/README.md`](../.agents/skills/README.md) |
| **Agent instructions** | [`.agents/instructions/ROADMAP_DISCIPLINE.md`](../.agents/instructions/ROADMAP_DISCIPLINE.md) — **mandatory box-ticking discipline for every phase** |
| Agent ops scripts | [`xops/README.md`](../xops/README.md) |
| MCP servers | [`.mcp.json`](../.mcp.json), [`.vscode/mcp.json`](../.vscode/mcp.json) |

**Rule:** if a file in this index already exists, **read it; do not
recreate it**. If you believe an existing file is wrong, propose an edit —
never shadow it with a new file at a different path.

## ⚡ Hard rules (read AGENTS.md for the long form)

1. **Never `git commit` / `git push`.** Append a tracking row via
   [`xops/agent/tracking_append.sh`](../xops/agent/tracking_append.sh),
   then `git add -A`, then stop. Human runs `make git`.
2. **Tests move with code** in the same commit.
3. **No system-level changes** without explicit per-occurrence confirmation.
4. **Non-zero exit recovery**: wrap risky commands with
   [`xops/agent/safe-run.sh`](../xops/agent/safe-run.sh); read the log,
   diagnose, fix, resume. Never retry blindly.
5. **Session recovery**: run [`xops/agent/session-bootstrap.sh`](../xops/agent/session-bootstrap.sh)
   at session start; surface any unresolved `last_failure.json`.
6. **ROADMAP discipline**: Every time you complete a deliverable in [`docs/planning/ROADMAP.md`](../docs/planning/ROADMAP.md),
   immediately tick its checkbox `[x]` using `multi_replace_string_in_file`. Do not leave
   incomplete sub-phases unchecked. See [`.agents/instructions/ROADMAP_DISCIPLINE.md`](../.agents/instructions/ROADMAP_DISCIPLINE.md).

## 🧠 Load skills on demand

[`.agents/skills/`](../.agents/skills/) contains short, model-agnostic skill files.
Load the relevant one before the matching kind of work. Especially:

- [`test-driven-development`](../.agents/skills/test-driven-development/SKILL.md)
- [`systematic-debugging`](../.agents/skills/systematic-debugging/SKILL.md)
- [`verification-before-completion`](../.agents/skills/verification-before-completion/SKILL.md)
- [`self-review`](../.agents/skills/self-review/SKILL.md)
- [`phase-persistence`](../.agents/skills/phase-persistence/SKILL.md)
- [`parallel-subagents`](../.agents/skills/parallel-subagents/SKILL.md)

## 💬 Communication discipline

- One short status line per loop step.
- File paths as workspace-relative markdown links.
- After staging: report `run_id`, files staged, tests run/passed/failed. Four lines max.
- After a revert: report `run_id`, which gate failed, the corrective action.
<!--
.github/copilot-instructions.md — GitHub Copilot Chat / agent-mode rules.
This file delegates cross-cutting policy to AGENTS.md; it owns Copilot-specific
discovery hints, slash-command pointers, and chat-mode conventions.
-->

# 🐙 Copilot repo instructions

> **Primary rulebook:** [`AGENTS.md`](../AGENTS.md). When this file disagrees
> with `AGENTS.md`, AGENTS.md wins. This file owns Copilot-specific guidance
> (discoverability index, slash commands, chat modes).

## 🔍 Discoverability index — read before searching or creating

| Concern | Path |
|---|---|
| Master rulebook | [`AGENTS.md`](../AGENTS.md) |
| Vendor entry points | [`CLAUDE.md`](../CLAUDE.md), [`GEMINI.md`](../GEMINI.md), [`CONVENTIONS.md`](../CONVENTIONS.md) |
| Copilot chat modes | [`.github/chatmodes/`](chatmodes/) |
| Copilot slash-command prompts | [`.github/prompts/`](prompts/) |
| Skill library (load on demand) | [`.agents/skills/README.md`](../.agents/skills/README.md) |
| Project roadmap | [`docs/planning/ROADMAP.md`](../docs/planning/ROADMAP.md) |
| Tracking log + schema | [`ai/tracking.csv`](../ai/tracking.csv), [`ai/tracking.schema.md`](../ai/tracking.schema.md) |
| Agent state | [`ai/state/`](../ai/state/) |
| Ops scripts | [`xops/agent/`](../xops/agent/), [`xops/makefile/`](../xops/makefile/) |
| MCP config | [`.mcp.json`](../.mcp.json), [`.vscode/mcp.json`](../.vscode/mcp.json) |
| VS Code workspace | [`.vscode/settings.json`](../.vscode/settings.json), [`.vscode/tasks.json`](../.vscode/tasks.json) |

**Rule:** if a file in this index already exists, **read it; do not recreate it**.

## 📝 Hard rules (cross-cutting — see AGENTS.md for the full text)

1. **Never `git commit` / `git push`.** Append to `ai/tracking.csv`, stage, stop. Human runs `make git`.
2. **Tests move with code** in the same commit.
3. **No system-level changes** without explicit confirmation.
4. **Read session state** first — [`xops/agent/session-bootstrap.sh`](../xops/agent/session-bootstrap.sh).
5. **Wrap risky commands with** [`xops/agent/safe-run.sh`](../xops/agent/safe-run.sh) so output survives a killed terminal.
6. **Phase persistence:** when asked to implement a phase / sub-phase, drain every `[ ]` bullet before handing back. See [`.agents/skills/phase-persistence/SKILL.md`](../.agents/skills/phase-persistence/SKILL.md).

## 💬 Chat modes

| Mode | When | File |
|---|---|---|
| `planner` | Decomposing a request into a roadmap or implementation plan | [`chatmodes/planner.chatmode.md`](chatmodes/planner.chatmode.md) |
| `implementer` | Executing a plan / phase end-to-end with tracking + staging | [`chatmodes/implementer.chatmode.md`](chatmodes/implementer.chatmode.md) |
| `reviewer` | Self-review or peer-review of staged or recent changes | [`chatmodes/reviewer.chatmode.md`](chatmodes/reviewer.chatmode.md) |

## ⚡ Slash commands

| Command | Purpose |
|---|---|
| `/plan` | Produce a written plan (no code) for a request. |
| `/implement` | Execute a plan / phase end-to-end, ending in `staged` / `reverted` / `no-op` / `blocked`. |
| `/review` | Self-review or peer-review staged or recent changes against AGENTS.md rules. |
| `/track` | Append a tracking row (used implicitly by `/implement`). |
| `/roadmap-status` | Summarize ROADMAP checkbox progress. |

Prompts live under [`.github/prompts/`](prompts/).

## 🧠 Memory & notes

If you keep long-lived per-repo notes, store them under `ai/state/notes/`
(gitignored). The memory tool, when available, may keep its own scope under
`/memories/repo/` — do not duplicate large facts already in this file.
