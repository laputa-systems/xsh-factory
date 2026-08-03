# Ticket task-envcfg-001

## Status

Closed.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-envcfg` (`evals/task-envcfg/EVAL.md`)
- Shared handbook lineage: `runs/run-1785687503942/phases/03-eval/lineage/handbook-approved.md` (approved `c7c9dd9a…`; candidate `c7c9dd9a…` unchanged)
- Manager run: `runs/run-1785687503942/phases/03-eval/workers/eval-manager/task-envcfg/session.jsonl`
- Executor run: `runs/run-1785687503942/phases/03-eval/workers/eval-worker/task-envcfg-1` (trial 1)
- XSH baseline commit: `defa805a18b4708efeecaa4da9de7d2096bcfb41`

## Observation

XSH provides no documented way to construct an `Error` value or force a
controlled nonzero exit from user code. `Err("msg")` type-checks to
`Result[<unknown>, Str]`, not `Result[T, Error]`, and the checker's only
guidance on error construction points at error variants that do not exist. The
task-envcfg worker needed to exit nonzero and write no file when `CFG_PORT` is
malformed; the intended path is a `?`-propagated `Error`. The worker spent
roughly 20 of 56 thinking blocks (blocks 13–34, plus 48 and 53) searching for
an error constructor and finally resorted to a deliberately failing host call
(`env.get("__XSH_ENVCFG_NO_SUCH_VARIABLE__")?`), which emits a runtime
traceback about a fake environment variable to stderr on the failure path
instead of a clean controlled error.

Reproduced on the pinned image (XSH commit `defa805a`, `xsh-factory-base:latest`
= `sha256:5cc09587c6cf`, the exact image the worker ran):

```text
$ cat errcheck.xsh
proc main() [error] -> Result[Int] {
  return Err("boom")
}
$ xsht check errcheck.xsh
err[check.type-mismatch]: type mismatch
  errcheck.xsh:2:10
    return Err("boom")
           ^^^^^^^^^^^ expected Result[Int, Error], found Result[<unknown>, Str]
rc=2

$ cat vtest5.xsh
proc main() [error] -> Result[Int] {
  return Error(kind: "boom")
}
$ xsht check vtest5.xsh
err[check.error-removed]: `Error(kind: ...)` was removed; construct a declared error variant such as `FsError.NotFound(...)`
err[check.type-mismatch]: type mismatch
  vtest5.xsh:2:10
    return Error(kind: "boom")
           ^^^^^^^^^^^^^^^^^^^ expected Result[Int, Error], found Error
rc=2

$ cat fsvar.xsh
proc main() [fs, error] -> Result[Int] {
  return FsError.NotFound("nope")
}
$ xsht check fsvar.xsh
err[check.unresolved-name]: unresolved name
  fsvar.xsh:2:10
    return FsError.NotFound("nope")
           ^^^^^^^ unresolved name
rc=2
```

The API reference confirms the gap: `xsht api module:error`, `record:Error`,
`search:abort`, `search:raise`, `search:panic` all return `missing`;
`search:fail` returns only the `language.core` fallback/results entries;
`language.core.results` documents `Ok("ready")` but no error constructor;
`language.effect.error` documents `?` propagation but no way to originate an
error value. The only documented way to obtain a typed `Error` is a host
operation that actually fails.

## Evidence

- Worker session: `runs/run-1785687503942/phases/03-eval/workers/eval-worker/task-envcfg-1/session.jsonl` — the `Err`/`Error`/`FsError` probes and the final `env.get("__XSH_ENVCFG_NO_SUCH_VARIABLE__")?` workaround; thinking blocks 13–34 show the failed search (checking `Err("msg")` typing, `Error(kind: ...)`, `FsError.NotFound`, `EnvError`, `abort`/`fail`/`panic`/`raise`, `parse_int` fallbacks) before settling on the fake host call.
- Worker review: `runs/run-1785687503942/phases/03-eval/workers/eval-worker/task-envcfg-1/review.md`, sections `## XSH language proposals` ("A direct way to build an Error value for a controlled nonzero exit") and `## xsht friction` ("`Err` / error construction is under-specified").
- Manager host probes on the pinned image listed above, plus `xsht api` reference probes (`module:error`, `record:Error`, `search:abort`, `search:raise`, `search:panic`, `search:fail`, `language:core.results`, `language:effect.error`).
- Runtime side effect of the workaround: `candidate.9.stderr` and `candidate.10.stderr` show `runtime traceback … error: env-missing: environment value is unset … call path: proc main` on the malformed-port cases. The eval still passed (exit nonzero, no file, stdout clean), but the "controlled" failure is only achievable with a misleading traceback about a nonexistent variable.
- Quantitative metrics: `run.json` `result: pass`, `correctness.all_exact: true` (10/10 cases), `restrictions.passed: true`, `protocol.review_ok: true` — correctness is not in question; the ergonomics gap is the observation.

## Diagnosis or hypothesis

`Result[T, Error]` is the core error boundary; the handbook teaches `?`
propagation and the agent correctly reached for an error to propagate. But the
language cannot originate a typed `Error` value in user code, and the checker
actively misleads by suggesting `FsError.NotFound(...)`-style variants that
`xsht check` then rejects as `unresolved-name`. A silent, no-diagnostic
workaround (a fake failing host call that prints a traceback about a variable
that does not exist) is the only current mechanism, and it is exactly the kind
of opaque, boundary-hiding behavior the north star says XSH should avoid. This
is a general ergonomics/correctness problem, not an envcfg recipe: any
validation boundary, config check, assertion, or user-defined failure in any
eval or script needs either a clean error constructor or a documented
`fail(...)`/`abort(...)` primitive.

## North-star impact

The north star asks for clear, explicit boundaries and fewer repeated
discoveries. A language whose central failure mechanism (`?`) can only be fed
by real host failures forces agents to invent fake host failures for ordinary
validation logic, emitting confusing tracebacks and hiding intent. A documented
error constructor (e.g. `error("msg")` returning `Result[Unit, Error]`, or a
`fail("msg")` that aborts with nonzero exit and no traceback noise) would make
controlled failure as explicit as success, teachable in one handbook sentence,
and reusable across every future validation task. Evidence of generalization:
after the change, the task-envcfg failure path should be writable with a
one-line constructor, and a replay of any future validation eval should show
the worker using the constructor instead of a fake host call.

## Proposed XSH change

Smallest candidate, one of:

1. Add an error constructor usable as a value, e.g. `error("msg")` or a
   recoverable `Err` that unifies with the `Error` type family, so
   `return error("invalid CFG_PORT")` type-checks in a `Result[T, Error]`
   procedure and propagates a clean nonzero exit; or
2. Add a `fail("msg")` builtin (with an `error`-effect contract) that aborts
   the program with a nonzero exit and a concise message without a
   misleading host-operation traceback.

In both cases, update `language:core.results` (and the checker's
`err[check.error-removed]` message) so the documented way to create an error
value actually resolves, and so the checker stops suggesting
`FsError.NotFound(...)` variants that do not exist.

No change to host-failure propagation semantics.

## Acceptance criteria

- `xsht api language:core.results` documents how to construct an error value
  from user code (constructor name and signature), and the documented name
  type-checks in a `proc main(...) [error] -> Result[T]` body.
- `return Err("boom")` either type-checks as `Result[T, Error]` or the checker
  emits a constructive diagnostic naming the supported constructor (not a
  suggestion to use `FsError.NotFound(...)`).
- The task-envcfg malformed-port path can be written with a one-line error
  construction and exits nonzero without creating the output file, with no
  traceback about a nonexistent environment variable on stderr.
- A replay of `task-envcfg` on the merged change still passes all 10
  correctness cases byte-for-byte against the oracle.

## Scope and non-goals

- No change to `?` propagation or host-failure semantics.
- Not an envcfg shortcut; the constructor must be general (usable in any
  validation or assertion boundary).
- No change to the shared agent handbook inside XSH; the factory lineage owns
  the agent-facing handbook.

## Post-merge evaluation

The `task-envcfg` eval-manager will run a controlled replay against the merged
XSH commit using the current approved handbook lineage, verify that the
malformed-port path uses the documented constructor without a fake host call,
confirm all 10 oracle cases still pass, and record acceptance or rejection in
that run's manager report.

## Budget breach

- Reason: too difficult
- Worker run: [engineer run](runs/run-1785784385782/phases/01-ticket/workers/engineer/task-envcfg-001/report.json)
