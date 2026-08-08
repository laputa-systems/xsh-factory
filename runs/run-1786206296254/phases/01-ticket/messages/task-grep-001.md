# Controller-assigned engineer ticket

This is an immutable controller assignment for one implementation worker.
The controller, not the worker, selected the ticket, snapshot, worktree, and
branch.

## Assignment authority

- Ticket ID: `task-grep-001`
- Ticket snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786206296254/phases/01-ticket/tickets/task-grep-001.md`
- Ticket snapshot SHA-256: `d86c62e4ce372862db68e931d8ec0b52be44ed5cf4657d9f6303dd60a6a025d8`
- Dedicated XSH worktree: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786206296254/task-grep-001`
- Branch: `factory/task-grep-001/1786206303274`
- XSH base commit: `608ab11bcf25cb0f69df4cb352fa40b27c1be2b3`
- engineer report: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786206296254/phases/01-ticket/workers/engineer/task-grep-001/REPORT.md`
- Factory root: `/Users/josh/d/laputa-systems/xsh-factory`
- Run evidence root: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786206296254/phases/01-ticket`

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
# Ticket task-grep-001

## Status

Approved.

## Change target

- `product`

## CTO review

- Review cycle: cycle 23 close.
- Decision: Approved for implementation in the next organization cycle.
- Basis: The manager's independent `task-grep` trial reproduced a general
  checker-diagnostic mismatch, the evaluator passed all nine cases, and the
  proposed change has a narrow product scope with explicit acceptance and
  non-goals. This is a product ergonomics ticket, not a factory change.
- Evidence: `runs/run-1786202908216/phases/03-eval/workers/eval-manager/task-grep/REPORT.md`
  and `runs/run-1786202908216/phases/03-eval/workers/eval-worker/task-grep-1/run.json`.

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

- Eval: task-grep (evals/task-grep/EVAL.md, Approved)
- Shared handbook lineage: runs/run-1786202908216/phases/03-eval/lineage/handbook-approved.md
- Manager run: runs/run-1786202908216/phases/03-eval/workers/eval-manager/task-grep/REPORT.md
- Executor run: runs/run-1786202908216/phases/03-eval/workers/eval-worker/task-grep-1/run.json
- XSH baseline commit: 608ab11bcf25cb0f69df4cb352fa40b27c1be2b3

## Observation

The eval worker wrote an initial `grep.xsh` with a local binding named `path`
(`let path = Path.parse_bytes(...)?`). `xsht check` then surfaced two
diagnostics: a `warn[check.standard-module-shadow]` on the binding itself, and
a misleading primary `err[check.unknown-module-api]` on the method call
`path.read_text()` ("unknown module API"). The worker, reading the errors, at
first thought the `read_text()` call was the actual defect and renamed the
binding to `file` only after reading the secondary shadow warning. The final
artifact passed all nine evaluator cases by renaming the binding (`file`).

## Evidence

- Session JSONL: runs/run-1786202908216/phases/03-eval/workers/eval-worker/task-grep-1/session.jsonl.bz2 (turns ~14-16: first script, then check output showing both diagnostics, then rename and pass).
- Tool result: `err[check.standard-module-shadow]: name `path` shadows the standard module `path`` AND `err[check.unknown-module-api]: unknown module API` at `path.read_text()`.
- Final artifact runs/run-1786202908216/phases/03-eval/workers/eval-worker/task-grep-1/grep.xsh (binding renamed to `file`).
- Worker self-report: review.md `## xsht friction` explicitly records "Naming a local binding `path` shadows the standard `path` module and makes the `check` stage report a confusing `unknown-module-api` ... A pointer in that error message would save debugging time."
- run.json correctness: all 9 cases exact, result pass.

## Diagnosis or hypothesis

This is a general XSH checker ergonomics issue, not task-specific noise. `path`
is a natural variable name for a file-path program, and any eval in which an
agent reaches for a module-name binding (`path`, `env`, `fs`, `json`, ...) will
hit the same pair of diagnostics. The misleading part is that the primary error
`unknown-module-api` points at the method call site as if the API did not
exist, while the actual cause — the shadowing binding — is reported only as a
secondary `standard-module-shadow` warning. A warning is easy to miss, and the
error text steers an agent toward debugging a method that is valid, wasting a
turn. The fix is a diagnostic-clarity improvement: when a frozen/standard
module is shadowed, surface the shadow as the primary, actionable error (or
have the dependent method error point to the shadow), so the agent sees one
clear cause instead of a misleading API error plus a buried warning.

## North-star impact

Improving the diagnostic makes XSH check output trustworthy and reduces agent
friction (fewer turns and less guesswork) when a local binding collides with a
standard module name. Evidence of generalization: a later eval/trial that names
a module-name binding and, from the improved check output alone, renames it
immediately (one turn) without the `unknown-module-api` dead end. This is an
ergonomics and learnability win consistent with the north-star goal of "fewer
guesses, workarounds, tool errors, and repeated discoveries."

## Proposed XSH change

Make `standard-module-shadow` a primary, actionable diagnostic (error rather
than a secondary warning) when a binding shadows a standard module, or make the
dependent `unknown-module-api` error cite the shadowing binding as the cause.
Do not claim this is implemented; this is the smallest candidate change.

## Acceptance criteria

- `xsht check` on `let path = Path.parse_bytes(...)?; ... path.read_text()?`
  reports the shadow as the primary error and does not misattribute the fault
  to a nonexistent (unknown) module API.
- Existing standard-module users that do not shadow still pass lint/check.
- The task-grep replay reaches the final correct script with the shadow renamed
  in one turn and without the misleading `unknown-module-api` probe.

## Scope and non-goals

- Scope: improve the shadowing diagnostic's clarity and primary/error ordering.
- Non-goal: renaming the standard `path` module, changing `read_text`, or
  altering the task output contract.

## Post-merge evaluation

The next task-grep manager replay (same eval and handbook lineage) accepts if a
worker that names a binding `path` gets a clear, primary shadow diagnostic and
renames it in one turn; rejects if the misleading `unknown-module-api` persists.

<!-- CONTROLLER_TICKET_SNAPSHOT_END -->

## Factory context required before coding

The factory documents below are outside the XSH worktree. Before coding, use
the `read` tool on each exact absolute path. This is required so the session
JSONL proves that the worker consumed the current factory guidance:

- North star: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786206296254/phases/01-ticket/guidance/NORTH-STAR.md`
- Approved handbook snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786206296254/phases/01-ticket/guidance/handbook.md`
- Handbook candidate: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786206296254/phases/01-ticket/lineage/handbook-candidate.md`

The approved snapshot is a run-scoped copy of the checked-in handbook. Read it
as an input and never edit it or the checked-in handbook. If this ticket
produces a reusable lesson, add it to the run-scoped candidate path above; the
candidate is shared review input and is promoted only after CTO review. If no
handbook improvement is justified, leave the candidate unchanged.

Then use the `read` tool on the product worktree's exact guidance files:

- Product agent guide: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786206296254/task-grep-001/AGENTS.md`
- XSH rationale: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786206296254/task-grep-001/docs/CHAPTER-01-why-xsh.md`

## Implementation contract

Work only in `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786206296254/task-grep-001` on branch `factory/task-grep-001/1786206303274`. Do not edit XSH main, the
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
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786206296254/phases/01-ticket/workers/engineer/task-grep-001/REPORT.md`. Complete that file in place; do not spend turns
reconstructing its headings. Keep `## Result` as `not-ready` until the
acceptance checks, commit, and clean-worktree validation are complete.

Write `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786206296254/phases/01-ticket/workers/engineer/task-grep-001/REPORT.md` with these exact headings:

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
