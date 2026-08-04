# Eval-manager report — task-envcfg

Run `run-1785804030340` phase `03-eval`, single fresh trial.
XSH commit under test: `5cee79306e2ce8c12fbd5b8575ff7accfcc5c82f`.
Approved handbook snapshot: `lineage/handbook-approved.md`
(`97c5d804…`, matches `runtime/handbook.md` and the run's recorded
`handbook_sha256`). Reconcile record: controller reported `none` merged
tickets, so this cycle carries no post-merge acceptance assignment.

## Result

pass

## Effort metrics

One trial, worker `eval-worker/task-envcfg-1`:

- assistant turns: 30 (1 user message, 1 normal stop, 29 toolUse stops)
- tool calls: 39 (32 bash, 4 read, 2 write, 1 edit); tool results: 39
- structured tool errors: 5 (all worker-side test-harness friction; none in
  the submitted artifact, none from `xsht api` discovery)
- session span: 133,053 ms; agent wall: 134,391 ms
- final artifacts present: `work/envcfg.xsh` (546 B), `work/review.md`
  (1178 B, both headings, no placeholders)

`envcfg.xsh` reads `CFG_HOST/CFG_PORT/CFG_DEBUG` via `env.get_or` (absent-only
default), validates `CFG_PORT` as a non-empty run of decimal digits before
`fs.write`, and forces a nonzero exit on malformed port (no output file). All
`xsht check` / `fmt` / `lint` pass; the worker's own 14-case differential
harness and the evaluator both report all cases PASS.

## Usage and cost

Provider `openrouter`, model `deepseek/deepseek-v4-flash-0731`, thinking `high`.

- input tokens: 20,937; output tokens: 12,055; cacheWrite: 0;
  cacheRead: 403,200; total bucket/provider: 436,192
- reasoning tokens: 6,475 (provider-reported this run)
- cost: total $0.01131183; input $0.00188433; output $0.0021699;
  cacheRead $0.0072576; cacheWrite $0; budget $0.50 (no breach)
- malformed usage lines: 0; unknown cost fields: 0
- single-trial aggregate equals the worker totals above.

## Thinking evidence

25 thinking blocks recorded (provider reported 6,475 reasoning tokens, a
subset of output). Thinking text shows the agent intentionally chose
`parse_int`-independent digit validation over `env.int` once it verified
`env.int`/`parse_int` accept `-5`, `+5`, and ` 5` (`msg34`), preserving
byte-exact output; it also reasoned past two false FAIL results from its own
test harness (streams merged, exact-exit-code compare) after confirming the
real failure-control behavior (nonzero exit, no file, clean stdout, `msg59`).
Reasoning is consistent with the final correct artifact.

## Tool-error findings

All 5 nonzero Pi tool results are `bash` wrapper errors in the worker's own
scratch/test sessions; none is an `xsht api` discovery failure and none
involves the submitted artifact:

1. `turn 6` (`msg23`): `err[parse.expected-token]: expected => in match arm`
   — the agent explored a `match` on `Result` that used `->` arm syntax; the
   language requires `=>`. Ordinary language-learning friction; the match
   approach was not used in the final solution.
2. `turn 13` (`msg38`): `err[check.standard-module-shadow]: name 'path'
   shadows the standard module 'path'` — a deterministic, reproducible checker
   restriction when a variable is named `path`; the agent renamed to
   `out_path`. Basis for the handbook candidate.
3. `turn 20` (`msg53`): `sh: export: line 0: illegal option -f` — BusyBox `sh`
   rejected `export` usage in the agent's throwaway harness; noise.
4. `turn 21` (`msg55`): worker harness reported `FAIL ... exit oracle=1 xsh=3`
   — the agent's self-harness required an exact exit code of 1, stricter than
   the eval contract (nonzero). Over-strict self check; noise.
5. `turn 22` (`msg57`): worker harness flagged failure-control cases because
   its run merged stderr into stdout (runtime traceback seen "on stdout");
   the real evaluator keeps stdout clean (candidate `*.stdout` 0 B, traceback
   on `*.stderr`). Noise; the agent verified the true behavior and proceeded.

The structured `tool_errors` arrays account for exactly these five.

## Timing evidence

No strict candidate/oracle timing gate (eval contract: diagnostic only; both
sides finish in milliseconds). All ten timings land in ~11–16 ms on both
sides with no ratio breach, e.g. `public` candidate 13,065,346 ns vs oracle
13,014,887 ns; failure controls also comparable and correctly nonzero. No
timing signal.

## Observation classification

- Correctness (pass): candidate matches oracle byte-for-byte on all ten cases
  including the two failure controls and the UTF-8/`us east 1`/empty cases —
  genuine product signal that the `env`/`fs`/`Result?` surface is
  discoverable and composable as staged.
- Reusable handbook guidance: the `path` module-shadow rejection (tool error 2)
  is a single, deterministic, reproducible restriction that will recur for any
  filesystem agent that names a variable `path`; it is actionable but only
  discoverable from the error text. Staged as a concise general handbook
  candidate.
- Worker friction (noise): tool errors 1, 3, 4, 5 are the agent's own
  exploration/harness artifacts (match-arm syntax, BusyBox `sh` misuse,
  over-strict exit-code compare, merged-stream capture). Not product or
  evaluator defects.
- Harness metadata (minor note, not a ticket): `evaluate_legacy.xsh` records
  `candidate_sha256` as the SHA-256 of `candidate.1.stdout`, which for this
  file-deliverable eval is intentionally empty, so the recorded hash
  (`e3b0c44…`, the empty-string digest) does not identify the source
  artifact. Correctness is still established by the byte-for-byte file
  comparison; this is metadata-only and does not affect the decision.
- API discovery: the agent used exact `api:env.*`, `api:fs.write`,
  `method:Str.*` queries correctly; `search:is_ok` and `search:match_stmt`
  returned `missing`/unhelpful results but were recovered from other
  `language:core` searches. Minor, non-blocking.

## Handbook decision

Provisional candidate: `lineage/handbook-candidate.md` = approved snapshot
plus one sentence in "Paths and filesystem values": do not shadow a standard
module name with a local binding (`xsht check`/`lint` reject it, e.g. `let
path = ...`); use a distinct name such as `out_path`. General lesson: local
bindings must not shadow standard module names. Replay scope: task-envcfg and
task-ecount (both path/filesystem-heavy) before promotion to
`runtime/handbook.md`.

## Tickets created

None. The `path` shadowing finding is best served as a concise handbook
candidate; the absent generic `Error`/`raise` constructor is already
documented in the approved handbook and is a deliberate design state, not a
surprising defect. The empty-`candidate_sha256` harness quirk is metadata-only
and does not warrant a ticket this cycle.

## Post-merge decisions

None — the reconciler reported no merged tickets for this cycle.

## Next replay

Replay `task-envcfg` against `lineage/handbook-candidate.md` (single trial) to
confirm the shadowing note and the env-config path still pass; cross-check the
same handbook candidate on `task-ecount` to validate the general path-handling
lesson. Promotion to `runtime/handbook.md` requires CTO approval after those
replays.

## North-star impact

The run validates the core hypothesis that the environment/config surface
(`xsht api module:env`, `env.get_or`, typed helpers, `fs.write`, postfix `?`
propagation) is discoverable and composable — a practical sysadmin workflow
NOT covered by existing evals, with exact byte output and a loud malformed-value
failure. It produced no product defect. The staged handbook candidate improves
learnability/ergonomics for filesystem naming so future path-handling agents
avoid a deterministic linter rejection, advancing the learnable, ergonomic,
trustworthy XSH that the north star calls for.
