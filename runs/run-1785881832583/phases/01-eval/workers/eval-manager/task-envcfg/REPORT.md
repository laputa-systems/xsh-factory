# Eval-manager report

## Result

pass

## Effort metrics

Single configured trial (controller completed exactly 1 fresh trial; EVAL.md default policy is one trial). Worker `task-envcfg-1` (`workers/eval-worker/task-envcfg-1/`):

- 26 assistant turns, 27 tool calls (20 `bash`, 2 `edit`, 4 `read`, 1 `write`), 27 tool results, 4 tool errors, 1 user message.
- Session span 157,151 ms (~2.6 min); agent wall 158,483 ms.
- Provider telemetry present: `retry_count=0`, `provider_errors=[]`, `retry_delay_ms=0`, `response_elapsed_ms=0`, `output_tokens_per_second=0`. No explicit retry/provider-error events. Response-level latency attribution is therefore `unknown` (telemetry fields are zero/unpopulated), but the short, low-turn session shows no agent-inefficiency signal and no external-health event. Provider switching is out of scope for this cycle.
- Worker friction limited to the four tool events classified below (module-shadow at turn 14, one lint warning at turn 17, and two deliberate failure-control tests at turns 15/19).

## Usage and cost

Trial 1 (sole worker): input 24,918; output 11,991; cacheRead 342,592; cacheWrite 0; reasoning 6,338 (subset of output); bucket total 379,501 = provider total 379,501 (balanced). Cost: cacheRead $0.00616666, input $0.00224262, output $0.00215838, cacheWrite $0, total $0.01056766. Budget $0.50; budget_state pass; budget_failures 0; unknown_costs 0. Aggregate = trial 1 (one worker, one trial).

## Thinking evidence

22 thinking blocks; reasoning tokens 6,338 (provider-reported `reasoning`); reasoning-token count is reported, so no `unavailable` disclaimer is needed. Qualitative reading of the session: the worker read `agents.md`/`handbook.md`/`task.md` first, then discovered the env surface via successful `xsht api module:env` / `api:env.get` queries, probed `parse_int`/Result semantics with throwaway scripts (per `review.md`), resolved the module-shadow friction (turn 14), and exercised the malformed/empty-port failure controls. The `env-missing` runtime tracebacks at turns 15/19 are the worker deliberately triggering its validation sentinel to confirm `exit=3` with no output file — correct behavior under test, not failed reasoning.

## Tool-error findings

All 4 structured tool errors from the current packet (worker `task-envcfg-1`), each accounted for:

1. **Turn 14** (bash): `err[check.standard-module-shadow]: name 'path' shadows the standard module 'path'` from `let path = Path(argv[0])` in `/tmp/p6.xsh`. Genuine, generalizable friction — the worker did not yet know standard module names cannot be rebound. Resolved by switching to the `fp"${argv[0]}"` path form.
2. **Turn 15** (bash): deliberate failure-control test; `let _ = env.get("<sentinel>")?` triggered `env-missing`, `exit=3`, and `ls: /tmp/bad.cfg: No such file or directory`. This is the intended malformed/empty-port behavior being validated (loud nonzero exit, no file), not a defect.
3. **Turn 17** (bash): `warn[lint.path-constructor]` that `Path(...)` should use p-string interpolation; `xsht lint` exited 1 on the warning. Documented friction, resolved by the fp form.
4. **Turn 19** (bash): deliberate failure-control test (same sentinel as #2) confirming `exit=3` and no output file on `CFG_PORT=abc`.

No invalid `xsht api` discovery queries were recorded; the five `xsht api` invocations (`module:env`, `api:env.get`, `language:core.display-strings`, `search:parse_int`, `summary`) returned normally. Manager session: `None.`

## Timing evidence

`run.json` candidate/oracle wall ns per case (candidate vs oracle): public 11.200/11.300; hidden_defaults 12.297/13.331; hidden_partial 11.391/11.945; hidden_empty 10.965/13.240; hidden_spaces 11.246/12.689; hidden_zero 13.204/12.000; hidden_utf8 11.039/13.351; hidden_debug_false 11.238/11.122; hidden_malformed 13.131/11.293; hidden_empty_port 10.953/11.406. All values are ~10–13 ms. EVAL.md states there is no strict candidate/oracle timing gate; timing is diagnostic until a stable envelope exists. No timing concern.

## Observation classification

- **Module-shadow friction (turn 14)** — reusable handbook guidance. `xsht check` rejects a binding that shadows a standard module name; the rule itself is not stated in the approved handbook even though the p-string preference is. Generalizes to any binding/parameter named after a standard module (`path`, `fs`, `env`, `stream`, …), in any eval. Staged as a concise provisional handbook candidate.
- **`Path(...)` lint warning (turn 17)** — reusable handbook guidance already present (fp preferred); ordinary agent iteration, resolved, no change needed.
- **Deliberate-validation sentinel (`env.get("<sentinel>")?` at turns 15/19)** — product/tooling gap already tracked by open ticket `task-envcfg-001` (deferred/rejected `fail` design; the artifact's `review.md` and run re-confirm the gap). No new ticket; this would be duplicative.
- **Result-introspection friction** (`is_err`/`is_ok` undefined on `Result[T, Error]`; `parse_int` accepts `+`/`-`/leading spaces) noted in `review.md` — single-trial ergonomics signal; not strong enough for a current-cycle ticket without reproduction.
- **Empty `candidate_sha256`** (`e3b0c44…`, the empty-string digest) recorded in `run.json`/phase report while the evaluated `envcfg.xsh` is non-empty (actual hash `7f7d8e0e…`) and produced matching output on all ten cases — harness data-recording noise; no correctness impact, not a ticket.
- **No correctness, restriction, protocol, or timing issue**; all ten cases exact, restrictions pass (`env_referenced`, `forbidden_operations`), `review.md` valid. No provider-health signal; latency attribution `unknown` (telemetry zeros).

## Handbook decision

Provisional candidate: add a short general rule to the "Paths and filesystem values" section that standard module names (`path`, `fs`, `env`, `stream`, …) may not be rebound as bindings/parameters (`check.standard-module-shadow`) and that dynamic runtime paths should use the interpolated p-string form (`let out = fp"${argv[0]}"`) rather than a binding named `path`. Written to `runs/run-1785881832583/phases/01-eval/lineage/handbook-candidate.md` (copy of the approved snapshot `97c5d804…` plus this one note). Replay scope: global — any env/fs/path task; must be replayed by `task-envcfg` (and ideally `task-ecount`/`task-tags`) before promotion to `runtime/handbook.md`.

## Tickets created

Zero new tickets. Open ticket `tickets/task-envcfg-001.md` (deliberate-error/sentinel gap) remains `Open.`/Deferred and is referenced by this run's evidence; it is not a reconciled merged ticket this cycle, so no status change is made here.

## Post-merge decisions

None. The controller reconciled zero merged ticket files (`none`); the candidate-ticket field is `not-reevaluation`. There are no post-merge acceptance assignments.

## Next replay

Replay `task-envcfg` (one trial; raise to two if a second is configured) against XSH commit `a67599b7865707d0ddbfdaf04bd1620f511556b8` with the module-shadow handbook candidate in the lineage, to confirm the agent no longer spends a discovery turn on rebinding standard-module names and still passes all ten evaluator cases. Also replay `runtime/handbook.md` consumers (`task-ecount`, `task-tags` when re-enabled) to confirm the added rule generalizes.

## North-star impact

The Eval confirms the env-module config-surface lesson transfers: an agent working from the handbook's `env.get_or` / `fs.write` / `fp"${...}"` guidance produced a byte-exact config file across all ten correctness and restriction gates with a clean stdout and a loud nonzero exit / no file on malformed input, at low cost and in a short session. The staged module-shadow candidate advances ergonomics and learnability (fewer checker errors, no shadowed-binding surprises) for any env/fs/path eval. The run also re-confirms, without duplicating a ticket, the open deliberate-error gap (`task-envcfg-001`) whose resolution would honor the north-star emphasis on structured errors and making expected failures visible through their own path rather than an unrelated sentinel.
