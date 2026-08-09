# Ticket task-envcfg-008

## Status

Approved.

## Change target

- `product`

## CTO review

- Review cycle: `runs/run-1786254016688` closeout (2026-08-08).
- Decision: Approved for one bounded organization-cycle assignment.
- Basis: detected XSH baseline `e2a609a94d8f624b8dc7cc1efae62a2691d3cbc8`
  implements, specifies, and natively tests `error.fail(message)`, but the
  canonical discovery query `xsht api api:error.fail` returns `status:
  missing`. The factory handbook also retained obsolete advice to fabricate a
  failure with an unrelated conversion. This is a reproducible reference
  defect, not a request for another error mechanism.
- Duplicate review: `task-envcfg-002` addressed registry coverage for the
  earlier, reverted `fail` experiment (`2d423c1` was reverted by `a67599b`).
  The current namespaced `error.fail` was later introduced by merged
  `task-colsum-001` commit `5f46267` without a registry change, so the current
  baseline has the same class of omission but no live ticket for this existing
  symbol.
- Assignment boundary: register only the existing `error.fail` behavior in
  the canonical `xsht api` reference; add focused reference coverage. Do not
  modify checker, lowering, runtime semantics, error kinds, or introduce a
  second spelling.
- Product hygiene after detection: `7b4bee1a1cef74fed832331cd6cc5bb6e324c4ee`
  removes unrelated unreachable showcase code so the required fresh lint gate
  exits cleanly; it does not change this ticket's behavior or scope.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-envcfg` (`evals/task-envcfg/EVAL.md`)
- Shared handbook lineage:
  `runs/run-1786254016688/phases/01-eval/lineage/handbook-approved.md`
  (`eba997ebd583ac6f2eb0ac48feaf701f64696fcaf72e93626fae238102b46d32`)
- Manager run:
  `runs/run-1786254016688/phases/01-eval/workers/eval-manager/task-envcfg-retry-1/REPORT.md`
- Executor run:
  `runs/run-1786254016688/phases/01-eval/workers/eval-worker/task-envcfg-1/run.json`
- XSH baseline commit: `e2a609a94d8f624b8dc7cc1efae62a2691d3cbc8`

## Observation

On the current product checkout, `error.fail("header is missing")` is covered
by `tests/xsh/stdlib/test.xsh`, and `docs/SPEC.md` specifies that it constructs
an expected validation result. Yet both `xsht api api:error.fail` and
`xsht api search:fail` lack an exact `error.fail` reference entry. The shared
factory handbook consequently told workers to fabricate deliberate failures
through an unrelated typed conversion.

## Evidence

- CTO reproduction at the baseline above: `xsht api api:error.fail` reports
  `status: missing`; `xsht api search:fail` returns unrelated word matches but
  no exact feature entry.
- Product implementation and native coverage:
  `src/runtime/eval/lowered_run/indexed_run.rs` and
  `tests/xsh/stdlib/test.xsh:test_error_fail_constructs_validation_result`.
- Canonical product specification: `docs/SPEC.md` lines 109–111 and 190–191.
- Current factual mismatch: `runtime/handbook.md` lines 102–106 before this
  closeout stated that no generic error value was available and prescribed a
  sentinel typed conversion.
- The current `task-envcfg` manager completed its ten-case evaluation without
  a product ticket; CTO review, not the manager's generic recommendation,
  connects the reproducible reference discrepancy to this ticket.

## Diagnosis or hypothesis

`xsht api` is the product's canonical interactive reference. An existing
language operation that is specified and tested but absent from that index is
operationally undiscoverable to agents following the supported discovery path.
The mismatch makes a valid, named validation result appear absent and causes
the handbook to preserve workaround guidance. This is a reusable learnability
and efficiency issue at a product-reference boundary, not task-envcfg-specific
behavior.

## North-star impact

Making a shipped language capability discoverable through its canonical
reference removes avoidable probes and makes expected validation failures
explicit rather than accidental. The linked replay's API-query gate will prove
the product reference is present in the candidate build, while the unchanged
ten-case config contract guards against an unrelated regression. A later
independent deliberate-validation eval can measure agent adoption separately;
this ticket does not overclaim that result.

## API-surface justification

This ticket adds no builtin, keyword, constructor, type, method, syntax, or
runtime capability. `error.fail(message)` is existing behavior with existing
checker, lowering, specification, and native-test coverage. The smallest
change is a canonical reference entry for that existing operation, so no
semantic-novelty exception or second spelling is being admitted. The
falsification replay requires the exact API query to resolve from the candidate
build and leaves all environment behavior unchanged.

## Proposed XSH change

Add one `xsht api` registry entry for the existing `error.fail(message)`
operation, including its `Result[Unit, Error]` validation contract, `error`
effect requirement when propagated, and a focused API-reference test. Update
only canonical product reference material if the registry pattern requires it.

## Acceptance criteria

- `xsht api api:error.fail` succeeds and returns an exact entry that names
  `error.fail`, its validation-result purpose, and its error-effect boundary.
- `xsht api search:fail` includes the exact entry rather than only incidental
  word matches.
- Focused product coverage proves the registry entry remains present; existing
  `test_error_fail_constructs_validation_result` still passes.
- The linked `task-envcfg` replay passes all ten existing cases and its
  package-owned `task-envcfg-008` gate records
  `ticket_replay.error_fail_reference_passed: true`.

## Scope and non-goals

- No runtime, checker, lowering, Result, error-kind, or syntax change.
- No bare `Error(...)`, `fail(...)`, or other convenience spelling.
- No broad retrofit of every historical language feature into this ticket.
- No claim that task-envcfg itself should use `error.fail`; malformed ports are
  correctly handled by their typed environment conversion.

## Post-merge evaluation

The controller-owned linked replay of `task-envcfg` for `task-envcfg-008`
will run the candidate build. Its package evaluator must resolve
`xsht api api:error.fail` and preserve the ten existing config cases; the
eval-manager records the independent result before the organization controller
may merge the engineer's commit.
