# 📋 ROADMAP Discipline — Box-Ticking & Phase Completion

**Mandatory discipline for every agent implementation task.**

## Overview

The [ROADMAP.md](../../docs/planning/ROADMAP.md) is the **single source of truth** for
sequenced work. Each sub-phase (e.g., 0a.1, 0a.2, 1.1, etc.) contains specific deliverable
checkboxes `[ ]` that must be **ticked `[x]` the moment each deliverable is complete**.

This document enforces the box-ticking rhythm and prevents incomplete sub-phases from being
silently left unchecked, causing confusion for subsequent sessions and agents.

## The Rule

**Every time you complete a deliverable item listed under a sub-phase section, immediately
tick its checkbox in `ROADMAP.md` using `multi_replace_string_in_file`.** This applies
whether you are:

- completing a full sub-phase (0a.1, 0a.2, etc.)
- partially completing a sub-phase (some items done, others deferred)
- hand-off to another session (leave unchecked items clear + document the state in session memory)

## Timing

**Tick immediately after each logical deliverable completion**, not at the end of the session.
This keeps the ROADMAP's state synchronized with the working tree and prevents three problems:

1. **Lost context**: a killed terminal or session boundary should not erase progress from the ROADMAP
2. **Silent incompleteness**: an unchecked box may masquerade as "not started" when it is actually "50% done"
3. **Downstream confusion**: a later agent reads an outdated ROADMAP and redundantly re-does work or starts a phase too early

## Checkboxes per Sub-Phase

Each sub-phase (e.g., `0a.1 — Metric definitions, formulas & dependency model`)
lists **specific deliverables** as numbered or bulleted items with checkboxes:

```markdown
### Phase 0a.1 — Metric definitions, formulas & dependency model

- [ ] Author `docs/design/metrics/NN-<slug>.md` for **all 15 indicators** (...)
- [ ] Add a **prerequisite / dependency block** to each doc (...)
- [ ] Add a **validity note** to each doc (...)
- [ ] ...
```

**If you complete "Author 15 metric docs":** tick that box immediately.
**If you complete "Add prerequisite blocks":** tick that box immediately.
**If you defer "Add validity notes" to a later session:** leave it unchecked and document in session memory.

## Workflow

1. **Start a sub-phase task** → check its deliverable boxes in ROADMAP.md (read them first)
2. **Complete each deliverable** → run `multi_replace_string_in_file` to tick its checkbox
3. **Stage the ROADMAP change** → `git add docs/planning/ROADMAP.md` (part of your normal `git add -A`)
4. **Append a tracking row** (per AGENTS.md §2) with the summary and scope — the row and the ticked boxes move together

## Example Workflow

You are implementing Phase 0a.1 and complete "Author 15 metric docs":

```bash
# After creating all 15 docs:
$ multi_replace_string_in_file \
    filePath="docs/planning/ROADMAP.md" \
    oldString="- [ ] Author \`docs/design/metrics/NN-<slug>.md\` for **all 15 indicators**" \
    newString="- [x] Author \`docs/design/metrics/NN-<slug>.md\` for **all 15 indicators**"

# Continue with the next deliverable. When done with all 0a.1 items:
$ git add docs/planning/ROADMAP.md  # part of git add -A
$ xops/agent/tracking_append.sh \
    --action=commit \
    --status=completed \
    --summary="docs(phase-0a.1): author 15 metric definitions with formulas and prerequisites"
```

## Partial / Deferred Deliverables

**If you cannot complete all boxes in a sub-phase**, explicitly document the state:

1. **Tick the completed boxes** (as above)
2. **Leave unchecked boxes** for the next session
3. **Append a tracking row with `action=block` and the reason:**
   ```bash
   xops/agent/tracking_append.sh \
       --action=block \
       --status=blocked \
       --summary="docs(phase-0a.3): authored spike harness skeleton; main-loop implementation deferred pending full source probing"
   ```
4. **Write session memory** ([`/memories/session/phase-checkpoint.md`](/memories/session/)) with:
   - Which deliverables are done (ticked)
   - Which are not (not ticked, with reason)
   - Any blocking issues or dependencies
   - The exact next step for the next agent/session

Example session memory:

```markdown
# Phase 0a Checkpoint

## Completed ✓
- 0a.1: All 15 metric docs authored
- 0a.2: All 6 source reconnaissance docs authored
- Makefile gating targets added

## Deferred
- 0a.3: Main loop not implemented (spike harness skeleton exists)
- 0a.4: Verdict report not generated; config/metric_sources.yaml still skeleton
- 0a.5: Golden vectors partial (2 MVP fixtures; full 15-metric set deferred)

## Blocker
None. Ready to implement 0a.3 main loop on session resume.

## Next Step
Parse 15 metric docs + 6 source docs to extract (source, dataset, field) tuples;
deduplicate by unique endpoint; implement fetch loop in check-sources.sh main body.
```

## Avoiding Silent Incompleteness

**Anti-pattern:** Completing 80% of a sub-phase but leaving all boxes unchecked:
```markdown
- [ ] Write spike harness (80% done: skeleton + helper functions, no main loop)
- [ ] Populate yaml (0% done)
- [ ] Generate report (0% done)
```
→ A later agent reads this and thinks the **entire sub-phase is not started**.
→ They re-read existing code, waste time, or skip to the next phase.

**Better:** Tick the boxes you've actually shipped and explicitly document the rest:
```markdown
- [x] Write spike harness (skeleton complete with safety guards and helper functions)
- [ ] Populate yaml (TODO: parse spike evidence fixtures)
- [ ] Generate report (TODO: buildability ledger + kill list)
```
+ Session memory note: "Main loop implementation deferred; see checkpoint.md"

Now a later agent sees **what's done** and **what's blocked**.

## Make Targets & Phase Gating

Once you've ticked boxes for a sub-phase, the Makefile should reflect the state:

- Add `make spike.validate` target (Phase 0a.5 gate) only once you've authored the validation scripts
- Add `make slice.smoke` (Phase 0b.5 gate) only once the slice smoke script is complete
- Update `make doctor` to include new validation gates as each phase wires them

**Do not promise a target in the Makefile before its gate is implemented.**

## Sync with `make roadmap.status`

The `make roadmap.status` command (from AGENTS.md) reads the ROADMAP and counts checked boxes:

```
| Phase | Sub-phases | Items | Done | Status |
|---|---|---|---|---|
| 0a … | 5 | 30 | 12 | 🟡 in-progress |
```

**Ticking boxes keeps this metric honest.** A low "Done" count signals the next agent that
work remains; a high count signals readiness to move forward.

## Summary

- ✅ **Tick boxes immediately** as each deliverable completes
- ✅ **Stage the ROADMAP change** as part of `git add -A`
- ✅ **Document partial work** in session memory + a `block` tracking row
- ✅ **Never leave an 80%-complete deliverable unchecked**
- ✅ **Match Makefile targets to ROADMAP state** (don't add a gate target before its implementation)

This discipline is **mandatory for every agent session** implementing any ROADMAP phase.
