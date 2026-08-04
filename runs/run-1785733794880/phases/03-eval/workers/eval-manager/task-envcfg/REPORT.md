# Eval-manager report

## Result

pass

## Effort metrics

One configured trial (`CYCLE-REQUEST.md` trial plan count `1`) executed by the
controller; the executor is a black box and was not rerun.

Trial 1 (worker `task-envcfg-1`):

- Assistant turns: 74 (stop reasons: 73 `toolUse`, 1 `stop`); user messages: 1.
- Tool calls: 75 total (67 `bash`, 4 `read`, 3 `write`, 1 `edit`); tool results: 75.
- Tool errors: 3 (all accounted in `## Tool-error findings`).
- Session span: 420158 ms (≈7.0 min); `agent_wall_ms`: 421890.
- Thinking blocks: 65; provider-reported reasoning tokens: 29183.
- Budget: $0.50 cap, no budget failure (`budget_state: pass`).

Worker friction: the dominant friction was `xsht api` discovery of receiver
method surfaces (turns 5–20, ~10 tool calls of rejected queries before
`xsht api summary | grep` and `search:` worked) and the missing native error
constructor (turns 27–41 searching for `fail`/`raise`/`assert`/`Err` before
settling on a deliberately failing host call). Neither blocked the eval;
correctness, restrictions, protocol, and timing all passed.

## Usage and cost

Trial 1 (provider: OpenRouter, model `deepseek/deepseek-v4-flash-0731`,
`thinking: high`):

- Input tokens: 89638 ($0.00806742); output tokens: 38181 ($0.00687258).
- Cache read tokens: 2169152 ($0.039044736); cache write tokens: 0 ($0).
- Provider-reported total tokens: 2296971; bucket total
  (input+output+cacheRead+cacheWrite): 2296971 — exact match.
- Provider-reported reasoning tokens: 29183 (subset of output, not added).
- Cost total: $0.053984736; unknown costs: 0; budget $0.50, no breach.
- Per-trial dollars: $0.053984736; aggregate (1 trial): $0.053984736.

## Thinking evidence

65 thinking blocks; the provider reported `reasoning_tokens: 29183`, so
reasoning-token counts are available for this run. Qualitative findings from
the session's thinking text:

- The worker reasoned correctly about `${VAR-default}` semantics: defaults
  apply only on absence; present-but-empty keeps the empty value (turn 10
  thinking analyzed the oracle pattern and `env.get_or` behavior, then verified
  with probes).
- The worker explicitly discovered that typed readers are lenient:
  `env.int` accepts `+5`, `-5`, ` 5`, and leading zeros; `env.bool` coerces
  `TRUE`/`1`/`0`/`yes`/`""`; `Str.parse_int` is equally lenient (turns 37,
  47–49, 61). It chose regex validation over `env.int` so the failure controls
  and edge cases match the oracle exactly.
- The worker spent turns 27–41 searching for a user-facing way to raise a
  native `Error` (`fail`, `assert`, `raise`, `panic`, `abort`, `Err`), proved
  `Err("...")` yields `Result[<unknown>, Str]` that cannot propagate through
  `[error]`, and settled on the deliberate failing host call
  `regex.compile("(")?`. This re-confirms ticket `task-envcfg-001`.
- The worker verified the failure controls empirically: `CFG_PORT=abc` and
  `CFG_PORT=` both exit nonzero and create no output file (turns 58, 150).

## Tool-error findings

Three nonzero Pi tool results in the worker session; the manager session
(this run) has zero tool errors.

1. Worker turn 19 (`bash`): `xsht api` invalid discovery queries —
   `constructor:Path.parse_bytes` (unknown selector kind `constructor`),
   `api:Path.parse_bytes` (status `missing`), `constructor:Path` (unknown
   selector kind `constructor`). Classified as an API-discovery gap: the agent
   guessed selector kinds that do not exist; the canonical fix is the
   handbook candidate (use `xsht api summary | grep` / `search:NAME`) and
   ticket `task-envcfg-004` (per-type index query).
2. Worker turn 49 (`bash`): `sh: syntax error: bad substitution` in the
   worker's own BusyBox ash test harness (it used `${PIPESTATUS[0]}`, a Bash
   extension). This is worker harness noise, not an XSH defect; the probe
   intent (verify `env.bool` coercion) was completed by the following turn.
3. Worker turn 58 (`bash`): exit=3 with `env-int: environment value is not an
   integer` and `ls: /tmp/out.cfg: No such file or directory`. This is an
   intentional negative verification: the worker ran `CFG_PORT=abc` to confirm
   the failure control exits nonzero and creates no file; the wrapper flagged
   the expected nonzero status. Not a defect.

No manager-session tool errors. All structured `tool_errors` entries in the
phase `report.json` and worker `report.json` are accounted for above.

## Timing evidence

Candidate/oracle wall times per case (ns), from `run.json` `timings`:

| case | candidate | oracle |
|---|---|---|
| public | 11649448 | 11566530 |
| hidden_defaults | 11067986 | 10980527 |
| hidden_partial | 13671127 | 11851782 |
| hidden_empty | 11150778 | 13349958 |
| hidden_spaces | 13030249 | 11154945 |
| hidden_zero | 12041242 | 12923122 |
| hidden_utf8 | 12095867 | 13896170 |
| hidden_debug_false | 11060444 | 12669038 |
| hidden_malformed | 12234368 | 11553697 |
| hidden_empty_port | 15060302 | 12172117 |

All runs are 11–15 ms; EVAL.md declares no strict candidate/oracle timing gate,
so timing is diagnostic only. No gate breached.

## Observation classification

- Correctness (pass, no friction): all 10 cases byte-for-byte exact
  (`all_exact: true`); the worker's regex `^[0-9]+$` + raw-string output
  matches the oracle even for signed/space/leading-zero edge cases the eval
  does not gate on. Evidence: `run.json` correctness map; session turns 140,
  144, 150.
- Restriction compliance (pass): source references `env.` and `fs.write`, no
  subprocess boundary, stdout clean, `review.md` complete. Evidence:
  `run.json` `restrictions` and `protocol`.
- Product/tooling defect, general (ticket `task-envcfg-004`): `xsht api` has
  no per-type index; `method:Str`, `method:Str.`, `type:Str`, and
  `constructor:Path` are all rejected, forcing a full-index dump. Reproducible
  in this session (turns 5–20) and general to any receiver browsing.
- Product/tooling defect, re-confirmed (existing ticket `task-envcfg-001`,
  Open): no user-facing native error constructor; the worker again resorted to
  a deliberately failing host call (`regex.compile("(")?`) instead of a clean
  `fail`/`assert`. This run is a second independent reproduction.
- Product/tooling refinement (existing ticket `task-envcfg-002`, Open): the
  worker's final `proc main(target: Path)` plain typed parameter ran fine in
  the compact runtime, so the runtime restriction observed in
  `task-envcfg-002` is narrower than "any plain parameter" — it rejected the
  plain `List[Str]` form specifically. No new ticket; recorded as evidence for
  the open ticket's diagnosis.
- Reusable handbook guidance (staged candidate): teach that bare receiver
  queries are rejected and that `xsht api summary | grep` / `search:NAME` is
  the enumeration route; the worker burned ~10 turns rediscovering this.
- Ordinary noise: turn-49 `PIPESTATUS` Bash-ism (worker harness), turn-58
  intentional negative verification flagged by the wrapper, and the recorded
  `candidate_sha256` being the hash of empty `candidate.1.stdout` (the
  deliverable is a file, so stdout is empty by design — the byte-for-byte
  file comparison is the real correctness evidence).

## Handbook decision

Provisional candidate staged at
`runs/run-1785733794880/phases/03-eval/lineage/handbook-candidate.md`
(approved `c7c9dd9abb6d50dac60562757a1824900f24d4bc2d38014d5cbf869f56bb0723`
unchanged except one added paragraph; candidate
`f98a930a743e0d4905af6aae21813ad71a3365ef57dfc50bad6af0ccafe12be3`).

General lesson: when an agent needs a receiver type's member surface, bare
`xsht api method:Str` / `method:Str.` queries are rejected; the supported
enumeration routes are `xsht api summary | grep` and `xsht api search:NAME`.
Replay scope: global. This candidate is not trusted until a future cycle
replays it (next `task-envcfg` run and ideally `task-tags`/`task-ecount`,
which also browse receiver types) and shows the worker resolving a type's
members from `summary`/`search:` without the rejected-query loop. The
error-constructor gap is deliberately NOT taught as a workaround recipe; it is
owned by ticket `task-envcfg-001`.

## Tickets created

One: `tickets/task-envcfg-004.md` (Open; `## Status` set to `Open.`; merge
record placeholders untouched). It links this eval, this manager run, the
executor evidence (`workers/eval-worker/task-envcfg-1`), the handbook lineage,
and XSH baseline `ea7dea2f2b436cce34262d7a02105cbb029243dd`. The observation —
`xsht api` lacks a per-type index query, so agents burn turns on rejected bare
receiver queries before falling back to `summary | grep` — is general
ergonomics, not an envcfg recipe. No duplicate ticket for the already-open
`task-envcfg-001` error-constructor gap.

## Post-merge decisions

None. The reconciler found no merged tickets for this cycle (`none`), so there
are no post-merge acceptance assignments to evaluate against XSH commit
`ea7dea2f2b436cce34262d7a02105cbb029243dd`.

## Next replay

Replay `task-envcfg` (1 trial) against the next merged XSH commit using the
lineage candidate `f98a930a…` (or the promoted `runtime/handbook.md` if
approved), and check: (a) the worker resolves receiver members from
`xsht api summary`/`search:` with no rejected bare-receiver probes —
falsification if the rejected-query loop recurs; (b) if `task-envcfg-001`
lands, the malformed-port path uses a native error constructor instead of
`regex.compile("(")?` and still exits nonzero with no file; (c) if
`task-envcfg-004` lands, `xsht api method:Str` lists members and the worker
uses it. All 10 oracle cases must remain byte-for-byte exact.

## North-star impact

This run advances the practical-glue mission on two fronts. First, it proves
the eval's core hypothesis: an agent with the handbook can discover the `env`
module, apply absence-only defaults, write a byte-exact config file, and make
expected failures loud (`?` propagation transferred to a real config-validation
boundary) — the eval passed 10/10 with a clean, typed solution. Second, it
sharpens two durable ergonomics signals: XSH still lacks a user-facing native
error constructor (re-confirmed with a second workaround instance, tracked in
`task-envcfg-001`), and `xsht api` cannot enumerate a type's members without a
slow full-index dump (new ticket `task-envcfg-004`, with a matching handbook
candidate). Removing either would cut repeated discovery turns for every future
agent; both align with the north star's "fewer guesses, workarounds, tool
errors, and repeated discoveries."
