# Controller-assigned engineer ticket

This is an immutable controller assignment for one implementation worker.
The controller, not the worker, selected the ticket, snapshot, worktree, and
branch.

## Assignment authority

- Ticket ID: `task-ecount-005`
- Ticket snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785801609594/phases/01-ticket/tickets/task-ecount-005.md`
- Ticket snapshot SHA-256: `115a1cadd5d95d9fe8b39c8b36d5f6c5148e6b4c34f1c6b4b256c7747c6ffe8c`
- Dedicated XSH worktree: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785801609594/phases/01-ticket/worktrees/task-ecount-005`
- Branch: `factory/task-ecount-005/1785801610686`
- XSH base commit: `7c939dbedcd680e812aadfef2cb248da8e824360`
- engineer report: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785801609594/phases/01-ticket/workers/engineer/task-ecount-005/REPORT.md`
- Factory root: `/Users/josh/d/laputa-systems/xsh-factory`
- Run evidence root: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785801609594/phases/01-ticket`

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
# Ticket task-ecount-005

## Status

Approved.

## CTO review

- Review cycle: `pre-cycle-1785801503` (2026-08-03)
- Decision: Approved for the next two-engineer ticket cycle.
- Basis: A checker-valid program emits its complete output and then exits with
  `lowered return type mismatch`; the failure is deterministic, general to
  terminal stream stages, and has a narrow checker/runtime acceptance contract.
- Assignment boundary: Align final terminal-stage lowering with the declared
  `proc` return, or reject it at check time with an actionable diagnostic; do
  not change non-final terminal-stage behavior or unrelated stream semantics.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-ecount` (`evals/task-ecount/EVAL.md`)
- Shared handbook lineage: `runs/run-1785703815040/lineage/handbook-approved.md` (approved `c7c9dd9a…`; candidate unchanged)
- Manager run: `runs/run-1785703815040/workers/eval-manager/task-ecount/session.jsonl.bz2`
- Executor run: `runs/run-1785703815040/workers/eval-worker/task-ecount-1` (trial 1)
- XSH baseline commit: `c2e1039d8856c04ad8466504d445dc93a341f720` (candidate under replay, image `sha256:ce893ea8cb690831f4da8fc5bb6e374c22d0d699ca4aff576cf8afa7802587f9`)

## Observation

`xsht check` accepts a `proc main` whose final statement is a terminal stream
stage such as `each { ... }`, but `xsh` runs that identical program, emits all
of its output, and then exits 3 with an internal error
`err[runtime.error]: lowered return type mismatch` whose location is the
`proc main` signature line instead of the offending statement. Appending any
later Unit-valued statement (a trailing `let` or `print`) makes the same body
exit cleanly (0). A program that the checker validates thus crashes at runtime
only because of where the terminal stage sits, after all work is done.

Reproduced on the candidate image (XSH commit `c2e1039`):

```text
$ cat term_probe.xsh
proc main() [fs, error, io] {
  let files = fs.files(p"/usr/share")
  files
    |> where .kind == "file"
    |> map { |e| e.path.display() }
    |> each { |s| print $s }
}
$ xsht check term_probe.xsh     # exit 0  (checker accepts)
$ xsh term_probe.xsh > out 2> err   # prints all lines, then:
$ echo $?
3
$ cat err
err[runtime.error]: lowered return type mismatch
  term_probe.xsh:1:1
  proc main() [fs, error, io] {
  ^
runtime traceback
executable: /usr/local/bin/xsh
operation: runtime.error
error: type-error: lowered return type mismatch
```

## Evidence

- Worker session: `runs/run-1785703815040/workers/eval-worker/task-ecount-1/session.jsonl.bz2` contains 12 occurrences of the `lowered return type mismatch` text. The first appears after `g |> each { |x| print $x.key }` (tool result around line 131), and the worker then spent multiple discovery turns (thinking transcript lines ~674–885 and ~1189) trying to reconcile the runtime error with the checker's `stream-terminal-stage` rule ("stream stages cannot follow a terminal stage"), at one point re-running an earlier probe to confirm the error also fired there (thinking line ~842). The worker finally concluded it "must end with a trailing statement" (thinking line ~1817).
- Worker review: `runs/run-1785703815040/workers/eval-worker/task-ecount-1/review.md`, section `## xsht friction` — "`proc main` whose final statement is a terminal stage such as `each { ... }` fails at runtime with `lowered return type mismatch` (exit 3) even though `xsht check` passes and all output was already emitted. The script only exits cleanly (exit 0) when a later Unit-typed statement (e.g. a trailing `let`/`print`) follows. This is non-obvious and easy to trip over."
- Manager host probe on the candidate image: the program above compiles (`xsht check` exit 0), prints the full file list, then exits 3 with the error above; adding a trailing `print ""` makes it exit 0.
- Quantitative metrics: `run.json` `result: pass`, `correctness.exact_output: true`; the accepted artifact works around the defect by ending with a final `print` (Unit) instead of a terminal stage.

## Diagnosis or hypothesis

The checker and the runtime lower `proc main` differently for stream programs.
The checker accepts `each` as a terminal stage and validates a body that ends
in the terminal stage, but the runtime's lowered final value for that shape is
not convertible to the procedure's Unit return, so execution fails at the very
end with an internal `type-error: lowered return type mismatch`. The error
message is internal jargon and its location is the `proc main` signature line,
not the final statement, so an agent cannot tell which statement is wrong or
that the fix is a trailing Unit statement. This makes a `xsht check`-valid
program fail at runtime after producing correct output — a trust and
learnability defect, not an ecount recipe: any eval or user script whose last
statement is a terminal stream stage hits the same hidden convention, and each
worker must rediscover it by trial and error.

## North-star impact

The north star asks for explicit boundaries, clear errors, and removing
"repeated discoveries." A program that prints exactly the right output and then
exits 3 with an internal error because of an undocumented trailing-statement
convention forces exactly the discovery loop the factory exists to remove and
undermines trust in `xsht check`. Making the runtime treat a terminal-stage
final expression as Unit (matching the checker) — or, if the shape is
intentionally unsupported, making the checker reject it with a diagnostic that
names the final stage instead of a runtime internal error — would let an agent
end a pipeline naturally. Evidence of generalization: a replay of task-ecount
(or any pipeline eval) on the merged change should show a worker ending a
`proc` with a terminal stage and exiting 0, or receiving a check-time
diagnostic naming the final stage, never output-then-exit-3.

## Proposed XSH change

Smallest candidate, one of:

1. Make the runtime lower a terminal-stage final expression to the procedure's
   Unit return (so `... |> each { ... }` as the final statement exits 0 after
   emitting output), matching what `xsht check` already accepts; or
2. If the terminal-stage-final shape is intentionally not supported, reject it
   at check time with a clear diagnostic that names the stage and the
   requirement (e.g. "the final statement of a proc must be Unit-valued;
   terminal stream stage `each` cannot be the last statement"), instead of a
   runtime `lowered return type mismatch` after output has been emitted.

In both cases, add a regression test for a `proc` whose final statement is each
of the terminal stages (`each`, `collect`, `count`, `first`, ...) asserting
that `xsht check` and `xsh` agree on the outcome.

No change to stream-stage execution semantics, ordering, or the sorting
contract from task-ecount-003.

## Acceptance criteria

- `xsht check` and `xsh` agree on a `proc` ending in a terminal stage: either
  the program exits 0 with full output, or the checker rejects it with a
  diagnostic naming the final stage/statement — never output-then-exit-3 with
  `lowered return type mismatch`.
- Programs whose final statement is already Unit-valued (`print`, `let`, a
  non-stream expression) behave exactly as before.
- Terminal-stage behavior in non-final positions is unchanged (stages that
  follow a terminal still fail at check time with `stream-terminal-stage`).
- A replay of `task-ecount` on the merged change reaches the oracle-matching
  candidate without the trailing-statement workaround or a discovery loop.

## Scope and non-goals

- No change to stream-stage semantics beyond how a final terminal stage is
  lowered.
- Not an ecount shortcut; the checker/runtime agreement must generalize to
  every stream-ending proc.
- The `Map[Any]` checker/runtime split for record sorts is tracked separately
  in task-ecount-004 and is out of scope here.
- No change to the shared agent handbook inside XSH; the factory lineage owns
  the agent-facing handbook.

## Post-merge evaluation

The `task-ecount` eval-manager will run a controlled replay against the merged
XSH commit using the current approved handbook lineage, verify the
checker/runtime agreement described in the acceptance criteria, and record
acceptance or rejection in that run's manager report.

<!-- CONTROLLER_TICKET_SNAPSHOT_END -->

## Factory context required before coding

The factory documents below are outside the XSH worktree. Before coding, use
the `read` tool on each exact absolute path. This is required so the session
JSONL proves that the worker consumed the current factory guidance:

- North star: `/Users/josh/d/laputa-systems/xsh-factory/NORTH-STAR.md`
- Shared handbook: `/Users/josh/d/laputa-systems/xsh-factory/runtime/handbook.md`

Then use the `read` tool on the product worktree's exact guidance files:

- Product agent guide: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785801609594/phases/01-ticket/worktrees/task-ecount-005/AGENTS.md`
- XSH rationale: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785801609594/phases/01-ticket/worktrees/task-ecount-005/docs/CHAPTER-01-why-xsh.md`

## Implementation contract

Work only in `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785801609594/phases/01-ticket/worktrees/task-ecount-005` on branch `factory/task-ecount-005/1785801610686`. Do not edit XSH main, the
factory main tree, or the ticket diagnosis. Make the smallest general XSH
language, tooling, test, or canonical-documentation change supported by the
ticket. Run the narrowest relevant checks, commit the product change on this
branch, and leave the worktree clean.

The controller has staged a fail-closed `not-ready` report at
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785801609594/phases/01-ticket/workers/engineer/task-ecount-005/REPORT.md`. Complete that file in place; do not spend turns
reconstructing its headings. Keep `## Result` as `not-ready` until the
acceptance checks, commit, and clean-worktree validation are complete.

Write `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785801609594/phases/01-ticket/workers/engineer/task-ecount-005/REPORT.md` with these exact headings:

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
