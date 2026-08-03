# Ticket task-envcfg-007

## Status

Open.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-envcfg` (`evals/task-envcfg/EVAL.md`)
- Shared handbook lineage: `runs/run-1785789595047/phases/03-eval/lineage/handbook-approved.md` (approved `97c5d804…`; candidate `handbook-candidate.md` with main-spread and `and`/`or` operator notes)
- Manager run: `runs/run-1785789595047/phases/03-eval/workers/eval-manager/task-envcfg/REPORT.md`
- Executor run: `runs/run-1785789595047/phases/03-eval/workers/eval-worker/task-envcfg-1` (trial 1)
- XSH baseline commit: `d2d87d2575c45343abfbcfe378f6ade4065043cf`

## Observation

`xsht check` accepts a `main` entry signature that the runtime cannot run.
Declaring `proc main(argv: List[Str]) [env, error] { ... }` (without the spread
parameter) passes `xsht check` with `rc=0`, but invoking `xsh SCRIPT` fails at
run time with a non-obvious message:

```text
err[runtime.compact-unsupported-main]: proc main could not run in the compact runtime
  /tmp/pi.xsh:1:1
  proc main(argv: List[Str]) [env, error] {
  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

The error text says nothing about the spread parameter being required, so the
worker spent several discovery iterations (testing `error`-effect removal,
other effect sets, even an empty `[]` main) before realizing the runtime
expects the spread form `main(...argv: List[Str])`. The working signature is
`proc main(...argv: List[Str]) [fs, env, error]`, which the worker confirmed
runs cleanly.

## Evidence

- Worker session: `runs/run-1785789595047/phases/03-eval/workers/eval-worker/task-envcfg-1/session.jsonl` — turn 36 (`/tmp/pi.xsh` with `main(argv: List[Str]) [env, error]` passes `xsht check` then `xsh` reports `runtime.compact-unsupported-main`), turn 43 (`/tmp/m3.xsh` repeats it), turn 55 (`/tmp/mt.xsh` even with `[]` effects still reports it), turn 58 (worker concludes "The spread `...` is required", runs with spread `[env, error]` and it works).
- Worker review: `runs/run-1785789595047/phases/03-eval/workers/eval-worker/task-envcfg-1/review.md`, section `## XSH language proposals`: "`proc main` must use the spread parameter form `(...argv: List[Str])`. Declaring `main(argv: List[Str])` passes `xsht check` but fails at runtime with `runtime.compact-unsupported-main`, which is a non-obvious link between the entry signature and the chosen runtime."
- Quantitative: trial passed 10/10 (`run.json` `correctness.all_exact: true`, `restrictions.passed: true`), so the gap did not block the eval; it cost the worker roughly turns 36–58 (~20 tool calls / several thinking blocks) to discover the spread requirement.

## Diagnosis or hypothesis

`xsht check` validates types and effects but does not validate the entry-point
shape against the compact runtime that `xsh SCRIPT` actually uses. The
resulting check-pass / run-fail split is a general correctness and ergonomics
defect: an agent writing any CLI entry-point script can get a green `xsht
check`, believe the program is valid, and only learn at run time that the
signature is unusable, with an error message that does not explain why. This is
not an envcfg-specific recipe: every eval that writes a `main` entry point
(task-tags, task-ecount, task-envcfg, and future glue tasks) pays the same
surprise on the first wrong guess. It is distinct from the open task-envcfg-004
ticket (about missing per-type `xsht api` index queries); this ticket is about
the entry-signature check/runtime mismatch.

## North-star impact

The north star asks for clear, learnable boundaries and fewer repeated
discoveries. A checker that reports success for a program the runtime cannot
run undermines trust in the toolchain and forces trial-and-error, exactly the
sludge XSH exists to remove. Fixing it means an agent's `xsht check` result is
a reliable signal for the entry point it will actually run, in every eval.
Evidence of generalization: after the change, any eval's worker that declares
`main(argv: List[Str])` (non-spread) should see `xsht check` reject it with a
constructive message naming the spread form, instead of passing check and
failing only at run time.

## Proposed XSH change

Smallest candidate, one of:

1. Make `xsht check` (or the runtime's static entry validation) reject a non-spread
   `main` parameter with a message like "main must use the spread form
   `(...argv: List[Str])`", so the failure is caught at check time, or
2. Keep the signature valid but improve the runtime message
   `runtime.compact-unsupported-main` to name the expected spread form.

Prefer (1): it moves the failure earlier and makes `xsht check` a trustworthy
gate for entry-point shape.

## Acceptance criteria

- A script declaring `proc main(argv: List[Str])` (single non-spread
  parameter) makes `xsht check` report a clear "use spread form" error rather
  than passing.
- `proc main(...argv: List[Str]) [fs, env, error]` still passes `xsht check`
  and runs under `xsh`.
- A replay of `task-envcfg` on the merged change shows the worker getting
  immediate check-time feedback on the spread requirement (no
  `runtime.compact-unsupported-main` run-time round-trip) and still passes all
  10 correctness cases byte-for-byte.

## Scope and non-goals

- No change to spread-parameter semantics, effects, or the runtime execution
  model.
- Not an envcfg shortcut; the entry-signature validation must apply to any
  `main` in any eval.
- Does not cover per-type `xsht api` index queries (task-envcfg-004) or the
  empty-signature defect (task-ecount-001); those remain separate tickets.

## Post-merge evaluation

The `task-envcfg` eval-manager will run a controlled replay against the merged
XSH commit using the current approved handbook lineage, verify the worker
receives check-time feedback on the spread form instead of a run-time
`compact-unsupported-main` round-trip, confirm all 10 oracle cases still pass,
and record acceptance or rejection in that run's manager report.
