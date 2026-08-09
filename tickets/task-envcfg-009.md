# Ticket task-envcfg-009

## Status

Approved.

## Change target

- `product`

## CTO review

- Review cycle: `runs/run-1786255756177` closeout (2026-08-08).
- Decision: Approved as the scoped successor to closed `task-envcfg-008`.
- Basis: `error.fail(message)` is specified, lowered, and natively tested, but
  canonical API registration makes `error` a standard-module name. The product
  contains 609 established local bindings named `error`; rejecting each would
  be a broad, unrelated source migration. The recorded candidate proved the
  registry and linked replay behavior, but its silent checker exception was
  outside the prior ticket's reference-only contract. This ticket makes the
  compatibility rule, specification, and regression coverage explicit.
- Duplicate review: this supersedes only the closed reference-only
  `task-envcfg-008`; it is not a second spelling, new error mechanism, or
  replacement for the existing `args` exception.
- Assignment boundary: expose only the existing `error.fail` operation and
  define `error` as a documented local-binding compatibility exception. Keep
  all runtime, lowering, Result, error-kind, and syntax behavior unchanged.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `7b4bee1a1cef74fed832331cd6cc5bb6e324c4ee`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-envcfg` (`evals/task-envcfg/EVAL.md`)
- Shared handbook lineage:
  `runs/run-1786255756177/phases/02-reeval-task-envcfg-008/lineage/handbook-approved.md`
  (`c1295e0ad1caaf0387c18293b8be7c79ebf567afd45154d4850912f686783618`)
- Manager run:
  `runs/run-1786255756177/phases/02-reeval-task-envcfg-008/workers/eval-manager/task-envcfg/REPORT.attempt-1.md`
- Executor run:
  `runs/run-1786255756177/phases/02-reeval-task-envcfg-008/workers/eval-worker/task-envcfg-1/run.json`
- XSH baseline commit: `7b4bee1a1cef74fed832331cd6cc5bb6e324c4ee`

## Observation

The candidate build recorded an exact `xsht api api:error.fail` result and a
passing package-owned replay gate, but registering that existing runtime module
caused the standard-module-shadow checker to reject the product's widespread
local `error` result bindings. The candidate preserved those bindings by adding
an undocumented exception; the specification currently documents only `args`.

## Evidence

- `runs/run-1786255756177/phases/01-ticket/workers/engineer/task-envcfg-008/REPORT.md`
  and provenance event `75-ticket-task-envcfg-008-provenance` record the
  candidate and its focused checks.
- `runs/run-1786255756177/phases/02-reeval-task-envcfg-008/workers/eval-worker/task-envcfg-1/run.json`
  records all ten task cases and the `error_fail_reference_required/passed`
  gate as `true`.
- Candidate commit `b9ddeadc3dcc6e51ecd3d1d81aa8675066d2c7a3` adds `error` to
  the registry and shows the two necessary checker sites. `rg` over product
  source found 609 existing local `error` bindings.
- `docs/SPEC.md` lines 295–304 define registry module names as reserved and
  document the sole `args` exception.

## Diagnosis or hypothesis

The API registry is the authoritative discoverability and standard-module
contract. Adding an existing runtime module to it must either reserve a name
or explicitly preserve compatible local bindings. `error` is the conventional
payload name for `Err(error)` matches, so a silent exception would make the
language contract misleading while a wholesale rename is disproportionate.
A documented, regression-tested exception is the smallest durable policy.

## North-star impact

Agents can discover and use the existing deliberate-validation operation with
an exact API query, while existing programs retain their ordinary error-result
bindings. Making the tradeoff explicit prevents a reference improvement from
quietly changing language validity and gives future standard-module additions
a clear compatibility precedent.

## API-surface justification

No builtin, keyword, constructor, type, method, or syntax form is added.
`error.fail(message)` already exists with its current Result and error-effect
contract. The only language-policy change is whether the already conventional
identifier `error` may remain a local binding after the existing module becomes
registry-visible. Existing `Err(error)` patterns are not a competing API or
desugaring; preserving them is a compatibility rule, not a new spelling.

## Proposed XSH change

Register the existing `error.fail(message)` module function in the canonical
API registry and documentation. Make `error`, like the already documented
`args` exception, legal in ordinary local binding positions; update
`docs/SPEC.md` to name its distinct rationale. Add focused API and checker
regressions that prove both the exact reference and local-binding behavior.

## Acceptance criteria

- `xsht api api:error.fail` returns an exact entry with the existing validation
  Result and error-effect contract; `xsht api search:fail` includes it.
- `docs/SPEC.md` documents why local `error` bindings remain legal while other
  registry module names stay reserved.
- Focused product tests prove an ordinary local `error` binding remains valid
  and an unshadowed `error.fail(...)` call keeps its existing effect contract.
- No runtime, lowering, error-kind, Result, parser, or syntax behavior changes.
- The package-owned `task-envcfg-009` replay gate passes all ten config cases
  and records the exact `error.fail` API reference as passed.
- `cargo build -p xsht --bin xsht` and `target/debug/xsht lint --fix` leave the
  candidate worktree clean.

## Scope and non-goals

- No bare `Error(...)`, `fail(...)`, or second deliberate-failure spelling.
- No general relaxation for other standard-module names.
- No broad source rename of current local `error` bindings.
- No task-envcfg behavior change beyond the package-owned reference gate.

## Post-merge evaluation

Run the controller-owned linked `task-envcfg` replay for `task-envcfg-009`.
The evaluator must resolve the exact API reference and preserve all ten config
cases; the eval-manager must record `Candidate acceptance: pass.` before the
organization controller may merge the provenance commit.
