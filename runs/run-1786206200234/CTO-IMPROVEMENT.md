# CTO factory improvement

## Status

pending-validation

`pending-validation` means the CTO has already implemented this change. It is
not awaiting another approval; the next cycle verifies the named metric or
applies the safe inverse.

## Change

The cycle-24 admission attempt exposed a manager-authored ticket identity
formatting gap: `task-grep-001` recorded an annotated eval value, and
`ticket_eval` treated the annotation as part of the selector. The deterministic
parser now extracts the canonical first token in `factory/control.xsh`, with a
regression case in `tests/factory_control_test.xsh`.

## Throughput requirement

No engineer row ran and no model budget was spent; this was an admission
failure, not a paid throughput cycle. The paid cycle-24 hard target remains at
least one delivered engineer commit.

## Provider-health attribution

No provider telemetry was applicable because admission stopped before dispatch.

## Baseline metric

Cycle 23 produced one reviewable fresh commit and zero delivered commits; see
`runs/run-1786202908216/report.json` and its productivity report.

## Target metric

Cycle 24 paid run: at least one delivered engineer commit and linked replay
acceptance/manager-report gates true.

## Validation

Re-run `run.xsh templates/ORGANIZATION-REQUEST-CYCLE-24.md`; admission must
accept `task-grep-001` and the resulting run must satisfy
`report.json.data.throughput.delivered_tickets >= 1`.

## Revert condition

If the annotated ticket still fails admission, or if canonical unannotated
ticket IDs regress, retain this admission evidence and revert only the parser
normalization after isolating the ticket fixture.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted`
after running the named verification, and link the evidence before admitting
paid work.
