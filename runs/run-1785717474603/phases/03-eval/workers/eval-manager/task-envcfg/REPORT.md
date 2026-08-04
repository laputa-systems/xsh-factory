# Eval-manager report: `task-envcfg`

- Phase run: `runs/run-1785717474603/phases/03-eval/`
- Worker: `workers/eval-worker/task-envcfg-1` (trial 1, single-trial plan)
- XSH commit under test: `de9880ce9cd13c4ef63acc212554d786358ed869`
- Handbook snapshot under review: `lineage/handbook-approved.md`
  (sha256 `c7c9dd9abb6d50dac60562757a1824900f24d4bc2d38014d5cbf869f56bb0723`)
- Reconciled merged tickets: none (post-merge acceptance: none)

## Result

pass

The single fresh trial passed on all gates. `run.json` reports
`classification: pass`, `correctness.all_exact: true` (10/10 cases including
both failure controls), `restrictions.passed: true` (source references `env.`,
no forbidden subprocess boundary), `protocol.review_ok: true`, and
`timing: pass`. Candidate stdout was empty for every case (SHA-256
`e3b0c442...`, the empty-input digest, matching the file-deliverable
contract); failure cases 9/10 exited nonzero with no output file and only a
stderr traceback. The phase `report.json` currently shows `result: fail` only
because the manager report, director report, and handbook candidate were
missing at controller time; this report and the staged candidate resolve the
manager-owned findings. The director report is outside this role.

## Effort metrics

Single trial (trial 1), one worker session.

- Assistant turns: 97 (`stop` 1, `toolUse` 96)
- Tool calls: 106; tool results: 106; tool errors: 5
- Tool mix: bash 94, write 8, read 3, edit 1
- Session span (Pi conversation): 537,840 ms (~8.96 min); wrapper
  `agent_wall_ms` 539,600 ms
- User messages: 1
- Budget: USD 0.5 cap, `budget_state: pass`, no breach
- Worker friction: high. The two dominant sinks were (a) the
  error-construction search (roughly session turns 50–126, ~25 API/source
  probes: `Err("...")`, `Error{...}`, `FsError.NotFound`, `EnvError.*`,
  `panic`/`fail`/`raise`, `record:Error`) before settling on the
  `"x".parse_int()` workaround, and (b) match-arm `if/else` expression
  syntax (turns ~132–190, multiple parse/type-check iterations) before the
  final helper-proc structure. Path construction from a runtime `argv` value
  cost three probes (`p$argv[0]`, `p(...)`, then `Path(...)` and the
  lint-preferred `fp"${...}"`). These are the same class of discovery cost
  that the handbook exists to remove.

## Usage and cost

Provider: `openrouter/deepseek/deepseek-v4-flash-0731` (model id per worker
report; one worker).

- input tokens: 273,147 (USD 0.02458323)
- output tokens: 34,776 (USD 0.00625968)
- cacheRead tokens: 2,795,584 (USD 0.050320512)
- cacheWrite tokens: 0 (USD 0)
- bucket total: 3,103,507 = provider-reported `totalTokens` 3,103,507
  (buckets reconcile exactly)
- reasoning tokens: 22,142 (provider-reported, a subset of output; never
  added to totals)
- cost total: USD 0.081163422; per-trial USD 0.081163422; aggregate
  USD 0.081163422 (1 trial). `unknown_costs: 0`, `malformed_lines: 0`.
- Per-turn cost is not a goal; correctness and clarity held (10/10 exact,
  lint-clean source), so the token spend is interpreted as fluency evidence:
  high session length concentrated in the two discovery loops above.

## Thinking evidence

- Thinking blocks: 74; provider-reported reasoning tokens: 22,142
  (reasoning counts were reported for this model; they are a subset of
  output).
- Trajectory (grounded in `session.jsonl.bz2` thinking blocks and tool calls):
  early turns confirmed `env.get_or`/`env.int`/`env.bool` and `fs.write`
  contracts via `xsht api` (`api:env.get_or`, `api:env.int`, `api:env.bool`,
  `api:fs.write` all exact); block at session line 25 correctly reasoned the
  `${VAR-default}` absent-vs-empty semantics and tested `CFG_HOST=` (present
  empty kept, absent defaulted) in one probe; blocks 28/48 correctly rejected
  `env.int` as a port validator because it normalizes `"007"`/`"-5"` instead
  of preserving raw bytes; the long error-construction search (blocks around
  lines 73–126) tested every plausible constructor and ended in the
  `parse_int` propagation hack; blocks around lines 133–190 debugged
  `if/else`-in-`match` parsing, `ignored Result`, and `missing-return` until
  helper procs type-checked; final verification loop compared against a local
  copy of the oracle across 8+ environment shapes and checked
  stdout/stderr/file-creation on failure.
- The review artifact (`review.md`) independently records the two friction
  findings (no generic `Error` constructor; statement/expression ambiguity
  with `if/else` in match arms and end-of-proc bodies), matching the
  transcript evidence.

## Tool-error findings

Structured `tool_errors` (worker `report.json` and phase `report.json`,
all 5 accounted for):

1. turn 8, `bash` exit 1, no output — `xsht api language:str | grep -iE
   "regex|match|..."`; wrong query kind (`language:str` is not an index id)
   plus grep no-match. Discovery friction, not a product error.
2. turn 9, `bash` exit 1, no output — `xsht api module:Str | grep -iE ...`;
   `module:Str` is `missing` (type receivers are queried as `method:...`),
   grep no-match. Same class.
3. turn 24, `bash` exit 2 — `let p = p$argv[0]`; parser: expected statement
   terminator; `$name` is command-word syntax, use `name` in expression
   context. Corrective diagnostic during path-construction discovery.
4. turn 25, `bash` exit 2 — `let p = p(argv.get(0, "/tmp/out3.cfg"))`;
   `check.unresolved-call` (no `p(...)` constructor). Part of the same
   runtime-Path discovery sequence (resolved by `Path(...)`, then
   `fp"${...}"`).
5. turn 62, `bash` exit 127 — `sh: python3: not found`. Worker attempted to
   parse `xsht api summary --format jsonl` with python3; the image has no
   language runtimes (handbook already says so). Worker noise, avoidable.

Failed `xsht api` discovery queries observed in the session that were not
`isError` tool results (returned as text, so absent from the structured
arrays): 7 invalid-query results (`method:Str`, `Str`,
`Path constructor`, `search:path from string`, `path`,
`search:error create`, `search:panic error`) and 19 `status: missing`
probes (`module:Str`, `method:Str.len`, `method:Str.chars`, `module:str`,
`language:results`, `language:procs`, `language:postfix-question`,
`language:error` x2, `language:path-literals`, `language:core.match`,
`language:core.`, `language:core.error`, `record:Error`, `search:EnvError`,
`search:FsError` x2, `search:error variant`, `search:NotFound`). The
valid identifiers the worker eventually needed were
`language:core.path-literals`, `language:core.results`,
`language:core.fallback`, `language.effect.error`; the handbook's api
section does not teach these identifier shapes or that `search:` takes one
term. One targeted handbook addition is staged (see Handbook decision).

No manager-session tool errors (manager performed read-only inspection).

## Timing evidence

Evaluator `run.json` timings (candidate vs oracle wall ns per case):

- public 11,372,029 / 12,339,028
- hidden_defaults 11,162,696 / 12,987,069
- hidden_partial 13,110,652 / 11,184,029
- hidden_empty 13,188,818 / 12,123,153
- hidden_spaces 13,492,193 / 13,193,026
- hidden_zero 13,225,777 / 11,384,195
- hidden_utf8 11,299,945 / 12,320,944
- hidden_debug_false 13,139,277 / 13,172,818
- hidden_malformed 13,188,193 / 13,530,818
- hidden_empty_port 13,176,943 / 12,930,777

Both sides finish in ~11–13.5 ms; no case is out of envelope and this eval
has no strict candidate/oracle ratio gate (EVAL.md: timing is diagnostic).
On the two failure controls both programs exit nonzero (oracle 1, candidate
3); the contract is "exit nonzero and no output file", which the candidate
meets. No timing-based finding.

## Observation classification

- Correctness: pass. 10/10 byte-exact, including `hidden_empty` (present-but-
  empty preserved), `hidden_zero`, `hidden_utf8`, and both failure controls.
- Restriction: pass. Source references `env.`; no `run`/spawn/shell; stdout
  clean.
- Worker friction → reusable handbook guidance (staged candidate):
  runtime Path construction. `p"..."` literals do not interpolate; the worker
  needed a Path from `argv[0]` and burned three probes and two tool errors
  before `Path(...)` (cast) and the lint-preferred `fp"${...}"` worked. This
  generalizes to every CLI eval that takes a path argument.
- Worker friction → product/tooling defect (already ticketed, reproduced):
  no generic `Error` constructor and no clean way to originate a deliberate
  failure. Reproduced in-session: `Err("msg")` types as `Result[<unknown>,
  Str]`; `Error{...}` is a parse error; `FsError.NotFound("x")` fails
  `compact.indexed-build`; `env.EnvError.Conversion("oops")` passes
  `xsht check` (check=0) but fails at runtime with "dynamic call expected
  Pure or Proc, found Result" — a checker/runtime inconsistency. The final
  solution propagates an unrelated `"x".parse_int()` failure, emitting
  `error: parse-int: invalid integer \`x\`` on the failure path — an
  opaque, boundary-hiding workaround exactly as the north star warns
  against. This is the same observation already captured by Open ticket
  `task-envcfg-001` (previous run `run-1785687503942`, baseline
  `defa805a`); this run adds a second reproduction with a different
  workaround variant.
- Worker friction → product/tooling defect (secondary, weaker evidence):
  statement/expression ambiguity for `if/else` in match arms and proc bodies
  (`expected record field` at session line 132, `ignored-result` /
  `missing-return` at line 162/186). The worker review also claims
  `xsht fmt` strips parentheses around an `if/else` used inside a match arm,
  producing a file that no longer type-checks; transcript evidence shows the
  parse fragility but not a clean before/after fmt repro, so I do not open a
  second ticket on this cycle.
- Worker friction → noise: grep exit-1 probes (turns 8/9) and the python3
  attempt (turn 62); the handbook already warns about language runtimes.
- Evaluator/harness mismatch: none. Candidate stdout hash `e3b0c442...`
  (empty) is correct for a file deliverable; failure-case stderr traceback is
  an expected consequence of the `?` propagation mechanism, not a harness
  artifact.
- Timing: ordinary diagnostic (see Timing evidence).

## Handbook decision

Provisional candidate staged at
`lineage/handbook-candidate.md` (copy of the approved snapshot plus three
short additions):

1. In `Paths and filesystem values`: runtime Path construction — `p"..."`
   literals do not interpolate; build a Path from data with the interpolated
   path string `fp"${expr}"` (lint-preferred) or the `Path(expr)` cast.
2. In `Effects and errors`: deliberate validation failures are expressed by
   propagating an expected failure from a typed conversion (for example
   `env.int(...)?` or a `parse_int` result), since this build has no generic
   `Error(...)` constructor.

A third one-sentence clarification goes into `Development loop and tooling`: `xsht api search:` accepts one term and language-rule ids live under `language:core.*` and `language.effect.*`. The candidate is a hypothesis;
promotion requires replay plus human approval.

## Tickets created

zero.

No new ticket: the strong reproducible product observation (no generic error
constructor; checker accepts `env.EnvError.Conversion(...)` that fails at
runtime) is already captured by Open ticket
`tickets/task-envcfg-001.md`. This run strengthens its evidence with a second
session reproduction (this worker's `"x".parse_int()` hack and the
`env.EnvError.Conversion("oops")` check-pass/runtime-fail probe at session
lines 117–126). The weaker fmt/parens observation is recorded in this report
for a future cycle but does not meet the one-strong-ticket bar this run.

## Post-merge decisions

None. The reconciler reported merged ticket files: `none`. No post-merge
acceptance assignment was in scope.

## Next replay

Replay `evals/task-envcfg` (trial 1, exact same harness) on the next cycle's
XSH commit with the staged handbook candidate. Success criteria for the
candidate: (a) the worker builds the output Path from `argv[0]` in one or two
probes (`fp"${...}"` or `Path(...)`) instead of the `p$argv[0]`/`p(...)`
sequence; (b) the malformed-port path is written as a single propagated
failure without the error-constructor research loop; (c) all 10 oracle cases
still pass byte-for-byte and the failure cases keep stdout clean with no
output file. Post-merge check for `task-envcfg-001`: when its implementation
commit lands, replay this eval and verify the failure path uses a documented
constructor with no fake/failing host call. Falsification check for the
secondary fmt/parens claim: a replay task that puts an `if/else` expression
inside a `match` arm, formatted then re-checked.

## North-star impact

The run advances the north star on two fronts. First, it confirms the env
surface is discoverable: with the approved handbook plus `xsht api`, the
worker found `env.get_or`/`env.int`/`env.bool`/`fs.write` exact contracts
within the first minutes and reasoned correctly about absent-vs-empty
defaults, so practical systems-glue capability (typed config from the
environment, file deliverable) is achievable. Second, it shows the language's
failure boundary is not yet trustworthy: a validation program cannot
originate a clean `Error`, and the checker accepts a construction
(`env.EnvError.Conversion("oops")`) that dies at runtime, forcing the agent
to propagate an unrelated `parse-int` failure whose stderr message names the
wrong value (`invalid integer \`x\``). That is precisely the opacity the
north star wants removed. The staged handbook candidate removes two
repeated-discovery costs (runtime Path construction, deliberate-failure
idiom) for every future eval, and the reproduced Open ticket gives the
implementation cycle a concrete, evidence-backed fix target whose acceptance
is testable by this eval's next replay.
