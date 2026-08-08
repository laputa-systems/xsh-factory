# Eval-manager report

## Result

fail — the eval executed cleanly (all nine cases byte-exact, restrictions and
protocol pass, no infra/harness issue), but this run was a pre-merge
validation of candidate ticket `task-histogram-004` (the `check.try-context`
relaxation so `?` works in a value-returning `[error]` helper). The worker's
`histogram.xsh` inlined all fallible `?` validation into `main` and into
stream-stage blocks — the exact workaround the ticket predicts should
disappear — and never defined a value-returning `[error] -> Int` helper. The
9/9 pass therefore serves only as a no-regression control; it does not
validate acceptance criteria 1 or 2. The candidate fix is not supported by
this trial and requires a focused helper check before admission.

## Effort metrics

Single configured fresh trial (`task-histogram-1`).

- assistant turns: 49
- tool calls: 55 (bash 43, edit 5, read 4, write 3)
- tool results: 55
- tool errors: 1 (an `edit` mismatch at turn 34, self-recovered)
- user messages: 1; stop reasons: 1 `stop` + 48 `toolUse`
- session span: `session_span_ms` 379353 (~379 s); `agent_wall_ms` 380501
- worker friction: the single edit error plus three low-signal notes in
  `review.md` (see Observation classification). No provider retries.

This is a one-trial plan; no trial-2 comparison was run by the controller.

## Usage and cost

One trial (`task-histogram-1`). Provider: `openrouter/deepseek/deepseek-v4-flash-0731`.

- input tokens: 34,217
- output tokens: 14,647
- cache-read tokens: 913,920; cache-write tokens: 0
- provider-reported total: 962,784; bucket total (in+out+cacheR+cacheW): 962,784 (match)
- reasoning tokens: 8,476 (provider-reported; a subset of output, not added)
- thinking blocks: 36
- cost: total 0.02216655 USD (input 0.00307953, output 0.00263646,
  cache-read 0.01645056, cache-write 0); budget 0.5 USD; budget pass.
- Aggregate = single trial: 0.02216655 USD.

## Thinking evidence

The provider reported reasoning-token counts (8,476 reasoning tokens, subset of
the 14,647 output tokens) and the worker session recorded 36 thinking blocks.
Thinking is qualitative supporting evidence here: the 36 blocks correlate with
a 49-turn iterative development loop (bash `xsht check`/`fmt`/`lint`/`xsh`
iterations, 43 bash + 5 edit + 4 read + 3 write calls) that converged on a
correct 9/9 solution. No anomaly: reasoning confirms deliberate inlining of
validation rather than a factored helper.

## Tool-error findings

One nonzero Pi tool result in the current structured packet:

- `edit` at turn 34 in `workers/eval-worker/task-histogram-1/report.json`:
  "Could not find the exact text in /work/histogram.xsh. The old text must
  match exactly including all whitespace and newlines." The worker re-read and
  re-edited successfully (final artifact present, `pass`). Single, self-recovered;
  ordinary agent-side editing noise.

No invalid `xsht api` discovery queries appear in the structured tool-error
arrays; the `review.md` notes on `//` division parsing and `fp`
interpolation were observations, not failed API calls in this run.

## Timing evidence

Candidate vs oracle wall time per case (ns), from `run.json`; the EVAL declares
no strict candidate/oracle timing gate (both sides finish in milliseconds), so
this is diagnostic only.

- public: candidate 12,746,579 vs oracle 13,684,457
- hidden_width: 14,114,666 vs 11,184,991
- hidden_many: 12,578,078 vs 15,002,044
- hidden_sparse: 11,578,701 vs 15,935,172
- hidden_single: 11,857,034 vs 11,882,201
- hidden_ties: 12,967,579 vs 11,630,200
- hidden_empty: 14,150,958 vs 14,381,833
- hidden_bad_width: 10,937,823 vs 12,301,453 (both exit nonzero)
- hidden_bad_value: 14,197,666 vs 12,383,619 (both exit nonzero)

All candidate ~11–14 ms, all oracle ~11–16 ms; no ratio gate, no timing
concern.

## Observation classification

- **Candidate not exercised (correctness-relevant).** The artifact inlines all
  `parse_int()?` and width validation into `main` (Unit) and into stream-stage
  blocks — contexts the old rule already allowed. No value-returning
  `[error] -> Int` helper exists, so acceptance criteria 1 and 2 (helper passes
  `xsht check`; natural helper factored out of `main`) are not demonstrated.
  The 9/9 byte-exact trial is a no-regression control for `task-histogram`
  only, not evidence for the fix. This is the decisive classification.
- **Eval healthy / no harness mismatch (signal).** All nine cases byte-exact,
  including both failure controls (`hidden_bad_width` exits 1, `hidden_bad_value`
  exits nonzero) and restrictions `pass` (typed `read_text`, `parse_int`,
  `sort-by` present; no subprocess boundary).
- **Worker friction / noise.** The single `edit` tool error at turn 34 is
  self-recovered editing noise, not a product defect.
- **Low-signal review notes (not tickets).** `review.md` records (a) `//`
  producing a confusing `expected statement terminator` parse diagnostic,
  (b) `fp"...${Result-expr}"` failing `display-conversion`, and (c) a `xsht
  lint` redundant-command-interpolation warning. These are single-session agent
  notes; none is a manager-verified strong, reproducible product defect, so no
  new ticket is opened.
- **Latency attribution.** Provider telemetry present: `retry_count 0`,
  `provider_errors []`, `retry_errors []` — clean. The ~379 s span is explained
  by 49 agent turns (iterate check/fmt/lint/run), not external latency.

## Handbook decision

Unchanged. The approved snapshot already teaches the typed-conversion + `?`
propagation, Map/sort/fold composition, and byte-exact-output guidance that
carried the worker to a 9/9 pass; no new reusable lesson emerged that the
approved text lacks. `lineage/handbook-candidate.md` is unchanged (identical
copy of the approved snapshot). The ticket's `check.try-context` question is a
product/checker change, not a handbook candidate — reserving it for the product
ticket, not a handbook edit. No new global candidate to replay.

## Tickets created

None.

No new reproducible, generalizable defect was established this run; the one
non-zero tool result is self-recovered editing noise, and the review friction
notes are not manager-verified as strong product defects. The pre-existing
candidate `tickets/task-histogram-004.md` (Open/Approved, not merged) already
captures the `?`-in-`[error]`-helper issue and is the vehicle for the fix; it
is not recreated.

## Post-merge decisions

None for reconciled merged tickets — the controller-reported reconciler found
no merged tickets (`none`) for this cycle.

Candidate (pre-merge) decision for `task-histogram-004`, candidate XSH commit
`d04e19f524cce28af9ccb2c37cc322b4da1ca7c3`: **needs-replay / not supported by
this trial.** Per the assignment this is a pre-merge validation of the clean
engineer worktree; do not mark merged and do not dispatch engineer. The worker
inlined all fallible validation into `main`/stream blocks and never wrote a
value-returning `[error] -> Int` helper, so acceptance criteria 1 and 2 were
not exercised. The 9/9 byte-exact pass confirms no `task-histogram` regression
but does not confirm the helper is accepted by `xsht check`. A focused helper
check and a helper-factored replay are required before the fix is trusted.
Commit attribution note: the phase `report.json` records `xsh_commit
f697fa2453f676f686c685171f5a8a9d514f871e` while the assignment names candidate
`d04e19f…`; the packet does not unambiguously establish that the trial executed
the candidate worktree. No revert is proposed (nothing was merged).

## Next replay

Focused helper check (the ticket's falsification), on the candidate/merged
commit once identity is confirmed:

1. `proc parse_uint(s: Str, min: Int) [error] -> Int { ...; let _ = s.parse_int()?; ... }`
   passes `xsht check` and exits nonzero on a non-uint argument.
2. Re-run `task-histogram` forcing the natural helper factored out of `main`
   and confirm 9/9 byte-exact.
3. Confirm the trial in fact ran on the candidate commit (resolve the
   `f697fa2…` vs `d04e19f…` attribution) before treating any result as
   validation.
4. One additional helper-heavy eval to confirm the rule generalizes with no
   new `xsht check` failures across the approved suite.

Eval: `task-histogram`; lineage:
`runs/run-1786183310798/phases/02-reeval-task-histogram-004/lineage/handbook-approved.md`.

## North-star impact

The run re-confirms `task-histogram` as a healthy, compositional measurement
probe: an agent guided by the current handbook produced a byte-exact binned
cumulative report across nine cases, including two audible failure controls
and a subprocess-free typed pipeline — direct evidence for XSH's practical
systems-glue and trustworthiness goals. It does not yet advance the specific
ergonomics/correctness target of `task-histogram-004`: the trial shows a
worker comfortably inlining `?` validation into `main` but never exercising a
value-returning `[error]` helper, so the real learnability win (clean, factored
fallible helpers without the inline workaround) remains unproven. The next
focused helper replay is the concrete step that will tell whether relaxing
`check.try-context` truly removes agent friction and generalizes — the honest
north-star outcome of this cycle is a disciplined "not yet validated" rather
than a false pass.
