# Eval-manager report

## Result

pass

## Effort metrics

Single trial (`task-bigfiles-1`). 20 assistant turns, 27 tool calls (21
`bash`, 4 `read`, 1 `edit`, 1 `write`), 27 tool results, 0 tool errors,
session wall span 52,109 ms. Worker friction: none — the agent discovered the
strict-decimal surface directly from the live API reference and produced a
clean single call. Provider telemetry present: retry_count 0, provider_errors
[], retry_failures 0; no external-health evidence, so no latency attribution is
needed beyond a short 52s session.

## Usage and cost

Provider-reported per trial: input 14,691; output 4,339; cacheRead 209,408;
cacheWrite 0; provider `totalTokens` 228,438, matching the bucket total
228,438 (input+output+cacheRead+cacheWrite). `reasoning` 2,235 (subset of
output; not added to totals). Cost total $0.005872554 against a $0.50 budget;
cache_read $0.003769344, input $0.00132219, output $0.00078102. malformed_lines
0, unknown_costs 0. Aggregate across the single trial is the same.
No `auto_retry_*` events, no provider errors.

## Thinking evidence

13 thinking blocks in `session.jsonl.bz2`; the provider reported `reasoning`
tokens = 2,235. Thinking text shows the worker enumerating the parse surface
via `xsht api search:parse_int`, reading the `method:Str.parse_int_decimal`
contract ("Only nonempty decimal digits without leading zeros (except `0`)
are accepted"), and selecting the strict-decimal call for the byte-exact `N`
gate. Correlates with zero tool errors and a passing artifact.

## Tool-error findings

None. The structured phase `report.json` and worker `report.json` `tool_errors`
arrays are both empty across the current evidence packet.

## Timing evidence

No strict candidate/oracle timing gate for this eval (documented in EVAL.md);
all timings are diagnostic and both sides complete in milliseconds. Per-case
candidate/oracle wall (ns): public 12,846,195/13,194,855; hidden_default
12,121,002/11,223,020; hidden_n2 13,094,731/12,574,992; hidden_single
13,128,023/13,179,397; hidden_deep 13,280,519/13,406,101; hidden_spaces
13,197,521/13,583,555; hidden_utf8 12,578,283/13,459,641; hidden_empty
13,354,184/13,307,019; hidden_bad_n 13,089,940/13,090,815. Failure control:
candidate exit 3, oracle exit 1 — both nonzero and both print nothing. No
ratio gate is violated.

## Observation classification

- Product signal (positive): the proposed `parse_int_decimal()` surface is
  present in the build under test and directly exercised — no digit-check plus
  force-invalid-string workaround remains. This is the general ergonomics fix
  ticket `task-bigfiles-005` proposed.
- Correctness: all nine cases byte-exact; `hidden_bad_n` exits nonzero and
  prints nothing.
- Restriction: source uses `fs.files(root, hidden: true)?`, a `sort-by --desc`
  stage, no subprocess; `review.md` preserves both headings with no template
  placeholders. `restrictions.passed: true`.
- Worker friction: none. No reusable handbook gap surfaced this cycle.

## Handbook decision

Unchanged. The worker discovered the new strict-decimal surface through the
live API reference with zero friction; the approved snapshot was adequate and
no new handbook lesson is warranted from this trial. The strict-decimal
surface itself is a product change owned by ticket `task-bigfiles-005` and is
under pre-merge validation here, not a handbook claim to promote. The approved
snapshot was copied unchanged to `lineage/handbook-candidate.md`.

## Tickets created

None. This run validated the candidate fix cleanly (1 trial, 0 tool errors,
0 friction) and produced no new strong reproducible observation.

## Post-merge decisions

None to record. The reconciler found no merged tickets for this cycle; the
open ticket `task-bigfiles-005` is a pre-merge candidate replay, not a
merged-ticket acceptance assignment.

Candidate acceptance: pass. The worker exercised ticket `task-bigfiles-005`'s
acceptance criteria directly: it selected `parse_int_decimal` from the API
reference, expressed the `N` validation with a single typed strict-decimal call
(`argv.get(1)?.parse_int_decimal()?`, no separate digit-check plus
force-invalid-string hack), and all nine cases remained byte-exact with
`hidden_bad_n` exiting nonzero and printing nothing.

## Next replay

Post-merge acceptance for `task-bigfiles-005`: after the CTO merges the
implementation branch (recorded implementation commit) into main, replay the
linked `task-bigfiles` eval at the merged XSH commit on the shared handbook
lineage to reconfirm the worker still selects the strict-decimal surface and
keeps all nine cases byte-exact. Also confirm the engineer's native tests
reject `0x10`, `+5`, ` 5 `, and `05` as required by the ticket. Post-merge
and falsification check: `hidden_bad_n` must remain exit-nonzero/print-nothing.

## North-star impact

This replay demonstrates that the proposed strict-decimal parse surface is a
real, discoverable, ergonomic improvement: the agent replaced an opaque
digit-check-plus-sentinel-string incantation with one typed, Result-returning
call that rejects hex/sign/whitespace/leading-zeros and lets `?` propagate a
nonzero exit. That aligns with XSH's explicit-boundary, trustworthy-errors
ethos and generalizes to any byte-exact decimal contract (counts, ports,
sizes, indices). Promotion of the fix and the linked replay will move this
capability forward for all evals and users.
