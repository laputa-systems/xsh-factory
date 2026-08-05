# Eval-manager report

## Result

pass

## Effort metrics

One trial (`task-colsum-1`), executor result `pass`.

- Assistant turns: 43 (1 user message, 42 toolUse stop, 1 stop).
- Tool calls: 50 (bash 41, write 5, read 4).
- Tool errors: 3, all warnings; each resolved within the next turn.
- Session span: `session_span_ms` 146640 (~2.4 min); `agent_wall_ms` 148213.
- Worker friction: low. The agent did not re-explore prior evals or loop on the
  same error; every tool error was corrected in one iteration (see Tool-error
  findings). Restriction compliance, artifact presence, and review presence all
  `pass`.

## Usage and cost

Provider: `openrouter/deepseek/deepseek-v4-flash-0731` (single worker).

- Input tokens: 25283; output tokens: 11538; cache read: 554816; cache write: 0.
- Bucket total: 591637; provider total: 591637 (match).
- Reasoning tokens: 5723 (subset of output); thinking blocks: 29.
- Cost: `cost_usd` 0.014338998 against a 0.5 budget (~0.5% of budget).
  Breakdown: input $0.00227547, output $0.00207684, cacheRead $0.009986688,
  cacheWrite $0. Total across the single trial $0.014338998.
- No `unknown_costs`; no budget breach.

## Thinking evidence

29 thinking blocks; the provider reported reasoning tokens (5723). The
thinking transcript (`session.jsonl.bz2.bz2`) shows the agent forming a plan, verifying
`lines()` trailing-newline semantics, confirming `for`/`continue` support,
testing negative-summation and both failure controls on stdout/stderr, then
writing the final artifact and cleaning up exploration files. Thinking
correlates with correct artifact construction: the candidate passed all nine
cases on first submission after the in-session fixture tests.

## Tool-error findings

All three nonzero Pi tool results come from the single executor worker session
(`task-colsum-1`), all in exploration bash calls and all resolved next-turn:

1. Turn 26 — `bash`: `err[parse.expected-expression]: $name is command-word
   syntax; in expression context, use name directly` (`let s = "n=" + $n`).
   Worker immediately corrected to expression-position spelling.
2. Turn 27 — `bash`: `err[check.unknown-method]: unknown method to_string on
   Int`. Worker immediately switched to a display string `f"n=${n}"`.
3. Turn 33 — `bash`: `sh: syntax error: unexpected "("` caused by a parenthesized
   echo label in the worker's own shell command. Worker recognized the shell
   quoting mistake and reran cleanly.

None arose from the final submitted `colsum.xsh`; all were development-loop
frictions. No invalid `xsht api` discovery queries occurred this session (the
one `search:for` and `language:core.iter` probe returned normally, not as an
error).

## Timing evidence

No strict candidate/oracle ratio gate for this eval. Both sides run in
milliseconds; timing is diagnostic only.

| case | candidate ns | oracle ns |
|---|---|---|
| public | 11,636,902 | 12,127,572 |
| hidden_order | 11,221,233 | 11,449,152 |
| hidden_negative | 11,316,026 | 13,703,373 |
| hidden_many | 11,130,066 | 12,887,535 |
| hidden_single | 13,484,830 | 13,211,161 |
| hidden_no_data | 13,021,744 | 13,173,995 |
| hidden_extra_cols | 13,338,495 | 13,814,374 |
| hidden_missing_header | 11,183,566 (exit 3) | 12,737,700 (exit 1) |
| hidden_bad_value | 12,488,033 (exit 3) | 12,886,827 (exit 2) |

Candidate and oracle are on-par (both ~11–14 ms); no agent-efficiency concern
derives from program timing.

## Observation classification

- **Correctness / protocol / restrictions:** `pass` on all nine cases,
  including both failure controls (nonzero exit, empty stdout), artifact and
  review present, no subprocess boundary. Reusable-signal source: the eval
  contracts are met without task-specific hacks (typed `read_text`,
  `parse_int`, no hard-coded total).
- **Worker friction (minor, resolved):** the three tool errors above. Turn 26/27
  are a single recurring theme (Int-to-text embedding); turn 33 is an
  ordinary shell quoting miss. Classification: agent friction, not product
  defect.
- **Product/tooling defect (one strong reproducible):** no explicit
  fail/error-raise form for a deliberate validation failure; the worker abused
  `"sentinel".parse_int()?` to exit nonzero on header-not-found. This is
  general and reproducible, flagged as a language proposal by the worker's own
  `review.md`. Opens ticket `task-colsum-001`.
- **Provider health:** `provider_telemetry.present = true`, `retry_count = 0`,
  `provider_errors = []`, `output_tokens_per_second = 0`; no retry events found
  in the events file. No external-health signal; the 2.4 min session is
  consistent with 43 turns of normal reasoning, so no latency attribution to
  agent inefficiency is warranted.
- **Noise:** none affecting the result.

## Handbook decision

Provisional candidate staged at
`runs/run-1785893827191/phases/01-eval/lineage/handbook-candidate.md`
(one-trial plan). The approved snapshot was copied and one concise rule added to
the `Text and output` section:

> Int has no `to_string()` and `$var` is command-word syntax (invalid inside an
> expression). To embed an Int in composed text, use a display string in
> expression position and then print the value: `let line = f"n=${n}"` then
> `print $line`.

General lesson: exact-output tasks repeatedly need to embed a number in text;
naming the absence of `Int.to_string()` and pointing at the f-string removes
the two most common Int-to-text errors. Replay scope: `runtime/handbook.md`
promotion requires the controller to replay `task-colsum` (and ideally one
other exact-output eval such as `task-tags` or `task-intsum`) against this
candidate; it is not yet trusted.

## Tickets created

- `/Users/josh/d/laputa-systems/xsh-factory/tickets/task-colsum-001.md` — Open:
  add an explicit fail/error-raise form for deliberate validation failure
  (replaces the `parse_int` sentinel abuse seen in this session). Linked to
  this eval, executor run, manager run, handbook lineage, and XSH commit
  `e5d29c7ec8b4411dc749fd3e44bf472d641ad9f4`.

## Post-merge decisions

The reconciler found no merged ticket for this eval (`none`); no post-merge
acceptance assignment. The open-ticket snapshot (`task-envcfg-001`,
`task-tags-003`) is unrelated to `task-colsum` and not reconciled here.

## Next replay

Replay `task-colsum` (single trial, same executor harness) against the
provisional handbook candidate and XSH commit `e5d29c7ec8b4411dc749fd3e44bf472d641ad9f4`
to confirm the Int-to-text rule does not regress correctness; additionally
replay one other exact-output eval to test the candidate's generality before
promoting it to `runtime/handbook.md`. Post-merge, replay `task-colsum` to
falsify ticket `task-colsum-001` (error-raise form).

## North-star impact

This run demonstrates a clean, compositional XSH solution to a real
structured-data reduction (named-column sum) with typed reading and parsing, no
subprocess escape, and a byte-exact integer contract — directly advancing the
"practical systems glue" and "explicit boundary" goals. It produced one durable
handbook candidate (Int-to-text embedding) and one general ergonomics ticket
(explicit validation-failure form), both aimed at reducing the sort of
workaround friction the session surfaced. Correctness held on all nine cases,
so the agent efficiency is high and the signal is general.
