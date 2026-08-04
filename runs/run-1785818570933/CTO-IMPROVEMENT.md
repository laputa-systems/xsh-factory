# CTO factory improvement

## Status

pending-validation

`pending-validation` records the reusable engineer-capacity adjustment below;
the next cycle must validate it before paid admission.

## Change

Raised the engineer role ceiling in `factory_control.xsh` from 0.25 to 0.35
USD and from 160 to 220 turns, with native assertions in
`tests/factory_control_test.xsh`. The previous cycle's engineer spent 160
turns on the runtime ticket without reaching validation or commit, so this is
a bounded capacity change, not an attempt to merge unverified product code.

## Baseline metric

`runs/run-1785818570933/phases/01-ticket/workers/engineer/task-envcfg-001/report.json`:
160 turns, 0.238560 USD, 9 tool errors, no commit or patch, and a
`SESSION-LIMIT` marker.

## Target metric

On the next approved engineer assignment, reach a clean committed branch and
reviewable report without a session-limit marker; keep spend within the new
0.35 USD ceiling.

## Validation

Run `XSH_MODULE_PATH=. xsht test`; verify the next engineer worker report has
`result: pass`, a completed `REPORT.md`, a commit and portable patch, and no
`SESSION-LIMIT` marker.

## Revert condition

If the next comparable engineer still reaches 220 turns or 0.35 USD without
reviewable output, revert both engineer ceilings to 160 turns and 0.25 USD.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted`
after the named verification, and link the evidence before admitting paid
work.
