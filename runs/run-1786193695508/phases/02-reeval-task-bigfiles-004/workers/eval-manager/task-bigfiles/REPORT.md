# Eval-manager report

## Result

fail (candidate acceptance not exercised; eval trial itself passed)

## Effort metrics

One fresh trial (`task-bigfiles-1`) was executed by the controller against the
approved handbook snapshot. The worker finished in 21 assistant turns, 28 tool
calls (24 `bash`, 3 `read`, 1 `write`), 1 tool error, and 28 tool results.
Session span 665,081 ms (~11.1 min); agent wall 666,318 ms. Provider telemetry
is present: retry_count 0, provider_errors [], retries success 0 / failure 0,
so no external-health interruption; wall time is ordinary agent effort, not a
provider-latency signal. Latency attribution to a specific cause beyond the
near-zero provider health indicators is `unknown` (output_tokens_per_second and
response_elapsed_ms are 0), but the 21-turn session shows no repeated
exploration, so there is no agent-efficiency regression. Worker friction is
limited to one self-resolved `xsht api` query-syntax slip and one genuine
`parse_int` permissiveness discovery (see below).

## Usage and cost

Worker `task-bigfiles-1` (model `openrouter/deepseek/deepseek-v4-flash-0731`):
input 63,317; output 6,952; cacheRead 175,680; cacheWrite 0;
provider total 245,949; bucket total 245,949 (match). Provider-reported
reasoning tokens 4,421 (subset of output). Cost: input $0.00569853, output
$0.00125136, cacheRead $0.00316224, cacheWrite $0, total **$0.01011213**.
Budget $0.50, no budget breach. One trial, so aggregate == this trial. Cost is
low and consistent with a 21-turn, single-pass task.

## Thinking evidence

20 thinking blocks captured in `session.jsonl.bz2` (reasoning tokens 4,421
provider-reported). The thinking transcript shows a coherent, linear
investigation: query `fs.files`/`module:fs`, learn `sort-by`, learn `take`,
discover `parse_int`, empirically probe `parse_int` permissiveness (0x10 =
0, 1_000 = 0, +7 = 0, -3 = 0, leading space = 0, abc = error), locate
`abort` as the clean nonzero exit, and assemble the final `fs.files(root,
stat: true)` pipeline. The only materially incorrect provisional branch was
the trial of `r.is_err()` and `r is Err` Result-matching syntax, which the
checker rejected promptly and the worker abandoned. No deep but wrong
reasoning loop; thinking tracks the executable choices well.

## Tool-error findings

Exactly one nonzero Pi tool result in the current evidence packet, from worker
`task-bigfiles-1` turn 12:

- `xsht api: invalid API query 'language.core.abort'; expected KIND:VALUE`
  (bash, exit 2). This was a query-syntax slip: the worker wrote the rule id
  with a dot (`language.core.abort`) instead of the `KIND:VALUE` form
  (`language:core.abort`). It immediately re-issued the correct form
  `xsht api language:core.abort`, which returned the exact `abort` entry. The
  handbook already documents the `KIND:VALUE` form, so this is a self-resolved
  query accent, not a handbook gap or product defect.

No manager-session tool errors (this review used only `read`/`write`/`edit`).
All other API queries (`api:fs.files`, `module:fs`, `language:stream.sort-by`,
`method:Str.parse_int`, `search:parse_int`, `module:env.int`, `search:Result`,
`language:core.abort`) returned valid results.

## Timing evidence

This eval has no strict candidate/oracle timing gate (per EVAL.md; both sides
finish in milliseconds). Candidate vs oracle per case (ns): public 16,036,984
vs 12,415,251; hidden_default 12,313,917 vs 14,249,555; hidden_n2 11,373,869
vs 14,643,808; hidden_single 11,671,579 vs 14,980,935; hidden_deep 12,159,083
vs 15,590,481; hidden_spaces 11,003,325 vs 12,294,042; hidden_utf8 15,046,727
vs 15,447,647; hidden_empty 15,664,398 vs 15,763,107; hidden_bad_n 13,073,338
vs 15,968,984. All within the same low-millisecond band and `timings.passed`
is true. Timing is diagnostic only.

## Observation classification

- Worker friction / candidate acceptance gap — **product/replay signal
  (candidate not exercised).** The API contract for `fs.files` in this trial
  states "hidden: false by default omits dot-prefixed files and directories,
  while hidden: true includes them", confirming the candidate documentation
  fix is present and readable in the live reference. The worker read this
  contract, but its final artifact calls `fs.files(root, stat: true)` with no
  `hidden:` argument and never selects the hidden behavior. That is a correct
  choice for the eval's nine fixtures (none contain dot entries), and all nine
  cases pass byte-for-byte, but the candidate ticket's acceptance criterion "a
  linked replay reads the contract and selects the intended hidden behavior,
  without relying on a fixture experiment, while all nine cases remain exact"
  was **not exercised** in this run. No fixture probe and no `hidden: true`
  selection occurred, so this replay does not demonstrate the fix achieves its
  post-merge behavior gate. The controller should retain the branch for a
  directed replay using a dot-entry-containing fixture tree.
- Reusable handbook signal — **parse_int permissiveness.** The worker's
  `review.md` (evidence-grounded) and the session record that `Str.parse_int()`
  accepts `0x10`, `1_000`, `+7`, and leading whitespace, so a strict-decimal
  gate cannot rely on it; validation must occur first (digit filter) and an
  explicit `abort(1)` rejects. This contradicts the handbook's implication that
  a typed conversion reliably produces the nonzero exit for rejected input.
  Generalizes to any strict-decimal boundary, so it is staged as a provisional
  handbook candidate (not a product ticket).
- Ordinary noise — the one `language.core.abort` query-syntax slip at turn 12,
  immediately corrected; not a durable gap.
- Evaluator/harness — no mismatch; protocol, restrictions, and all nine cases
  pass (`all_exact: true`).

## Handbook decision

Provisional candidate staged at `lineage/handbook-candidate.md` (approved
snapshot + one new sentence in "Effects and errors"):

> `Str.parse_int()` is permissive, not a strict decimal validator: in the
> pinned image it also accepts `0x10`, `1_000`, `+7`, and leading whitespace.
> A byte-exact decimal (digits-only) contract must validate the digits first
> (e.g. `n != "" and n.delete("0123456789") == ""`) before parsing, and reject
> otherwise (an explicit `abort(1)` is a clean nonzero exit without stdout).

Replay scope: this is a one-trial plan; the candidate is provisional and must
be replayed before promotion. It should be replayed on `task-bigfiles` (strict
`N` boundary) and independently on any future strict-decimal eval
(`task-ecount`/count-style) to confirm agents stop relying on `parse_int`
alone. No eval-specific handbook branch is created; the approved snapshot file
is not modified.

## Tickets created

Zero. No new ticket is opened this cycle. The `parse_int` permissiveness
observation is handled as a provisional handbook candidate rather than a
product ticket because it is primarily a learnability/documentation lesson, not
a runtime correctness defect, and a stronger, reproducible, second-confirmed
surface would be needed before a product ticket is justified.

## Post-merge decisions

None. The reconciler reported no merged ticket files, and `task-bigfiles-004`
is a pre-merge candidate under validation (status Approved.), not a merged
post-merge assignment. The candidate decision is recorded in the evidence
above: the fix's documentation is confirmed present and the eval passes, but
the candidate's replay acceptance gate (selecting hidden behavior) was not
exercised; the branch should be retained for a directed replay rather than
accepted or dispatched this cycle.

## Next replay

Directed replay of `task-bigfiles` at the candidate commit
(`608ab11bcf25cb0f69df4cb352fa40b27c1be2b3`) with a fixture tree that includes
a dot-prefixed regular file, so the worker must read the (now documented)
`fs.files` hidden contract and either select `hidden: true` or demonstrate the
documented default, byte-exact across all cases — this is the falsification
check for candidate ticket `task-bigfiles-004`. Separately, a future
`task-bigfiles` (or equivalent strict-decimal) replay must be run against the
staged handbook candidate to validate the `parse_int` permissiveness lesson
before it is promoted to `runtime/handbook.md`.

## North-star impact

This run advances the learnable-trust axis of the north star in two ways. It
also re-confirms (from the candidate fix present in the live API) that
recursive discovery now documents its silent dot-entry default, replacing a
silent behavior trap with an explicit contract. And it surfaces a genuinely
reusable ergonomic lesson — `Str.parse_int` is not a strict decimal validator —
so future agents writing exact-output count/number gates stop producing
silently-wrong results and instead validate tokens explicitly, which is exactly
the "fewer guesses, correct by construction, explicit boundaries" improvement
the factory is chartered to make. The candidate itself is not yet accepted:
honesty about the unexercised acceptance gate preserves trust, ensuring the
documentation change is proven (not just present) before it compounds.
