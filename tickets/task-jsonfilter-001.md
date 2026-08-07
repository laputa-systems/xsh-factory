# Ticket task-jsonfilter-001

## Status

Approved.

## CTO decision — 2026-08-07

- Decision: Approved for implementation in the next organization cycle.
- Evidence: `task-jsonfilter` reproduced a parser/lint contradiction twice;
  the evaluator remained byte-correct, and the linked acceptance criteria
  define a focused checker/lint regression.
- Admission: Dispatch one engineer and require the linked `task-jsonfilter`
  replay before delivery. The existing API-surface justification is present;
  prefer the lower-risk lint correction if it satisfies the acceptance tests.

## Change target

- `product`

Factory changes are CTO-owned. Do not create a factory-target ticket for
engineer dispatch; report the infrastructure change to the CTO instead.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `857154dfe505f0d01053c1b5311f44422070eb34`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-jsonfilter`
- Shared handbook lineage: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786136684797/phases/01-eval/lineage/handbook-approved.md` (candidate: `handbook-candidate.md`)
- Manager run: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786136684797/phases/01-eval/workers/eval-manager/task-jsonfilter/REPORT.md`
- Executor run: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786136684797/phases/01-eval/workers/eval-worker/task-jsonfilter-1/`
- XSH baseline commit: `857154dfe505f0d01053c1b5311f44422070eb34`

## Observation

The eval-worker wrote a typed record and returned it from a tail expression.
Annotating a record literal with its type in expression position —
`return {name: name, active: active, count: count}: Item` and, earlier,
`map { |r| {name: ..., count: ...}: Out }` — is rejected by `xsht check`:

```
err[parse.expected-terminator]: expected statement terminator
  jsonfilter.xsh:26:52
    return {name: name, active: active, count: count}: Item
err[parse.expected-expression]: expected expression
rc=2
```

The binding form `let item: Item = {...}` parses, but
`xsht lint` then reports `warn[lint.redundant-tail-return-binding]`
("tail binding `item` can be returned implicitly ... make the initializer the
final expression"), which directs the agent to write exactly the
`return {...}: Item` form that the parser rejects.

## Evidence

- Worker report: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786136684797/phases/01-eval/workers/eval-worker/task-jsonfilter-1/report.json` (tool_errors, turn 44)
- Session JSONL: `.../task-jsonfilter-1/session.jsonl` — the `: Out`/`: Item`
  parse errors at turns 41 and 44, and the `lint.redundant-tail-return-binding`
  warning plus the worker's failed fix at turn 46
- Artifact: `.../task-jsonfilter-1/jsonfilter.xsh` (final workaround:
  field-level annotations `let name: Str = json.get(...)?` with a plain
  structural record return)
- Review: `.../task-jsonfilter-1/review.md` (xsht friction section documents
  the trap)
- Evaluator: `.../task-jsonfilter-1/run.json` (all ten cases exact, pass)

## Diagnosis or hypothesis

This is a correctness inconsistency between two pieces of XSH tooling: a lint
rule ("redundant-tail-return-binding") recommends a transformation whose
target syntax the parser rejects. The `: Type` annotation is accepted only in
binding position (`let x: T = ...`), not as a postfix cast on an arbitrary
expression. Because the lint surfaces the exact invalid form, the agent is
steered into a parse-error loop (observed twice in this session). The defect
is general — it affects any record-producing program that uses a heterogeneous
or typed record returned from a tail expression, not this eval's JSON pipeline
specifically — and it is reproducible from the artifact and session evidence.

## North-star impact

A lint rule that recommends an unparseable rewrite erodes agent ergonomics and
trust in the toolchain, forcing wasted check/edit cycles on a task that a
clear rule would complete in one pass. Resolving this improves XSH's
learnability (predictable record-typing rules), ergonomics (lint advice is
always safe to apply), and trustworthy tooling, which compounds across every
eval that constructs or returns typed records. Generalization evidence: the
same parse-error/lint loop should stop reproducing in the replay of this eval
and in any other record-producing eval (e.g. task-histogram) once the rule is
correct — either by accepting expression-position casts or by suppressing the
lint for type-annotated binding forms.

## Proposed XSH change
## API-surface justification

For any new builtin, keyword, constructor, type, method, or syntax form, state:

- the semantic capability that existing XSH cannot express;
- the closest existing spelling and why it is insufficient;
- whether a desugaring, type-directed rule, declared error family, or library
  API would solve the problem with less surface area;
- the implementation and maintenance cost, including checker, runtime, API
  registry, documentation, and test changes; and
- the evidence and falsification replay required before approval.

An ergonomic shortcut that merely gives a second spelling to an existing
operation is not sufficient justification for product admission.

## Proposed XSH change

No new surface area is required. The smallest candidates are (engineer to
choose): (a) make the parser accept a postfix `: T` type annotation on a record
literal in expression position (desugaring to an annotated binding), or
(b) fix `lint.redundant-tail-return-binding` so it never recommends a rewrite
the parser rejects — i.e., it must not fire when the tail binding carries a
type annotation required to give the literal its type (suppress or adjust the
message). Option (b) is lower-risk and sufficient to remove the observed trap;
option (a) is the more ergonomic long-term surface. Do not claim either is
already implemented.

## Acceptance criteria

- `xsht check` accepts both `let x: T = {...}; return x` and (if (a) is
  chosen) `return {...}: T` with no parse error; at a minimum, `xsht lint`
  no longer suggests `return {...}: T` as a rewrite when `T` is an annotated
  record binding.
- A regression test covers a typed record returned from a tail expression,
  plus a block/`map` record cast.
- The linked eval-manager replay of `task-jsonfilter` (and ideally
  `task-histogram`) completes without the parse-error loop and stays
  byte-correct.

## Scope and non-goals

- Out of scope: enabling arbitrary postfix type casts on all expressions,
  changing the JSON module, or adding a new cast operator.
- The handbook workaround (annotate each field, return a plain structural
  record) is separate and already staged as a handbook candidate.

## Post-merge evaluation

Replay `/Users/josh/d/laputa-systems/xsh-factory/evals/task-jsonfilter` at the
merged XSH commit and re-check that the worker no longer reproduces the
`redundant-tail-return-binding`/parse-error trap while all ten cases remain
exact; also replay `task-histogram` as the falsification check that the
fix generalizes.
