# Ticket task-trim-001

## Status

Approved.

## CTO decision — 2026-08-07

- Decision: Approve for the second requested organization cycle.
- Evidence: `task-trim` passed its correctness and restriction trial and
  reproduced a general checker-diagnostic defect across multiple effect-guess
  probes; the ticket proposes a minimal diagnostic/documentation fix rather
  than a new syntax form.
- Admission: Dispatch one engineer and require the linked `task-trim` replay
  plus an independent helper-using eval before delivery. No `[pure]` keyword
  or unrelated effect redesign is admitted.

## Change target

- `product`

Factory changes are CTO-owned. Do not create a factory-target ticket for
engineer dispatch; report the infrastructure change to the CTO instead.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-trim`
- Shared handbook lineage: `runs/run-1786146336183/phases/03-eval/lineage/handbook-approved.md`
- Manager run: `runs/run-1786146336183/phases/03-eval/workers/eval-manager/task-trim/REPORT.md`
- Executor run: `runs/run-1786146336183/phases/03-eval/workers/eval-worker/task-trim-1/run.json`
- XSH baseline commit: `630d14261ce5cf0160bf9809e79e2fca12922c70`

## Observation

The eval-worker needed a side-effect-free helper (`trim_line`) callable from a
`main` proc that declares `[fs, error]` effects. Writing the helper with no
effect annotation (`proc trim_line(s: Str) -> Str`) made the checker reject the
call; the worker then tried `[none]`, `[no_effects]`, and `[pure]` as effect
markers, and all three failed with `unknown effect` / `expected effect name`.
The only acceptable spelling is the empty bracket form `proc trim_line(s: Str)
[] -> Str`. The checker/lint diagnostic for a no-annotation helper does not
point the agent at the `[]` fix.

## Evidence

- Worker session: `runs/run-1786146336183/phases/03-eval/workers/eval-worker/task-trim-1/session.jsonl.bz2` — the helper-fix turns where `[none]`, `[no_effects]`, `[pure]` were rejected and `[]` was discovered.
- Worker review: `runs/run-1786146336183/phases/03-eval/workers/eval-worker/task-trim-1/work/review.md` — documents the "unrestricted proc" diagnostic as misleading because it does not suggest the empty-bracket fix.
- Final artifact: `runs/run-1786146336183/phases/03-eval/workers/eval-worker/task-trim-1/work/trim.xsh` uses `proc trim_line(s: Str) [] -> Str`.
- Worker `report.json`: 9 tool errors, 44 thinking blocks, pass result.

## Diagnosis or hypothesis

Declaring a pure (no-host-effect) helper is a general XSH authoring task, not
specific to `task-trim`. A helper that reads no host state and raises no
errors is deliberately pure and must be annotated `[]`; a proc with no effect
annotation is instead treated as "unrestricted" and cannot be called from an
effect-declaring proc. The marker `[]` is non-obvious, and the diagnostics
returned for the three guessed spellings plus the "unrestricted proc" message
do not point at it. This is a learnability/ergonomics defect: either the
diagnostic should suggest the `[]` fix, or a readable pure marker should be
accepted. It is not task confusion — the same friction would recur for any
helper in any effect-using eval.

## North-star impact

Improving the discoverability of the pure-helper marker (or the diagnostics
that explain it) advances XSH learnability and ergonomics: an agent writing a
small helper in the common effect-using shape will stop guessing effect names
and reach a correct script faster with fewer rejected probes. Evidence that it
generalized: another eval that requires a pure helper (e.g. task-histogram,
task-dupcheck) shows fewer invalid effect probes and a shorter session under
the improved messaging.

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

A new keyword such as `[pure]` is a second spelling for the existing empty-list
`[]` effect marker and would add surface area; the likely smallest fix is a
diagnostic improvement, not a new keyword. If accepted, `[pure]`/`[none]`/
`[no_effects]` must carry identical checker/runtime semantics to `[]`, which is
a checker and API-registry change with documentation and test cost; the closest
existing spelling `[]` already expresses the semantics, so a new keyword needs
a strong learnability case before being admitted.

## Proposed XSH change

Smallest candidate: improve the checker/lint diagnostic so that when a
no-effect-annotation (unrestricted) proc is called from an effect-declaring
proc, the message names the fix — i.e. "declare the helper with an empty
effect list `[]`". Optionally document the `[]` pure marker in the canonical
reference/`xsht api`. Do not claim this is already implemented.

## Acceptance criteria

- A call to a no-annotation helper from an effect-using proc produces a
  diagnostic that names the `[]` effect-list fix (or the accepted pure marker).
- `task-trim` and at least one helper-using eval replay green against the new
  diagnostics with no regression in correctness.
- No behavior change for already-valid scripts.

## Scope and non-goals

- No change to effect semantics for `[]`-annotated procs.
- No new keyword unless a separate strong learnability case is added.
- Provider switching is out of scope.

## Post-merge evaluation

Replay `task-trim` (and a helper-using eval such as `task-histogram` or
`task-dupcheck`) on the merged XSH commit and verify the agent reaches a
correct script without guessing `[none]`/`[pure]`/`[no_effects]`.
