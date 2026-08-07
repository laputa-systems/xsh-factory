# Ticket task-pathparts-002

## Status

Open.

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

- Eval: `task-pathparts`
- Shared handbook lineage: `runs/run-1786138321778/phases/02-reeval-task-pathparts-001/lineage/handbook-approved.md`
- Manager run: `runs/run-1786138321778/phases/02-reeval-task-pathparts-001/workers/eval-manager/task-pathparts/`
- Executor run: `runs/run-1786138321778/phases/02-reeval-task-pathparts-001/workers/eval-worker/task-pathparts-1/`
- XSH baseline commit: `857154dfe505f0d01053c1b5311f44422070eb34`

## Observation

`xsht lint` hard-fails (`exit 1`) on the documented direct `Path(str)` cast
and recommends the interpolated `fp"${...}"` form instead. In the `task-pathparts`
re-evaluation session the worker first wrote `let p = Path(argv[0])` (the exact
construction the eval's `path_referenced` restriction gate requires), ran
`xsht lint`, and got an `exit 1` lint failure steering it to
`let p = fp"${argv[0]}"`. The worker switched to the lint-preferred form to make
lint clean. The submitted artifact then no longer contains the literal `Path(`
token, so the evaluator reports `restrictions.path_referenced: false`,
`classification: restriction_failed`, and the trial fails despite correct
output on all seven oracle cases.

## Evidence

- Session `task-pathparts-1/session.jsonl` line 38: the worker's thinking reads
  "There's a lint warning suggesting `fp"${argv[0]}"` instead of
  `Path(argv[0])` ... lint exits with code 1 because of the warning. Let me use
  the fp form to make lint pass," followed by an `edit` replacing
  `Path(argv[0])` with `fp"${argv[0]}"`. The final summary (line 52) states
  "Used the lint-preferred `fp"${argv[0]}"` over `Path(argv[0])` to keep
  `xsht lint` clean."
- Handbook `handbook-approved.md` (sha256 `3b56a781...`) lists the direct cast
  first and labels `fp"${expr}"` "the interpolated, lint-preferred form,"
  compounding the steer away from the `Path(` token.
- Evaluator `task-pathparts-1/run.json`: all seven `correctness` cases true,
  `restrictions.passed: false`, `restrictions.path_referenced: false`,
  `classification: restriction_failed`, `result: fail`.
- No provider retries or provider errors in `provider_telemetry`; the failure
  is a source-contract/tooling mismatch, not external health.

## Diagnosis or hypothesis

This is a general XSH ergonomics/trust conflict, not task-specific confusion.
The eval's typed-Path restriction gate detects a typed `Path` construction by
the literal `Path(` token, while the factory's own `xsht lint` hard-errors on
that same documented cast and pushes the agent to the semantically equivalent
`fp"${...}"` interpolated form. The handbook reinforces the lint direction by
calling `fp"${...}"` the "lint-preferred form." An agent that follows the
factory's visible checks (lint error exit, handbook) deterministically fails a
factory eval gate that requires the `Path(` token. This is exactly the kind of
internally inconsistent boundary the north star says the factory should
eliminate: two factory surfaces (lint/handbook and the eval restriction) tell
the agent opposite things about constructing a typed `Path`, so the agent
cannot satisfy both and must guess which is authoritative.

The observation generalizes beyond `task-pathparts`: any eval or contract that
requires the literal `Path(` typed-Path construction, and any agent building a
dynamic `Path` from a runtime string, will hit the same lint-vs-gate wall and
be driven to the wrong surface even when it knows the right one.

## North-star impact

The XSH rationale and north star name typed `Path` a boundary to strengthen
and target ergonomics ("fewer guesses, workarounds, ... repeated discoveries")
and trustworthy, learnable surfaces. A lint that hard-rejects a documented,
sometimes contract-required construction forces agents to either leave a
failing lint or fail the contract gate — a lose-lose that erodes trust in the
tool's guidance. Resolving the tension (e.g. lint downgrading the `fp"`-over-`Path(`
advisory to a non-fatal suggestion, or the eval restriction recognizing any
typed-Path construction such as `fp"${...}"`) lets an agent satisfy both the
tool and the contract, reproducing the typed-Path boundary the north star
wants. Evidence of generalization: a second `task-pathparts` trial and a
different path-construction eval passing with a clean documented cast would
show the guidance is no longer misleading.

## Proposed XSH change

Smallest-surface candidates, in recommended order:

1. Make `xsht lint`'s `fp"${...}"`-over-`Path(str)` advisory non-fatal (warn,
   not `exit 1`) when `Path(str)` is a documented, semantically equivalent
   typed-Path construction, so an agent that honors a contract-required cast is
   not blocked by the tool.
2. If a literal `Path(` token gate is intentional, reword the `Path(str)` cast
   documentation/lint so agents know the direct cast is valued and the `fp"`
   form does not subsume it.
3. Align eval restriction gates (such as `task-pathparts`'s
   `path_referenced`) to recognize `fp"${...}"` interpolation as a valid typed
   `Path` construction, matching the handbook's own claim that it is a typed
   Path form.

This is an ergonomics/trust fix to tooling or the restriction gate, not an
admission of a new spelling for an existing operation; it removes a conflict
between two factory surfaces that already exist.

## Acceptance criteria

- An agent that writes the typed `Path` construction a task names can do so
  without a hard `xsht lint` failure on a documented idiom.
- A fresh `task-pathparts` trial that uses the typed `Path` surface (methods
  from the `task-pathparts-001` change) and references `Path(` passes both
  `xsht lint` and the `path_referenced` restriction gate.
- The eval contract, fixture cases, and oracle are unchanged.

## Scope and non-goals

- No change to the `task-pathparts` task contract, fixture cases, or oracle.
- No change to provider/fallback policy.
- Does not re-open the `task-pathparts-001` path-decomposition methods, which
  are validated separately; this ticket targets the lint/gate tension that
  blocks the decomposed surface from being used.

## Post-merge evaluation

Replay `task-pathparts` against the merged build and the merged
`task-pathparts-001` methods; the linked eval-manager records whether the agent
can pass both lint and the `path_referenced` gate through a named typed `Path`
construction, and whether the same guidance no longer misleads a second
path-construction eval.
