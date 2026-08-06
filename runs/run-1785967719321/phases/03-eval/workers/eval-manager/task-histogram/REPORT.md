# Eval-manager report

## Result

pass

## Effort metrics

Single trial (`task-histogram-1`) against XSH commit
`1cf4ad3d7ee5fde9b3160b11d8073cbd7ce5e7c4`, approved handbook snapshot
`lineage/handbook-approved.md`.

- Assistant turns: 52 (stop 1, toolUse 51).
- Tool calls: 58 total — `bash` 53, `edit` 1, `read` 4; tool results 58.
- Tool errors: 0 (structured `tool_errors` empty).
- Session span: 360433 ms (~6.0 min) wall, agent_wall_ms 361843; no retries.
- Worker friction: moderate. The helper-proc `?` restriction forced the worker
  through repeated controlled experiments (`/tmp/t17..t20.xsh`) before it
  learned to return `Result[Int]` from the helper and apply `?` at the call
  site. Not tool errors — exploratory trial-and-error on a language rule.

## Usage and cost

Worker `task-histogram-1` (provider `openrouter/deepseek/deepseek-v4-flash-0731`):

- input 40907, output 17718, cacheRead 905088, cacheWrite 0;
- provider_total_tokens 963713, bucket total 963713 (match);
- reasoning 10115 (subset of output; provider did report reasoning-token count);
- thinking blocks 42;
- cost: input 0.00368163, output 0.00318924, cacheRead 0.016291584,
  cacheWrite 0, total 0.023162454 USD; budget 0.5 USD, budget_state pass.

Aggregate (1 worker): $0.02316. 42 thinking blocks + 10115 reasoning tokens are
the only provider-reported reasoning; thinking text in the session JSONL is
qualitative. cacheRead dominates the bucket because the shared handbook/system
context is cached across turns.

## Thinking evidence

42 thinking blocks, 10115 provider-reported reasoning tokens. Findings grounded
in the raw thinking blocks:
- the worker explicitly diagnosed the missing `Error` constructor and the
  `"".parse_int()?` forced-failure idiom;
- it searched `parse_uint`/`unsigned`/`nat` and confirmed only `nat` matched,
  no unsigned parser exists;
- it reproduced the `?`/`Result`-context restriction across t17–t20 and
  reasoned the fix (return `Result[Int]` from the helper, apply `?` at the
  call site);
- it reasoned carefully about laziness/error propagation (errors surface before
  any print so failure controls emit nothing) and about blank-line handling,
  leading to a correct byte-exact solution in one pass.

## Tool-error findings

None. The structured `tool_errors` arrays for the worker and manager sessions
are empty. The `xsht api search:parse_uint`, `search:unsigned`, and
`search:nat` probes returned `status: missing`/`matches` as discovery
("no match") results, not failed tool results (all `isError: false`); these
are API-discovery gaps, recorded as guidance, not tool errors.

## Timing evidence

No strict candidate/oracle timing gate for this eval; both sides finish in
milliseconds, so timing is diagnostic. Per case (candidate vs oracle, ns):

- public 11659959 vs 11945307; hidden_width 10820014 vs 11385306; hidden_many
  12246933 vs 13493351; hidden_sparse 10992764 vs 13482143; hidden_single
  11761973 vs 13477684; hidden_ties 13265267 vs 13616309; hidden_empty
  13190892 vs 13527976; hidden_bad_width 13355809 vs 12172808; hidden_bad_value
  11732390 vs 13298934.

All nine cases byte-exact. Failure controls: bad_width and bad_value both emit
empty stdout and exit nonzero (candidate exit 3 via runtime traceback; oracle
exits 1/2 — both nonzero, gate is nonzero-and-empty, satisfied). No timing gate
was breached.

Provider telemetry is present with retry_count 0, provider_errors [],
output_tokens_per_second 0; there is no provider-latency signal. The ~6-min
span over 52 turns with many bash experiments is agent effort, not provider
health; latency attribution is therefore not the cause of the wall clock.

## Observation classification

- **Correctness — pass.** All nine cases byte-exact including both failure
  controls (nonzero exit + empty stdout). Evidence: `run.json`
  `correctness.all_exact:true`, candidate stdout files `1..9`.
- **Restriction / protocol — pass.** No subprocess boundary; source references
  a typed file read (`fs.read_text`), `parse_int`, and a `sort-by` stage;
  `review.md` keeps both required headings with no placeholders.
- **Worker friction — reusable handbook guidance (staged).** The
  `check.try-context: ? requires a Result-returning context` rule in helper
  procs is undocumented; the worker rediscovered the `Result[Int]`-returning
  helper pattern via t17–t20 trial and error. Already tracked as open product
  ticket `task-histogram-004`; this run additionally stages a handbook lesson
  for the current language so future agents skip the exploration.
- **Product/tooling defect — new ticket.** Strict non-negative decimal
  validation has no first-class spelling: no unsigned parser and no generic
  `Error` constructor force a `regex` + `parse_int` + `"".parse_int()?` hack.
  General, reproducible, and not covered by `task-histogram-004` (which
  explicitly scopes out the Error constructor and parse_int permissiveness).
  Ticket `task-histogram-005`.
- **Provider health — no signal.** retry_count 0, provider_errors [].
- **Ordinary noise — none.** No flaky or stochastic finding.

## Handbook decision

Provisional candidate staged at
`lineage/handbook-candidate.md` (baseline + one concise addition to the
"Effects and errors" section). General lesson: to factor a fallible parse into
a helper, declare the return type `Result[T]` and apply `?` at the call site
(`?` is rejected in a plain `-> Int [error]` helper); for a strict
non-negative contract, reject signs with `^[0-9]+$` because `parse_int`
accepts an optional sign, and force a deliberate failure without a matching
typed conversion via `"".parse_int()?` (no unsigned parser, no `Error`
constructor). This is a short, general rule that removes repeated agent
friction rather than a task recipe. Replay scope: `task-histogram` and any
eval that reads a numeric field or factors a validation helper. Promotion to
`runtime/handbook.md` requires a later replay + CTO approval; this run does not
edit the approved snapshot or the checked-in handbook.

## Tickets created

- `tickets/task-histogram-005.md` — product ticket for the strict
  non-negative-integer validation ergonomics gap (unsigned parser / generic
  `Error` constructor). Links eval `task-histogram`, this manager run, executor
  `run.json`, the handbook lineage, and XSH commit
  `1cf4ad3d7ee5fde9b3160b11d8073cbd7ce5e7c4`. Open for the next cycle; not
  dispatched to engineer this cycle.
- No factory-target ticket (no infrastructure finding this run).

## Post-merge decisions

None. The reconciler reported merged tickets: `none`. There are two Open
tickets for this eval (`task-histogram-003` about fold-with-print, and
`task-histogram-004` about the `?`/Result-context rule) that are not merged
and are out of scope for this manager pass (no pending acceptance). No revert
proposal is required.

## Next replay

Replay `task-histogram` on the next cycle's lineage to (a) falsify or support
the staged handbook candidate (the `Result`-returning helper + strict
non-negative validation idiom) and (b) post-merge-replay `task-histogram-005`
and `task-histogram-004` once either is merged at a future XSH commit,
checking that the natural `parse_uint`/`Error` spelling and the relaxed `?`
rule keep all nine cases byte-exact.

## North-star impact

This eval confirms XSH composes a measured distribution pipeline (typed file
read → `parse_int` → integer div to a derived bin → `group-by` keyed count →
`sort-by` → cumulative `fold` → exact output) with no subprocess escape — a
canonical systems-glue shape. The durable signal is ergonomics: two error/edge
idioms (`?` in helpers; strict unsigned validation) cost the agent real
exploration and are now (a) a staged global handbook lesson and (b) a linked
product ticket, so future agents and the language itself can make strict
numeric validation explicit, learnable, and trustworthy rather than relying on
regex-plus-empty-string hacks.
