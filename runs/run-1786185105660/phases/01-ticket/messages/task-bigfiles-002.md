# Controller-assigned engineer ticket

This is an immutable controller assignment for one implementation worker.
The controller, not the worker, selected the ticket, snapshot, worktree, and
branch.

## Assignment authority

- Ticket ID: `task-bigfiles-002`
- Ticket snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786185105660/phases/01-ticket/tickets/task-bigfiles-002.md`
- Ticket snapshot SHA-256: `8a30d908ad08030ff66236bc024f4a7cd9c7b0d194da4cfef7e946c3758ea1a5`
- Dedicated XSH worktree: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786185105660/task-bigfiles-002`
- Branch: `factory/task-bigfiles-002/1786185106648`
- XSH base commit: `fdeee37e911f820865dc617a14d61ec8e111c603`
- engineer report: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786185105660/phases/01-ticket/workers/engineer/task-bigfiles-002/REPORT.md`
- Factory root: `/Users/josh/d/laputa-systems/xsh-factory`
- Run evidence root: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786185105660/phases/01-ticket`

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
# Ticket task-bigfiles-002

## Status

Approved.

## CTO decision — cycle-11 adaptive queue

- Decision: Approved for one fresh engineer row.
- Basis: This is the oldest focused open product observation, its linked eval
  is available, and the queue has high open pressure with no remaining
  approved implementation branch. The proposed change is narrow API-reference
  guidance with an existing evaluator and a clear replay contract.
- Scope: Clarify the command-word spelling for block-bearing stream stages in
  `xsht api`, especially `sort-by --desc { |e| e.size }`; preserve parser
  behavior and evaluator contracts.
- Required acceptance: the engineer's reference change passes focused native
  tests, and the linked replay must actually exercise the documented spelling
  before delivery.

## CTO review

- Review cycle: pre-cycle-3.
- Decision: Deferred; do not approve or dispatch in this cycle.
- Basis: The observation is a useful general API-documentation candidate, but
  it has not yet received a matched replay after the cycle-2 manager collision
  was repaired. Preserve it for a future `task-bigfiles` replay.
- Next evidence: Require a fresh manager reproduction using a new ticket
  identity and confirm the proposed documentation guidance generalizes beyond
  the one `sort-by` spelling.

## Change target

- `product`

Factory changes are CTO-owned. Do not create a factory-target ticket for
engineer dispatch; report the infrastructure change to the CTO instead.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `95878384b9d6bb66f5631d630dca4d306f95a3a0`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-bigfiles`
- Shared handbook lineage: `runs/run-1786163685229/phases/03-eval/lineage/handbook-approved.md`
- Manager run: `runs/run-1786163685229/phases/03-eval/workers/eval-manager/task-bigfiles/REPORT.md`
- Executor run: `runs/run-1786163685229/phases/03-eval/workers/eval-worker/task-bigfiles-1/session.jsonl.bz2`
- XSH baseline commit: `95878384b9d6bb66f5631d630dca4d306f95a3a0`

## Observation

`xsht api language:stream.sort-by` renders the signature as
`sort-by(--desc: Bool = false, block) -> Stream[T]`. A block-bearing stream
stage in this build does not accept parenthesized call arguments. The
eval-worker tried `sort-by(--desc, { |e| e.size })` and
`sort-by({ |e| e.size })` in `/work/bigfiles.xsh` and in `/tmp` scratch
scripts; each failed to parse (`err[parse.expected-record-field]`,
`err[parse.unsupported-boolean-operator]`, etc.). It then tried
`sort-by(--desc) { |e| e.size }`, which failed with
`err[check.arity]: stream stage does not accept call arguments`. Only the
command-word form `|> sort-by --desc { |e| e.size }` is accepted.

## Evidence

- Worker session `session.jsonl.bz2` turns 44, 46, 47, 52, 53, 55: four tool errors
  (structured `tool_errors` in `report.json`) plus intervening scratch probes
  before the accepted spelling at turn 55.
- Final artifact `/work/bigfiles.xsh` uses `|> sort-by --desc { |e| e.size }`
  and passes all nine evaluator cases exactly.
- `worker report.json` `tool_errors` entries at turns 17 (the parse failure of
  `sort-by(--desc, { |e| e.size })`) and the `check.arity` rejection at
  turn 52.
- `review.md` describes the same friction and proposes a worked example in the
  API doc.

## Diagnosis or hypothesis

The `xsht api` signature string for a block-bearing stream stage reads like an
ordinary function call with a positional/named argument list, which implies
spellings the parser rejects. Several block stages (where, map, sort-by, each,
fold) take a block as a command argument, not as a parenthesized call
argument; the signature rendering does not convey that, and it is especially
misleading when a named flag (`--desc`) is combined with the key block. This is
a general XSH ergonomics/learnability problem in the API reference, not a
task-specific confusion: any agent composing a stage that pairs a named flag
with a block will hit the same rejections. It recurs across the sort-by
discovery in this session and is reproducible with a one-line scratch script.

## North-star impact

A clear signature or example that shows the command-word spelling for
block-bearing stages (including a named-flag + block case) reduces repeated
discovery and failed tool calls, improving XSH ergonomics and learnability for
both agents and humans. Evidence that it generalized: a subsequent eval
composing `sort-by --desc { ... }` or another flag-plus-block stage reaches the
accepted form without the parse/arity trial-and-error observed here.

## Proposed XSH change

Add a worked example to the `xsht api` reference entry for block-bearing
stream stages that combine a named flag with a key block (e.g. sort-by), and/
or adjust the rendered signature so it does not imply a parenthesized
call-argument form. At minimum, the sort-by example should show the accepted
pipeline spelling `|> sort-by --desc { |e| e.size }`.

## API-surface justification

This is primarily a documentation/reference-rendering fix rather than a new
syntactic capability. The parser already accepts the command-word block form;
the gap is that the reference signature string misrepresents the accepted
spelling as a call-argument list. If the team instead wants command-word block
stages to accept parenthesized call-argument spelling for consistency,
that is a larger parser surface change and should be justified separately;
the minimal, low-risk change is a corrected/annotated signature and a worked
example in the API registry documentation and tests.

## Acceptance criteria

- The `xsht api language:stream.sort-by` entry includes the accepted
  command-word example `|> sort-by --desc { |e| e.size }`, and
- a regression test (doc snapshot or reference example) prevents the signature
  from reverting to a form that implies only parenthesized call arguments, and
- a replay of `task-bigfiles` (or another rank/order eval) shows the agent
  reaching the accepted sort-by spelling without the parse/arity trial loop.

## Scope and non-goals

Out of scope: changing stream-stage parser grammar to accept parenthesized
call-argument blocks; adding new sorting capabilities; changing the evaluator
or harness; recommending provider changes.

## Post-merge evaluation

A `task-bigfiles` replay at the merged XSH commit, checking that the worker
adopts `sort-by --desc { ... }` on the first or second attempt and that all
nine cases still pass byte-for-byte.

<!-- CONTROLLER_TICKET_SNAPSHOT_END -->

## Factory context required before coding

The factory documents below are outside the XSH worktree. Before coding, use
the `read` tool on each exact absolute path. This is required so the session
JSONL proves that the worker consumed the current factory guidance:

- North star: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786185105660/phases/01-ticket/guidance/NORTH-STAR.md`
- Approved handbook snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786185105660/phases/01-ticket/guidance/handbook.md`
- Handbook candidate: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786185105660/phases/01-ticket/lineage/handbook-candidate.md`

The approved snapshot is a run-scoped copy of the checked-in handbook. Read it
as an input and never edit it or the checked-in handbook. If this ticket
produces a reusable lesson, add it to the run-scoped candidate path above; the
candidate is shared review input and is promoted only after CTO review. If no
handbook improvement is justified, leave the candidate unchanged.

Then use the `read` tool on the product worktree's exact guidance files:

- Product agent guide: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786185105660/task-bigfiles-002/AGENTS.md`
- XSH rationale: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786185105660/task-bigfiles-002/docs/CHAPTER-01-why-xsh.md`

## Implementation contract

Work only in `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786185105660/task-bigfiles-002` on branch `factory/task-bigfiles-002/1786185106648`. Do not edit XSH main, the
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
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786185105660/phases/01-ticket/workers/engineer/task-bigfiles-002/REPORT.md`. Complete that file in place; do not spend turns
reconstructing its headings. Keep `## Result` as `not-ready` until the
acceptance checks, commit, and clean-worktree validation are complete.

Write `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786185105660/phases/01-ticket/workers/engineer/task-bigfiles-002/REPORT.md` with these exact headings:

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
