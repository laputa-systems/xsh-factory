# Eval-manager report

## Result

pass

## Effort metrics

One trial (controller-completed), one worker `task-envcfg-1` at
`runs/run-1785728831509/phases/03-eval/workers/eval-worker/task-envcfg-1/`.

- assistant turns: 65; tool calls: 65; tool results: 65; tool errors: 2;
  user messages: 1; stop reasons: 1 `stop`, 64 `toolUse`.
- session span: 312,090 ms (Pi conversation; worker wrapper `agent_wall_ms`
  313,726); no budget failure (budget 0.50 USD).
- worker friction: the two failed runs (`compact-unsupported-main`) plus a
  ~30-turn discovery arc (turns 12–42) hunting for an `Error` constructor and
  digit validation before falling back to the intended `env.int` natural-error
  path, and ~10 turns (47–56) diagnosing the compact-runtime main-signature
  failure. Both frictions are generalizable (see Observation classification);
  neither blocked correctness.

## Usage and cost

Provider-reported per worker `report.json` / phase `report.json`:

- tokens: input 56,305; output 25,166; cacheRead 1,592,896; cacheWrite 0;
  provider total 1,674,367; bucket total 1,674,367 (consistent; no
  malformed lines).
- reasoning tokens: 16,561 (provider-reported subset of output).
- cost: input 0.00506745; output 0.00452988; cacheRead 0.028672128; total
  0.038269458 USD. Aggregate equals the single worker; no unknown costs.
- budget 0.50 USD; no breach. Provider `openrouter/deepseek/deepseek-v4-flash-0731`.

## Thinking evidence

58 thinking blocks recorded; provider reported 16,561 reasoning tokens (so
token-level counts are available and are a subset of output). Transcript
grounding in `thinking.md`/session JSONL:

- Blocks 1–6: read task/handbook, probe `module:env`, `api:env.get_or`,
  `api:env.int`, `api:env.bool`; identify present-but-empty semantics.
- Blocks 7–42 (largest arc): digit-validation and `Error`-constructor search —
  `Str`/regex probes, `Err("msg")` typing, `Error(kind:...)` removal message,
  `FsError.NotFound` unresolved-name, `search:fail`/`abort`/`panic`, `Result.context`,
  `Str.parse_int`. Conclusion reached in-block: construct no custom error;
  propagate `env.int`'s natural error.
- Blocks 43–56: build script, run harness; after the two runtime tool errors,
  the worker isolates the trigger to the plain `argv: List[Str]` main
  parameter and confirms the rest/spread form fixes it (positive control
  `/tmp/m4.xsh`, rc=0).
- Blocks 58–65: `xsht check`/`fmt`/`lint` clean, full 10-case verification,
  review.md written.

The thinking correlates with the observed friction: the long error-constructor
arc matches the open ticket `task-envcfg-001` gap, and the post-error thinking
matches the compact-runtime diagnosis recorded in review.md.

## Tool-error findings

Both nonzero Pi tool results from the structured arrays (phase
`data.tool_errors` and worker `report.json` `tool_errors`; worker session
JSONL lines 98 and 104 are the `isError: true` results):

1. turn 47 — `bash` running `xsh /work/envcfg.xsh /tmp/ours`:
   `err[runtime.compact-unsupported-main]: proc main could not run in the
   compact runtime` at `/work/envcfg.xsh:1:1`
   (`proc main(argv: List[Str]) [env, fs, error] -> Result[Unit]`), rc=3.
2. turn 50 — `bash` running `xsh /tmp/m2.xsh /tmp/out2`:
   `err[runtime.compact-unsupported-main]` at `/tmp/m2.xsh:1:1`
   (`proc main(argv: List[Str]) [fs, error] -> Result[Unit]`), rc=3.

Both share one root cause: the compact runtime rejects a plain (non-rest)
`main` argument parameter after `xsht check` accepted the source; the message
does not name the required `...argv` form. No other failed Pi tool results
exist in the worker session, and the manager session has zero tool calls.
Several invalid `xsht api` discovery queries (e.g. `topics:string`,
`language:Str`, `language:results` vs `language:core.results`, `module:result`)
returned exit-0 text inside compound bash commands, so they are not structured
tool errors; they are recorded as discovery friction below.

## Timing evidence

`run.json` timings (candidate vs oracle wall ns per case, no strict ratio
gate per EVAL.md — both sides finish in milliseconds):

- public: 11,383,408 vs 11,275,534
- hidden_defaults: 10,962,284 vs 11,134,658
- hidden_partial: 11,034,034 vs 13,268,657
- hidden_empty: 14,209,240 vs 14,472,198
- hidden_spaces: 11,136,992 vs 10,980,201
- hidden_zero: 11,495,158 vs 12,053,282
- hidden_utf8: 11,042,284 vs 14,021,948
- hidden_debug_false: 14,089,115 vs 15,615,780
- hidden_malformed: 12,192,657 vs 12,038,450
- hidden_empty_port: 13,471,490 vs 12,783,866

Candidate 10.9–14.2 ms, oracle 10.9–15.6 ms; no case diverges meaningfully.
Timing is diagnostic only; `timing: pass`.

## Observation classification

- Correctness — pass (not noise): all 10 cases byte-exact
  (`correctness.all_exact: true`), candidate stdout empty
  (`candidate_sha256 = e3b0…` = SHA-256 of empty stdout, matching the
  clean-stdout contract), failure controls exit nonzero with no output file
  (`candidate.9/.10.stderr` show `env-int: environment value is not an
  integer`; oracle likewise), restrictions pass (`env.` referenced, no
  subprocess boundary), `review.md` valid.
- Product/tooling defect — compact-runtime main signature mismatch
  (reproducible, general): the two `runtime.compact-unsupported-main` errors.
  `xsht check` accepts `proc main(argv: List[Str])`, `xsh SCRIPT` rejects it
  at run time with a non-actionable message; rest/spread `...argv` works.
  Generalizes to every argv-taking script/eval. Opened as
  `tickets/task-envcfg-002.md` (one strong reproducible observation; distinct
  from `task-ecount-002`/`006` indexed-IR triggers).
- Reusable handbook guidance — rest/spread `main` requirement: the handbook's
  main example already shows `...argv` but does not warn that the plain form
  passes check yet fails at run time; the worker burned ~10 turns discovering
  it. Staged one-sentence candidate at
  `runs/run-1785728831509/phases/03-eval/lineage/handbook-candidate.md`.
- Worker friction / already-tracked gap — `Error` construction: ~30 turns
  (12–42) searching for a public `Error` constructor (`Err("msg")` →
  `Result[_, Str]`, `Error(kind:...)` removed, `FsError.NotFound` unresolved)
  before using the intended natural `env.int` error. This is the same gap as
  open ticket `task-envcfg-001`; not re-ticketed.
- Worker friction / discovery noise — `xsht api` query-syntax confusion
  (`language:results` vs `language:core.results`, `topics:`/`language:Str`
  probes, `module:result` missing): exit-0 text inside bash, not structured
  errors; cost several turns but the handbook already documents `KIND:VALUE`
  syntax, so no handbook change is proposed for it.
- Residual risk, not gating — `env.int` accepts `+5`/`-5` and normalizes
  `007` while the oracle rejects signed forms and preserves zero-padding; the
  hidden cases do not exercise those, so the eval passes. If future cases add
  signed/whitespace ports, the agent would need manual digit validation,
  which is currently blocked by the `Error`-construction gap
  (`task-envcfg-001`). Flagged for the eval designer, not a ticket.

## Handbook decision

Provisional candidate staged unchanged-at-approved-plus-one-sentence at
`runs/run-1785728831509/phases/03-eval/lineage/handbook-candidate.md`
(diff vs approved is exactly the addition). General lesson: "a command-line
`main` that takes arguments must use the rest/spread form `...argv`; the
plain `proc main(argv: List[Str])` passes `xsht check` but fails at run time
with `compact-unsupported-main`." This is a short, general rule (not a
recipe) that removes repeated agent friction across any argv-taking eval.
Replay scope before promotion: next `task-envcfg` cycle (worker should write
`...argv` first-try with zero `compact-unsupported-main` runs) plus one other
argv-taking eval (task-tags or task-ecount) to confirm generality; promotion
requires human approval.

## Tickets created

- `tickets/task-envcfg-002.md` (Open) — compact-runtime `main` signature
  mismatch: check accepts plain-parameter main, `xsh SCRIPT` fails at run
  time with non-actionable `compact-unsupported-main`; proposed smallest fix
  (support plain form, or reject in check / actionable runtime message).
  Merge-record placeholders left untouched for the reconciler.
- No duplicate for the `Error`-construction gap: already tracked by open
  ticket `tickets/task-envcfg-001.md`.

## Post-merge decisions

None. The controller reconciler reported no merged ticket files
(`none`); there are no post-merge acceptance assignments this cycle.

## Next replay

- Eval: `task-envcfg` (`evals/task-envcfg/EVAL.md`).
- Handbook lineage: replay with `runs/run-1785728831509/phases/03-eval/lineage/handbook-candidate.md` and confirm the worker writes
  `proc main(...argv: List[Str])` first-try, produces zero
  `compact-unsupported-main` runs, and still passes 10/10.
- Post-merge/falsification checks: when `task-envcfg-002` merges, replay
  task-envcfg against the merged XSH commit to verify no
  `compact-unsupported-main` occurs regardless of main form; when
  `task-envcfg-001` merges, verify the malformed-port path uses a documented
  `Error` constructor with no fake host-call traceback. Also re-run one
  argv-taking eval (task-tags or task-ecount) on the candidate handbook
  before promotion.

## North-star impact

This run validates the eval's north-star hypothesis: the agent discovered the
`env` module (`env.get_or` present-but-empty semantics, `env.int` natural
validation error, `fs.write`, clean stdout) and produced a byte-exact config
file for all ten cases — evidence that the environment/config surface is
discoverable and composable with the current handbook. The run also surfaced
two durable lessons: (1) a real ergonomics defect — the compact runtime's
`main` signature restriction is invisible to `xsht check` and its runtime
message is non-actionable, costing every future argv-taking agent a failed
run (ticket `task-envcfg-002`, with a one-sentence handbook candidate staged
for replay); (2) confirmation of the already-tracked `Error`-construction gap
(`task-envcfg-001`). Both directly serve the north-star goals of ergonomics,
learnability, and trust: fewer guesses, clearer boundaries, and a language
whose checker and runtime agree about entry points.
