# CTO factory improvement

## Status

pending-validation

## Change

The organization request's independent-eval rotation was corrected from the disabled `task-col2` selection to the live, approved, untried `task-colsum` package in `cycle-organization.md`. The prior invalid rotation is recorded as reverted in `runs/run-1785888999833/CTO-IMPROVEMENT.md`.

## Throughput requirement

This cycle produced zero engineer implementation commits because all three Open tickets were correctly blocked: `task-envcfg-001` fails the API-surface quality gate, `task-tags-003` links to a disabled eval, and the newly generated `task-colsum-001` remains a convenience-API proposal without demonstrated semantic novelty. This is an intentional eval-to-ticket quality gate, not a dispatch failure.

## Provider-health attribution

Provider telemetry was present for all three workers in `runs/run-1785893827191/report.json`. Retries were zero and provider errors were unknown; response timing was not populated. Four nonzero tool results were agent workflow errors, not provider-health signals.

## Baseline metric

Prior run `runs/run-1785888999833/report.json`: one merged engineer commit, 167 turns, and $0.118816, but the independent eval used the disabled `task-col2` package and failed to produce a valid trial manifest. This run `runs/run-1785893827191/report.json`: zero engineer commits, 81 turns, $0.048801, and a passing `task-colsum` trial plus a rejected/incomplete `task-usagerep` proposal review.

## Target metric

The next organization cycle must select `task-colsum` as the independent approved untried eval, produce a valid trial manifest, and either approve a ticket with genuine API-surface novelty for one engineer commit or record a concrete quality-gate deferral before paid work. Target cost is at or below $0.048801 unless an admitted product ticket is delivered.

## Validation

Run `XSH_MODULE_PATH=. xsht test`, confirm `cycle-organization.md` names `task-colsum`, run `XSH_MODULE_PATH=. xsh run-cto.xsh`, and verify the next root report contains the selected untried eval and a valid `run.json`. Check that no convenience-only Open ticket is admitted without the API-surface justification gate.

## Revert condition

If the next run selects an eval other than the first approved untried eval, or if `task-colsum` lacks a valid evaluator manifest, revert the request rotation and repair the controller/package boundary before further paid work. Do not approve the convenience `fail` tickets without new semantic evidence.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted` after running the named verification and link the evidence before admitting paid work.
