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

{{TRIAL_RULE}}
