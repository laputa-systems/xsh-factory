# Factory run {{RUN_ID}}

## Result

{{RESULT}}

## Mode

`ticket-implementation`

## North-star status

This cycle implements user-approved XSH tickets in isolated worktrees. It does
not merge product changes or claim that an implementation is accepted; the
branch remains pending user review.

## Cycle

- Request: `CYCLE-REQUEST.md`
- Approved tickets: `{{TICKET_NAMES}}`
- XSH base commit: `{{XSH_COMMIT}}`

## Required outputs

- Director session: `{{DIRECTOR_STATE}}`
- SWE dispatch: `{{SWE_STATE}}`
- Patch artifacts: `{{PATCH_STATE}}`
- Cost report: `{{COST_STATE}}`
- Director report: `{{DIRECTOR_REPORT_STATE}}`
- Deterministic audit: `{{AUDIT_STATE}}` (`{{AUDIT_RESULT}}`)

Each validated ticket has a portable patch under `patches/`. A standalone
ticket cycle removes its clean temporary worktree after writing the patch;
an organization cycle retains it until the linked re-evaluation passes, then
removes it. The review branch remains in the XSH repository. See
`TICKET-DISPATCH.md`, `SWE-RESULTS.md`, `patches/`, `DIRECTOR-REPORT.md`,
`PROVENANCE.md`, `COST.md`, and `AUDIT.md`.
