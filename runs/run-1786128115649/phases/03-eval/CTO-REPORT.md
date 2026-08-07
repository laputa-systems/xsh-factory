# CTO briefing 03-eval

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

- `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786128115649/phases/03-eval/report.json`: result `pass`; report `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786128115649/phases/03-eval/report.json`
- `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786128115649/phases/03-eval/workers/eval-manager/task-dupcheck/report.json`: result `pass`; report `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786128115649/phases/03-eval/workers/eval-manager/task-dupcheck/report.json`
- `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786128115649/phases/03-eval/workers/eval-worker/task-dupcheck-1/report.json`: result `pass`; report `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786128115649/phases/03-eval/workers/eval-worker/task-dupcheck-1/report.json`


## Employee accounting

### Worker metrics

- `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786128115649/phases/03-eval/workers/eval-manager/task-dupcheck/report.json` (`unknown`): result `pass`; report `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786128115649/phases/03-eval/workers/eval-manager/task-dupcheck/report.json`
  - Execution: `not recorded`; classification: `not recorded`
  - Turns: `15`; bucket tokens: `395566`; thinking blocks: `12`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=15; observed_output_tps=0`
  - Tool errors: `0`; cost: `0.011748`; budget: `0.150000`
- `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786128115649/phases/03-eval/workers/eval-worker/task-dupcheck-1/report.json` (`unknown`): result `pass`; report `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786128115649/phases/03-eval/workers/eval-worker/task-dupcheck-1/report.json`
  - Execution: `pass`; classification: `pass`
  - Turns: `23`; bucket tokens: `291577`; thinking blocks: `19`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=23; observed_output_tps=0`
  - Tool errors: `0`; cost: `0.009270`; budget: `0.500000`


### Nonzero tool results
### Provider health and latency

Provider retry, latency, and attribution data are in worker `report.json`
`provider_telemetry` fields. Missing telemetry is `unknown`, not evidence of
normal provider health. Provider switching is out of scope and tracked in
`TODO.md`.

### Nonzero tool results

No nonzero Pi tool results were recorded.

### Cycle total

- Workers: `2`
- Assistant turns: `38`
- Bucket tokens: `687143`
- Cost (USD): `0.021019`
- Nonzero tool results: `0`
- Budget failures or unknown costs: `0`


## Employee decisions

### /Users/josh/d/laputa-systems/xsh-factory/runs/run-1786128115649/phases/03-eval/workers/eval-manager/task-dupcheck/REPORT.md

- Role: `unknown`
- Result: `pass`
- Report: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786128115649/phases/03-eval/workers/eval-manager/task-dupcheck/REPORT.md`

#### Efficiency and evidence

Trial 1 (the only trial; controller completed 1 fresh trial) — worker
`task-dupcheck-1`:

- Assistant turns: 23
- Tool calls: 25 (22 `bash`, 1 `edit`, 2 `read`)
- Tool results: 25
- Tool errors: 0
- Session span: 250,414 ms (~250 s); agent wall 251,606 ms; stop reasons 1
  `stop` + 22 `toolUse`
- Worker friction: low. The agent read the handbook, discovered `hash.sha256`
  and `fs.files` via `xsht api`, hit the named-argument parse friction
  (~2-3 turns), resolved it with positional args, and produced a passing
  artifact with a `xsht check`/`fmt`/`lint` loop. No repeated reads beyond
  normal discovery, no tool errors, no re-exploration churn.

#### Handbook or proposal decision

Provisional candidate staged at
`runs/run-1786128115649/phases/03-eval/lineage/handbook-candidate.md`
(approved snapshot + one concise paragraph under "Development loop and
tooling"). The general lesson: **function calls are positional-only in this
build**; a rendered `name: Type = default` shows an omittable default, not a
named argument, and `name = value` in a call fails to parse — override
defaulted parameters positionally (e.g. `fs.files(root, false, false, [],
true)`). This is a short, general rule that removes a repeated-discovery class,
not a task recipe. It is a hypothesis only: it must be replayed (task-dupcheck
and at least one other defaulted-parameter eval) before promotion to
`runtime/handbook.md`; promotion requires CTO review.

#### Ticket or product decision

- `tickets/task-dupcheck-002.md` — Open, product target. Description: `xsht
  api` signature rendering implies named-argument support that the parser
  (positional-only) rejects; proposal is to make the displayed surface honest
  (smallest fix) or consider named args as a separate larger admission. Links
  this eval, manager run, executor run, handbook lineage, and XSH baseline
  `1477f472d5b4d57db3584357116ef97c32358ab6`. A new-ticket for the next cycle.

(Existing `tickets/task-dupcheck-001.md` is a closed historical factory ticket
for the evaluator module-provisioning fix; it is CTO-owned and already
resolved, so it is not re-opened or duplicated.)

#### Next action

- Eval: `task-dupcheck`, trial 1, against the staged handbook candidate
  (`runs/run-1786128115649/phases/03-eval/lineage/handbook-candidate.md`).
- Falsification/replay checks: (1) task-dupcheck still passes all eight cases
  with the positional-only rule in the handbook; (2) a second eval that calls a
  module function with defaulted parameters replays to confirm the agent no
  longer attempts invalid `name = value` calls; (3) if `task-dupcheck-002` is
  implemented and merged, replay task-dupcheck and a second eval there too.

#### North-star impact

This run is the first paid validation of a content-level systems-glue eval:
the agent composed the typed `fs` stream, the `hash` module, and the
group/filter/flatten/sort idiom to reproduce `find | sha256sum | sort | awk`
with no subprocess — turning the eval's north-star hypothesis into measured,
byte-exact evidence across all eight cases. Separately, the run surfaced one
durable ergonomics defect (a reference surface that invites invalid
named-argument syntax) and a corresponding positional-only handbook rule,
both aimed at the north-star goals of fewer guesses/tool errors and an honest,
explicit, learnable API boundary. Correctness and clarity were strong at low
token/cost, and the historical harness defect that once blocked this eval is
confirmed fixed.



## Eval proposal review

No CTO eval review was recorded.

## Handbook lineage

Checked-in `runtime/handbook.md`: `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b`
- approved snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786128115649/phases/03-eval/lineage/handbook-approved.md` sha256 `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b` — promoted by CTO ledger; matches checked-in handbook
- candidate: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786128115649/phases/03-eval/lineage/handbook-candidate.md` sha256 `b8850d2021ac99f587cdd368ab9b40132d73b52b79f35ab5647cd02e6162db75` — dispositioned in CTO ledger; differs from current handbook


## Historical handbook backlog

Historical candidates: 8; differing: 3; ledger-dispositioned: 3; unresolved: 0.
No unresolved candidate content is present.

## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `validated`
