# Eval-manager report

## Result

pass

## Effort metrics

Trial 1 (single trial; controller completed exactly 1):
- assistant_turns: 32
- tool_calls: 33, tool_results: 33, tool_errors: 4 (all warnings)
- tools: bash 29, read 3, write 1
- user_messages: 1, malformed_lines: 0, budget_failures: 0
- session_span_ms: 482,406 (~8 min); agent_wall_ms 484,022
- All 10 evaluator cases passed byte-for-byte; protocol, restrictions, and
  reporting all `pass`. Worker friction was modest: the agent looped on syntax
  (`if not ok`, `return ()`, effect annotations) and on confirming `parse_int`/
  `env.int` leniency, but converged to a correct, clean solution.

## Usage and cost

Provider: openrouter, model `deepseek/deepseek-v4-flash-0731`, thinking=high,
offline=unknown.
- input_tokens: 103,214 (input_cost $0.00928926)
- output_tokens: 17,531 (output_cost $0.00315558)
- cache_read_tokens: 513,728 (cache_read_cost $0.009247104)
- cache_write_tokens: 0 ($0)
- bucket total: 634,473 (matches provider_total_tokens 634,473)
- reasoning_tokens (provider-reported): 11,829 (subset of output)
- thinking_blocks: 30
- cost_usd total per trial: $0.02169; budget_usd 0.50; aggregate (1 trial):
  $0.02169

## Thinking evidence

30 thinking blocks; provider reported 11,829 reasoning tokens. The transcript
shows the worker (a) discovering `module:env`, `env.get_or`, `env.int`,
`env.bool` and `Str.parse_int`/`Str.delete` via `xsht api`, (b) empirically
probing `parse_int`/`env.int` leniency (`+5`, `-5`, `0x10`, `010`, whitespace,
`5.0`, empty) and discovering BusyBox printf lacks `%q`, (c) attempting
`language.core.fail` twice and confirming the documented `fail` does not
resolve at check time, and (d) choosing a manual digit check plus an incidental
`"".parse_int()?` in the rejected branch. The resulting `envcfg.xsh` is small,
deterministic, and stdout-clean; the traceback on the failure controls is
emitted to stderr, not stdout.

## Tool-error findings

All four structured `tool_errors` come from the current worker session; the
manager session has zero tool errors. Each is classified:

1. turn 13 (`bash`): `env.int sh: %-6q -> exit=%s  out=%s: invalid format`.
   The worker's own probe harness used BusyBox `printf '%-6q'`, which this
   image does not implement. Worker-harness friction, not a product defect.
2. turn 17 (`bash`): `parse.expected-expression ... if not ok {`. The worker's
   scratch used `not`, which is not an XSH operator. Learning friction/noise.
3. turn 24 (`bash`): candidate deliberately rejects `CFG_PORT=abc` (exit 3),
   then the harness `ls /tmp/out4.cfg` fails because no file was (correctly)
   created; bash reports code 1. Expected deliberate-failure behavior.
4. turn 29 (`bash`): same pattern — `exit=3` on invalid port, `ls /tmp/o3.cfg`
   fails because no file was created; bash code 1. Expected.

No `xsht api` query in this session returned an error; the discovery queries
(`module:env`, `api:env.get`, `search:parse_int`, `method:Str.parse_int`,
`language:core.fail`, `search:fail`, `api:Str.parse_int` which was `missing`)
all resolved as hits or `missing` without a tool error. The only actual
discovery dead-end was semantic (see handbook/ticket section).

## Timing evidence

No strict candidate/oracle timing gate (documented in EVAL.md). All cases are
millisecond-scale; candidate and oracle are comparable:
public 11.2/11.4 ms, defaults 11.4/11.3 ms, empty 13.7/14.2 ms, spaces
13.1/14.0 ms, zero 11.1/11.2 ms, utf8 10.8/11.1 ms, malformed 12.7/11.0 ms,
empty_port 11.8/14.1 ms, partial 12.6/12.0 ms, debug_false 12.4/12.7 ms.
Timing is diagnostic only.

## Observation classification

- Correctness: pass — all 10 cases exact; both failure controls exit nonzero
  and create no output file; `env.` referenced; no forbidden subprocess.
- Restriction: pass.
- Tool-error observations #1 and #2: worker-harness/learning noise.
- Tool-error observations #3 and #4: expected deliberate-failure propagation
  (a success signal, recorded as nonzero bash because the harness then `ls`'s a
  correctly absent file).
- Product/tooling defect: `language.core.fail` is documented by `xsht api`
  (exact hit with contract) yet `xsht check` rejects `fail("...")?` as
  `unresolved pure function call`, and `xsht api search:fail`/`summary` still
  resolve only "fail/failure" word matches. This is a documentation-ahead-of-
  runtime mismatch that forces the sentinel `"".parse_int()?` idiom. Already
  tracked by open ticket `task-envcfg-001` (deliberate-error primitive) and the
  API-registry aspect by merged ticket `task-envcfg-002`.
- Noise/minor: `env.int`/`parse_int` leniency (accept signs, whitespace,
  leading zeros) requires the manual `delete("0123456789")`+`byte_len` check;
  deliberate-failure exit code is 3, not the oracle's 1 — both are within the
  task contract ("nonzero", byte-exact decimal). Diagnostic only.
- Harness noise: run.json reports `candidate_sha256` as the empty-input hash
  `e3b0c44...`. This is a metadata-field artifact; the candidate file on disk
  is 444 bytes and all ten byte-for-byte comparisons passed, so correctness is
  not in question.

## Handbook decision

Unchanged. Copied `lineage/handbook-approved.md` to
`lineage/handbook-candidate.md` verbatim (sha256 `97c5d8...` matches the
approved snapshot). The handbook's env/config section and its "no generic
Error(...) constructor" note are accurate for this build and adequate: the
agent completed the task correctly with only modest friction. The real gap is
the `fail` documentation/runtime mismatch, which is a product defect best fixed
and then replayed, not papered over with a task-specific workaround recipe.
Replay scope: none added this cycle.

## Tickets created

None. The single strong reproducible observation — `xsht api` documents
`language.core.fail` while the runtime cannot resolve it, forcing the sentinel
`parse_int` idiom — is already captured by open ticket
`tickets/task-envcfg-001.md` (deliberate-error primitive) and its
API-discoverability successor `task-envcfg-002.md`. A duplicate ticket would be
redundant; this run is evidence for the existing open ticket rather than a new
product gap.

## Post-merge decisions

None. The reconciler found no merged ticket files for this cycle, so there are
no post-merge acceptance assignments to reconcile.

## Next replay

Replay `task-envcfg` against the commit that lands the deliberate-error
primitive tracked by `task-envcfg-001` (and registers it in the `xsht api`
reference per `task-envcfg-002`). Acceptance: `xsht api search:fail`/
`language:core.fail` resolve and the agent adopts `fail("...")?` without the
sentinel `parse_int`, while all ten evaluator cases (including both failure
controls) still pass. This is the falsification check for the current
workaround-dependent solution and validates the handbook's "let postfix `?`
propagate a typed failure" lesson on a real validation boundary.

## North-star impact

This run demonstrates that the env/config surface (typed reads, absent-only
defaults, byte-exact file output, propagation of a malformed value to a loud
nonzero exit with no partial file) is discoverable and composable — a genuinely
new systems-glue capability the factory previously did not cover. It also keeps
stdout clean and rejects hidden cases without hard-coding. The one durable
product signal is the `fail` documentation-vs-runtime mismatch, which directly
undermines the north-star trust principle ("the live reference should not
mislead") and the explicit-error/expected-failures-visible rationale. Fixing
that gap and replaying here will show whether the clean deliberate-error idiom
generalizes beyond this eval to any config/args-validation boundary.
