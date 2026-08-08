# Eval-manager report

## Result

pass

## Effort metrics

This run is a candidate-linked replay of the pre-merge engineer worktree for
`task-histogram-005` (`Str.parse_uint()` additive change). A single fresh
trial (`Trial 1`, worker `task-histogram-1`) was executed by the controller
against the candidate XSH commit; the manager did not launch or rerun the
executor.

- Trial 1: 39 assistant turns, 43 tool calls (34 `bash`, 2 `edit`, 3 `read`,
  4 `write`), 0 tool errors, 43 tool results.
- Session span: `session_span_ms` 274768 (≈ 4.6 min); `agent_wall_ms` 276050.
- Stop reasons: 1 `stop`, 38 `toolUse`.
- Worker friction: one `err[check.standard-module-shadow]` from naming a local
  binding `path`; resolved within the same turn by renaming to `file_path`.
  Low overall friction; no repeated exploration.

## Usage and cost

Worker `task-histogram-1` (openrouter/deepseek/deepseek-v4-flash-0731):

- input 255795 / output 10751 / cacheRead 368640 / cacheWrite 0 tokens.
- `provider_total_tokens` 635186; bucket total (`input+output+cacheRead+cacheWrite`)
  635186 — the two totals match (no mismatch).
- Reasoning tokens 6077 (provider-reported, subset of output; not added to output).
- Cost `cost_usd` 0.03159225 (input 0.02302155, output 0.00193518, cacheRead
  0.00663552, cacheWrite 0). Budget USD 0.5; no budget breach.
- Aggregate across the single trial: 0.03159225 USD, 635186 bucket tokens.
- Phase `report.json` data confirms `budget_failures: 0`, `unknown_costs: 0`,
  `malformed_lines: 0`.

## Thinking evidence

- 28 thinking blocks recorded in the worker report; reasoning tokens 6077
  provider-reported (available, not omitted).
- Grounded in `thinking.md`/session thinking: the worker discovered
  `Str.parse_uint` via `xsht api search:parse_uint` (status `exact`, contract
  "Parses text as a non-negative decimal integer", signs/radix rejected), then
  `method:Str.parse_uint` (status `exact`, signature `Str.parse_uint() ->
  Result[Int, Error]`), reasoned about `abort(1)` for the non-positive width
  path, chose `group-by` for keyed binning plus `sort-by` + record-accumulator
  `fold` for the cumulative column, and explicitly rejected using the opaque
  `"".parse_int()?` workaround in favor of the candidate's `parse_uint` surface.
- Reasoning tokens are provider-reported for this worker, so the qualitative
  thinking count is supported by a numeric reasoning-token figure.

## Tool-error findings

`None.` The structured `tool_errors` arrays are empty for the current worker
session (`tool_errors: 0`), the phase `report.json` (`tool_errors: []`), and
the manager session. Every `xsht api` probe (including the two bare-module
queries `method:Str.` and `module:`, which returned the documented "invalid API
query … expected NAME.MEMBER"/"selector value is empty" messages, and the
`missing` results for `read_lines`/`span`/`is_blank`/`blank`) returned within
the `bash` tool result as non-error output, so none incremented the tool-error
count. These are design-expected discovery behaviors already described in the
handbook, not tool failures.

## Timing evidence

Candidate vs oracle wall time per case (candidate_wall_ns / oracle_wall_ns):

- public 12980072 / 13342616; hidden_width 11645190 / 11712690;
  hidden_many 11638648 / 10877561; hidden_sparse 11424439 / 13289615;
  hidden_single 12539403 / 13002072; hidden_ties 12928155 / 11828941;
  hidden_empty 11739107 / 13234240; hidden_bad_width 13008280 / 11720232;
  hidden_bad_value 11255021 / 11701565.

All candidate and oracle times are ~11–13 ms (milliseconds). This eval has no
strict candidate/oracle timing ratio gate (`timings.passed: true`; both sides
finish in milliseconds), so timing is diagnostic only. No latency concern.

Note on `hidden_bad_value`: candidate exit 3 (runtime `result.propagate` from
`parse-uint`) vs oracle exit 2, both nonzero with empty stdout; the eval
contract requires "exit nonzero and print nothing," and correctness is
recorded `all_exact: true`, so this is not a defect.

## Observation classification

- **Candidate acceptance (pass)** — the executor evidence supports the proposed
  `Str.parse_uint()` fix: parse_uint is discoverable via `xsht api` (status
  exact), and the submitted `histogram.xsh` uses `parse_uint()?` directly for
  both the width and each value, expressing sign rejection and the
  non-positive-width path (via `abort(1)`) without the prior
  `"".parse_int()?` workaround. All nine cases pass byte-exact; restrictions
  pass; review.md preserved both headings. This directly exercises the
  ticket's acceptance criteria 1 and 2.
- **Reusable handbook guidance** — naming a local binding `path` produced a
  hard `err[check.standard-module-shadow]` check error (session + review.md
  both capture it); the agent lost a turn naming-guessing. This is
  generalizable learnability friction: bindings must not collide with standard
  module names (`path`, `env`, `fs`, …). Recorded as a provisional handbook
  candidate.
- **Ordinary noise (discovery)** — `xsht api` probes that returned `missing`
  (`read_lines`, `span`, `is_blank`, `blank`) and the two bare-module query
  rejections are normal reference discovery; the worker moved on quickly with
  no repeated re-probing, so they are not product or harness defects.
- **Recording note** — the phase `report.json` records `xsh_commit`
  `5e6f7b0…` while the candidate commit supplied by the controller is
  `2d255aa…`. The functional evidence (parse_uint present and exercised, all
  nine cases exact) confirms the candidate surface ran; the recorded commit
  field appears to track the mainline baseline rather than the candidate
  worktree HEAD. Flagged as a metadata-recording note, not a blocker.
- **No evaluator/harness failure** — `image_id`, `platform`, protocol
  `artifact_present`/`review_ok`, and `restrictions.passed` are all consistent;
  correctness and timing passed.

## Handbook decision

Provisional candidate staged at
`lineage/handbook-candidate.md`. It is the approved snapshot plus one concise,
general sentence in the `Source and entry points` section: do not name a local
binding or parameter after a standard module (`path`, `env`, `fs`, …) because
`xsht check` rejects it with a hard `err[check.standard-module-shadow]` error;
use a distinct name such as `file_path` or `root_dir`. This is a reusable
learnability lesson (not a task recipe) that removes a repeated agent
friction. Promotion is not claimed; it requires later replay and CTO approval.

## Tickets created

None. This is a candidate-linked pre-merge replay; the observation is captured
as provisional handbook guidance rather than a new product ticket, and no
factory-target ticket is warranted.

## Post-merge decisions

None. The reconciler found no merged tickets for this cycle (`none`), so there
are no post-merge acceptance assignments to record.

## Next replay

A directed replay of `task-histogram` (eval `task-histogram`, this manager run
`02-reeval-task-histogram-005`, handbook lineage `lineage/handbook-candidate.md`)
over the same candidate XSH commit, plus at least one additional
numeric-parse eval, to (a) confirm the standard-module-shadow warning removes
the naming friction and (b) satisfy the ticket's cross-eval no-regression
acceptance criterion 3, which this single-eval trial does not itself cover.

## North-star impact

This replay validates an additive ergonomic fix (`Str.parse_uint()`): a strict
non-negative integer contract — a recurring systems-glue boundary for ports,
sizes, counts, and durations — now has one typed, discoverable spelling that
rejects signs directly instead of the regex-plus-opaque-empty-string idiom.
The staged handbook sentence on avoiding standard-module name shadowing
improves learnability and removes a hard check error that cost the agent a
turn. Both findings advance the north-star goals of practical, ergonomic,
trustworthy XSH; the cross-eval replay remains the next validation step.
