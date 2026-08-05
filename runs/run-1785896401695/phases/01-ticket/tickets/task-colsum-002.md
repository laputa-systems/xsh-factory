# Ticket task-colsum-002

## Status

Approved.

## CTO decision — next organization cycle

- Review cycle: next organization cycle.
- Decision: Approved for one bounded engineer assignment.
- Basis: The linked `task-colsum` replay reproduced a general pipeline-sugar/desugaring inconsistency across several near-equivalent forms. The ticket proposes no new API surface, has focused acceptance criteria, and is small enough for one engineer. Its linked eval is live and the follow-up replay can falsify both implementation and documentation claims.
- Assignment boundary: make the smallest parser/desugarer or diagnostic/documentation change that establishes one consistent contract for the reported pipeline forms. Preserve existing Result/`?` semantics, avoid new syntax or stream stages, and add focused regression tests plus canonical docs where appropriate.
- Acceptance gate: clean portable commit, linked stream replay addressing the previously failing shapes, and independent eval manifest passing.

[tickets/task-dupcheck-001.md]
@INS.AFTER
-## Status
## CTO decision — next organization cycle

- Review cycle: next organization cycle.
- Decision: Deferred; do not approve or dispatch.
- Basis: This is an infrastructure ticket, but its linked eval identifier is malformed as `evals/task-dupcheck` rather than the package ID `task-dupcheck`, and the evaluator packaging defect is not yet repaired. The current organization controller requires a live linked eval and a valid replay boundary; approving it now would risk a second harness-only failure.
- Next evidence: normalize the linked eval ID, repair the evaluator container's `factory_control` module provisioning, and run a valid trial with a manifest before admission. Keep `Open.`.

Open.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-colsum`
- Shared handbook lineage: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785894766939/phases/02-reeval-task-colsum-001/lineage/handbook-approved.md`
- Manager run: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785894766939/phases/02-reeval-task-colsum-001/workers/eval-manager/task-colsum/REPORT.md`
- Executor run: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785894766939/phases/02-reeval-task-colsum-001/workers/eval-worker/task-colsum-1/run.json`
- XSH baseline commit: `e5d29c7ec8b4411dc749fd3e44bf472d641ad9f4` (candidate under test: `5f46267067991d5af1d988732e5c2f6f5de5ad04`)

## Observation

The pipeline-sugar desugaring contract is inconsistent about which stage forms
desugar, and the errors do not say why. In the `task-colsum-1` worker session
several equivalent-looking pipelines were rejected while a different spelling
worked:

- `let x = text.lines() |> collect() |> get(0)?` — rejected with
  `pipeline sugar was not desugared` (a Result-returning method stage at the
  pipe tail).
- `where { |e| e.value == header }` (explicit block parameter over an
  `enumerate()` result) — rejected with `unresolved proc command`, while the
  field-shorthand `where .value == header` in the identical pipeline was accepted.
- A plain local `hr |> split(",")` receiver was rejected by the desugarer while
  the same expression as a bound value (`let parts = hr.split(",")`) worked.

The agent had to discover these by trial and error; none of the messages
explain the accepted spelling.

## Evidence

- Worker session: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785894766939/phases/02-reeval-task-colsum-001/workers/eval-worker/task-colsum-1/session.jsonl.bz2.bz2` (messages ~50–85: `pipeline sugar was not desugared` on `|> get(0)?` and on `hr |> split(",")`; `unresolved proc command` on `where { |e| e.value == header }`; repeated empirical `/tmp/tp*.xsh` probes before the shorthand `.value` form).
- Submitted artifact `/work/colsum.xsh` uses the working spelling (`where .value == header`, `first())?`).
- Worker `review.md` records the inconsistency verbatim under `## XSH language proposals`.

## Diagnosis or hypothesis

This is candidate-agnostic XSH ergonomics friction, not task confusion: the
desugarer accepts some stage shapes (method call with receiver, shorthand
field predicates) and rejects near-identical ones (a plain-receiver method at
the pipe tail, a Result-returning stage at the pipe tail, a block-parameter
`where` predicate over an `enumerate()` result) with messages that do not name
the silent rule. Any agent writing a stream pipeline hits this as exponential
trial-and-error. The smallest change is not a new builtin but a documented,
consistent desugar contract (and better error text) covering: which receivers
desugar, whether a Result-returning stage is allowed at the pipe tail, and
whether `where` accepts a block parameter or only the `.field` shorthand.
This is general across every stream-based eval (`task-groupsum`,
`task-tags`, `task-jsonfilter`, `task-countsum`), not a `task-colsum` trick.

## North-star impact

A consistent pipeline contract improves learnability (one documented shape
instead of an empirical black list) and agent efficiency (fewer invalid
probes, lower token spend, fewer tool errors) across the whole family of
stream-based evals. Success evidence: a later stream eval resolving the same
shape the first time, with no `pipeline sugar was not desugared` /
`unresolved proc command` discovery loop, or the API reference showing the
stage rule up front.

## Proposed XSH change
## API-surface justification

- Semantic gap: the pipeline sugar has no single documented rule for which
  stage forms desugar, so equivalent spellings behave differently with
  uninformative errors.
- Closest existing spelling and why it is insufficient: the field-shorthand and
  bound-value forms work but the contract is undocumented, forcing empirical
  discovery; there is no way to learn the accepted shape from the error.
- Whether a desugaring rule solves it with less surface: yes — a documented
  desugar contract plus targeted error text is smaller than any new syntax.
- Implementation and maintenance cost: parser/desugarer path plus API-reference
  and handbook text, with tests for each stage shape (receiver source, plain
  local pivot, Result-returning tail stage, block-parameter vs shorthand
  predicate).
- Evidence/falsification replay required: a stream-based eval resolving the
  previously-failing shapes correctly and without extra discovery turns.

## Proposed XSH change

Document (and, where reasonable, align) the pipeline-sugar desugar rule so a
plain receiver source and a plain local pivot desugar identically, a
Result-returning method stage is lawful at the pipe tail, and `where`/predicate
stages accept a consistent block-parameter or shorthand form; update the
`pipeline sugar was not desugared` and `unresolved proc command` errors to name
the required spelling. Describe the smallest candidate implementation; do not
claim it is implemented.

## Acceptance criteria

- A stream eval reproduces the previously-failing shapes (`|> get(0)?`,
  `local |> split(...)`, `where { |e| e.value == ... }` over `enumerate()`)
  with no desugar/proc-command error, or the documented contract explains why
  a given shape is invalid.
- The API reference / handbook names the stage forms that desugar.

## Scope and non-goals

Does not change Result/`?` semantics; does not add new stream stages; does not
change the submitted `colsum.xsh` behavior.

## Post-merge evaluation

The exact linked eval-manager replay
(`runs/run-1785894766939/phases/02-reeval-task-colsum-001/workers/eval-manager/task-colsum/REPORT.md`)
and a follow-up stream eval will accept or reject the merged change by
confirming the previously-failing shapes resolve without an empirical
discovery loop.
