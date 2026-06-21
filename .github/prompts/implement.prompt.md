---
agent: agent
description: Execute a plan end-to-end. Drains every checklist bullet, ships tests with code, ends in staged / reverted / no-op / blocked.
---

# Implement a plan

Switch to the [`implementer` custom agent](../agents/implementer.agent.md).

## Core Rule: Complete Phase → No Interruption

**When `/implement #phase $PHASENUMBER` is given, you MUST complete every `[ ]` bullet in that phase without interruption.** Do not hand back to the user with partial completion. Do not cite token budget, context limits, or session boundaries as a reason to stop. You are responsible for draining the entire phase scope before the turn ends, using checkpoints and session memory if needed.

- ✅ **Complete scope**: every bullet → ticked `[x]`
- ✅ **Tests with code**: behavior-changing commits include tests
- ✅ **Tracking discipline**: one row per logical delivery unit
- ✅ **Checkpoints**: save progress in `docs/tracking/state/checkpoint.json` + session memory if turn is interrupted
- ❌ **No handoff**: "you can review and commit" is not a terminal state
- ❌ **No token excuses**: throttle context carefully so the phase completes in one session

## Inputs

- A plan (in chat, in `docs/planning/`, or referenced as a `[ ]` block in
  the ROADMAP). If no plan exists, run [`plan`](plan.prompt.md) first.
- **For phase implementation:** the phase ID (e.g., `0a.1`, `0a.2`, `0b`, `1.1`, etc.) from [ROADMAP.md](../../docs/planning/ROADMAP.md).

## Loop — one pass per `[ ]` bullet

**Keep looping until every bullet in the phase is `[x]` or you hit a documented blocker.**

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
6. **Tick the bullet's checkbox** in ROADMAP.md (or the plan document) using `multi_replace_string_in_file`.
7. `git add -A`.
8. **Move to the next `[ ]` bullet.** **Do not stop.** Do not hand back to the user. Do not cite token count or context limits. Keep going until:
   - Every bullet in the named phase is `[x]`, **OR**
   - You hit a documented real blocker (see [`phase-persistence`](../../.agents/skills/phase-persistence/SKILL.md)).

### Token & Context Management

If you approach context limits **before completing the phase:**

1. **Write a checkpoint** to `docs/tracking/state/checkpoint.json`:
   ```json
   {
     "phase": "0a.1",
     "completed_bullets": 5,
     "next_bullet": "Add prerequisite blocks",
     "last_tracking_run_id": "run-20260613...",
     "status": "in-progress",
     "timestamp": "2026-06-13T15:35:00Z"
   }
   ```
2. **Update session memory** ([`/memories/session/phase-checkpoint.md`](/memories/session/)):
   - Which bullets are done (with `[x]`)
   - Which are still pending
   - The exact next step
3. **Append a tracking row with `action=block`:**
   ```bash
   xops/agent/tracking_append.sh --action=block --status=blocked --summary="Phase 0a.1 75% complete; 2 bullets remaining; see checkpoint.json and session memory"
   ```
4. **Stage everything** (`git add -A`)
5. **Report** the checkpoint state to the user: "Paused at [bullet name]; checkpoint written."
6. **On session resume**, the next agent reads `checkpoint.json` + session memory + the ROADMAP and resumes mid-phase without restarting.

**This is not a terminal state (`staged`).** The phase is not complete until every bullet is `[x]` or explicitly blocked/deferred with justification.

Report exactly one. **For phase implementation, `staged` only reports when the ENTIRE phase is complete.**

- **`staged`** — **every `[ ]` bullet in the phase is now `[x]`, gates green, tracking rows appended, ROADMAP ticked, `git add -A` clean.** Report `run_id`s, file list, and the ticked box count. This is the **only success state for phase implementation**.
- **`reverted`** — a bullet failed, could not be fixed within the rules, and the user declined to unblock it. Append `action=revert, status=failed`. `git restore .`. *This should be rare; most failures can be fixed within the loop.*
- **`no-op`** — `git status -s` was already clean and no edit was needed (only for single-file plans, not phases).
- **`blocked`** — a documented real blocker hit (not a token budget). Write `docs/tracking/state/checkpoint.json` + session memory + `action=block` tracking row. *The phase is partially complete; the next session resumes from the checkpoint.*

**Note:** "I'll let you review and commit" is not a state. "Partial completion" is not a state. "Token limits" is not a state. Only `staged` (full phase done), `reverted` (fatal error, user opt-out), `no-op` (nothing to do), or `blocked` (real blocker, checkpoint written).
