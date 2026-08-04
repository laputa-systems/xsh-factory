# CTO factory improvement

## Status

pending-validation

`pending-validation` means the CTO has already implemented this change. It is
not awaiting another approval; the next cycle verifies the named metric or
applies the safe inverse.

## Change

The CTO consolidated the historical handbook candidates into
`runtime/handbook.md`, added the comment-syntax rule, and recorded every
candidate hash in `runtime/handbook-ledger.md`. The controller now blocks
undispositioned handbook candidates, renders lineage/backlog evidence in
`tools/cto-report.xsh`, re-evaluates each passing engineer independently, and
uses a comment-aware subprocess restriction helper in `factory_control.xsh`.
The stream-stage implementation from `task-envcfg-005` was merged to XSH as
`d2d87d2`.

## Baseline metric

Prior cycle: one admitted engineer completed the useful stream fix, but the
factory had no enforced handbook disposition gate and did not surface the
historical candidate backlog. This run admitted two engineers concurrently;
the structured report at `report.json` records six workers, $0.542220 total,
one budget breach, and one valid engineer implementation. The failed sibling
also exposed wrong-path exploration in its session evidence.

## Target metric

The next paid cycle must start with zero unresolved handbook candidates,
preserve two-engineer admission, and re-evaluate a passing ticket even when a
sibling ticket fails. The evaluator restriction regression must classify a
comment containing `run ` as allowed while still rejecting real
`process.run(...)`/`spawn` source.

## Validation

Run `XSH_MODULE_PATH=. xsht test`, inspect the next `CTO-REPORT.md` handbook
backlog, require `required-outputs.json` to show the handbook lineage gate,
and require linked re-evaluation events for every worker report with
`result: pass`. Replay `task-envcfg` after the scanner fix and compare its
`classification`, `correctness.all_exact`, and restriction fields.

## Revert condition

If any candidate is not ledger-dispositioned, if a valid sibling is skipped
from re-evaluation, or if the scanner still rejects comment-only occurrences,
stop paid admission, retain the run evidence, and revert only the faulty
controller/scanner change. If the handbook rule is contradicted by a clean
replay, record rejection in the ledger rather than deleting the lineage.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted`
after running the named verification, and link the evidence before admitting
paid work.
