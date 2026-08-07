# Eval-manager report

## Result

pass

## Effort metrics

Trial 1 (`task-groupsum-1`, XSH commit
`857154dfe505f0d01053c1b5311f44422070eb34`):
- assistant turns: 66 (stop: 1, toolUse: 65)
- tool calls: 75 total (bash 66, write 4, edit 3, read 2); tool results: 75
- tool errors: 1 (single `xsht api` query-format slip, recovered next turn)
- session span: 473101 ms (~7.9 min); agent wall: 474694 ms
- worker friction: low. One minor discovery slip; no repeated exploration, no
  re-reads beyond normal reference lookups, no budget breach. Worker friction
  classification: minimal / ordinary-noise tool error.

## Usage and cost

Trial 1 provider-reported usage (openrouter/deepseek/deepseek-v4-flash-0731):
- input tokens: 52011; output tokens: 22905; cache read: 1550656;
  cache write: 0; bucket total: 1625572; provider total: 1625572
  (buckets reconcile exactly)
- reasoning tokens: 13453 (reported subset of output)
- thinking blocks: 50
- cost: input 0.004681, output 0.004123, cache read 0.027912, cache write 0,
  total 0.036716 USD; budget 0.50 USD; unknown costs 0
- aggregate across the single worker = 0.036716 USD; no other workers/cost.

## Thinking evidence

50 thinking blocks recorded; provider reported 13453 reasoning tokens. Thinking
was productive and task-aligned: the agent checked `Str.fields`, `parse_int`
semantics, Map.get/set fallback, stream sort stability, and deliberately
validated the `-?[0-9]+` value grammar before printing (so an error after some
rows could still print nothing). This matched the plan of validate-then-print.
Reasoning tokens are provider-reported and treated as a subset of output.

## Tool-error findings

Exactly one nonzero Pi tool result across the current evidence packet:
- worker `task-groupsum-1`, turn 12, bash tool:
  `xsht api: invalid API query 'language.core.results'; expected KIND:VALUE`
  and `xsht api: invalid API query 'language.core.postfix-question'; expected
  KIND:VALUE`, exit code 2. The agent used a dot separator (`language.core.X`)
  instead of the KIND:VALUE colon form (`language:core.X`); the tool's own
  error named the correct shape and the agent recovered on the immediately
  following turn with `language:core.results`. Classified as ordinary
  discovery noise, not recurring friction.
Manager session: zero tool errors. All other `xsht api`/`search:` queries in
the worker returned `status: exact` or `status: matches`.

## Timing evidence

Candidate vs oracle wall ns per case (candidate / oracle), all in the 11–15 ms
band and close to the oracle's own 1–15 ms:
- public 12501106 / 11627559; hidden_accumulate 12903608 / 12115478;
  hidden_order 12391438 / 15653080; hidden_many 11947353 / 11866602;
  hidden_blank 15435495 / 13256526; hidden_empty 11673101 / 11944728;
  hidden_bad_fields 10956389 / 1507841; hidden_bad_value 11955936 / 11943936;
  hidden_missing 11170391 / 11977894.
No strict candidate/oracle ratio gate exists for this eval; timing is
diagnostic only. Candidate timing is comparable to the oracle, so no envelope
concern. Provider telemetry present with retry_count 0, provider_errors [],
and no retry events; `output_tokens_per_second` was 0 (client-observed, not
continuously measured). No external-health signal; the ~7.9 min session reflects
66 turns of API/probe exploration, not latency stalls.

## Observation classification

- Correctness (signal): all 9 cases pass byte-exact; failure cases exit
  nonzero with empty stdout; empty/blank file prints nothing and exits 0.
  Evidence: `run.json` `correctness.all_exact=true`, cases exact=true.
- Restriction (signal): source reads text via `file_path.read_text()?` and
  contains no subprocess/process-boundary use. Evidence: run.json
  `restrictions.reads_text=true, passed=true`.
- Protocol (signal): `groupsum.xsh` present; `review.md` keeps both required
  headings. Evidence: `protocol.artifact_present=true, review_ok=true`.
- Tool-error friction (noise): the single `language.core.X` vs
  `language:core.X` discovery slip was self-corrected by the tool's KIND:VALUE
  message on the next turn; not recurring in this session.
- Agent-flagged observations (candidate, single-run, not independently
  reproduced here): (a) `?` inside an `if`/`else` branch within a `stream.fold`
  stage block fails `xsht check` with "indexed IR could not encode
  'full_ir_function_blocker'", while the same `?` inside an `each` block works;
  (b) `Str.parse_int` accepts leading `+` and surrounding whitespace, so the
  task's stricter `-?[0-9]+` grammar required an explicit regex check. Both are
  single-trial observations with a successful workaround; they are candidates
  for next-cycle replay, not strong enough alone to open a product ticket this
  cycle.
- Timing (diagnostic, no gate): candidate/oracle comparable.

## Handbook decision

Unchanged. The single discovery slip is a query-format error the tool
immediately explains and corrects; the approved handbook already documents
KIND:VALUE, gives `language:core.*`/`language:effect.*` as namespace ids, and
provides the exact `language:stream.sort-by` colon example. One recovered error
is not enough to justify a handbook edit under the short-general-rule policy.
The approved snapshot was copied unchanged to
`lineage/handbook-candidate.md` (no provisional candidate staged). If the
`parse_int`/`fold` observations reproduce in a later run, a future candidate
would name the exact language-rule query and the fold/error-propagation
limitation, replayed by a Map-accumulation eval before any promotion.

## Tickets created

Zero. The single tool error was recovered noise; the two agent-flagged friction
points are single-trial observations with workarounds and were not reproduced,
so they do not meet the one-strong-reproducible-observation bar for a product
ticket.

## Post-merge decisions

None. The reconciler reported no merged tickets for this run.

## Next replay

Same eval `task-groupsum` against the same approved handbook lineage
(`lineage/handbook-approved.md`) at XSH commit
`857154dfe505f0d01053c1b5311f44422070eb34`. Because the run already passes,
the next replay is a falsification/regression check (no handbook change to
validate). Separately, a follow-up eval that again routes a deliberate
validation failure should watch for the two single-run observations (fold `?`
IR blocker, `parse_int` leading-sign/whitespace permissiveness) to decide
whether they generalize into a handbook rule or a product ticket.

## North-star impact

This run is direct product signal: it demonstrates that the handbook's typed
Map (`Map.set`/`Map.get` fallback), integer parsing, and keyed stream sort
compose into a correct aggregation tool, byte-exact against an external oracle
across accumulation, byte-order, blank-lines, empty-file, and clean-failure
cases. The agent reached the correct, clear typed solution with low friction
and no shell escape, confirming the north-star hypothesis that the immutable
Map idiom and stream sort idiom are learnable together in XSH. The single
recovered discovery slip is noise; the two candidate frictions (fold `?`
limitation, parse_int permissiveness) point at ergonomic edges worth a
replay-guided look next cycle but are not yet strong enough to warrant a ticket
or handbook edit.
