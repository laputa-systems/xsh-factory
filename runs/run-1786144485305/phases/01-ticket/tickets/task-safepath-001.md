# Ticket task-safepath-001

## Status

Approved.

## CTO decision — 2026-08-07

- Decision: Approved for implementation in the next organization cycle.
- Evidence: `task-safepath` passed all correctness and restriction cases, and
  its manager identified a general product gap: deliberate validation failure
  currently requires a traceback-producing `parse_int?` workaround.
- Admission: Dispatch one engineer and require the linked `task-safepath`
  replay before delivery. The engineer may implement the smallest documented
  quiet-exit API; no unrelated error or exception redesign is admitted.

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

- Eval: `task-safepath`
- Shared handbook lineage: `runs/run-1786142295779/phases/02-eval/lineage/handbook-approved.md`
- Manager run: `runs/run-1786142295779/phases/02-eval/workers/eval-manager/task-safepath/REPORT.md`
- Executor run: `runs/run-1786142295779/phases/02-eval` (workers/eval-worker/task-safepath-1)
- XSH baseline commit: `a248267612439dfcfa203fba583ac3e95d37f70c`

## Observation

A program that must deliberately fail with a nonzero exit status on a
validation failure has no clean way to do so. `task-safepath` must exit
nonzero when the relative path escapes the root. The only mechanism the
pinned XSH build provides is to propagate an expected failure from a typed
conversion, e.g. `let _ = "invalid".parse_int()?`. That produces the correct
nonzero exit code but dumps a full runtime traceback to stderr:

```
runtime traceback
executable: /usr/local/bin/xsh
operation: result.propagate
error: parse-int: invalid integer `invalid`
call path:
  1. proc main at /work/safepath.xsh:1:1-1:1
```

The external `sh` oracle for the same escape cases exits nonzero with an
empty stderr; every candidate escape case in the trial carried this spurious
traceback. The evaluation currently compares only stdout and exit
success/failure, so the run passed, but the traceback is noise that any
stricter stderr contract or a human reading a supervisor log would reject.

## Evidence

- Worker session: `runs/run-1786142295779/phases/02-eval/workers/eval-worker/task-safepath-1/session.jsonl.bz2` — turns 25-28 the agent discovers the `parse_int?` exit idiom and confirms stdout carries only the escape line while stderr carries the traceback.
- Artifact: `.../task-safepath-1/safepath.xsh` (lines using `"invalid".parse_int()?`).
- Evaluator: `.../task-safepath-1/run.json` (result `pass`; escape cases exact).
- Candidate/oracle stderr contrast: `candidate.5..8.stderr` each contain the traceback; `oracle.5..8.stderr` are empty.
- Worker `report.json` (result `pass`, 4 exploratory tool errors, none on the exit path).

## Diagnosis or hypothesis

This is a reusable XSH language ergonomics gap, not task-specific confusion.
Any systems-glue program that validates input — installers, chroot/jail setup,
service supervisors, configuration loaders — needs an explicit, quiet way to
terminate with a chosen status. Current XSH forces the author either (a) to
fabricate a failing typed conversion, which emits a traceback the program did
not intend, or (b) to leave the process running and rely on a later unrelated
failure, which weakens the exit contract. The handbook already documents the
absence ("This build has no generic `Error(...)` constructor; do not invent an
error value"), and the safe-path eval contract itself names an explicit
`abort`/exit as the intended mechanism, confirming the capability is wanted but
missing.

## North-star impact

Resolving this would give XSH a direct deliberate-failure exit that keeps
diagnostics off stdout and off stderr when the author wants a quiet status,
making validation boundaries explicit and trustworthy — the XSH rationale's
"make expected failures visible" without turning every validation exit into an
error traceback. It would also remove several exploratory turns:
`task-safepath` spent most of its session discovering how to exit nonzero
cleanly. Evidence of generalization: the same quiet-exit idiom should be reused
by other validator-style evals (`task-envcfg`-style rejection, `task-pathsafe`
descendants) without re-deriving the `parse_int?` workaround.

## Proposed XSH change

Add a small, explicit deliberate-exit capability — for example a builtin that
terminates with a given exit status and optional stderr message without the
`result.propagate` traceback (`abort`/`exit(CODE)`, or a non-tracebacking
`Error(...)` constructor that the checker separates from an invented value).
Keep the existing Result/`?` path for in-band expected failures; this change is
only about clean process termination after the decision to fail.

## API-surface justification

- Semantic capability not expressible today: terminate the program with a
  chosen nonzero status on a validation decision without emitting a runtime
  traceback. Today every clean-exit attempt is a fabricated typed failure.
- Closest existing spelling: `"literal".parse_int()?` propagation — produces
  the right exit code but appends a traceback and is semantically misleading
  (the string never needed parsing).
- Desugaring / type-directed rule: an effect-tagged builtin (e.g. `abort` with
  the exit-status effect) is simpler than a new error family and avoids
  touching Result semantics; alternatively a declared `exit` error family. A
  library wrapper around `parse_int?` that suppresses the traceback is
  insufficient because the traceback comes from the runtime propagation path,
  not the program.
- Cost: checker addition for a new core builtin/effect annotation, runtime
  process-termination path, API-registry entry, handbook sentence, and a few
  tests. No change to Result/`?` semantics.
- The evidence / falsification gate is the linked eval-manager replay, which
  must show escape
  cases exiting nonzero with clean stderr, matching the oracle exactly, and a
  second validator-style eval reproducing the quiet exit without re-deriving a
  workaround.

## Proposed XSH change

Describe the smallest candidate implementation or bug fix. Do not claim that
the change is already implemented.

## Acceptance criteria

- A program can terminate with a chosen nonzero status with no traceback on
  stderr (empty stderr on the escape path).
- Existing `Result`/`?` expected-failure propagation is unchanged.
- `xsht check`/`fmt`/`lint` accept the new form, and the API registry documents
  it.
- `task-safepath` replays pass all escape cases with stderr identical to the
  oracle (empty), and stdout byte-for-byte identical.

## Scope and non-goals

- Not changing provider handling, the evaluator, or the harness.
- Not adding general `try/catch` or exception machinery; only clean, explicit
  process termination.
- Not removing the `parse_int?` propagation path.

## Post-merge evaluation

The next `task-safepath` manager replay (and one additional validator-style
eval) must accept the merged change when escape cases exit nonzero with empty
stderr and identical stdout, and reject it otherwise.

## CTO review

- Review cycle: ramp-05 four-way discovery, 2026-08-07.
- Decision: Superseded by the CTO approval above; dispatch one engineer in the
  next organization delivery cycle.
- Basis: The evaluator confirms the proposed behavior is correct, but the
  quiet-exit API is not implemented and needs a product engineer cycle. Keep
  the ticket separate from the staged handbook candidates and require a
  post-merge replay with exact stderr checks.
- Admission: Product ticket is eligible for the next engineer slot; no
  implementation branch or commit exists yet.
