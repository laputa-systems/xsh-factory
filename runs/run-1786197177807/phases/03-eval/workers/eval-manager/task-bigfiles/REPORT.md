# Eval-manager report

## Result

pass

Eval `task-bigfiles`, phase `03-eval`, run `run-1786197177807`, XSH commit
`c77b01a3e2fb676cc57cdeddbb7575be7723aa32`. One fresh trial completed and passed:
correctness pass on all 9 cases (including the failure control), restriction
pass, protocol pass, timing pass. The worker produced a real `fs.files` +
`sort-by` + `take` compositional solution with no subprocess escape; the
candidate/oracle stdout matched byte-for-byte and both exited nonzero on
`hidden_bad_n`.

## Effort metrics

Trial 1 (`eval-worker/task-bigfiles-1`):
- Assistant turns: 23 (stop reasons: 1 `stop`, 22 `toolUse`).
- Tool calls: 27 (bash 20, edit 3, read 3, write 1); tool results 27.
- Tool errors: 1 (see Tool-error findings).
- Session span: 280,696 ms (~4.7 min); agent wall 281,972 ms.
- User messages: 1 (single task dispatch).
- Worker friction: low. One minor discovery probe exited 1; discovery was
  otherwise fluent (exact `xsht api` queries: `api:fs.files`, `api:fs.walk`,
  `language:stream.sort-by`, `language:stream.take`, `method:Str.parse_int`,
  `method:List.get`, `search:*`). One redundant probe (`xsht api lang 2>/dev/null`)
  was immediately superseded by an exact query. The solution converged after a
  single hidden-file correction (`fs.files(root, hidden: true)`), caught by the
  worker's own dot-file fixture test.

No trial 2 configured (single-trial plan); nothing to compare.

## Usage and cost

Trial 1 provider-reported usage (openrouter/deepseek/deepseek-v4-flash-0731):
- Input 64,506; output 5,504; cacheRead 177,728; cacheWrite 0.
- Bucket total 247,738; provider totalTokens 247,738 (match).
- Reasoning tokens: 2,496 (provider-reported, a subset of output).
- Cost: input $0.00580554, output $0.00099072, cacheRead $0.003199104,
  cacheWrite $0; total $0.009995364. Budget $0.50; no budget failures.
- Aggregate (1 worker): $0.009995364.

## Thinking evidence

Thinking blocks: 19 (provider-reported reasoning tokens: 2,496). The thinking
transcript shows a direct, well-ordered design path: read environment →
query the exact `fs.files`/`sort-by`/`take` signatures → confirm
`Str.parse_int()` and `List.get` → write the compositional pipeline → iterate
on lint (`$` field access in print, `fp"${...}"` path interpolation, bare Path
display) → test dot/hidden files, explicit N, and invalid N on a local fixture
→ verify stdout is empty on invalid N. Thinking correlates with the passing
artifact; no wasteful re-discovery after the first few turns.

## Tool-error findings

One nonzero Pi tool result in the worker report `tool_errors` (turn 5, `bash`):
```
---list index--- ... ---List methods---
Command exited with code 1
```
This was `xsht api summary 2>/dev/null | grep -A40 "List methods"`: grep found no
match (the summary header is `List (6 items)`, not `List methods`), so the final
pipeline stage exited 1 and the command was flagged. The worker recovered
immediately by querying `method:List.get` and `method:List.len` directly. This is
a benign discovery-probe miss (ordinary friction), not a product defect; the
handbook already teaches `xsht api summary | grep List`. No other tool errors
in the current worker or manager sessions.

Manager session contributed zero tool calls/errors (bounded evidence review).

## Timing evidence

No candidate/oracle ratio gate for this eval; timing is diagnostic. Per-case
candidate vs oracle wall time (ms), all equivalent:
- public 14.9/12.0; hidden_default 10.9/14.3; hidden_n2 11.8/11.6;
  hidden_single 11.7/11.8; hidden_deep 10.8/14.8; hidden_spaces 14.5/12.9;
  hidden_utf8 11.3/12.3; hidden_empty 14.7/12.4; hidden_bad_n 12.5/12.3.
All milliseconds, no meaningful gap. Provider telemetry: retry_count 0,
provider_errors [], so no provider-latency signal; the ~281 s session span is
ordinary multi-turn agent work for 23 turns.

## Observation classification

- Correctness: candidate byte-matched the oracle on all 9 cases and exited
  nonzero with empty stdout on `hidden_bad_n` (candidate exit 3 vs oracle 1,
  both nonzero). Valid regular-file filtering, descending size sort, `take`,
  hidden/dot inclusion, and empty-tree handling all correct.
- Restriction compliance: source references `fs.files` and a `sort-by` stage,
  no subprocess/process/spawn boundary, no hard-coded result; passes the
  evaluator's restriction checks.
- Product/tooling: the one failed grep probe is not a reproducible product
  defect; the summary header naming (`List (6 items)`) is minor and already
  addressed by the handbook's `grep List` guidance. No ticket.
- Handbook signal: the session confirmed existing handbook idioms
  (`sort-by --desc { |e| e.size }` command-word form, `take(n)`, `fp"${...}"`,
  `parse_int()?` error propagation) all worked as documented; no new reusable
  lesson surfaced. The `hidden: true` flag on `fs.files` is documented in the
  API and was correctly discovered. Classified as ordinary noise / no change.
- No image or harness mismatch; no evaluator failure.

## Handbook decision

Unchanged. The staged `lineage/handbook-candidate.md` is byte-identical to the
approved `lineage/handbook-approved.md` (no candidate staged). The single trial
exercised existing handbook guidance without friction, so there is no
falsifiable general lesson to promote. A two-trial replay could still firm up
stability, but no handbook edit is warranted from this evidence.

## Tickets created

None. No strong reproducible observation met the product-ticket bar. The single
tool error was benign discovery noise already covered by handbook guidance.
Pre-existing ticket files (`task-bigfiles-001..004`, and all other listed
pre-manager identities) were left untouched.

## Post-merge decisions

None. The reconciler reported zero merged tickets for this cycle.
(`task-bigfiles-004` appears as an open/approved ticket in `open_tickets`, not
as a reconciled merged ticket, so it is not a post-merge acceptance assignment
here.)

## Next replay

No handbook change was staged, so no replay is required to validate one. The
next useful replay is a second fresh `task-bigfiles` trial against the same
approved `run-1786197177807/phases/03-eval/lineage/handbook-approved.md`
snapshot to confirm the numeric `sort-by` + `take` ranked-report hypothesis is
stable across runs; a later cycle may also replay `task-bigfiles` after any
future handbook promotion that touches stream stages.

## North-star impact

This run confirms the eval's central north-star hypothesis: the classic
`find | ls -S | head` disk-hygiene shape is expressed naturally and
composably in XSH (`fs.files |> where |> sort-by --desc |> take |> collect`),
with no subprocess escape, byte-exact `<size> <path>` output, and loud
`parse_int()?` validation for a malformed count. The worker reached a correct,
clean solution in a compact, low-friction session — evidence that the handbook
and `xsht api` make numeric stream ordering (`sort-by` on a per-file size plus
`take`) and the Result/`?` idiom learnable and reliable. This is a practical,
ergonomic, trustworthy systems-glue result that generalizes to ranked-report
and log-truncation tasks beyond this eval.
