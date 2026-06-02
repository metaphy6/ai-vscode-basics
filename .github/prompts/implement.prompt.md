---
mode: agent
description: Execute a plan end-to-end. Drains every checklist bullet, ships tests with code, ends in staged / reverted / no-op / blocked.
---

# Implement a plan

Switch to the [`implementer` chat mode](../chatmodes/implementer.chatmode.md).

## Inputs

- A plan (in chat, in `docs/planning/`, or referenced as a `[ ]` block in
  the ROADMAP). If no plan exists, run [`plan`](plan.prompt.md) first.

## Loop — one pass per `[ ]` bullet

1. Read the bullet, the *Goal*, and the *Test plan* line for that bullet.
2. Write the test first when the bullet adds behavior / fixes a bug.
3. Implement the smallest change that turns the test green.
4. Run the project's test gate. If red:
   - Read the log (via [`xops/agent/safe-run.sh`](../../xops/agent/safe-run.sh)).
   - Diagnose the root cause; fix it.
   - Restart from a clean tree if needed.
5. Append a tracking row via
   [`xops/agent/tracking_append.sh`](../../xops/agent/tracking_append.sh):
   `--action=commit --status=completed --commit-sha=pending --summary="..."`.
6. `git add -A`.
7. **Move to the next `[ ]` bullet.** Do not stop until every bullet in the
   named scope is `[x]` or you hit a real blocker (see
   [`phase-persistence`](../../.agents/skills/phase-persistence/SKILL.md)).

## Terminal states

Report exactly one:

- **`staged`** — every bullet closed, gates green, tracking rows appended,
  `git add -A` clean. Report `run_id`s and the staged file list.
- **`reverted`** — a bullet failed and could not be fixed within the rules.
  Append `action=revert, status=failed`. `git restore .`.
- **`no-op`** — `git status -s` was already clean and no edit was needed.
- **`blocked`** — a real blocker hit. Write `ai/state/checkpoint.json`.

Never end with "I'll let you review and commit" — that is not a state.
