# Ticket task-envcfg-002

## Status

Open.

## CTO review

- Review cycle: `pre-cycle-1785801503` (2026-08-03)
- Decision: Deferred; retain `Open.` pending closure as a duplicate.
- Basis: This reproduces the same plain-`main` compact-runtime mismatch that
  was fixed and merged as `task-envcfg-007` at XSH commit `7c939db`.
- Next evidence: Reconcile the duplicate against the merged regression and
  close this ticket once the linked replay confirms the fix.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-envcfg` (`evals/task-envcfg/EVAL.md`)
- Shared handbook lineage: `runs/run-1785728831509/phases/03-eval/lineage/handbook-approved.md` (approved `c7c9dd9a…`; candidate `c7c9dd9a…` with one added sentence)
- Manager run: `runs/run-1785728831509/phases/03-eval/workers/eval-manager/task-envcfg/REPORT.md`
- Executor run: `runs/run-1785728831509/phases/03-eval/workers/eval-worker/task-envcfg-1` (trial 1)
- XSH baseline commit: `ea7dea2f2b436cce34262d7a02105cbb029243dd`

## Observation

The `xsh SCRIPT` entry point (the "compact runtime" the gym uses for a
script) refuses to run a `main` declared with a plain argument parameter,
while `xsht check` accepts the same signature. Reproduced twice in one
worker session:

```text
$ cat /work/envcfg.xsh        # initial worker version
proc main(argv: List[Str]) [env, fs, error] -> Result[Unit] {
  ...
}
$ xsht check envcfg.xsh       # passes
$ xsh envcfg.xsh /tmp/ours
err[runtime.compact-unsupported-main]: proc main could not run in the compact runtime
  /work/envcfg.xsh:1:1
  proc main(argv: List[Str]) [env, fs, error] -> Result[Unit] {
  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
runtime traceback
executable: /usr/local/bin/xsh
operation: main
error: compact-unsupported-main: proc main could not run in the compact runtime
rc=3
```

Second reproduction with a minimal case:

```text
$ cat /tmp/m2.xsh
proc main(argv: List[Str]) [fs, error] -> Result[Unit] {
  let dst = Path(argv.get(0)?)
  fs.write(dst, "hi")?
}
$ xsh /tmp/m2.xsh /tmp/out2
err[runtime.compact-unsupported-main]: proc main could not run in the compact runtime
rc=3
```

Positive controls in the same session:

- `proc main() [env, error] -> Result[Unit]` runs (parameterless main is fine);
- `proc main(...argv: List[Str]) [fs, error] -> Result[Unit]` runs and writes the
  file (rc=0, `/tmp/out4` created).

So the compact runtime dispatches a parameterless or rest/spread `main`, but
rejects a plain `argv: List[Str]` parameter at run time after `xsht check`
approved the program. The runtime error does not name the fix (use `...argv`),
and `xsh --help` (`xsh SCRIPT [ARGS...]`) documents no alternative runtime
selection.

## Evidence

- Worker session: `runs/run-1785728831509/phases/03-eval/workers/eval-worker/task-envcfg-1/session.jsonl` — session lines 98 and 104 are the two `isError: true` tool results quoted above (structured report turn numbers 47 and 50); line 93 is the check-accepted initial source; line 114 is the `...argv` positive control (`rc=0`, file written); line 115 is the one-line fix to `/work/envcfg.xsh` (`(argv:` → `(...argv:`); `xsh --help` probe at session line ~110 and `xsht api search:compact` / `language:cli.xsh-SCRIPT` probes show no documented plain-parameter restriction.
- Worker review: `runs/run-1785728831509/phases/03-eval/workers/eval-worker/task-envcfg-1/review.md`, section `## xsht friction` — "The runtime selects a 'compact' runtime for `proc main`, and it rejects a plain argument parameter: `proc main(argv: List[Str])` fails to run with `error: compact-unsupported-main`, while `proc main(...argv: List[Str])` (rest/spread parameter) runs fine. This asymmetry is undocumented in the handbook's main-procedure example and costs a failed-run cycle to discover."
- Structured tool errors: `runs/run-1785728831509/phases/03-eval/report.json` `data.tool_errors` and worker `report.json` `tool_errors` — both entries are `runtime.compact-unsupported-main`; no other failed Pi tool results in the session.
- Quantitative: trial passed 10/10 (`run.json` `correctness.all_exact: true`, `restrictions.passed: true`), so the defect did not block this eval; it cost the worker two failed runs and roughly turns 47–56 (~10 tool calls) to diagnose, ending with the `...argv` fix and the review.md friction note.

## Diagnosis or hypothesis

`xsh SCRIPT` dispatches `main` through a compact runtime whose entry-point
contract accepts only a parameterless `main` or the rest/spread form
(`...argv`). `xsht check` type-checks the plain-parameter form and reports
success, so the first signal an agent sees is a runtime failure whose message
("proc main could not run in the compact runtime") does not explain the
required signature. This is a general ergonomics/correctness problem, not an
envcfg recipe: any eval or script whose `main` reads arguments is one
wrong-form edit away from a confusing rc=3, and the checker gives false
confidence. The fix is either to make the compact runtime accept the plain
parameter form (semantically equivalent to `...argv` for a single list
argument) or to make both `xsht check` and the runtime error state the
requirement explicitly.

## North-star impact

The north star asks for clear, explicit boundaries and fewer repeated
discoveries. A checker/runtime contract mismatch with a non-actionable error
is exactly the opaque friction that costs agents turns and erodes trust in the
tooling. Making the documented `xsh SCRIPT` entry point predictable (support
the plain form, or reject it with a diagnostic that names `...argv`) would
remove ~10 turns of diagnostic work from the task-envcfg path and protect every
future argv-taking task. Evidence of generalization: after the change, a replay
of any argv-taking eval (task-envcfg, task-tags, task-ecount, task-logroll)
should show the worker writing `proc main(...argv: List[Str])` — or the
runtime accepting the plain form — with no `compact-unsupported-main` failed
run.

## Proposed XSH change

Smallest candidate, one of:

1. Make the compact runtime accept `proc main(argv: List[Str])` as equivalent
   to the rest form (dispatch the script arguments as that list), or
2. Make `xsht check` reject the plain-parameter `main` with a constructive
   diagnostic naming the rest form, or
3. Improve the runtime error to name the requirement, e.g. `proc main could
   not run in the compact runtime: main must declare its arguments as a rest
   parameter, e.g. proc main(...argv: List[Str])`.

Prefer (1) if the compact runtime can pass argv trivially; otherwise (2) and
(3) for an actionable message. Keep the parameterless-main behavior unchanged.

## Acceptance criteria

- `xsht check` accepts `proc main(argv: List[Str]) [fs] { ... }` and
  `xsh SCRIPT ARG` runs it, passing argv as the list; OR `xsht check` rejects
  the plain form with a diagnostic that names `...argv`; OR the runtime error
  names the rest-parameter requirement.
- `xsh SCRIPT ARG` on `proc main(...argv: List[Str])` continues to work
  (regression).
- A replay of `task-envcfg` on the merged change passes all 10 correctness
  cases with no `compact-unsupported-main` failed run.

## Scope and non-goals

- No change to `main`'s effects, return type, or `?` propagation semantics.
- Not an envcfg shortcut; the fix must apply to any script `main`, not just
  this eval.
- Does not cover the related but distinct compact-runtime issues tracked in
  `task-ecount-002` and `task-ecount-006` (compact indexed-IR compilation
  failures); those are separate triggers.

## Post-merge evaluation

The `task-envcfg` eval-manager will run a controlled replay against the merged
XSH commit using the current approved handbook lineage, verify no
`compact-unsupported-main` failure occurs regardless of which main form the
worker writes, confirm all 10 oracle cases still pass, and record acceptance
or rejection in that run's manager report.
