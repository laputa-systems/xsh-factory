# Controller-assigned engineer ticket

This is an immutable controller assignment for one implementation worker.
The controller, not the worker, selected the ticket, snapshot, worktree, and
branch.

## Assignment authority

- Ticket ID: `task-ecount-008`
- Ticket snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785809029885/phases/01-ticket/tickets/task-ecount-008.md`
- Ticket snapshot SHA-256: `ad92dc213e6c553f81089576b0be7cf2835b1fc4f711f5c5c5cd424ef20c524d`
- Dedicated XSH worktree: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785809029885/phases/01-ticket/worktrees/task-ecount-008`
- Branch: `factory/task-ecount-008/1785809030662`
- XSH base commit: `e8f64a244af1727f64b4ee368441d04ca820d774`
- engineer report: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785809029885/phases/01-ticket/workers/engineer/task-ecount-008/REPORT.md`
- Factory root: `/Users/josh/d/laputa-systems/xsh-factory`
- Run evidence root: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785809029885/phases/01-ticket`

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
# Ticket task-ecount-008

## Status

Approved.

## CTO review

- Review cycle: `post-cycle-1785805967215` (2026-08-03)
- Decision: Approved for the next two-engineer ticket cycle.
- Basis: The missing `var` guidance remains a reproducible discoverability gap
  in an active `task-ecount` eval, and the current cycle closed the higher-
  urgency runtime fixes that previously took priority.
- Assignment boundary: Add the smallest accurate handbook/reference or
  diagnostic improvement that makes mutable binding syntax discoverable;
  preserve `let` immutability and existing `var` behavior.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-ecount` (`evals/task-ecount/EVAL.md`)
- Shared handbook lineage: `runs/run-1785725237379/phases/03-eval/lineage/handbook-approved.md` (approved `c7c9dd9a…`; candidate `b323e668…`)
- Manager run: `runs/run-1785725237379/phases/03-eval/workers/eval-manager/task-ecount/REPORT.md`
- Executor run: `runs/run-1785725237379/phases/03-eval/workers/eval-worker/task-ecount-1` (trial 1)
- XSH baseline commit: `ea7dea2f2b436cce34262d7a02105cbb029243dd`

## Observation

Agents cannot discover XSH's mutable-binding syntax from the documented
sources of truth. `let mut x = 0` is a parse error
(`err[parse.expected-token]: expected '=' in binding` pointing at `mut`), a
`let` binding cannot be reassigned (`err[check.assign-let]: assignment to
immutable 'let' binding`), and the `language:core.bindings` reference entry
only says "Bindings have declared mutability and type boundaries" without
stating the token. The actual keyword is `var`, which the task-ecount worker
had to find by trial and error.

In the task-ecount session, the worker tried `let mut total = 0` (parse
error), then reassignment of a plain `let` (assign-let error), then searched
`xsht api search:"mutable"` / `search:"mut"`, then looped over `var total =
0`, `let var total = 0`, and `mut total = 0` before confirming that only
`var total = 0` checks and runs.

Reproduced on the pinned image (XSH commit `ea7dea2`):

```text
$ cat letmut_probe.xsh
proc main() {
  let mut total = 0
  total = total + 1
  print $total
}
$ xsht check letmut_probe.xsh
err[parse.expected-token]: expected `=` in binding
  letmut_probe.xsh:2:11
    let mut total = 0
            ^^^^^ expected `=` in binding
...
```

```text
$ cat var_probe.xsh
proc main() {
  var total = 0
  total = total + 1
  print $total
}
$ xsht check var_probe.xsh   # exit 0
$ xsh var_probe.xsh
1
```

`xsht api language:core.bindings` prints: "Bindings have declared mutability
and type boundaries; reassignment cannot create an invalid inferred state."
It never names the `var` token. The approved handbook's binding section says
only "Bind values with let:" and never documents mutable state.

## Evidence

- Worker session: `runs/run-1785725237379/phases/03-eval/workers/eval-worker/task-ecount-1/session.jsonl.bz2` — tool errors at turns 53 (`let mut` parse error) and 56 (immutable-`let` reassignment), the `search:"mutable"` / `search:"mut"` probes, and the `var`/`let var`/`mut` keyword loop; the worker's final `ecount.xsh` uses `var results = []`, `var cur = ""`, `var cnt = 0` with reassignment and passes check + oracle.
- Worker review: `runs/run-1785725237379/phases/03-eval/workers/eval-worker/task-ecount-1/review.md`, section `## xsht friction` — "Mutable bindings are declared with the `var` keyword (`var x = 0`, then `x = x + 1`); `let` is immutable and `let mut x = 0` is a parse error, yet the `language:core.bindings` doc only says bindings have 'declared mutability' without stating the `var` token — it had to be discovered by trial."
- Manager host probe at the same commit: `let mut` fails with the identical parse error; `var` checks and runs, printing `1`.
- Quantitative metrics: `run.json` `result: pass`, `correctness.exact_output: true`, `restrictions.passed: true`, `timings.ratio: 0.975`; the eval still passed because the worker spent ~3 extra discovery turns finding `var`, and used `var` + `List.push` instead of a map/fold accumulator.

## Diagnosis or hypothesis

The runtime supports `var` correctly; the defect is discoverability. The
`language.core.bindings` reference, which the handbook tells agents to treat
as authoritative, describes mutability without naming its token, and the
parse/check diagnostics for `let mut` / immutable-`let` reassignment do not
mention `var`. Any agent that needs a mutable accumulator or counter — a
routine systems-glue need, not an ecount quirk — will guess `let mut`,
`mut`, or `let var` and burn discovery turns. This is a general learnability
and reference-accuracy defect: the documented source of truth should either
state the `var` keyword or the diagnostics should teach it.

## North-star impact

The north star asks for a language that is "clear enough for people to learn"
and for agents that reach correct solutions with "less unnecessary
exploration, turns, and thinking." A core binding keyword that is invisible
to both the reference and the handbook forces exactly the repeated-discovery
loop the factory exists to remove. Naming `var` in `language:core.bindings`
(and having `let mut`/assign-let diagnostics suggest it) would let any future
agent write a mutable accumulator on the first attempt. Evidence of
generalization: any eval worker that needs a counter (task-ecount, task-tags,
task-envcfg, or a future port) would reach `var` from the reference instead
of by trial; a replay should show no `let mut`/`mut`/`let var` probe loop.

## Proposed XSH change

Smallest candidate, one of:

1. Update the `language:core.bindings` reference text to state the mutable
   token explicitly, e.g. "Bindings are immutable with `let`; declare a
   reassignable binding with `var` (`var x = 0; x = x + 1`). `let mut` is not
   valid syntax."; or
2. Additionally, make the parse/check diagnostics for `let mut` and for
   reassigning a `let` name the `var` keyword in their help text.

No runtime semantics change.

## Acceptance criteria

- `xsht api language:core.bindings` states the `var` token and that `let`
  bindings are immutable.
- A first-time agent writing a counter from the handbook or `xsht api` uses
  `var` without a probe loop: a replay shows no `let mut`, `mut x`, or
  `let var x` attempts.
- `xsht check` and `xsh` behavior for `var` and `let` is unchanged
  (`var` reassignment works; `let` reassignment still errors, ideally with a
  message naming `var`).
- A replay of `task-ecount` on the merged change still byte-for-byte matches
  the `fd | awk | sort | uniq -c | sort -n` oracle and passes the timing gate.

## Scope and non-goals

- No change to binding semantics, type rules, or runtime behavior.
- Not an ecount shortcut; the reference/diagnostic fix must generalize to any
  mutable-binding use in any eval or user script.
- The empty-map-literal `{}` facet and fold-arity gap observed in the same
  session are tracked separately in `task-ecount-007`; the mutable-binding
  keyword is independent and out of that ticket's scope.
- No change to the shared agent handbook inside XSH; the factory lineage owns
  the agent-facing handbook (a `var`-binding sentence is staged as the
  provisional candidate in this run's lineage).

## Post-merge evaluation

The `task-ecount` eval-manager will run a controlled replay against the merged
XSH commit using the current approved handbook lineage, verify that the worker
reaches `var` from `xsht api` without the keyword trial loop, confirm the
byte-for-byte oracle match and timing gate, and record acceptance or rejection
in that run's manager report.

<!-- CONTROLLER_TICKET_SNAPSHOT_END -->

## Factory context required before coding

The factory documents below are outside the XSH worktree. Before coding, use
the `read` tool on each exact absolute path. This is required so the session
JSONL proves that the worker consumed the current factory guidance:

- North star: `/Users/josh/d/laputa-systems/xsh-factory/NORTH-STAR.md`
- Shared handbook: `/Users/josh/d/laputa-systems/xsh-factory/runtime/handbook.md`

Then use the `read` tool on the product worktree's exact guidance files:

- Product agent guide: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785809029885/phases/01-ticket/worktrees/task-ecount-008/AGENTS.md`
- XSH rationale: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785809029885/phases/01-ticket/worktrees/task-ecount-008/docs/CHAPTER-01-why-xsh.md`

## Implementation contract

Work only in `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785809029885/phases/01-ticket/worktrees/task-ecount-008` on branch `factory/task-ecount-008/1785809030662`. Do not edit XSH main, the
factory main tree, or the ticket diagnosis. Make the smallest general XSH
language, tooling, test, or canonical-documentation change supported by the
ticket. Run the narrowest relevant checks, commit the product change on this
branch, and leave the worktree clean.

The controller has staged a fail-closed `not-ready` report at
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785809029885/phases/01-ticket/workers/engineer/task-ecount-008/REPORT.md`. Complete that file in place; do not spend turns
reconstructing its headings. Keep `## Result` as `not-ready` until the
acceptance checks, commit, and clean-worktree validation are complete.

Write `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785809029885/phases/01-ticket/workers/engineer/task-ecount-008/REPORT.md` with these exact headings:

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
