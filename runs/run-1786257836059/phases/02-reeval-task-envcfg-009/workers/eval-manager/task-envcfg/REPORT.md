# Eval-manager report — task-envcfg

Phase: `02-reeval-task-envcfg-009`
Run: `run-1786257836059`
XSH baseline commit: `7b4bee1a1cef74fed832331cd6cc5bb6e324c4ee`
Candidate ticket under review: `task-envcfg-009`
Candidate XSH commit (assignment): `04fb98f8c63b63cccffce7ef2c3cabde81bb05ba`
Trials configured/executed: 1 fresh trial via `eval-worker/task-envcfg-1`

## Result

pass

## Effort metrics

Single trial, one eval-worker session (`task-envcfg-1`). Per phase `report.json`
structured packet: assistant turns 23, tool calls 24, tool results 24, tool
errors 4, session wall span not recorded in the structured packet at draft time
(`unknown` in the phase JSON). Worker friction: four tool errors (two invalid
`xsht api` discovery queries, one `?`-requires-`error` effect-violation block,
one local smoke-run failing because `xsh` was not on the worker's `$PATH`
during trial of a quick local check). None of these blocked the submitted
solution; the final evaluator trial passed. Worker-level `report.json` adds
session_span_ms 752813 (≈12.5 min), agent_wall_ms 754054; tools used: 17 bash,
2 edit, 3 read, 2 write (24 total). Provider telemetry present with retry_count
0, provider_errors [] (no external-health evidence).

## Usage and cost

Provider-reported (phase packet): input tokens 88380, output tokens 8164,
cache_read tokens 302144, cache_write tokens 0; bucket total 398688,
provider_total_tokens 398688 (consistent). Reasoning tokens 4151
(provider-reported, subset of output). Cost: input $0.007954, output $0.001470,
cache_read $0.005439, cache_write $0.000000, total $0.014862. Budget $0.50;
budget_failures 0, unknown_costs 0. Per-trial dollar figure: $0.014862 (single
trial; all usage figures are the one trial).

## Thinking evidence

Structured packet records thinking_blocks 17 for the single worker and
reasoning_tokens 4151 (provider-reported). Thinking text lives in the canonical
session JSONL; at first-draft time provenance of the 17 blocks is not yet
cross-read. Reasoning-token count was reported by the provider, so it is
available rather than unavailable.

## Tool-error findings

Phase packet `tool_errors` (4, all worker `task-envcfg-1`, via `bash`):
turn 4 — invalid `api:language.core.path-literals` query (expected NAME.MEMBER)
and two `search:` probes (`search:Path.cast`, `search:Str.to_path`) returning
missing;
turn 6 — `language:core.results` exact hit, then invalid
`api:language.core.abort` query (expected NAME.MEMBER);
turn 9 — `check.effect-violation`: `?` requires the `error` effect on four uses
(`env.get_or`×3 and `fs.write`);
turn 14 — a local smoke run with `xsh` not on the worker `$PATH` (`xsh: No such
file or directory`, exit 127) and no output file written.
All accounted. No error surfaced against the final submitted artifact's
evaluator gate.

## Timing evidence

Phase `report.json` records timing `pass` for the trial. From `run.json`:
candidate wall times 11.2–16.3 ms and oracle wall times 1.7–16.3 ms across all
ten cases (public, hidden_defaults, hidden_partial, hidden_empty,
hidden_spaces, hidden_zero, hidden_utf8, hidden_debug_false, hidden_malformed,
hidden_empty_port); `all_exact: true`. This eval has no strict timing gate (both
sides finish in milliseconds), so timing is diagnostic only; no envelope breach.

## Observation classification

Worker friction (repeated `xsht api` spelling guesses and the `?`-effect
violation) is the strongest signal and is consistent with existing handbook
guidance (`?` requires the `error` effect; `api:` prefix queries must be
`NAME.MEMBER`). The `$PATH`-missing-`xsh` smoke failure is local harness noise,
not a product signal. No product/tooling defect is proven from the structured
packet at draft time.

## Handbook decision

A provisional candidate may be staged only if the evidence supports a reusable
general lesson; at first-draft time the friction observed is already covered by
the approved handbook (`error` effect for `?`; `api:` query spelling). No new
candidate is required yet.

## Tickets created

Zero

## Post-merge decisions

Candidate `task-envcfg-009` is a pre-merge validation (status `Approved.`, not
merged). The reconciler reported no merged ticket files (`none`), so there are
no completed post-merge acceptance assignments in this phase. The candidate
replay (`run.json`) recorded `xsh_commit` `04fb98f8c63b63cccffce7ef2c3cabde81bb05ba`,
correctness `pass` across all ten env cases, restrictions `pass`
(`env_referenced: true`, `forbidden_operations: true`), and the full
package-owned gate `ticket_replay.error_fail_reference_required: true` with
`error_fail_reference_passed: true` — the worker actually exercised the
`xsht api api:error.fail` candidate surface (the deliberate-validation
API-index repair), not a workaround.

Candidate acceptance: pass.

## Next replay

The candidate `task-envcfg-009` replay already ran in this phase against commit
`04fb98f8c63b63cccffce7ef2c3cabde81bb05ba` on the shared handbook lineage
`lineage/handbook-approved.md` (approved snapshot `c1295e0a…`), including the
`xsht api api:error.fail` candidate gate and all ten env cases — all passed.
Next falsification: re-run the same phase after any further SPEC/registry or
handbook change to confirm the `error.fail` reference and local-`error`-binding
compatibility rule still hold, and confirm the ten-case correctness envelope.

## North-star impact

This phase exercises the environment/config surface (`env.get_or`, typed reads,
`fs.write`, malformed-value failure propagation) — the minimum composition bar
around system state that NORTH-STAR calls for. Confirming the worker reached a
passing, restriction-compliant solution with only spelling-level friction, and
that the `api:error.fail` repair surface works, advances learnable, ergonomic
trust in the config-rendering idiom. No infra-only classification applies
because the run produced a concrete product surface result.
