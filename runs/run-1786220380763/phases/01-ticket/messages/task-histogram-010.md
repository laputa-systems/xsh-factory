# Controller-assigned engineer ticket

This is an immutable controller assignment for one implementation worker.
The controller, not the worker, selected the ticket, snapshot, worktree, and
branch.

## Assignment authority

- Ticket ID: `task-histogram-010`
- Ticket snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786220380763/phases/01-ticket/tickets/task-histogram-010.md`
- Ticket snapshot SHA-256: `4f65dcf9829f1309f3abaff9e11ff4385eb92a15af9b16f2c7adf5bd62bba899`
- Dedicated XSH worktree: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786220380763/task-histogram-010`
- Branch: `factory/task-histogram-010/1786220391269`
- XSH base commit: `e6d3fd96f9fa654c0d1c9f434f83b6984a60c204`
- engineer report: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786220380763/phases/01-ticket/workers/engineer/task-histogram-010/REPORT.md`
- Factory root: `/Users/josh/d/laputa-systems/xsh-factory`
- Run evidence root: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786220380763/phases/01-ticket`

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
# Ticket task-histogram-010

## Status

Approved.

## CTO review — cycle 29 close

- Decision: Approved for one fresh engineer implementation slot.
- Basis: Review of merged commit `e6d3fd96f9fa654c0d1c9f434f83b6984a60c204`
  found a concrete parser-family inconsistency: `parse_uint` trims surrounding
  whitespace before validating, while the newly added `parse_uint_positive`
  validates the raw string and rejects the same surrounding whitespace. The
  positive parser was delivered correctly for the histogram argv contract, but
  the public parser family should have one explicit normalization contract.
- Scope guard: preserve rejection of signs, malformed text, zero, and
  out-of-range values; only align the positive parser's surrounding-whitespace
  behavior and tests/docs. Do not change `parse_uint` or add another API.
- Evidence: merged product commit above; linked cycle-29 replay
  `../runs/run-1786218719345/phases/02-reeval-task-histogram-009/` passed all
  nine cases and exercised `parse_uint_positive`.

## Change target

- `product`

Factory changes are CTO-owned. Do not create a factory-target ticket for
engineer dispatch; report infrastructure changes to the CTO instead.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-histogram`
- Shared handbook lineage: `../runs/run-1786218719345/phases/02-reeval-task-histogram-009/lineage/handbook-approved.md`
- Manager run: `../runs/run-1786218719345/phases/02-reeval-task-histogram-009/workers/eval-manager/task-histogram/REPORT.md`
- Executor run: `../runs/run-1786218719345/phases/02-reeval-task-histogram-009/workers/eval-worker/task-histogram-1/run.json`
- XSH baseline commit: `e6d3fd96f9fa654c0d1c9f434f83b6984a60c204`

## Observation

The merged parser family has inconsistent whitespace handling. `parse_uint`
calls `trim()` before checking unsigned decimal digits, but
`parse_uint_positive` checks the untrimmed input. Therefore equivalent inputs
such as `" 5 "` succeed through `parse_uint` and fail through
`parse_uint_positive`, despite both being decimal integer conversions.

## Evidence

- Product source: `../xsh/src/modules/text.rs` in merged commit
  `e6d3fd96f9fa654c0d1c9f434f83b6984a60c204`.
- Linked replay: cycle-29 `task-histogram` manager report confirms the new
  typed positive parser is discoverable and used successfully for the width;
  the task's argv cases do not exercise surrounding whitespace.
- The discrepancy is visible by comparing the two adjacent conversion
  implementations and is isolated to the new method.

## Diagnosis or hypothesis

This is a reusable library-contract inconsistency, not a task-specific
workaround. Agents use the parser family for ports, widths, counts, sizes, and
durations; inconsistent normalization forces each caller to guess whether to
trim before conversion. Aligning the new method with `parse_uint` keeps the
existing family predictable without expanding the language surface.

## North-star impact

Consistent typed conversions reduce agent guesswork and make numeric boundary
validation composable. Falsification requires the linked histogram eval to
remain byte-exact and native tests to show that positive parsing accepts the
documented surrounding-whitespace form while still rejecting zero, signs,
malformed text, and overflow.

## Proposed XSH change

## API-surface justification

- No new API, keyword, type, or syntax is proposed; this is a behavior fix to
  the newly merged `Str.parse_uint_positive()` method.
- The closest existing contract is `Str.parse_uint()`, which trims before
  validating. Reusing that normalization is smaller and clearer than adding a
  second conversion or a caller-side workaround.
- Maintenance cost is limited to the parser implementation, API contract
  wording if needed, native method tests, and one linked eval replay.
- Falsification evidence is the full nine-case `task-histogram` replay plus
  direct whitespace/zero/sign/malformed/overflow tests.

## Proposed XSH change

Trim the input at the start of `parse_uint_positive`, then apply its existing
positive-decimal validation and typed error behavior. Preserve all existing
`parse_uint` and `parse_int` behavior.

## Acceptance criteria

1. `" 5 ".parse_uint_positive()?` returns `5`.
2. Zero, signs, malformed text, and out-of-range text still return the existing
   typed `parse-uint-positive` error.
3. The linked `task-histogram` replay passes all nine cases byte-exact, with no
   restriction or protocol regression.
4. Native parser/API tests and the relevant XSH checks pass.

## Scope and non-goals

- Non-goal: changing `parse_uint` or `parse_int` behavior.
- Non-goal: adding another parser, generic error constructor, or syntax form.
- Non-goal: changing the histogram task contract or oracle.

## Post-merge evaluation

Replay `task-histogram` against the merged commit, including the existing nine
cases and the parser's typed positive-bound behavior; record the decision in
the linked eval-manager report.

<!-- CONTROLLER_TICKET_SNAPSHOT_END -->

## Factory context required before coding

The factory documents below are outside the XSH worktree. Before coding, use
the `read` tool on each exact absolute path. This is required so the session
JSONL proves that the worker consumed the current factory guidance:

- North star: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786220380763/phases/01-ticket/guidance/NORTH-STAR.md`
- Approved handbook snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786220380763/phases/01-ticket/guidance/handbook.md`
- Handbook candidate: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786220380763/phases/01-ticket/lineage/handbook-candidate.md`

The approved snapshot is a run-scoped copy of the checked-in handbook. Read it
as an input and never edit it or the checked-in handbook. If this ticket
produces a reusable lesson, add it to the run-scoped candidate path above; the
candidate is shared review input and is promoted only after CTO review. If no
handbook improvement is justified, leave the candidate unchanged.

Then use the `read` tool on the product worktree's exact guidance files:

- Product agent guide: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786220380763/task-histogram-010/AGENTS.md`
- XSH rationale: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786220380763/task-histogram-010/docs/CHAPTER-01-why-xsh.md`

## Implementation contract

Work only in `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786220380763/task-histogram-010` on branch `factory/task-histogram-010/1786220391269`. Do not edit XSH main, the
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
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786220380763/phases/01-ticket/workers/engineer/task-histogram-010/REPORT.md`. Complete that file in place; do not spend turns
reconstructing its headings. Keep `## Result` as `not-ready` until the
acceptance checks, commit, and clean-worktree validation are complete.

Write `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786220380763/phases/01-ticket/workers/engineer/task-histogram-010/REPORT.md` with these exact headings:

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
