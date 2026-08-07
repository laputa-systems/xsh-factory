# Eval-manager report

## Result

pass

## Effort metrics

Trial 1 (the only trial; controller completed 1 fresh trial) — worker
`task-dupcheck-1`:

- Assistant turns: 23
- Tool calls: 25 (22 `bash`, 1 `edit`, 2 `read`)
- Tool results: 25
- Tool errors: 0
- Session span: 250,414 ms (~250 s); agent wall 251,606 ms; stop reasons 1
  `stop` + 22 `toolUse`
- Worker friction: low. The agent read the handbook, discovered `hash.sha256`
  and `fs.files` via `xsht api`, hit the named-argument parse friction
  (~2-3 turns), resolved it with positional args, and produced a passing
  artifact with a `xsht check`/`fmt`/`lint` loop. No repeated reads beyond
  normal discovery, no tool errors, no re-exploration churn.

## Usage and cost

Per worker `task-dupcheck-1` (provider-reported):

- Input tokens: 37,898
- Output tokens: 7,983
- Cache read: 245,696; cache write: 0
- Provider total: 291,577; bucket total (input+output+cacheRead+cacheWrite):
  291,577 — match, no mismatch.
- Reasoning tokens: 4,203 (provider reported; subset of output).
- Cost: input $0.00341082 + output $0.00143694 + cacheRead $0.004422528 +
  cacheWrite $0 = **$0.009270288** total. Budget $0.50, no breach.
- Aggregate: 1 trial, $0.009270288, 291,577 total tokens, 0 unknown costs.

## Thinking evidence

19 thinking blocks in the worker session; the provider reported 4,203
reasoning tokens (so a reasoning count is available for this model,
`openrouter/deepseek/deepseek-v4-flash-0731`). Thinking grounded the key
decisions: confirming `hidden` traversal semantics via `fs.files`, applying
`hash.sha256(...)?.hex()` at the content boundary, choosing positional args
after the named-arg parse failures, and sorting by digest then path for the
deterministic digest-first order. Thinking tracks closely with the correct
tool sequence and the final byte-exact result.

## Tool-error findings

None. The worker `report.json` `tool_errors` array is empty, the phase
`report.json` `tool_errors` array is empty, and the session JSONL contains zero
`"isError":true` results (all 25 toolResults are `isError:false`). No invalid
`xsht api` discovery query produced a failed Pi tool result in this run.

## Timing evidence

The eval has no strict candidate/oracle ratio gate. Per-case candidate vs
oracle wall (both milliseconds, from `run.json`):

- public 13.7 vs 13.5 ms; hidden_empty 11.3 vs 11.8; hidden_nested 11.0 vs
  11.0; hidden_three 10.8 vs 11.9; hidden_spaces 11.3 vs 11.2; hidden_many
  14.3 vs 13.0; hidden_none 13.3 vs 11.8; hidden_missing 13.2 vs 11.2
  (candidate exit 3, oracle exit 1 — both nonzero, no stdout).

All eight cases byte-exact (`correctness.all_exact = true`), including the
failure control. Timing is diagnostic only; no gate implication.

## Observation classification

- **Correctness pass (reusable positive signal / not a defect):** the agent
  composition — `fs.files(root, false, false, [], true)` (hidden traversal),
  `hash.sha256(e.path)?.hex()`, `group-by .digest`, `where .items.len() > 1`,
  sort by digest then path — matches the eval's north-star hypothesis and the
  EVAL reference. All eight fixtures pass. This is the first paid trial of the
  eval and confirms the previously-fixed evaluator module provisioning.
- **Named-argument display friction (reusable signal: product/tooling defect +
  handbook guidance):** `xsht api api:fs.files` renders `fs.files(path: Path,
  gitignore: Bool = default, ..., hidden: Bool = default)`, which invites
  `name = value` call syntax that the parser rejects (`expected ')' after call
  arguments`). The worker reproduced it independently in `named.xsh` without a
  postfix `?`, then fell back to positional args. This is general — any eval
  calling a defaulted-parameter module function can hit it — so I record it as
  one reproducible XSH ergonomics observation (product ticket task-dupcheck-002)
  and a concise positional-only handbook rule.
- **Historical factory defect (already handled, not re-opened):** the
  evaluator module-provisioning failure that `task-dupcheck-001` documented is
  confirmed fixed in this run — the evaluator started and measured all eight
  cases. No new factory ticket; that infrastructure repair is CTO-owned.
- **Ordinary noise:** nothing else. Minor discovery steps (Path cast, print
  `$` deref, fp interpolation) were normal handbook-aligned semantics, not
  defects.

## Handbook decision

Provisional candidate staged at
`runs/run-1786128115649/phases/03-eval/lineage/handbook-candidate.md`
(approved snapshot + one concise paragraph under "Development loop and
tooling"). The general lesson: **function calls are positional-only in this
build**; a rendered `name: Type = default` shows an omittable default, not a
named argument, and `name = value` in a call fails to parse — override
defaulted parameters positionally (e.g. `fs.files(root, false, false, [],
true)`). This is a short, general rule that removes a repeated-discovery class,
not a task recipe. It is a hypothesis only: it must be replayed (task-dupcheck
and at least one other defaulted-parameter eval) before promotion to
`runtime/handbook.md`; promotion requires CTO review.

## Tickets created

- `tickets/task-dupcheck-002.md` — Open, product target. Description: `xsht
  api` signature rendering implies named-argument support that the parser
  (positional-only) rejects; proposal is to make the displayed surface honest
  (smallest fix) or consider named args as a separate larger admission. Links
  this eval, manager run, executor run, handbook lineage, and XSH baseline
  `1477f472d5b4d57db3584357116ef97c32358ab6`. A new-ticket for the next cycle.

(Existing `tickets/task-dupcheck-001.md` is a closed historical factory ticket
for the evaluator module-provisioning fix; it is CTO-owned and already
resolved, so it is not re-opened or duplicated.)

## Post-merge decisions

None. The reconciler reported zero merged tickets for this cycle
(`merged: none`); no post-merge acceptance assignment exists.

## Next replay

- Eval: `task-dupcheck`, trial 1, against the staged handbook candidate
  (`runs/run-1786128115649/phases/03-eval/lineage/handbook-candidate.md`).
- Falsification/replay checks: (1) task-dupcheck still passes all eight cases
  with the positional-only rule in the handbook; (2) a second eval that calls a
  module function with defaulted parameters replays to confirm the agent no
  longer attempts invalid `name = value` calls; (3) if `task-dupcheck-002` is
  implemented and merged, replay task-dupcheck and a second eval there too.

## North-star impact

This run is the first paid validation of a content-level systems-glue eval:
the agent composed the typed `fs` stream, the `hash` module, and the
group/filter/flatten/sort idiom to reproduce `find | sha256sum | sort | awk`
with no subprocess — turning the eval's north-star hypothesis into measured,
byte-exact evidence across all eight cases. Separately, the run surfaced one
durable ergonomics defect (a reference surface that invites invalid
named-argument syntax) and a corresponding positional-only handbook rule,
both aimed at the north-star goals of fewer guesses/tool errors and an honest,
explicit, learnable API boundary. Correctness and clarity were strong at low
token/cost, and the historical harness defect that once blocked this eval is
confirmed fixed.
