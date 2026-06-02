# 📂 `ai/` — agent runtime state

This folder is the agent's working memory.

| Path | Purpose | Source-controlled? |
|---|---|---|
| [`tracking.csv`](tracking.csv) | Append-only log of every agent action. | ✅ Yes — header + every row. |
| [`tracking.schema.md`](tracking.schema.md) | Schema for `tracking.csv`. | ✅ Yes. |
| `state/current.json` | The task the agent is currently running. | ❌ No (gitignored). |
| `state/checkpoint.json` | Mid-task interrupt point (written on SIGINT / 429). | ❌ No. |
| `state/last_failure.json` | Last non-zero-exit breadcrumb from `safe-run.sh`. | ❌ No. |
| `state/log.jsonl` | Append-only per-event log; tail with `tail -f`. | ❌ No. |
| `state/notes/` | Long-lived per-repo notes the agent wants to keep. | ❌ No. |

## Agent contract

Read first: [`../AGENTS.md`](../AGENTS.md) + [`tracking.schema.md`](tracking.schema.md).

Append a row whenever you do meaningful work — see the *Enum cheat-sheet*
in the schema for which `action` to use. Use
[`../xops/agent/tracking_append.sh`](../xops/agent/tracking_append.sh) —
never hand-edit `tracking.csv`.
