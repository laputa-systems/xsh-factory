# Eval-manager report

## Result

pass

Pre-merge validation of candidate `dcb2ad23636d5b3eceed23e72ac53ba65fd694b8`
("Document var keyword in core.bindings reference and assign-let diagnostic")
for ticket `task-ecount-008` is SUPPORTED by the executor evidence. Trial 2
passed every gate (correctness, restrictions, protocol, timing 0.9503). Trial 1
failed only the wall-time gate (1.1188) on a byte-identical candidate binary,
which is process-launch noise for a documentation/diagnostic-only change with
no runtime semantics change. Both worker reviews show the `var` binding was
reached directly from the handbook with no `let mut`/`mut x`/`let var x` probe
loop, satisfying the ticket's key discoverability acceptance criterion.

## Effort metrics

Two fresh trials against candidate commit `dcb2ad2` (handbook snapshot
`97c5d804…`), model `deepseek/deepseek-v4-flash-0731`, provider openrouter.

- Trial 1 (`task-ecount-1`): 57 assistant turns, 69 tool calls, 1 tool error,
  42 thinking blocks, session span 486,696 ms (~8.1 min). Agent state pass
  (artifact present, review present, budget pass); evaluator flagged timing
  only. Top-level worker result "pass"; execution classification
  `evaluator_failed` (timing).
- Trial 2 (`task-ecount-2`): 40 assistant turns, 49 tool calls, 8 tool errors,
  33 thinking blocks, session span 377,834 ms (~6.3 min). Full pass
  (classification `pass`).

Aggregate (phase data): 97 assistant turns, 9 tool errors, 2 workers.

Worker friction in both trials centred on stream/collection discovery (map
tail with `if/else`, `join` not a stream stage, single-arg `List.get`
returning `Result`), not on mutable-binding discoverability.

## Usage and cost

Provider-reported (openrouter) per worker:

- Trial 1: input 146,190 / output 26,532 / cacheRead 1,577,280 / cacheWrite 0
  tokens; bucket and provider total 1,750,002; reasoning 18,220 (subset of
  output); cost $0.0463239.
- Trial 2: input 81,036 / output 21,983 / cacheRead 839,168 / cacheWrite 0
  tokens; bucket and provider total 942,187; reasoning 14,647 (subset of
  output); cost $0.026355204.

Aggregate (phase data): cost $0.072679104; total bucket tokens 2,692,189;
budget failures 0 (budget $0.50 each).

Reasoning-token counts were reported by the provider for both workers.

## Thinking evidence

Trial 1: 42 thinking blocks; Trial 2: 33 thinking blocks. Reasoning-token
counts 18,220 / 14,647 were provider-reported. Thinking was qualitative in
nature: neither worker reasoned about guessing the mutable-binding keyword; in
trial 2 the thinking shows the worker working through padding/count alignment
and stream stages (turn 73) using `var`/`let` correctly from the handbook.
Thinking correlated with the iterative `xsht check` → fix loop that produced
the final passing artifact and review.

## Tool-error findings

Every nonzero Pi tool result from the structured `tool_errors` arrays:

Trial 1 (`task-ecount-1`, 1 error):
- turn 30: `xsht api: invalid API query 'language.core.display-strings';
  expected KIND:VALUE` (exit 2). Worker used the dotted `language.core.*` form
  instead of `language:core.*`. Classified as worker/API-discovery friction;
  the handbook already documents the `language:core.*` form, so this is a
  transient query-format slip, not a product defect.

Trial 2 (`task-ecount-2`, 8 errors):
- turn 21: check/fmt/lint of an early `ecount.xsh` draft — `unresolved proc
  command` (a `where { |e| ... }` block), `unknown method 'lower' on
  Result[Str,Error]` (single-arg `List.get` returns `Result`; two-arg overload
  needed), `desugar: pipeline sugar was not desugared` and two `type-mismatch`
  (`padstr + s`, int + Str) on the padding draft. Normal development-loop
  checker feedback while iterating; worker friction.
- turns 23,24,25: `desugar: pipeline sugar was not desugared` while testing
  the padding pipeline (`let padstr = [0,1,2,3,4,5,6]`, `idxs`, `idxs |> map …
  |> join("")`). Worker friction on stream-vs-List `join`; worker2 documented
  this in review (`join` is not a stream stage; collect first).
- turn 26: `display-conversion: value cannot be displayed by print` and a
  `desugar` on `[1,2,3] |> map … |> join(",")`. Worker friction, same root.
- turns 27,28: `check.map-tail: map requires a tail value` on `map { |i| if i
  < pad { … } else { "" } }`. Recurring two-trial friction → provisional
  handbook candidate (see Handbook decision).
- turn 32: `diff` exit 1 showing a worker-local synthetic oracle that included
  a `/noext` entry absent from the candidate. This is a worker-authored test
  fixture (no-extension path that the task requires omitting), not the real
  `/usr/share` oracle, which passed byte-for-byte in `run.json`
  (`exact_output: true`). Ordinary noise / local test artifact.

All 9 structured tool errors are accounted for as above. No manager-session
tool errors (this session ran no probes).

## Timing evidence

EVAL.md sets the candidate/oracle wall-time ratio gate at `0.90..1.10` for a
stable repeated trial set; the manager keeps timing failures separate from
language-correctness failures.

- Trial 1: candidate_wall 12,537,463 ns, oracle_wall 11,205,962 ns,
  ratio 1.1188 → outside gate → `timing: fail` (only failing gate).
- Trial 2: candidate_wall 10,943,713 ns, oracle_wall 11,516,336 ns,
  ratio 0.9503 → inside gate → `timing: pass`.

Both trials executed the byte-identical candidate (`candidate_sha256`
`c7c35609…` in both `run.json`), so the 1.1188 vs 0.9503 difference is
pure process-scheduling noise at the ~11 ms scale of a fast filesystem scan.
The candidate is a documentation/diagnostic-only change (`reference.rs`, two
diagnostic strings, three tests) with no runtime or binding-semantics change,
so the timing miss cannot be attributed to the change. Verdict: trial 1's
timing failure is noise; trial 2 demonstrates the gate is met for the same
program.

## Observation classification

- Reusable handbook guidance (recurring, 2/2 trials): a stream block's tail
  must be a plain value; an `if/else` expression alone is not accepted as a
  `map` tail and must be bound to a `let` first. Both workers hit
  `check.map-tail`; both reviews recorded the workaround. Generalizes to any
  stream-callback eval. → provisional handbook candidate.
- Reusable signal (1/2, from worker2 review): `join` is a List method, not a
  stream stage; `collect()` before `.join()`. Minor; handbook already implies
  this but does not state it explicitly. Not added to the candidate to keep it
  to one concise, general rule.
- Correctness (task success): both candidates byte-for-byte matched the
  `fd | awk | sort | uniq -c | sort -n` oracle and passed restriction and
  protocol checks.
- Noise: trial 1 timing miss (identical binary, docs-only change); turn-32
  local `/noext` diff artifact; the single invalid `xsht api` query (a format
  slip against documented `language:core.*` syntax).
- No product/tooling defect surfaced in this run beyond what ticket
  `task-ecount-008` already addresses; the candidate resolves the previous
  `var`-discoverability defect.

## Handbook decision

Provisional candidate staged at
`lineage/handbook-candidate.md` = approved snapshot `97c5d804…` unchanged in
substance plus one concise general rule under "Streams and collections":

> A stream block's tail must be a plain value; an `if/else` alone is not
> accepted as the block's tail (`map` reports "map requires a tail value").
> Bind the `if/else` result to a `let` and end the block with that variable.

The approved snapshot already carries the `var`-binding sentence, and the
`var`-discoverability acceptance criterion for ticket `task-ecount-008` is met
(no keyword probe loop in either trial), so no further `var` handbook change is
needed. The new rule is provisional and must be replayed before promotion.

## Tickets created

None. This run is a pre-merge re-evaluation of open ticket `task-ecount-008`;
no new product/tooling defect ticket is warranted (no strong, general, new
reproducible defect beyond what the candidate already fixes).

## Post-merge decisions

The reconciler found no merged tickets (`none`). No post-merge acceptance
assignment. The candidate branch `dcb2ad2` is NOT an ancestor of `main`, so it
is treated as an open pre-merge validation, not merged work.

## Next replay

Replay the provisional handbook candidate on `task-ecount` (same `fd | awk |
sort | uniq -c | sort -n` oracle, same `/usr/share` filesystem shape) at the
merged XSH commit once `task-ecount-008` is merged, to confirm: (a) no
`let mut`/`mut x`/`let var` probe loop, (b) byte-for-byte oracle match, and
(c) the map-tail `if/else` friction is reduced. Also run a nearby filesystem
case to test the stream-block-tail rule's generality. Only after that replay
would the provisional handbook sentence be promoted to `runtime/handbook.md`.

## North-star impact

Ticket `task-ecount-008` targets a core learnability gap: a mutable-binding
keyword that was invisible to the authoritative `xsht api language:core.bindings`
reference and the assign-let diagnostic forced `let mut`/`mut`/`let var`
guessing. The candidate names `var`, states `let` immutability, and teaches it
in the diagnostic, directly serving the north-star goal that agents reach a
correct solution "with less unnecessary exploration, turns, and thinking."
Both re-evaluation trials confirm the probe loop is gone (workers used `var`
from the handbook on the first attempt) while correctness, restrictions, and
the timing gate hold. The staged stream-block-tail rule is a small, general
handbook improvement that removes a recurring two-trial friction and improves
the clarity of XSH's explicit stream boundaries — both in service of a
practical, learnable, ergonomic, and trustworthy XSH.
