# Controller-assigned engineer ticket

This is an immutable controller assignment for one implementation worker.
The controller, not the worker, selected the ticket, snapshot, worktree, and
branch.

## Assignment authority

- Ticket ID: `task-pathparts-002`
- Ticket snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786167293099/phases/01-ticket/tickets/task-pathparts-002.md`
- Ticket snapshot SHA-256: `b941cfb5ec118a8c77edcbefba2c38bc827f3aa1aa9c7463c59a675f9b3e410d`
- Dedicated XSH worktree: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786167293099/task-pathparts-002`
- Branch: `factory/task-pathparts-002/1786167297024`
- XSH base commit: `9bbc473af32e20e7bb3fa9b967a51acd89eb5200`
- engineer report: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786167293099/phases/01-ticket/workers/engineer/task-pathparts-002/REPORT.md`
- Factory root: `/Users/josh/d/laputa-systems/xsh-factory`
- Run evidence root: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786167293099/phases/01-ticket`

You are an implementation worker, not a ticket selector. Implement only the
ticket identified above and inlined below. Do not search for open tickets,
choose another ticket, or broaden this assignment. Do not create or modify a
ticket assignment. If the ticket ID, worktree, branch, or snapshot is missing
or conflicts with the runner's `FACTORY_TICKET_ID` or `FACTORY_WORKDIR`, stop
and report the assignment problem; do not guess.

The snapshot path is retained for provenance. The inlined snapshot below is
the controller's authoritative task input, so no ticket-discovery read is
required. Relative links in that snapshot resolve from the factory root above,
not from the XSH product worktree; use exact paths under that root if linked
evidence needs to be consulted.

## Ticket snapshot

<!-- CONTROLLER_TICKET_SNAPSHOT_BEGIN -->
# Ticket task-pathparts-002

## Status

Approved.

## CTO decision — pre-cycle-4

- Decision: Approved for one bounded implementation and linked-replay cycle.
- Basis: The typed-`Path` restriction/lint conflict remains a reproducible,
  general contract failure with a minimal tooling-alignment scope. The prior
  deferral required a named repair and isolated acceptance plan; this ticket
  now provides both, and the linked `task-pathparts` eval remains available.
- Scope: Align the lint guidance and restriction boundary so a documented
  typed-`Path` construction can satisfy both checks; do not change the task,
  oracle, or path-decomposition API.
- Admission: Dispatch one engineer; require the linked replay and one
  independent eval before delivery.

## CTO decision — 2026-08-07

- Decision: Deferred; do not approve or dispatch in this recovery cycle.
- Evidence: The observation is reproducible and identifies a real lint-versus-
  restriction contract conflict, but the proposed product change needs its
  own focused implementation and replay rather than being bundled with the
  retained `task-jsonfilter-001` delivery.
- Admission: Keep `Open.`. Revisit after the typed-`Path` restriction and
  `xsht lint` contract have a named repair and an isolated acceptance plan.

## CTO review

- Review cycle: ramp recovery admission.
- Decision: Deferred; do not approve or dispatch.
- Basis: Preserve this reproducible lint-versus-restriction conflict for a
  separate repair cycle; it is not a safe dependency of JSON-filter delivery.

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

- Session `task-pathparts-1/session.jsonl.bz2` line 38: the worker's thinking reads
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

<!-- CONTROLLER_TICKET_SNAPSHOT_END -->

## Factory context required before coding

The factory documents below are outside the XSH worktree. Before coding, use
the `read` tool on each exact absolute path. This is required so the session
JSONL proves that the worker consumed the current factory guidance:

- North star: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786167293099/phases/01-ticket/guidance/NORTH-STAR.md`
- Approved handbook snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786167293099/phases/01-ticket/guidance/handbook.md`
- Handbook candidate: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786167293099/phases/01-ticket/lineage/handbook-candidate.md`

The approved snapshot is a run-scoped copy of the checked-in handbook. Read it
as an input and never edit it or the checked-in handbook. If this ticket
produces a reusable lesson, add it to the run-scoped candidate path above; the
candidate is shared review input and is promoted only after CTO review. If no
handbook improvement is justified, leave the candidate unchanged.

Then use the `read` tool on the product worktree's exact guidance files:

- Product agent guide: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786167293099/task-pathparts-002/AGENTS.md`
- XSH rationale: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786167293099/task-pathparts-002/docs/CHAPTER-01-why-xsh.md`

## Implementation contract

Work only in `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786167293099/task-pathparts-002` on branch `factory/task-pathparts-002/1786167297024`. Do not edit XSH main, the
factory checkout, the approved handbook snapshot, or the ticket diagnosis.
Make the smallest general XSH language, tooling, test, or
canonical-documentation change supported by the ticket. Run the narrowest
relevant checks, commit the product change on this branch, and leave the
worktree clean.

For ordinary product tickets, use `xsht lint --fix` for linting, then rerun the
relevant checks. If this ticket specifically targets lint, parsing, or
diagnostics, preserve the behavior under test and follow its explicit
acceptance procedure instead of auto-fixing away the evidence.

The controller has staged a fail-closed `not-ready` report at
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786167293099/phases/01-ticket/workers/engineer/task-pathparts-002/REPORT.md`. Complete that file in place; do not spend turns
reconstructing its headings. Keep `## Result` as `not-ready` until the
acceptance checks, commit, and clean-worktree validation are complete.

Write `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786167293099/phases/01-ticket/workers/engineer/task-pathparts-002/REPORT.md` with these exact headings:

```markdown
## Result

ready-for-review

## Branch

<branch name>

## Commit

<commit hash>

## Files changed

<short list>

## Tests

<commands and results>

## North-star impact

<how this improves XSH or agent use>

## Remaining risks

<known limitations, or None.>
```

Change `## Result` to `ready-for-review` only when the branch is committed, the worktree is
clean, and the relevant checks passed. Do not merge the branch or update the
ticket status; the deterministic controller records it for CTO review.
