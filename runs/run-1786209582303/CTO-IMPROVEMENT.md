# CTO factory improvement

## Status

pending-validation

`pending-validation` means the CTO has already implemented this change. It is
not awaiting another approval; the next cycle verifies the named metric or
applies the safe inverse.

## Change

Describe the concrete factory-wide code, prompt, controller, test, or policy
change and link the exact paths.

Cycle 25 validated fresh-first dispatch structurally: the fresh engineer row
and its linked replay ran before the retained replay was merged. It exposed a
false-negative delivery gate: `factory/control.xsh::reeval_manager_acceptance_gate`
did not recognize the fresh manager's plain-language statement that the
candidate re-evaluation was accepted, even though the report documented all
acceptance criteria and the trial passed. The next repair adds one narrow,
explicit acceptance form and native regression coverage; quality and
provenance gates remain hard.

## Throughput requirement

State whether the cycle produced at least one reviewable engineer
implementation commit. If not, classify the cycle as a throughput failure and
describe the corrective factory change; a passing eval-only cycle does not
satisfy this requirement when an eligible product ticket existed.

No. One fresh engineer row completed, but zero implementation commits were
delivered. With two eligible/admitted tickets, this is a throughput failure,
not an acceptable eval-only cycle.

## Provider-health attribution

State whether provider telemetry was captured. Do not treat latency as an agent
regression when retry, provider-error, or response-timing evidence indicates an
external provider-health issue; if telemetry is missing, state `unknown`.
satisfy this requirement when an eligible product ticket existed.

Telemetry was captured. The delivery miss is attributable to deterministic
acceptance-contract wording, not a provider outage; the fresh replay worker
and manager both produced usable evidence.

## Baseline metric

State the prior-cycle measurement and evidence path.

Cycle 24 delivered one fresh commit; cycle 25 delivered zero. Evidence:
`runs/run-1786206296254/report.json` and
`runs/run-1786209582303/report.json`.

## Target metric

State the measurable result expected in the next cycle.

At least one fresh engineer row and one delivered fresh commit, with the fresh
delivery event emitted before any retained replay delivery event.

## Validation

State the exact next-cycle command, report field, or invariant that will be
checked.

Run the next request through `run.xsh`; verify
`data.throughput.fresh_engineer_rows >= 1` and
`data.throughput.delivered_tickets >= 1`, inspect `events.jsonl` ordering, and
run the focused acceptance-gate regression plus the factory test suites.

## Revert condition

State the evidence that falsifies the change and the safe inverse action.

Revert the wording expansion if it admits explicit needs-replay, rejection, or
failed-acceptance language, or if a candidate passes without required trial,
restriction, and provenance evidence. Preserve the branch and reports and
restore the previous narrow gate.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted`
after running the named verification, and link the evidence before admitting
paid work.

Keep `pending-validation` until the next cycle proves one fresh delivery and
the acceptance regression is green. Then mark `validated`; otherwise preserve
the failure and revert the wording change.
