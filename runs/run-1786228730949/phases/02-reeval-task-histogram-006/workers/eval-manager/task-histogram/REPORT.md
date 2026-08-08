# Eval-manager report

## Result

pass

The single trial passed: all nine cases byte-exact (public, hidden_width,
hidden_padded_width, hidden_many, hidden_sparse, hidden_single, hidden_ties,
hidden_empty, hidden_bad_width, hidden_bad_value) with restrictions and
protocol pass in `workers/eval-worker/task-histogram-1/run.json`. The phase
was staged `fail` only because the manager report was absent; this report now
supplies that required output. Trial decision and the separate candidate
acceptance token are under `## Post-merge decisions`.

## Effort metrics

Trial 1 (only trial): 32 assistant turns, 40 tool calls (33 `bash`, 4 `read`,
2 `write`, 1 `edit`), 40 tool results, 1 tool error, session span 171146 ms
(≈171 s), agent wall 172467 ms. No provider retries (`provider_telemetry`
present, `retry_count` 0, `provider_errors` empty). The session was focused:
the worker solved the composition task in a single continuous loop and the
only failed tool call was one malformed `xsht api` query. No notable repeated
exploration or rediscovery beyond normal API checks.

## Usage and cost

Trial 1 (aggregate equals the single trial): input tokens 62282, output 17845,
cacheRead 985088, cacheWrite 0, bucket total 1065215, provider total 1065215,
provider cost $0.026549 against a $0.50 budget. Reasoning tokens 10299
(provider-reported, a subset of output). No unknown-cost fields. One trial, so
aggregate dollars = $0.026549.

## Thinking evidence

27 thinking blocks; provider reported 10299 reasoning tokens. Thinking grounded
in the session: the worker explicitly reasoned about strict width validation
after discovering `parse_int` accepts hex (`0x10`), underscore separators
(`1_000`), and signs (`+5`, `-0`), about integer division being `/` and not
`//`, about `abort` returning `Unit` (cannot be a typed block tail), and about
guarding division-by-zero before binnning. These reasoning steps are
qualitative evidence and correlate with the correct 9/9 result.

## Tool-error findings

One failed Pi tool result in the worker `report.json` (`tool_errors`, turn 13):
`xsht api` rejected both the bare `language.core.abort` form and the
`api:language.core.abort` form (`expected KIND:VALUE` / `expected NAME.MEMBER`)
and exited 2; only `language:core.abort` succeeded. This is a single
agent-side API-query spelling slip, recovered immediately; not a product
defect. The manager session had no tool errors. Otherwise: `None.`

## Timing evidence

No strict candidate/oracle timing gate for this eval. Each of the ten cases ran
in ≈11–13 ms on both sides (candidate and oracle) with no meaningful gap;
`hidden_bad_width` (candidate 1 / oracle 1) and `hidden_bad_value` (candidate 1
/ oracle 2) both exit nonzero. The ~171 s worker span is agent-interaction
time, not process timing, and with no provider-latency signal it is classified
normal agent speed.

## Observation classification

- Coverage/harness gap (candidate-directed): this eval and its evaluator expose
  no case that exercises the candidate ticket's defining acceptance criterion
  (a `filter`-pipeline producing a readable stage-level error naming `filter`
  and `where`). The worker session confirms the solution used `where`, not
  `filter`; the evaluator restrictions and `run.json` cases probe none of the
  candidate surface. Criteria 2 and 3 (the `where` form passes check/lint; the
  histogram remains 9/9) were exercised. Criterion 1 was not.
- Infrastructure/factory finding (CTO-owned): the phase `report.json`
  `xsh_commit` (`b2ed25f69ea49eb22c5e06318a10d26f7736c481`) differs from the
  candidate commit supplied in the assignment
  (`fc432eadf48fdbf607c52fe487770d630dad5838`); I could not extract the
  deployed image commit from `events.jsonl` line 7 (single 224 KB JSON record,
  unreadable with the `read` tool). Reported to CTO; not a manager ticket.
- Reusable handbook lesson (signal): `Str.parse_int` is not a decimal-only
  parser; strict decimal/positive contracts need explicit digit validation
  (e.g. `Str.delete("0123456789")`). Generalizes to any eval that validates an
  integer measurement or width.
- Agent API-discovery friction (ordinary noise): one malformed `xsht api`
  query; recovered in one step.
- Division-by-zero raw trap (ordinary/expected): zero width produced exit 133
  trap during exploration; the worker guarded it before submission. Not
  confirmed as a defect; not ticketed.

## Handbook decision

Provisional candidate staged at `lineage/handbook-candidate.md`. General
lesson: `parse_int` accepts surrounding whitespace, hex, underscores, and
explicit signs, so a byte-exact decimal/positive integer contract must be
validated explicitly (digit check) rather than trusting `parse_int` alone.
Replay scope before promotion: a strict-decimal eval (e.g. re-running this task
or any eval that rejects non-decimal widths/measurements) must still be 9/9,
and the proposed replay must confirm the narrowed parse advice does not break
other integer-parsing tasks. Provisional only.

## Tickets created

None. No new ticket this cycle. The in-flight candidate remains tracked by
`tickets/task-histogram-006.md`.

## Post-merge decisions

Reconciled merged tickets: none (reconciler reported `none`).

Candidate re-evaluation for `task-histogram-006` (pre-merge validation of the
engineer worktree; candidate XSH commit
`fc432eadf48fdbf607c52fe487770d630dad5838`): the linked replay exercised
acceptance criteria 2 and 3 — the `where`-based solution passes `xsht check`
and `xsht lint`, and the histogram eval is 9/9 byte-exact with `restrictions:
pass` and `protocol: pass`, so the fix does not regress the composition eval.
However, the worker did not exercise the ticket's defining criterion 1: no eval
case probes a `filter` pipeline, the worker solved the task with `where` and
never produced a `filter` parse, and no engineer-reported native test for the
`filter` diagnostic is present in this packet. Because the replay did not
exercise the proposed surface, the branch must be retained for a directed
replay that actually compiles a `filter`-based pipeline.

Candidate acceptance: fail.

## Next replay

Directed replay under this lineage (and, if the handbook candidate survives, a
second strict-decimal eval): compile a `filter { |x| ... }` pipeline at the
candidate commit and assert a readable stage-level error naming `filter` and
recommending `where` (with no `expected record field`/`expected } after record`
cascade), then re-run `task-histogram` 9/9. The natural falsifier is any
stream-filter eval; `task-histogram` alone cannot certify the diagnostic.

## North-star impact

This run advances ergonomics and trust. The session independently re-observed a
reusable parse-int decimal-contract gap now staged as a provisional handbook
lesson, and it gates the parser-diagnostic candidate behind an actual probe of
its defining behavior rather than a composition no-regression alone.
Trustworthy promotion of the `filter` diagnostic requires the diagnostic itself
to be exercised; a 9/9 histogram pass only proves no regression, which is why
the candidate cannot be accepted on this evidence.