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

## CTO cycle closeout

- Cycle: `runs/run-1785809029885`.
- Decision: Retain `Approved.` pending a stable multi-trial replay.
- Evidence: the candidate matched the oracle and restrictions, but the single
  timing sample was `1.221`, outside the `0.90..1.10` gate; the manager
  classified this as likely noise for a documentation-only change and did not
  recommend merging on one sample.

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

- Worker session: `runs/run-1785725237379/phases/03-eval/workers/eval-worker/task-ecount-1/session.jsonl` — tool errors at turns 53 (`let mut` parse error) and 56 (immutable-`let` reassignment), the `search:"mutable"` / `search:"mut"` probes, and the `var`/`let var`/`mut` keyword loop; the worker's final `ecount.xsh` uses `var results = []`, `var cur = ""`, `var cnt = 0` with reassignment and passes check + oracle.
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
