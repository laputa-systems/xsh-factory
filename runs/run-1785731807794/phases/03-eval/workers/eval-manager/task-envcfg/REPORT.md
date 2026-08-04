# Eval-manager report

## Result

pass

## Effort metrics

One configured trial (controller completed exactly 1). Worker `task-envcfg-1`
(`openrouter/deepseek/deepseek-v4-flash-0731`, thinking level high):

- Assistant turns: 57 (stop reasons: 1 `stop`, 56 `toolUse`)
- Tool calls: 62 (57 bash, 3 read, 2 write); tool results: 62
- Tool errors: 2, both `bash` "Command exited with code 1" (no output) — see
  `## Tool-error findings`; neither blocked progress
- Session span: 302,254 ms (`session_span_ms`), agent wall 303,994 ms
  (`agent_wall_ms`); session ran 2026-08-03 04:40:53Z to ~04:45:56Z
- Budget: $0.50 cap, `budget_failures: 0`, `budget_state: pass`

Worker friction per trial: (a) ~20 turns (turns 10–30, ~15 bash probes) hunting
for an error constructor before settling on the `"".parse_int()?` failure
signal; (b) ~10 turns (turns 37–46, 8 bash probes) discovering word-form
boolean operators `or`/`and` and `if COND { }` syntax. Both are below in
`## Observation classification`; neither was fatal — the worker reached a
correct, minimal solution and self-checked against the oracle (turns 47–55).

## Usage and cost

Single worker, provider-reported (deepseek-v4-flash-0731 via OpenRouter):

- input: 49,149 tokens / $0.00442341
- output: 24,083 tokens / $0.00433494
- cacheRead: 1,391,424 tokens / $0.025045632
- cacheWrite: 0 tokens / $0
- bucket total: 1,464,656 tokens; provider total: 1,464,656 (exact match)
- reasoning (provider-reported): 17,075 tokens, a subset of `output`, not
  added to totals
- cost total: $0.033803982 across 1 worker; `unknown_costs: 0`, `malformed_lines: 0`
- Aggregate: 1 trial, $0.0338, no budget breach

## Thinking evidence

Thinking-block count: 49 (worker `report.json`). Provider reported reasoning
tokens (17,075), so reasoning-token counts are available and are a subset of
`output`. There is no separate `thinking.md` artifact in the worker packet; raw
thinking blocks live in the canonical `session.jsonl.bz2` (`type: "thinking"`),
which this manager read directly.

Qualitative findings from the transcript: the heaviest thinking clusters are
turn 10 (~11K chars) after the first `env`/`error` probes, turn 29 (~3.8K)
after the `Err(Error(...))` type-check rejection, turn 30 (~4.7K) reasoning
about the `parse_int` failure signal, and turn 37 (~3.2K) after the first `||`
parse misparse. These correlate exactly with the two friction clusters:
missing error constructor (task-envcfg-001, reproduced here) and unsupported
boolean operators with a misleading diagnostic (task-envcfg-003 +
handbook candidate). Thinking also shows deliberate oracle-correspondence
reasoning at turns 48–52 (failure controls and empty-vs-absent semantics),
which matches the 10/10 byte-exact result.

## Tool-error findings

Every nonzero Pi tool result in the structured `tool_errors` arrays (phase
`report.json` and worker `report.json`, both identical):

1. turn 28, tool `bash`, summary "(no output)\n\nCommand exited with code 1":
   `xsht api summary 2>&1 | grep -inE "fail|fatal|panic|abort|die|raise|throw|unreachable..."`
   — `grep` found no matches and exited 1. The underlying `xsht api summary`
   succeeded; this is an agent-side grep no-match inside the error-constructor
   search (part of the task-envcfg-001 gap), not an xsht failure.
2. turn 40, tool `bash`, summary "(no output)\n\nCommand exited with code 1":
   `xsht api summary 2>&1 | grep -nE "language \("` — same pattern: grep no-match
   during the `if`/operator discovery hunt; `xsht api summary` itself exited 0.

Manager session: zero tool errors.

Context (not in the structured arrays because the wrapping bash command exited
0, but transcribed discovery misses worth accounting for): the session also
issued several invalid or missing `xsht api` queries — `api:...` (invalid
KIND:VALUE at turn 6), `language.core.results` (invalid form at turn 11,
retried correctly as `language:core.results` at turn 16), `effect:error`
(unknown selector kind at turn 15), and missing targets `module:error`,
`module:core`, `language:error`, `language:results`, `record:Result`,
`record:Path`, `search:raise`, `search:abort`, `search:write_text`,
`api:fs.write_text`. These are discovery misses, not tool failures; the worker
recovered from all of them within the same or next turn. Final answer: the
structured arrays contain the two grep entries above; all other tool results
succeeded.

## Timing evidence

No strict candidate/oracle ratio gate for this eval (EVAL.md: "timing is
diagnostic until a stable envelope is established"). All ten cases ran in the
same ~11–13 ms process-launch envelope on both sides:

- public: candidate 12.29 ms / oracle 1.43 ms
- hidden_defaults: 11.06 / 11.84; hidden_partial: 13.32 / 11.18
- hidden_empty: 12.54 / 12.45; hidden_spaces: 13.27 / 13.02
- hidden_zero: 11.71 / 13.44; hidden_utf8: 11.24 / 11.77
- hidden_debug_false: 11.84 / 11.67; hidden_malformed: 11.80 / 11.14
- hidden_empty_port: 12.73 / 13.39

The single 1.43 ms `public_oracle_wall_ns` reading is a one-off outlier vs the
11–13 ms peers (likely launch-cache noise); with no gate it is ordinary noise,
not a signal.

## Observation classification

- Correctness (strong pass): candidate passed all 10 cases byte-exact
  (`run.json` `correctness.all_exact: true`), restriction checks
  (`env_referenced: true`, `forbidden_operations: true`), protocol
  (`artifact_present`, `review_ok`), and never produced the output file on the
  two failure controls (`hidden_malformed`, `hidden_empty_port` — empty
  candidate stdout, stderr traceback only, exit 3). The final `/work/envcfg.xsh`
  is 399 bytes after fmt, uses `env.get_or` + `?`, `Path.parse_bytes` +
  `Path.write`, and a decimal-integer guard — a minimal, deterministic,
  general solution, not a task hack.
- Worker friction, already ticketed (product gap): error construction. The
  worker spent ~20 turns probing `Err`, `Error(kind:)`, `FsError.NotFound`,
  `err(...)`, `abort`, `fail`, `raise`, `panic` before settling on
  `"".parse_int()?`, which fails with `parse-int: expected integer` on the
  failure path. This reproduces ticket `task-envcfg-001` (Open, originally
  detected at commit `defa805a`) at the current commit `ea7dea2f`; the gap
  persists. Not re-ticketed (already tracked); the report re-links it.
- Worker friction, new (product/tooling defect): misleading parse diagnostic
  for unsupported boolean operators. `if a || b { }`, `&&`, `|`, and
  `if ... then { }` all produced `expected '{' to start block` (caret on the
  present brace) or `expected statement terminator`, never naming the
  unsupported token. Reproduced four times (turns 37, 44, 45, 46). General
  ergonomics problem, not envcfg-specific → new ticket `task-envcfg-003`.
- Reusable handbook guidance (new): the approved handbook never documents
  boolean operators or `if` syntax; the worker found `or`/`and` only by
  probing seven candidates at turn 46. A one-sentence condition-operator
  lesson is a general, learnable addition → provisional handbook candidate
  staged (see `## Handbook decision`).
- Harness mismatch (evidence integrity, non-blocking): `run.json`
  `outputs.candidate_sha256` records `e3b0c44298...` — the SHA-256 of the
  empty string — while the evaluated artifact `/work/envcfg.xsh` hashes to
  `2cc3da5c...` and demonstrably contains the `env.`-referencing source that
  passed restriction and byte-exact checks. The manifest's candidate hash does
  not match the submitted program; correctness is unaffected (restriction and
  byte-exact checks are the pass gates), but the recorded hash is unreliable
  evidence. Notified here as a harness mismatch; not ticketed (factory
  evaluator infrastructure, not an XSH ergonomics defect).
- Ordinary noise: the single 1.43 ms oracle outlier; the two grep no-match
  exits; a few transient `xsht api` discovery misses (invalid/missing
  queries) that were recovered immediately.

## Handbook decision

Provisional candidate staged at
`runs/run-1785731807794/phases/03-eval/lineage/handbook-candidate.md`
(diff vs approved snapshot `c7c9dd9a…`: exactly one added block in
`## Streams and collections`):

> Conditions compose with the word-form boolean operators `or` and `and` (not
> `||` / `&&`), and `if` takes `COND { ... }` with no `then` keyword:
> `if port == "" or port.delete("0123456789") != "" { ... }`

General lesson: XSH conditions use word-form boolean operators and a
`COND { }` shape without `then`. This is reusable across every future eval
with conditional logic (validation branches, where-block predicates, guard
clauses), not an envcfg recipe. Replay scope before promotion:
(a) next-cycle replay of `task-envcfg` should show the worker writing `or`/
`and` with no `||` misparse; (b) at least one other relevant eval (task-tags,
task-ecount) that composes conditions should replay the same sentence before
the handbook is promoted to `runtime/handbook.md`. No eval-local handbook
exists or was created; only the run lineage candidate was written. The
approved snapshot and checked-in `runtime/handbook.md` were not modified.

## Tickets created

- `tickets/task-envcfg-003.md` (Open; next-cycle). One strong reproducible
  observation: the parser diagnostic for unsupported `||`/`&&`/`then`
  misattributes the error to the block brace and never names the supported
  word-form operators, costing ~10 session turns. Links eval `task-envcfg`,
  this manager run, executor worker `task-envcfg-1` (trial 1), handbook
  lineage `runs/run-1785731807794/phases/03-eval/lineage/handbook-approved.md`,
  and XSH baseline `ea7dea2f2b436cce34262d7a02105cbb029243dd`. Template
  merge-record placeholders left unchanged.

No ticket for the reproduced error-constructor gap (`task-envcfg-001` already
Open) or the compact-runtime mismatch (`task-envcfg-002` already Open).

## Post-merge decisions

None. The reconciler found no merged ticket files for this run, and the
candidate reevaluation is `not-reevaluation` with no engineer worktree.

## Next replay

Eval `task-envcfg` against the next cycle's XSH commit using
`runs/run-1785731807794/phases/03-eval/lineage/handbook-candidate.md` as the
input snapshot. Checks: (1) all 10 oracle cases pass byte-for-byte; (2) if
`task-envcfg-001` merges, the malformed-port path uses a documented error
constructor with no fake host call or `parse-int` traceback on the failure
path; (3) if the handbook candidate is still staged, the worker session
contains no `expected '{' to start block` misparse and no operator probe loop;
(4) if `task-envcfg-002` merges, no `compact-unsupported-main` failed run
regardless of `main` parameter form. A second non-envcfg eval (task-tags or
task-ecount) should replay the condition-operator sentence before promotion
to `runtime/handbook.md`.

## North-star impact

The run shows the environment/config surface is genuinely discoverable: the
worker hit `module:env` and `env.get_or` on the first queries, composed
`Path.parse_bytes` + `Path.write` from exact API contracts, and delivered a
10/10 byte-exact, restriction-clean config renderer with clean stdout and
loud, no-file failure. That is the north-star shape: typed, explicit
boundaries that an agent can learn once. The two friction clusters are both
general ergonomics gaps, not task noise: a language that cannot originate a
typed `Error` forces opaque fake-host-failure workarounds (ticket 001), and a
parser that blames a present `{` for an unsupported `||` wastes agent turns and
erodes trust in diagnostics (ticket 003). The staged handbook sentence makes
the `or`/`and`/`if` grammar teachable in one line instead of ten probing
turns, directly serving learnability and AI efficiency. The manifest
candidate-hash mismatch is flagged so the factory's evidence trail stays
trustworthy for future replays.
