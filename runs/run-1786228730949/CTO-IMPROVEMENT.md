# CTO factory improvement

## Status

validated

The report-first manager handoff introduced in the preceding closeout was
validated by this run.

## Change

The manager role, assignment, and bounded retry now require the staged
`REPORT.md` to be completed immediately after the required structured reads,
before optional raw-session inspection or artifact probing. The manager still
must include the exact acceptance token, and the controller still fails closed
when the token rejects or the narrative is incomplete.

## Throughput requirement

Zero reviewable engineer implementation commits were delivered. This cycle
had no branchless Approved ticket; it replayed a retained branch. Retained
validation is not fresh delivery and does not satisfy the eligible-cycle
throughput target. The zero is correctly classified as retained quality work,
not hidden as a fresh engineer result.

## Provider-health attribution

Provider telemetry was captured. The evaluator worker used 32 assistant turns
and the manager used 14; there were no provider retries or budget breaches.
The manager completed with a 171-second session span and a valid report, so
the earlier manager-latency issue is not attributable to a provider outage.

## Baseline metric

Run 4 (`run-1786227317528`) left the manager narrative incomplete after two
bounded attempts and delivered zero. Its evaluator passed, but the report
gate failed. Run 5's manager report is complete, has all required headings,
and contains `Candidate acceptance: fail.`.

## Target metric

For the next retained or fresh replay, the manager must produce a complete
report with no retry when possible, and the controller must preserve the
quality decision. For the next eligible fresh cycle, the target remains at
least one delivered engineer commit.

## Validation

Evidence is in `phases/02-reeval-task-histogram-006/report.json`,
`required-outputs.json`, and the manager `REPORT.md`. The report-first change
held: no `81-manager-retry-started` event was emitted, the narrative result is
`pass`, and the manager explicitly rejected the candidate because the
defining `filter` diagnostic was not exercised.

## Revert condition

Do not revert the report-first handoff because the quality gate rejected the
candidate. Revert only if a future manager report is accepted without the
exact token, omits structured tool errors, or is materially incomplete while
the controller marks it valid. A future report timeout should be treated as a
new evidence-backed machinery defect.

## Next-cycle disposition

Keep the handoff validated. Move `task-histogram-006` to `Open.` pending its
directed evaluator replay, and let adaptive selection consider the next
retained Approved branch. Do not claim fresh qualification until a branchless
Approved product ticket is available.
