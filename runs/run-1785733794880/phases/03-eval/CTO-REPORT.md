# CTO briefing 03-eval

This is the deterministic first-pass briefing for the CTO. The structured
`report.json` files and raw Pi sessions remain the source of truth.

## Result

pass

## Operating context

- Mode: `eval`
- Request: `CYCLE-REQUEST.md`
- Structured report: `report.json`

## Phase outcomes

- `report.json`: result `pass`; report `report.json`
- `workers/eval-manager/task-envcfg/report.json`: result `pass`; report `workers/eval-manager/task-envcfg/report.json`
- `workers/eval-worker/task-envcfg-1/report.json`: result `pass`; report `workers/eval-worker/task-envcfg-1/report.json`


## Employee accounting

### Worker metrics

- `eval-manager/task-envcfg` (`eval-manager`): result `pass`; report `workers/eval-manager/task-envcfg/report.json`
  - Execution: `not recorded`; classification: `not recorded`
  - Turns: `40`; bucket tokens: `2126938`; thinking blocks: `35`
  - Tool errors: `1`; cost: `0.032916`; budget: `0.150000`
- `eval-worker/task-envcfg-1` (`eval-worker`): result `pass`; report `workers/eval-worker/task-envcfg-1/report.json`
  - Execution: `pass`; classification: `pass`
  - Turns: `74`; bucket tokens: `2296971`; thinking blocks: `65`
  - Tool errors: `3`; cost: `0.053985`; budget: `0.500000`


### Nonzero tool results

- `eval-manager/task-envcfg`, turn `5`, tool `read`: EISDIR: illegal operation on a directory, read
  - Structured report: `workers/eval-manager/task-envcfg/report.json`
- `eval-worker/task-envcfg-1`, turn `19`, tool `bash`: xsht api: invalid API query 'constructor:Path.parse_bytes'; unknown selector kind 'constructor'
===
query: api:Path.parse_bytes
status: missing
===
xsht api: invalid API query 'constructor:Path'; unknown selector kind 'constructor'


Command exited with code 2
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`
- `eval-worker/task-envcfg-1`, turn `49`, tool `bash`: --- CFG_DEBUG='true' ---
true
sh: syntax error: bad substitution


Command exited with code 2
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`
- `eval-worker/task-envcfg-1`, turn `58`, tool `bash`: exit=3
== stdout ==
== stderr ==
runtime traceback
executable: /usr/local/bin/xsh
operation: result.propagate
error: env-int: environment value is not an integer
call path:
  1. proc main at /work/envcfg.xsh:1:1-1:1
== file? ==
ls: /tmp/out.cfg: No such file or directory


Command exited with code 1
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`


### Cycle total

- Workers: `2`
- Assistant turns: `114`
- Bucket tokens: `4423909`
- Cost (USD): `0.086901`
- Nonzero tool results: `4`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-manager/task-envcfg

- Role: `eval-manager`
- Result: `pass`
- Report: `workers/eval-manager/task-envcfg/REPORT.md`

#### Efficiency and evidence

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

#### Handbook or proposal decision

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

#### Ticket or product decision

One: `tickets/task-envcfg-004.md` (Open; `## Status` set to `Open.`; merge
record placeholders untouched). It links this eval, this manager run, the
executor evidence (`workers/eval-worker/task-envcfg-1`), the handbook lineage,
and XSH baseline `ea7dea2f2b436cce34262d7a02105cbb029243dd`. The observation —
`xsht api` lacks a per-type index query, so agents burn turns on rejected bare
receiver queries before falling back to `summary | grep` — is general
ergonomics, not an envcfg recipe. No duplicate ticket for the already-open
`task-envcfg-001` error-constructor gap.

#### Next action

Replay `task-envcfg` (1 trial) against the next merged XSH commit using the
lineage candidate `f98a930a…` (or the promoted `runtime/handbook.md` if
approved), and check: (a) the worker resolves receiver members from
`xsht api summary`/`search:` with no rejected bare-receiver probes —
falsification if the rejected-query loop recurs; (b) if `task-envcfg-001`
lands, the malformed-port path uses a native error constructor instead of
`regex.compile("(")?` and still exits nonzero with no file; (c) if
`task-envcfg-004` lands, `xsht api method:Str` lists members and the worker
uses it. All 10 oracle cases must remain byte-for-byte exact.

#### North-star impact

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



## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` (required; next CTO must
  validate or revert it before paid work)
