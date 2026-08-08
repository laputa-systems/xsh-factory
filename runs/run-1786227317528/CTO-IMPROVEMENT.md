# CTO factory improvement

## Status

pending-validation

`pending-validation` is retained because this run measured the 120-second
manager-idle change, but the manager still failed to produce a contract-complete
narrative within the bounded attempts. The next cycle must validate the new
report-first handoff together with the idle bound.

## Change

The run exercised the throughput machinery committed before admission:

- adaptive queue selection admitted the retained `task-histogram-006` branch;
- ticket pressure suppressed the independent eval lane (`independent_eval_target=0`);
- the evaluator manager received the controller-owned evidence packet;
- the manager idle ceiling was 120 seconds, below the 300-second normal wall
  limit and the 180-second retry wall limit;
- evaluator evidence remained isolated from the product branch.

The next factory change is report-first manager recovery: the assignment and
retry will require a complete staged narrative immediately after the required
structured reads, before any optional raw-session or artifact investigation.
The manager report remains fail-closed and the controller will not deliver on
an inferred or implicit acceptance decision.

## Throughput requirement

Zero reviewable engineer implementation commits were delivered. This is a
throughput failure. The retained engineer branch was validated by the primary
phase, but the evaluator manager did not produce a complete narrative, so the
controller correctly withheld delivery despite evaluator correctness and
restriction gates passing.

## Provider-health attribution

Provider telemetry was captured. The evaluator worker completed with 46
assistant turns and the manager attempts completed with 9 and 7 turns in their
structured reports. No provider retry or budget breach was recorded. The
manager delay is therefore attributed to report-production behavior and
evidence-review scope, not a demonstrated provider outage.

## Baseline metric

Run 3 delivered zero commits because the manager timed out at both 60-second
and 180-second walls. Run 4 improved the idle false-positive behavior: the
manager was allowed to continue active review under the 120-second idle bound,
and the evaluator passed, but the manager still left `REPORT.md` at
`not-ready`. Evidence: `phases/02-reeval-task-histogram-006/report.json` and
the two manager worker reports.

## Target metric

The next organization cycle must produce a contract-complete manager report
before the retry wall and, when evaluator gates and the explicit acceptance
token pass, deliver the admitted engineer implementation commit. The target
is one delivered product commit, zero independent evals while approved ticket
pressure exists, and no manager `not-ready` report after retry.

## Validation

Run the next organization request through `run.xsh` with the local evaluator
image already qualified. Verify:

1. `report.json` has `manager_report=true` and
   `candidate_acceptance=true` when the manager accepts;
2. the phase events contain `85-manager-validated`;
3. the organization events contain `85-ticket-...-delivered` and the ticket
   records `Merged.` with the amended implementation commit;
4. the root throughput data records at least one delivered commit;
5. the manager report contains no `not-ready`, `Fill from`, or `Fill every`
   placeholders.

## Revert condition

If a manager report is completed but the structured evaluator evidence fails,
or if the report-first handoff causes acceptance to be inferred without an
explicit machine token, revert the handoff optimization and preserve the
fail-closed manager gate. If the next run again leaves the report incomplete,
reduce the manager assignment to the structured packet plus one targeted
artifact check before changing wall limits again.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` only after the
named manager-report and delivered-commit invariants pass, or keep it pending
and record the next bounded repair with evidence.
