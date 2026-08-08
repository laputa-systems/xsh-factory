# Eval-manager report

## Result

pass

## Effort metrics

Single fresh trial (Trial 1). Worker `task-uniqcat-1`:
- assistant turns: 27; user messages: 1; stop reasons: 1 `stop`, 26 `toolUse`
- tool calls: 28; tool results: 28; tool errors: 2
- tool mix: bash 20, read 5, write 2, edit 1
- agent wall: 102680 ms; session span: 97185 ms
- worker friction: 2 self-corrected tool errors (turn 8 negation parse; turn 13
  lint/shadow) — both resolved without repeated exploration; no correctness
  rework beyond them. Agent reached a passing solution in a single efficient
  development loop.

## Usage and cost

Trial 1 (provider openrouter, model deepseek-v4-flash-0731):
- input tokens 15906, output 5863, cacheRead 260864, cacheWrite 0; provider
  total 282633 = bucket total (282633).
- reasoning_tokens 2705 (provider-reported, a subset of output).
- cost: input 0.00143154, output 0.00105534, cacheRead 0.004695552,
  cacheWrite 0, total 0.007182432 USD.
- budget 0.5 USD, budget_state pass, budget_failures 0, unknown_costs 0.
- Aggregate equals the single trial (no additional trials).

## Thinking evidence

23 thinking blocks; provider reported 2705 reasoning tokens (not a sub-estimate
from text). Thinking transcript shows the worker explicitly reasoning about
boolean operators: after `if not set.has(...)` failed, it queried
`language:core.bool`, `language:core.operators`, `search:boolean`,
`search:negation`, and `search:operator`, found no negation rule, and
discovered the prefix `!` form by trial-and-error. This thinking directly
grounds the handbook-candidate decision.

## Tool-error findings

Both entities in the structured `tool_errors` array (worker `task-uniqcat-1`)
are accounted for:
- turn 8 (bash): `if not set.has(seen, ln)` →
  `err[parse.expected-expression]` (`not` is not an XSH keyword). Resolved by
  switching to `!`.
- turn 13 (bash): `check.standard-module-shadow` (variable `path` shadows the
  `path` module) plus `check.bare-print-ident` (`print ln` → `$ln`). Resolved
  by renaming the variable and using `$ln`.

No invalid `xsht api` discovery query appears as an error row in either the
worker or manager structured arrays; the negation/boolean search probes
(`search:negation`, `search:boolean`, `search:operator`, `language:core.bool`,
`language:core.operators`) returned no error entries in the current packet.
No manager-session tool errors were present.

## Timing evidence

This eval has no strict candidate/oracle timing gate (both finish in
milliseconds). Per-case candidate/oracle wall times are all within launch noise
(e.g. public 13.06 ms / 11.56 ms; hidden_all_empty 13.37 / 13.33;
hidden_missing 10.91 / 11.66; hidden_three 10.94 / 10.93). Timing is diagnostic
only and does not constrain the pass.

## Observation classification

- Correctness: `pass` — all eight cases byte-exact (candidate_sha256 equals
  oracle_sha256 `927c9bb4...` for `public, hidden_single, hidden_three,
  hidden_blank, hidden_utf8, hidden_space, hidden_all_empty, hidden_missing`).
- Restrictions: `pass` — no subprocess boundary; `read_text` referenced
  (hard-coded workaround classified as restriction failure by evaluator, not
  present here). Protocol/review: `pass`.
- Reusable handbook gap (turn 8 negation): XSH boolean negation is the prefix
  `!`; `not` is a parse error. Undocumented in the approved handbook and not
  surfaced by the worker's search queries. Generalizes to any conditional
  guard, not task-specific. → handbook candidate.
- Ordinary noise (turn 13 print bare-ident): handbook already states `$var`
  for dereference; the worker's `print ln` was a miss caught by lint, not a
  durable gap.
- Ordinary noise (turn 13 `path` shadow): minor lexical edge, no recurring
  lesson beyond existing naming care.
- Latency attribution: provider telemetry present with `retry_count 0`,
  `provider_errors []`, `retry_failures 0` → no external-health signal. The
  97 s span (27 turns, 28 tools, 2 self-corrected errors) is an
  agent-efficiency signal and looks efficient. `output_tokens_per_second` is 0
  (response elapsed not measured), so throughput is not asserted.

## Handbook decision

Provisional candidate staged at
`runs/run-1786147170660/phases/03-eval/lineage/handbook-candidate.md` (approved
snapshot copied unchanged plus one added paragraph). General lesson: document
that boolean negation uses the prefix `!` operator and there is no `not`
keyword, so guards read `if ! set.has(...)`. Replay scope: promote only after
CTO review and a replay that re-runs a guard-using eval (task-uniqcat and a
second one such as task-setdiff) on the shared lineage; the candidate removes a
parse-error probe confirmed in this session's thinking.

## Tickets created

None. The negation observation is staged as a handbook candidate rather than a
product ticket because prefix `!` is a deliberate language choice (not a
defect) and the missing piece is documentation/learnability, which the
handbook owns.

## Post-merge decisions

The reconciler found merged ticket files: `none`. Candidate re-evaluation:
`not-reevaluation` (no clean worktree to pre-validate). Accordingly there are
no post-merge acceptance assignments for this cycle; no dispatches and no
reverts.

## Next replay

Re-run `task-uniqcat` on the next approved handbook lineage (after CTO review
and promotion of the negation candidate), and in parallel re-run a second
guard-using eval (e.g. `task-setdiff`) to test generalization of the `!`
negation lesson. Falsification check: confirm the turn-8 `not` parse error no
longer occurs and that `!` guarded conditions remain correct on the shared
handbook lineage.

## North-star impact

Staging a concise, general rule that XSH negation is the prefix `!` operator
(no `not` keyword) removes an undocumented language-surface probe, improving
learnability and ergonomics for any future guard-using agent and eval. The
passing run itself demonstrates that multi-file sequential input through `fs.read_text`,
order-preserving set dedup (`set.empty`/`set.has`/`set.add`), and `Str.lines`
edge semantics compose cleanly — concrete evidence that XSH works as practical,
explicit-boundary systems glue (the `cat "$@" | awk '!seen[$0]++'` analogue
without a subprocess or sort).
