# Controller-assigned engineer ticket

This is an immutable controller assignment for one implementation worker.
The controller, not the worker, selected the ticket, snapshot, worktree, and
branch.

## Assignment authority

- Ticket ID: `task-trim-002`
- Ticket snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786155403216/phases/01-ticket/tickets/task-trim-002.md`
- Ticket snapshot SHA-256: `8c81e42f2318bf8ba88d69919c718edd26bfe4b87a31b88235aa3c60707dd9ca`
- Dedicated XSH worktree: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786155403216/task-trim-002`
- Branch: `factory/task-trim-002/1786155405105`
- XSH base commit: `2e244e4ac8c724c2e4720e8840405f8faaee1fb1`
- engineer report: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786155403216/phases/01-ticket/workers/engineer/task-trim-002/REPORT.md`
- Factory root: `/Users/josh/d/laputa-systems/xsh-factory`
- Run evidence root: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786155403216/phases/01-ticket`

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
# Ticket task-trim-002

## Status

Approved.

## CTO decision — 2026-08-07

- Decision: Approve for one bounded engineer implementation row in the next
  organization cycle.
- Basis: the linked `task-trim` trial reproduced a general, byte-exact
  `Str.lines()` contract gap, and the proposed change is documentation-only
  with explicit product-doc and handbook acceptance criteria. It adds no
  builtin, keyword, constructor, type, method, or syntax form, so the API
  surface gate is satisfied.
- Admission: run alongside the retained `task-pathparts-001` implementation
  branch when the organization controller batches retained and fresh work;
  require the linked replay and an independent file-rewriting eval before
  delivery/promotion.

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
- Shared handbook lineage: `runs/run-1786151585420/phases/03-eval/lineage/handbook-approved.md`
- Manager run: `runs/run-1786151585420/phases/03-eval/workers/eval-manager/task-trim/REPORT.md`
- Executor run: `runs/run-1786151585420/phases/03-eval/workers/eval-worker/task-trim-1/run.json`
- XSH baseline commit: `2e244e4ac8c724c2e4720e8840405f8faaee1fb1`

## Observation

`task-trim` requires a byte-exact rewrite: read a newline-terminated input and
write one `\n` per input line after trimming leading/trailing ASCII space and
tab from each line. The submitted program's natural structure is
`fs.read_text(IN)? |> lines() |> map(trim) |> collect() |> join("\n")`. The
`Str.lines()` method drops the empty segment produced by a terminal
newline, so `"a\nb\n"` yields `["a","b"]` and the naive
`lines() |> join("\n")` round-trip emits `"a\nb"` — one line short. The
worker had to discover this empirically with a probe (`count 2` for the two
real lines) and then manually re-append `"\n"` after the join, plus verify the
byte-exact output with `od -c` before trusting it. Nothing in `Str.lines()`
contract or the handbook signals this off-by-one.

## Evidence

- Worker session: `runs/run-1786151585420/phases/03-eval/workers/eval-worker/task-trim-1/session.jsonl.bz2` — the probe turn (message `5b1d080c`) shows `count 2` / `[a]` / `[b]` for `"a\nb\n"`, establishing that `lines()` drops the trailing empty segment; the `482f4c22` and `50d7738c` thinking blocks reason that the trailing `"\n"` must be re-added; the `99367cb9` and `b8a62b5d` turns verify byte-exact output with `od -c`/`cmp` against the `sed` oracle.
- Final artifact: `runs/run-1786151585420/phases/03-eval/workers/eval-worker/task-trim-1/work/trim.xsh` — `let result = trimmed.join("\n") + "\n"`.
- Worker review: `runs/run-1786151585420/phases/03-eval/workers/eval-worker/task-trim-1/work/review.md` — "xsft friction: `Str.lines()` drops the empty segment produced by a terminal newline … required manually re-appending `\"\\n\"`".
- Worker `report.json`: 4 tool errors, 21 turns, pass result (all 8 cases, restrictions, protocol).

## Diagnosis or hypothesis

`Str.lines()` splitting without a trailing empty segment is a plausible design,
but it is undocumented in the canonical `lines()` contract and the handbook,
so any eval or agent that needs a byte-exact newline round-trip (file rewrite,
config clean, diff-prep, log normalization) hits an off-by-one that only a
byte-level oracle comparison can reveal. This is a general learnability and
correctness trap for line-oriented systems-glue work, not task-specific
confusion. It will recur for any file-transformation eval that reassembles
lines. The smallest fix is product documentation: state in the `Str.lines()`
contract that a trailing newline does not produce an empty final element, and
show the round-trip that preserves one `\n` per input line.

## North-star impact

Making `Str.lines()` terminal-newline semantics explicit (or adding a
newline-preserving line split) advances XSH learnability and correctness for
its core file-glue role: an agent rewriting a file's lines will not silently
drop the final newline or spend extra probes proving the byte count. Evidence
that it generalized: a file-rewriting eval (e.g. a future config/log trim or
line-normalization eval) shows no off-by-one discovery turn and a correct
round-trip on the first check.

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

A new "keep empty trailing" split variant would be additive surface area; the
existing behavior is self-consistent and the working spelling already exists
(re-append `"\n"`). The smallest admission is therefore a documentation change
to the `Str.lines()` contract stating that a terminal newline does not emit an
empty final element and showing the newline-preserving round-trip. If a
separate strong ergonomics case later arises, an explicit
`lines(keep_empty: Bool = false)` overload could be considered, but that is a
checker/API-registry change with docs and test cost and is out of scope here.

## Proposed XSH change

Smallest candidate: update the canonical `Str.lines()` documentation (and the
handbook's text/output section) to state that a trailing newline is absorbed
(no empty final segment) and to show the byte-exact round-trip that re-appends
`"\n"` after `join("\n")` for a newline-terminated file. Do not claim this is
already implemented.

## Acceptance criteria

- The `Str.lines()` contract states the trailing-newline behavior, and a
  trusted handbook sentence captures the re-append round-trip.
- `task-trim` and at least one other file-rewriting eval replay green with no
  correctness regression.
- No behavior change for existing valid scripts.

## Scope and non-goals

- No change to `Str.lines()` runtime behavior unless a separate reproduction
  shows it is semantically broken rather than merely under-documented.
- No new split keyword or default-flip in this ticket.
- Provider switching is out of scope.

## Post-merge evaluation

Replay `task-trim` (and a second file-rewriting eval) on the merged XSH commit
and verify the agent reaches a correct one-`\n`-per-line output without an
empirical off-by-one discovery turn.

<!-- CONTROLLER_TICKET_SNAPSHOT_END -->

## Factory context required before coding

The factory documents below are outside the XSH worktree. Before coding, use
the `read` tool on each exact absolute path. This is required so the session
JSONL proves that the worker consumed the current factory guidance:

- North star: `/Users/josh/d/laputa-systems/xsh-factory/NORTH-STAR.md`
- Shared handbook: `/Users/josh/d/laputa-systems/xsh-factory/runtime/handbook.md`

Then use the `read` tool on the product worktree's exact guidance files:

- Product agent guide: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786155403216/task-trim-002/AGENTS.md`
- XSH rationale: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786155403216/task-trim-002/docs/CHAPTER-01-why-xsh.md`

## Implementation contract

Work only in `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786155403216/task-trim-002` on branch `factory/task-trim-002/1786155405105`. Do not edit XSH main, the
factory main tree, or the ticket diagnosis. Make the smallest general XSH
language, tooling, test, or canonical-documentation change supported by the
ticket. Run the narrowest relevant checks, commit the product change on this
branch, and leave the worktree clean.

For ordinary product tickets, use `xsht lint --fix` for linting, then rerun the
relevant checks. If this ticket specifically targets lint, parsing, or
diagnostics, preserve the behavior under test and follow its explicit
acceptance procedure instead of auto-fixing away the evidence.

The controller has staged a fail-closed `not-ready` report at
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786155403216/phases/01-ticket/workers/engineer/task-trim-002/REPORT.md`. Complete that file in place; do not spend turns
reconstructing its headings. Keep `## Result` as `not-ready` until the
acceptance checks, commit, and clean-worktree validation are complete.

Write `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786155403216/phases/01-ticket/workers/engineer/task-trim-002/REPORT.md` with these exact headings:

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
