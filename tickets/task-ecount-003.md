# Ticket task-ecount-003

## Status

Approved.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-ecount` (`evals/task-ecount/EVAL.md`)
- Shared handbook lineage: `runs/run-1785661432406/phases/03-eval/lineage/handbook-approved.md` (approved `c7c9dd9a…`; candidate unchanged)
- Manager run: `runs/run-1785661432406/phases/03-eval/workers/eval-manager/task-ecount/session.jsonl`
- Executor run: `runs/run-1785661432406/phases/03-eval/workers/eval-worker/task-ecount-1` (trial 1)
- XSH baseline commit: `a66ade8218aacb38a2d1247db192f0c550cbb5cd`

## Observation

`language.stream.sort-by` silently returns the input unchanged when the key
projection produces a compound/record value, with no error or diagnostic. The
task-ecount worker needed `sort | uniq -c | sort -n` semantics (count
ascending, name ascending for ties) and projected a two-field record
`{c: r.count, n: r.name}` expecting lexicographic comparison; the stream came
back in the original order and the run "succeeded" with no message. The worker
then had to discover empirically that only scalar keys sort, that the sort is
stable, and that a two-pass idiom (sort by name first, then by count) produces
the required ordering.

Reproduced on the pinned image (XSH commit `a66ade82`, host `xsh` at the same
commit):

```text
$ cat sortby_test.xsh
proc main() [error, io] {
  let records = [
    {name: "b", count: 2},
    {name: "a", count: 1},
    {name: "c", count: 1},
  ]
  let out = records
    |> sort-by { |r| {c: r.count, n: r.name} }
    |> collect()
  for r in out { print $r.name $r.count }
}
$ xsh sortby_test.xsh
b 2
a 1
c 1        # original order, unsorted, no error
```

`xsht api language:stream.sort-by` shows only: "Sorts stream items by a
projected key. The key projection controls ordering and the stage materializes
the input before emitting results." It does not state which key types are
orderable, whether keys may be compound, the ascending/descending semantics,
or whether the sort is stable. `language.stream.group-by` has the same
shape-documentation gap (record `key`/`items` shape is undocumented; that
discoverability gap is already tracked in task-ecount-001).

## Evidence

- Worker session: `runs/run-1785661432406/phases/03-eval/workers/eval-worker/task-ecount-1/session.jsonl` — the sort-by record-projection probe and the two-pass discovery appear in the session tool results around thinking blocks 26–27; the worker's thinking shows it projected `{c: r.count, n: r.name}`, observed "The sort didn't apply", then verified stability and switched to the two-pass idiom.
- Worker review: `runs/run-1785661432406/phases/03-eval/workers/eval-worker/task-ecount-1/review.md`, section `## xsht friction`, "sort-by stability and compound keys are undocumented" — "When I projected a two-field record `{c: r.count, n: r.name}`, the stream came back in the original order with no error, silently failing to sort."
- Manager host probe on the pinned commit: the program above compiles, runs, and returns input order with exit 0; scalar-key sorts (`Int`, `Str`) do sort ascending; a two-pass stable sort (name first, then count) produces count-major/name-minor order.
- Quantitative metrics: `run.json` `result: pass`, `correctness.exact_output: true`, `restrictions.passed: true`; the candidate still matched the oracle on `/usr/share` because that tree has no count ties. The silence of the failed sort is the defect, not the eval result.

## Diagnosis or hypothesis

The sort stage accepts any projection and silently no-ops when the projected
value has no defined ordering. A silent wrong order is worse than a diagnostic:
an agent believes the pipeline worked. The contract gives no way to predict
that record keys are unsupported, so the worker burned multiple discovery
turns on a general language question (what can `sort-by` sort by, and is it
stable?) that the reference should answer. This is a general correctness and
learnability defect, not an ecount recipe: any multi-key or record-key sort in
any eval or user script either silently returns unsorted data or requires
trial-and-error discovery of the stability idiom.

## North-star impact

The north star asks for a typed, composable language where boundaries and
ordering are explicit and agents avoid "repeated discoveries." A sort stage
that silently ignores an unsupported key projection undermines trust in the
core pipeline abstraction and forces exactly the trial-and-error loop the
factory exists to remove. Fixing this would make compound ordering either work
deterministically or fail loudly with a message naming the stage and key type,
and would document the stability guarantee agents currently must guess.
Evidence of generalization: a replay of task-ecount (or any pipeline eval) on
the merged change should show a worker either sorting by a compound key with a
documented comparison or receiving a clear diagnostic — never silent
unsorted output — and the oracle-matching candidate should be reached without
the stability discovery loop.

## Proposed XSH change

Smallest candidate, one of:

1. Support compound/record key projections in `sort-by` with documented
   lexicographic field comparison, so `sort-by { |r| {c: r.count, n: r.name} }`
   sorts by count then name; or
2. Reject unsupported (non-orderable) key projections with a clear diagnostic
   that names the stage and the projected key type, instead of silently
   returning input order.

In both cases, update the `language.stream.sort-by` contract to state the
supported key types, ascending/descending semantics, and whether the sort is
stable (the two-pass idiom used by the worker relies on stability and it is
currently undocumented).

No change to scalar-key sorting behavior.

## Acceptance criteria

- `xsht api language:stream.sort-by` text documents supported key types,
  ascending/descending semantics, and stability.
- `sort-by { |r| {c: r.count, n: r.name} }` on records either sorts
  deterministically by the documented compound comparison or fails with a
  diagnostic naming `sort-by` and the record key type; it must not silently
  return input order with exit 0.
- Scalar-key sorts (`Int`, `Str`) behave exactly as before.
- The two-pass stable sort idiom (secondary key first, then primary) still
  produces the same result.
- A replay of `task-ecount` on the merged change with a synthetic tie-containing
  root still byte-for-byte matches the `fd | awk | sort | uniq -c | sort -n`
  oracle, and the worker no longer needs to discover the stability idiom by
  trial and error.

## Scope and non-goals

- No change to stream-stage execution semantics beyond sort key handling.
- Not an ecount shortcut; the diagnostic or compound-key support must
  generalize to every `sort-by` use.
- No change to the shared agent handbook inside XSH; the factory lineage owns
  the agent-facing handbook.

## Post-merge evaluation

The `task-ecount` eval-manager will run a controlled replay against the merged
XSH commit using the current approved handbook lineage, verify the compound-key
or diagnostic behavior described in the acceptance criteria, and record
acceptance or rejection in that run's manager report.
