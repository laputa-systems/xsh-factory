# Shared handbook lineage

## Factory handbook

All evals in this factory consume `runtime/handbook.md`. This run snapshots
that one approved document and validates the requested candidate lineage.

## Snapshots

- Approved: `lineage/handbook-approved.md` (`{{BASELINE_SHA}}`)
- Candidate: `lineage/handbook-candidate.md` (`{{CANDIDATE_SHA}}`)
- Trial 1 used: `{{TRIAL1_SHA}}`
- Trial 2 used: `{{TRIAL2_SHA}}`

## Controller checks

- Approved snapshot unchanged: `{{APPROVED_SNAPSHOT_UNCHANGED}}`
- Checked-in handbook unchanged: `{{CHECKED_IN_HANDBOOK_UNCHANGED}}`
- Lineage result: `{{LINEAGE_STATE}}`

Trial 1 always uses the approved snapshot. With one configured trial, the
candidate must be byte-identical to that snapshot. With two configured trials,
trial 2 uses the candidate snapshot. Promotion is never performed by the
controller; an approved candidate becomes the shared handbook only through
the documented review step.
