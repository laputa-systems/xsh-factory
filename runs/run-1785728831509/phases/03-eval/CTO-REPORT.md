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
  - Turns: `22`; bucket tokens: `888474`; thinking blocks: `21`
  - Tool errors: `1`; cost: `0.015853`; budget: `0.150000`
- `eval-worker/task-envcfg-1` (`eval-worker`): result `pass`; report `workers/eval-worker/task-envcfg-1/report.json`
  - Execution: `pass`; classification: `pass`
  - Turns: `65`; bucket tokens: `1674367`; thinking blocks: `58`
  - Tool errors: `2`; cost: `0.038269`; budget: `0.500000`


### Nonzero tool results

- `eval-manager/task-envcfg`, turn `17`, tool `bash`: 45a46,50
> The `xsh SCRIPT` compact runtime only runs `main` with no parameters or with
> the rest/spread form. A plain `proc main(argv: List[Str])` passes `xsht
> check` but fails at run time with `error: compact-unsupported-main` (rc=3).
> Declare a command-line main that takes arguments with `...argv`.
> 


Command exited with code 1
  - Structured report: `workers/eval-manager/task-envcfg/report.json`
- `eval-worker/task-envcfg-1`, turn `47`, tool `bash`: err[runtime.compact-unsupported-main]: proc main could not run in the compact runtime
  /work/envcfg.xsh:1:1
  proc main(argv: List[Str]) [env, fs, error] -> Result[Unit] {
  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
runtime traceback
executable: /usr/local/bin/xsh
operation: main
error: compact-unsupported-main: proc main could not run in the compact runtime
rc=3
--- stderr ---
err[runtime.compact-unsupported-main]: proc main could not run in the compact runtime
  /work/envcfg.xsh:1:1
  proc main(argv: List[Str]) [env, fs, error] -> Result[Unit] {
  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
runtime traceback
executable: /usr/local/bin/xsh
operation: main
error: compact-unsupported-main: proc main could not run in the compact runtime
--- file ---


Command exited with code 1
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`
- `eval-worker/task-envcfg-1`, turn `50`, tool `bash`: err[runtime.compact-unsupported-main]: proc main could not run in the compact runtime
  /tmp/m2.xsh:1:1
  proc main(argv: List[Str]) [fs, error] -> Result[Unit] {
  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
runtime traceback
executable: /usr/local/bin/xsh
operation: main
error: compact-unsupported-main: proc main could not run in the compact runtime
rc=3


Command exited with code 1
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`


### Cycle total

- Workers: `2`
- Assistant turns: `87`
- Bucket tokens: `2562841`
- Cost (USD): `0.054123`
- Nonzero tool results: `3`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-manager/task-envcfg

- Role: `eval-manager`
- Result: `pass`
- Report: `workers/eval-manager/task-envcfg/REPORT.md`

#### Efficiency and evidence

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

#### Handbook or proposal decision

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

#### Ticket or product decision

- `tickets/task-envcfg-002.md` (Open) — compact-runtime `main` signature
  mismatch: check accepts plain-parameter main, `xsh SCRIPT` fails at run
  time with non-actionable `compact-unsupported-main`; proposed smallest fix
  (support plain form, or reject in check / actionable runtime message).
  Merge-record placeholders left untouched for the reconciler.
- No duplicate for the `Error`-construction gap: already tracked by open
  ticket `tickets/task-envcfg-001.md`.

#### Next action

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

#### North-star impact

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



## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` (required; next CTO must
  validate or revert it before paid work)
