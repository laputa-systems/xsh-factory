# CTO briefing 04-eval

This is the deterministic first-pass briefing for the CTO. The structured
`report.json` files and raw Pi sessions remain the source of truth.

## Result

pass
## Result

pass

## Outcome dimensions

- Product: `pass`
- Evaluator: `pass`
- Infrastructure: `pass`

## Operating context

- Mode: `eval`
- Request: `CYCLE-REQUEST.md`
- Structured report: `report.json`

## Phase outcomes

- `report.json`: result `pass`; report `report.json`
- `workers/eval-manager/task-svcstat/report.json`: result `pass`; report `workers/eval-manager/task-svcstat/report.json`
- `workers/eval-worker/task-svcstat-1/report.json`: result `pass`; report `workers/eval-worker/task-svcstat-1/report.json`


## Employee accounting

### Worker metrics

- `eval-manager/task-svcstat` (`eval-manager`): result `pass`; report `workers/eval-manager/task-svcstat/report.json`
  - Execution: `not recorded`; classification: `not recorded`
  - Turns: `19`; bucket tokens: `759897`; thinking blocks: `16`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=19; observed_output_tps=0`
  - Tool errors: `3`; cost: `0.019377`; budget: `0.150000`
- `eval-worker/task-svcstat-1` (`eval-worker`): result `pass`; report `workers/eval-worker/task-svcstat-1/report.json`
  - Execution: `pass`; classification: `pass`
  - Turns: `36`; bucket tokens: `754954`; thinking blocks: `28`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=36; observed_output_tps=0`
  - Tool errors: `1`; cost: `0.020463`; budget: `0.500000`


### Nonzero tool results
### Provider health and latency

Provider retry, latency, and attribution data are in worker `report.json`
`provider_telemetry` fields. Missing telemetry is `unknown`, not evidence of
normal provider health. Provider switching is out of scope and tracked in
`TODO.md`.

### Nonzero tool results

- `eval-manager/task-svcstat`, turn `3`, tool `bash`: total 936
drwxr-xr-x  47 josh  staff    1504 Aug  7 16:03 .
drwxr-xr-x   3 josh  staff      96 Aug  7 15:58 ..
-rw-r--r--@  1 josh  staff      64 Aug  7 15:58 agent.cid
-rw-r--r--   1 josh  staff       0 Aug  7 15:58 container.stderr
-rw-r--r--   1 josh  staff  155120 Aug  7 16:03 container.stdout
-rw-r--r--@  1 josh  staff      64 Aug  7 16:03 evaluator.cid
-rw-r--r--   1 josh  staff       0 Aug  7 16:03 evaluator.stderr
-rw-r--r--   1 josh  staff       0 Aug  7 16:03 evaluator.stdout
-rw-r--r--@  1 josh  staff       0 Aug  7 15:58 pi.stderr
-rw-r--r--   1 josh  staff    3210 Aug  7 16:03 report.json
-rw-r--r--@  1 josh  staff     927 Aug  7 16:03 review.md
-rw-r--r--@  1 josh  staff    2067 Aug  7 16:03 run.json
-rw-r--r--@  1 josh  staff  157154 Aug  7 16:03 session.jsonl.bz2
-rw-r--r--@  1 josh  staff    1566 Aug  7 16:03 svcstat.xsh
-rw-r--r--@  1 josh  staff       0 Aug  7 16:03 task-svcstat-candidate-1.stderr
-rw-r--r--@  1 josh  staff      28 Aug  7 16:03 task-svcstat-candidate-1.stdout
-rw-r--r--@  1 josh  staff       0 Aug  7 16:03 task-svcstat-candidate-2.stderr
-rw-r--r--@  1 josh  staff       9 Aug  7 16:03 task-svcstat-candidate-2.stdout
-rw-r--r--@  1 josh  staff       0 Aug  7 16:03 task-svcstat-candidate-3.stderr
-rw-r--r--@  1 josh  staff      40 Aug  7 16:03 task-svcstat-candidate-3.stdout
-rw-r--r--@  1 josh  staff       0 Aug  7 16:03 task-svcstat-candidate-4.stderr
-rw-r--r--@  1 josh  staff      17 Aug  7 16:03 task-svcstat-candidate-4.stdout
-rw-r--r--@  1 josh  staff       0 Aug  7 16:03 task-svcstat-candidate-5.stderr
-rw-r--r--@  1 josh  staff      42 Aug  7 16:03 task-svcstat-candidate-5.stdout
-rw-r--r--@  1 josh  staff       0 Aug  7 16:03 task-svcstat-candidate-6.stderr
-rw-r--r--@  1 josh  staff      23 Aug  7 16:03 task-svcstat-candidate-6.stdout
-rw-r--r--@  1 josh  staff       0 Aug  7 16:03 task-svcstat-candidate-7.stderr
-rw-r--r--@  1 josh  staff       0 Aug  7 16:03 task-svcstat-candidate-7.stdout
-rw-r--r--@  1 josh  staff     234 Aug  7 16:03 task-svcstat-candidate-8.stderr
-rw-r--r--@  1 josh  staff       0 Aug  7 16:03 task-svcstat-candidate-8.stdout
-rw-r--r--@  1 josh  staff       0 Aug  7 16:03 task-svcstat-oracle-1.stderr
-rw-r--r--@  1 josh  staff      28 Aug  7 16:03 task-svcstat-oracle-1.stdout
-rw-r--r--@  1 josh  staff       0 Aug  7 16:03 task-svcstat-oracle-2.stderr
-rw-r--r--@  1 josh  staff       9 Aug  7 16:03 task-svcstat-oracle-2.stdout
-rw-r--r--@  1 josh  staff       0 Aug  7 16:03 task-svcstat-oracle-3.stderr
-rw-r--r--@  1 josh  staff      40 Aug  7 16:03 task-svcstat-oracle-3.stdout
-rw-r--r--@  1 josh  staff       0 Aug  7 16:03 task-svcstat-oracle-4.stderr
-rw-r--r--@  1 josh  staff      17 Aug  7 16:03 task-svcstat-oracle-4.stdout
-rw-r--r--@  1 josh  staff       0 Aug  7 16:03 task-svcstat-oracle-5.stderr
-rw-r--r--@  1 josh  staff      42 Aug  7 16:03 task-svcstat-oracle-5.stdout
-rw-r--r--@  1 josh  staff       0 Aug  7 16:03 task-svcstat-oracle-6.stderr
-rw-r--r--@  1 josh  staff      23 Aug  7 16:03 task-svcstat-oracle-6.stdout
-rw-r--r--@  1 josh  staff       0 Aug  7 16:03 task-svcstat-oracle-7.stderr
-rw-r--r--@  1 josh  staff       0 Aug  7 16:03 task-svcstat-oracle-7.stdout
-rw-r--r--@  1 josh  staff       0 Aug  7 16:03 task-svcstat-oracle-8.stderr
-rw-r--r--@  1 josh  staff       0 Aug  7 16:03 task-svcstat-oracle-8.stdout
drwxr-xr-x   7 josh  staff     224 Aug  7 16:03 work
---
      82 session.jsonl.bz2


Command exited with code 1
  - Structured report: `workers/eval-manager/task-svcstat/report.json`
- `eval-manager/task-svcstat`, turn `16`, tool `bash`: (no output)

Command exited with code 1
  - Structured report: `workers/eval-manager/task-svcstat/report.json`
- `eval-manager/task-svcstat`, turn `18`, tool `bash`: 87c87,92
< produce the nonzero exit. This build has no generic `Error(...)` constructor;
---
> produce the nonzero exit. Postfix `?` is valid only in a Result-returning
> context: a procedure that must abandon-and-propagate a validation failure has
> to return `Result[T, Error]` (or `Result[T]`), not a plain value type; a bare
> `?` inside a procedure whose return type is not a Result is rejected even when
> that procedure declares the `error` effect. This build has no generic
> `Error(...)` constructor;


Command exited with code 1
  - Structured report: `workers/eval-manager/task-svcstat/report.json`
- `eval-worker/task-svcstat-1`, turn `12`, tool `bash`: err[check.effect-violation]: `?` requires the `error` effect
  /tmp/probe.xsh:2:15
    let files = fs.files(p"/work/logs")?
                ^^^^^^^^^^^^^^^^^^^^^^^^ `?` requires the `error` effect


Command exited with code 2
  - Structured report: `workers/eval-worker/task-svcstat-1/report.json`


### Cycle total

- Workers: `2`
- Assistant turns: `55`
- Bucket tokens: `1514851`
- Cost (USD): `0.039840`
- Nonzero tool results: `4`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-manager/task-svcstat

- Role: `eval-manager`
- Result: `pass`
- Report: `workers/eval-manager/task-svcstat/REPORT.md`

#### Efficiency and evidence

One fresh trial (trial 1) executed by the controller. Editorial decision: this
eval's manager policy defaults to one trial and no `## Trial plan` raising the
count, so a single trial is the expected plan.

Trial 1 (`workers/eval-worker/task-svcstat-1/`):
- assistant turns 36, user messages 1
- tool calls 42: 35 bash, 3 read, 3 write, 1 edit; tool results 42
- structured tool_errors: 1 (see `## Tool-error findings`)
- session span 307,967 ms (worker `session_span_ms`); agent wall 309,212 ms
- agent_state, budget_state, evaluator_state, reporting_state, result all `pass`
- worker friction: early probe was rejected for missing the `error` effect on
  a `?` (`/tmp/probe.xsh`); the candidate helper lost several turns rediscovering
  that `?` needs a Result-returning context. Both are worker-side discovery
  friction, resolved within the trial, and the second is a reusable handbook
  lesson (candidate staged).

#### Handbook or proposal decision

Provisional candidate staged at
`lineage/handbook-candidate.md` (approved snapshot plus one sentence in the
Effects and errors section): postfix `?` is valid only in a Result-returning
context — a procedure that must abandon-and-propagate a validation failure
must return `Result[T, Error]` (or `Result[T]`), and a bare `?` in a proc whose
return type is not a Result is rejected even when that proc declares the
`error` effect.

This is a general XSH language rule, not a task recipe: it applies to any
helper that performs manual field validation and must fail the whole program,
so it should reduce repeated agent friction across validation-style evals
(task-svcstat, task-jsonfilter, task-groupsum, task-safepath). Replay scope:
the same eval and at least one other validation/aggregation eval against the
candidate lineage. Not promoted; promotion requires later replay and CTO
approval.

#### Ticket or product decision

None. The only meaningful observation (postfix `?` Result-returning context)
is handled by the handbook candidate; the missing-`Error`-constructor point is
a pinned-build design constraint already consistent with the handbook, not a
strong reproducible defect against this commit. Nothing warrants a product
ticket this cycle.

#### Next action

Replay `evals/task-svcstat` against the candidate handbook lineage
(`runs/run-1786142295779/phases/04-eval/lineage/handbook-candidate.md`) on XSH
commit `a248267612439dfcfa203fba583ac3e95d37f70c` to confirm the
Result-returning-context lesson removes the validation-helper discovery
friction while preserving byte-exact correctness. Because this is a
one-trial plan, the staged candidate was NOT independently replayed by the
controller this cycle; validation is pending a later trial. A falsification
check: if a future trial writes a validation helper that returns a non-Result
type and correctly avoids `?` (e.g. by building a Result explicitly), the
candidate sentence should be narrowed.

#### North-star impact

This eval directly advances the practical, learnable systems-glue mission: the
agent produced a correct, subprocess-free, byte-exact keyed count+sum rollup
across a recursive file tree using typed `fs.files` discovery, `group-by`, and
an accumulator `fold` — exactly the kind of stateful aggregation the north
star wants XSH to be first-class. Correctness passed on all eight cases,
including the strict failure control (malformed line suppresses the entire
report with nonzero exit and empty stdout). The one staged lesson
(postfix `?` needs a Result-returning context) improves learnability and AI
efficiency by removing a repeated discovery cost, and the clean result
strengthens the evidence that stream grouping plus accumulator fold are
discoverable and composable, keeping the connection to clarity and
explicit boundaries explicit.



## Eval proposal review

No CTO eval review was recorded.

## Handbook lineage

Checked-in `runtime/handbook.md`: `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b`
- approved snapshot: `lineage/handbook-approved.md` sha256 `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b` — promoted by CTO ledger; matches checked-in handbook
- candidate: `lineage/handbook-candidate.md` sha256 `cdd6a29864eb15c8c7d07fee83def54a2b9d85e2d68f640f74d24ce01a49de4c` — DIFFERS; CTO promotion or rejection decision required


## Historical handbook backlog

Historical candidates: 29; differing: 16; ledger-dispositioned: 13; unresolved: 3.
Unresolved candidates requiring one explicit CTO decision:
- `runs/run-1786142295779/phases/02-eval/lineage/handbook-candidate.md` sha256 `af2b35ff916e42a95757f43811b072d77a1e78a387dfcf80cf254d5d6d8bb8a7`
- `runs/run-1786142295779/phases/03-eval/lineage/handbook-candidate.md` sha256 `0b92e385ad13cccb41b04d798a77836ab62e0d716577de62866d25248ad04c71`
- `runs/run-1786142295779/phases/04-eval/lineage/handbook-candidate.md` sha256 `cdd6a29864eb15c8c7d07fee83def54a2b9d85e2d68f640f74d24ce01a49de4c`


## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
