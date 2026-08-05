# Eval-manager report

## Result

pass

## Effort metrics

Single trial (`task-histogram-1`), 1 configured fresh trial; no trial 2.
Worker: 48 assistant turns (47 toolUse, 1 stop), 58 tool calls
(51 bash, 1 edit, 4 read, 2 write), 1 tool error, 1 user message. Session span
189,993 ms (~190 s); agent wall 191,661 ms. No repeated exploration beyond one
division-operator probe; recovery was immediate. Manager session: 0 tool
errors. One worker; no other workers requested.

## Usage and cost

Worker `task-histogram-1` (provider `openrouter/deepseek/deepseek-v4-flash-0731`):
- input 40,601; output 19,327; cacheRead 969,792; cacheWrite 0; bucket total
  1,029,720; provider-total 1,029,720 (buckets match).
- cost: input $0.003654; output $0.003478; cacheRead $0.017456; cacheWrite $0;
  total $0.024589. budget $0.50; no budget failure; 0 unknown cost.
- Aggregate = single worker = $0.024589, 1,029,720 tokens.
- Cost is heavily cache-read dominated (969.8k read, ~94% of tokens), i.e. the
  long shared handbook + onboarding context was served from prompt cache.

## Thinking evidence

34 thinking blocks; provider reported 12,381 `reasoning` tokens (subset of
output). Bounded evidence scan of the transcript (turns 26-45) shows the agent
deliberately probing division (`op:/`, `op:div`), assertion availability
(`search:assert`, `record.require` -> missing), and error/`?` semantics before
writing the artifact. One probe (`let x = 17 div 5`) failed and the agent
correctly switched to `/`; the workbook then produced a valid `sort-by` +
`fold` cumulative pipeline. Thinking is present and correlated with correct
artifact construction.

## Tool-error findings

One structured worker tool error (phase `report.json` and worker
`report.json`, `tool_errors`), turn 31, tool `bash`:
`let x = 17 div 5` -> `err[parse.expected-terminator]` (exit 2). `div` is not
an XSH operator; a prior `op:/` probe returned `3`, and the agent immediately
used `/`. This is a single discovery miss, not a repeat loop. Manager sessions
have zero errors. (Qualitative, non-structured discovery friction was also
visible in the transcript and not counted as failures: an `xsht api` probe of
`div` and two malformed API queries `language.effect.error` /
`language.core.postfix-question` returning "expected KIND:VALUE" around turn
41-43; these are already covered by the handbook's exact KIND:VALUE rule and
were not recorded in the structured `tool_errors` arrays.) Otherwise `None.`

## Timing evidence

Candidate/oracle per-case (ns), all 9 cases:
public 11.37/12.13, hidden_width 12.17/12.59, hidden_many 13.07/12.65,
hidden_sparse 11.61/13.08, hidden_single 11.14/12.08, hidden_ties 11.42/11.06,
hidden_empty 12.10/11.92, hidden_bad_width 11.84/11.48 (exit 3 vs 1, both
nonzero), hidden_bad_value 12.60/12.45 (exit 3 vs 2, both nonzero). Candidate
and oracle both finish at low millisecond scale; no strict ratio gate exists in
this eval (`timing: pass`). Diagnostics only. worker session (~190 s) is
unrelated to the ~12 ms program runs — separate clocks as expected.

## Observation classification

- correctness/restriction/protocol (pass): all 9 cases byte-exact; both
  failure controls exit nonzero and print nothing; `fs.read_text`,
  `parse_int`, and `sort-by` referenced; no subprocess boundary; `review.md`
  has both headings, no placeholders. Strong signal.
- timing (no gate): both sides ms-scale; diagnostic only.
- worker friction (minor): one division-operator probe (`div` invalid ->
  `/`); single-turn recovery, not repeated exploration. Ordinary noise-level
  friction; not a handbook candidate on its own.
- product/tooling defect (one strong observation): no first-class way to fail
  on a parsed-but-domain-invalid condition; worker resorted to sentinel
  `"".parse_int()?` at both validation sites. Generalizes to numeric/range
  validation beyond this eval. Opened ticket `task-histogram-001`.
- handbook guidance: the approved handbook already documents the
  validation-failure workaround ("no generic Error(...) constructor; propagate
  from a typed conversion"); the agent applied it. No new reusable handbook
  rule is strongly indicated by this pass.
- telemetry: `provider_telemetry` present; 0 retries, 0 provider errors,
  output_tokens_per_second 0 (client-derived unavailable). No provider-latency
  signal; nothing to attribute to external health.

## Handbook decision

Unchanged. Copied `lineage/handbook-approved.md` -> `lineage/handbook-candidate.md`
byte-identical (sha256 `3b56a781...`). The only strong reusable lesson is the
missing-assertion product gap, which belongs in a ticket, not a handbook rule;
the division-operator probe was single-turn noise. No provisional candidate
is staged; any future `require` lesson becomes handbook content only after the
ticket is implemented and replayed across evals.

## Tickets created

- `/Users/josh/d/laputa-systems/xsh-factory/tickets/task-histogram-001.md`
  (Open) - first-class `require(cond, msg)` / expected-failure predicate for
  negative validation not expressible by a typed conversion. Links eval
  `task-histogram`, session `task-histogram-1`, executor `run.json`, lineage
  `handbook-approved.md`, and XSH commit `5f462670...`. For next cycle.

## Post-merge decisions

None. The reconciler found no merged tickets (`none`) and open-ticket snapshot
contains no `task-histogram` ticket to accept. Candidate re-evaluation is
`not-reevaluation`; no pre-merge worktree validation.

## Next replay

Replay `task-histogram` on the same `handbook-approved.md` lineage against a
future XSH commit after `task-histogram-001` lands, to confirm the two
validation branches can be expressed with `require(...)` while staying
byte-exact on all nine cases (including both failure controls). No falsification
replay needed for the unchanged handbook this cycle.

## North-star impact

This eval demonstrates a composable, typed systems-glue pipeline (bin via
integer division -> keyed Map count -> sort-by -> cumulative fold) built from
the handbook stream/Result idioms with a single minor discovery misstep and
byte-exact output across width, sparsity, ties, and failure controls. It
advances learnability/ergonomics by validating that the existing handbook
idioms transfer to a real measurement-summary boundary, and it surfaces one
general ergonomics gap (explicit negative validation) opening a focused
product ticket rather than noise.
