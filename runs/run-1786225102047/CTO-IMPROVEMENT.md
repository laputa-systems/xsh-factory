# CTO factory improvement

## Status

validated

## Change

This run exposed and repaired the organization controller's independent-lane
admission. The queue policy computed zero independent evals for a retained
ticket cycle, but `factory/controllers/organization.xsh` still unconditionally
created `03-eval` whenever a ticket was selected. The controller now creates
that phase only when `independent_eval_requested` is true. The regression is
covered by `tests/tools_test.xsh::test_ticket_cycle_bounds_concurrent_engineers`
and the full native suite.

## Throughput requirement

This was not a fresh-eligible delivery cycle: the inventory contained three
approved product tickets, all with retained implementation branches, and no
branchless ticket. The retained row was admitted, but its linked replay stopped
at the local XSH distribution build before any worker started. Therefore the
cycle delivered zero commits and is classified as a retained-validation and
infrastructure failure, not as a fresh-engineer target failure. The failure
must not be hidden by counting the retained row as fresh throughput.

## Provider-health attribution

No Pi worker started (`workers=0`, cost `$0.00`), so provider telemetry is not
applicable. The replay failure is attributable to the local Docker toolchain:
the `xsh-test` image lacked `linux/random.h` and `libunwind`, and the build
failed while compiling `aws-lc-sys`.

## Baseline metric

The implementation tranche's deterministic baseline was 140/140 native tests,
with the organization policy targeting zero independent evals whenever a
product row was selected. The run's admission evidence recorded
`independent_eval_target=0`, but the event ledger nevertheless showed an
independent eval start. Evidence: `events.jsonl`,
`report.json.data.throughput`, and
`phases/02-reeval-task-histogram-005/xsh-build.stderr`.

## Target metric

On the next organization run, a request with one retained or fresh product row
and no explicit independent eval must emit no
`10-independent-eval-*-started` event and must reserve the paid budget for the
delivery/replay path. The retained replay must reach its package evaluator;
if its gates pass, exactly one retained engineer commit must be delivered to
XSH `HEAD`.

## Validation

Run `xsht test --jobs 1` and inspect the next organization
`events.jsonl`/`report.json`: the independent lane must be absent when the
request's adaptive target is zero. Also verify the retained/fresh outcome split
in `data.throughput` and the delivery provenance event if the replay passes.

## Revert condition

Revert this controller change only if a native or completed-run case proves
that an explicit independent eval is silently dropped, or that a ticketless
organization request cannot still select its adaptive discovery evals. The
safe inverse is to restore the phase boundary only for explicit eval requests,
not to return to unconditional independent work in product cycles.

## Next-cycle disposition

Validated by `runs/run-1786225653459/events.jsonl`: the retained ticket cycle
recorded `independent_eval_target=0` and `independent_evals=0`, so the
independent-lane admission repair held. The next improvement under test is the
session-watch timestamp conversion recorded in that run's handoff.
