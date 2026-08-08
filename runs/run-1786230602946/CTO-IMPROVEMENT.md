# CTO factory improvement

## Status

validated

The handbook-lineage gate repair was implemented and validated in the same
closeout by native tests and a fresh deterministic CTO inventory. It removes a
false preflight backlog without weakening substantive candidate review.

## Change

`factory/control.xsh::handbook_text_equivalent` and
`factory/runtime.xsh::unresolved_handbook_candidates` now recognize only
editorial apostrophe variants and outer whitespace as equivalent handbook
snapshots. The exact candidate hash remains required for every substantive
change, and `runtime/handbook-ledger.md` records the Run 10 snapshot
disposition. Regression coverage is in
`tests/factory_control_test.xsh::test_handbook_text_equivalent_ignores_editorial_drift`.

## Throughput requirement

Engineer implementation commits: `0`; fresh-engineer target: `0`. Run 10 was
correctly ticketless because inventory had two `Open.` tickets and zero
`Approved.` rows. No eligible product ticket existed, so the hard one-commit
goal was not applicable. Both discovery evals nevertheless passed and their
managers produced complete reports.

## Provider-health attribution

Provider telemetry was captured for all four workers. `task-bigfiles` had no
retry; `task-colsum` had one successful 503 retry after 2000 ms. This is
provider health, not an agent-efficiency regression. Total cost was
`$0.052743888`, with 4 workers, 97 assistant turns, 5 worker tool errors, no
budget failures, and no unknown costs.

## Baseline metric

Run 9 had 0 workers and failed before Pi because the reused explicit tag was a
broken image. Run 10 restored the intended path: both XSH builds passed, both
workers passed their nine-case evaluators, both managers completed report-first
closeout, and root product/evaluator/infrastructure outcomes were all `pass`.
See `report.json` and `phases/{01-eval,02-eval}/report.json`.

## Target metric

Keep no-op handbook snapshots out of the unresolved backlog while retaining a
hard disposition gate for substantive edits. The next inventory must report
zero unresolved candidates for the Run 10 lineage and native tests must remain
green.

## Validation

Validated now with `xsht test --jobs 1`: `144 passed; 0 failed; 0 skipped`, and
`XSH_MODULE_PATH=. xsh factory/tools/cto.xsh` now reports the Run 10 candidate
as non-blocking. The candidate hash
`9c3fc917935612d17cd065ad3c78bce13e17945c55e980b81f00fca3fa2ed857` remains
explicitly recorded in `runtime/handbook-ledger.md`; the checked-in handbook
is unchanged.

## Revert condition

If a candidate with substantive wording changes is ignored without an explicit
ledger entry, or if punctuation normalization causes two materially different
handbooks to compare equal, revert `handbook_text_equivalent` and return to
exact SHA-256 blocking while adding a narrower regression case.

## Next-cycle disposition

Validated. This handoff is linked to the Run 10 report, the ledger entry, the
144-test suite, and the deterministic CTO inventory.
