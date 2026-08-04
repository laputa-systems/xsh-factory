# Ticket task-ecount-004

## Status

Merged.

## CTO review

- Review cycle: `pre-cycle-1785805851` (2026-08-03)
- Decision: Approved for the next two-engineer ticket cycle.
- Basis: The checker/runtime disagreement remains reproducible on active XSH
  HEAD and has a focused type-boundary contract distinct from merged stream
  fixes.
- Assignment boundary: Align `Any`-backed record sort checking with runtime
  behavior or reject it with a precise key-type diagnostic; preserve supported
  literal-record sorting and unrelated type checking.

## Budget breach

None.

## Merge record

- Implementation branch: `factory/task-ecount-004/1785805967997`
- Implementation commit: `c4f5fa1c56d6e302f6d392c4d19aed0f24faacf7`
- Detected at XSH commit: `e8f64a244af1727f64b4ee368441d04ca820d774`
- Implementation run: `runs/run-1785805967215`

## CTO merge decision

- Decision: Merged after engineer validation and linked `task-ecount` replay.
- Merge commit: `9b090cf`.
- Evidence: `runs/run-1785805967215/phases/02-reeval-task-ecount-004/report.json`.
- Note: the controller's final organization report was affected by a factory
  manager-evidence gate bug; the phase report and manager report both passed,
  and the gate fix is covered by a native regression test.

## Source eval and manager

- Eval: `task-ecount` (`evals/task-ecount/EVAL.md`)
- Shared handbook lineage: `runs/run-1785687503942/phases/02-reeval/lineage/handbook-approved.md` (approved `c7c9dd9a…`; candidate unchanged)
- Manager run: `runs/run-1785687503942/phases/02-reeval/workers/eval-manager/task-ecount/session.jsonl`
- Executor run: `runs/run-1785687503942/phases/02-reeval/workers/eval-worker/task-ecount-1` (trial 1)
- XSH baseline commit: `c2e1039d8856c04ad8466504d445dc93a341f720`

## Observation

After the task-ecount-003 fix (record sort keys order lexicographically,
unsupported keys fail loudly, stable sort), `xsht check` still rejects
`sort-by .count` / `sort` on records whose fields carry the `Any` type, even
though the runtime executes the identical program correctly and the projected
key is a supported scalar. The natural map-accumulator pattern for this eval
hits it every time:

```text
let counts = map.empty()                     # Map[Any]
...
let result = keys
  |> map { |k| {count: counts.get(k, 0), ext: k} }   # count: Any (Map.get fallback returns Any)
  |> sort-by .count
  |> collect()
```

`xsht check` reports `sort-by keys must be Int, Str, Bool, Path, or a record of
supported keys` (check.stream-sort) even though `.count` projects an Int at
runtime and `xsh` runs the program correctly, sorting deterministically with
the new comparator. The list-comprehension equivalent and plain `sort` over the
same records are rejected the same way. Only an explicit named type annotation
(`type Pair = {count: Int, ext: Str}` plus a typed `List[Pair]`) makes the
checker accept it. The task-ecount worker burned roughly ten thinking blocks
(blocks 49–58) discovering this workaround.

## Evidence

- Replay worker session: `runs/run-1785687503942/phases/02-reeval/workers/eval-worker/task-ecount-1/session.jsonl` — the map-block/comprehension `sort-by` rejections and the named-type discovery appear around thinking blocks 49–58; 7 occurrences of the `sort-by` key rejection and 2 of the `sort` item rejection are in the tool results; the worker review's `## xsht friction` section "sort-by contract over-promises structural-record support" describes the workaround.
- Worker review: `runs/run-1785687503942/phases/02-reeval/workers/eval-worker/task-ecount-1/review.md`, section `## XSH language proposals` → "sort-by / sort reject structural records produced by map blocks and list comprehensions".
- Manager host probes on the pinned image (XSH commit `c2e1039`):
  - `["b","a"] |> map { |k| {count: counts.get(k,0), ext: k} } |> sort-by .count`: `xsht check` fails (`check.stream-sort`), `xsh` runs and prints `1 a / 2 b` (correct order).
  - Same stream with `|> sort`: `xsht check` fails (`sort items must be …`), `xsh` runs correctly.
  - Named type + typed list comprehension (`let pairs: List[Pair] = [...] |> sort-by .count`): `xsht check` passes, output correct.
  - Literal record list `[{count:1,ext:"a"}] |> sort-by .count`: `xsht check` passes (so the gap is specific to records built from `Any`-typed values, not to record literals).
- Quantitative metrics: `run.json` `result: pass`, `correctness.exact_output: true`, `restrictions.passed: true`, `timings.ratio: 1.081` (within the 0.90..1.10 gate); the candidate still matched the oracle byte-for-byte after applying the named-type workaround.

## Diagnosis or hypothesis

The runtime and the checker disagree about `Any`. The runtime comparator
(`lowered_sort_key_orderable`) treats the actual values (Ints at runtime) as
orderable and sorts them; the checker's `is_sortable_key_type` in
`src/sema/check/stream.rs` matches only `Int | Str | Bool | Path | Unknown`
and `Type::Record(fields)` whose fields are themselves supported, so a record
field typed `Any` (from `Map.get(key, fallback: Any) -> Any` on a `Map[Any]`
built by `map.empty()`) makes the record non-orderable and even a scalar
`.count` projection is reported as an unsupported key. The diagnostic does not
name the actual key type (`Any`), so the message is actively misleading: the
user believes `.count` (an Int at runtime) is unsupported. The updated
`language.stream.sort-by` contract says records whose fields are supported keys
are valid, so the checker over-promises for the very common
map-accumulator → sort-by pipeline. The implementation's own sema tests only
cover literal records, so this gap passed the task-ecount-003 test suite.
This is a general correctness/learnability defect, not an ecount recipe: any
eval or user script that counts into `map.empty()` and then sorts by a
record field either gets a wrong diagnostic or is forced into a named-type
workaround that the runtime does not require.

## North-star impact

The north star asks for explicit boundaries and no "repeated discoveries."
After task-ecount-003, unsupported sort keys fail loudly instead of silently
returning input order, but this checker/runtime split reintroduces a
trial-and-error loop: the runtime accepts a program the checker rejects, and
the rejection message does not say why. Aligning the checker with the runtime
(or making the diagnostic name the `Any` key type and scoping the contract
honestly) would make the `map`/`Map.get` → record → `sort-by` pipeline work
the first time, exactly the fluency the factory exists to buy. Evidence of
generalization: a replay of task-ecount (or any pipeline eval) on the merged
change should show a worker either sorting a map-accumulator record stream
without a named-type annotation, or receiving a diagnostic that names `Any`
and a contract that matches checker behavior.

## Proposed XSH change

Smallest candidate, one of:

1. Accept `Type::Any` (and records whose fields are `Any`-compatible) in the
   checker's `is_sortable_key_type`/`is_sortable_record_key_type`, matching the
   runtime's `lowered_sort_key_orderable` so `xsht check` and `xsh` agree on
   what can sort; or
2. Keep the checker strict but make the rejection diagnostic name the actual
   key type (`found Any from Map.get fallback`) and narrow the
   `language.stream.sort-by` / `sort` contract text to say records must have
   statically-supported (non-`Any`) fields.

In both cases, add checker tests for records produced by `map` blocks and list
comprehensions whose fields come from `Map.get` (`Any`) and for records built
from literal scalars, and confirm the runtime and checker accept the same
programs.

No change to runtime sort semantics.

## Acceptance criteria

- The map-accumulator pattern
  `keys |> map { |k| {count: counts.get(k, 0), ext: k} } |> sort-by .count`
  (and its list-comprehension equivalent) either type-checks without a named
  type annotation, or fails with a diagnostic that names the stage and the
  actual key type (`Any`), never a bare "keys must be Int, Str, Bool, Path…".
- `xsht check` and `xsh` agree on the same sort program: a program that runs
  correctly is not rejected by the checker, and a program the checker rejects
  fails at runtime with the same reason.
- Literal-record and named-type record sorts behave exactly as in
  task-ecount-003 (compound keys order deterministically; unsupported keys fail
  loudly; scalar sorts unchanged; stability preserved).
- A replay of `task-ecount` on the merged change still byte-for-byte matches
  the `fd | awk | sort | uniq -c | sort -n` oracle, and a worker following the
  handbook reaches the candidate without the named-type workaround or a
  discovery loop.

## Scope and non-goals

- No change to runtime sort ordering, stability, or the loud-failure gate from
  task-ecount-003.
- Not an ecount shortcut; the checker/runtime agreement must generalize to every
  `sort-by`/`sort` use.
- The `fold`/`reduce` reference gap (no signature/example; single-parameter
  stage block) observed in the same replay is tracked separately in the manager
  report and is out of scope here.
- No change to the shared agent handbook inside XSH; the factory lineage owns
  the agent-facing handbook.

## Post-merge evaluation

The `task-ecount` eval-manager will run a controlled replay against the merged
XSH commit using the current approved handbook lineage, verify the
checker/runtime agreement described in the acceptance criteria, and record
acceptance or rejection in that run's manager report.
