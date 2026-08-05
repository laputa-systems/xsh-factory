# CTO briefing 01-eval

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
- `workers/eval-manager/task-colsum/report.json`: result `pass`; report `workers/eval-manager/task-colsum/report.json`
- `workers/eval-worker/task-colsum-1/report.json`: result `pass`; report `workers/eval-worker/task-colsum-1/report.json`


## Employee accounting

### Worker metrics

- `eval-manager/task-colsum` (`eval-manager`): result `pass`; report `workers/eval-manager/task-colsum/report.json`
  - Execution: `not recorded`; classification: `not recorded`
  - Turns: `16`; bucket tokens: `523762`; thinking blocks: `14`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=16; observed_output_tps=0`
  - Tool errors: `1`; cost: `0.014475`; budget: `0.150000`
- `eval-worker/task-colsum-1` (`eval-worker`): result `pass`; report `workers/eval-worker/task-colsum-1/report.json`
  - Execution: `pass`; classification: `pass`
  - Turns: `43`; bucket tokens: `591637`; thinking blocks: `29`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=43; observed_output_tps=0`
  - Tool errors: `3`; cost: `0.014339`; budget: `0.500000`


### Nonzero tool results
### Provider health and latency

Provider retry, latency, and attribution data are in worker `report.json`
`provider_telemetry` fields. Missing telemetry is `unknown`, not evidence of
normal provider health. Provider switching is out of scope and tracked in
`TODO.md`.

### Nonzero tool results

- `eval-manager/task-colsum`, turn `12`, tool `bash`: 170a171,175
> Int has no `to_string()` and `$var` is command-word syntax (invalid inside an
> expression). To embed an Int in composed text, use a display string in
> expression position and then print the value: `let line = f"n=${n}"`
> then `print $line`.
> 


Command exited with code 1
  - Structured report: `workers/eval-manager/task-colsum/report.json`
- `eval-worker/task-colsum-1`, turn `26`, tool `bash`: err[parse.expected-expression]: `$name` is command-word syntax; in expression context, use `name` directly
  t2.xsh:7:18
    let s = "n=" + $n
                   ^^ use `n` here, not `$n`
RUN data2
err[parse.expected-expression]: `$name` is command-word syntax; in expression context, use `name` directly
  t2.xsh:7:18
    let s = "n=" + $n
                   ^^ use `n` here, not `$n`
RUN data3
err[parse.expected-expression]: `$name` is command-word syntax; in expression context, use `name` directly
  t2.xsh:7:18
    let s = "n=" + $n
                   ^^ use `n` here, not `$n`


Command exited with code 2
  - Structured report: `workers/eval-worker/task-colsum-1/report.json`
- `eval-worker/task-colsum-1`, turn `27`, tool `bash`: err[check.unknown-method]: unknown method `to_string` on Int
  t2.xsh:7:18
    let s = "n=" + n.to_string()
                   ^^^^^^^^^^^^^ `to_string` is not defined for Int
RUN data2
err[check.unknown-method]: unknown method `to_string` on Int
  t2.xsh:7:18
    let s = "n=" + n.to_string()
                   ^^^^^^^^^^^^^ `to_string` is not defined for Int
====
RUN data3
err[check.unknown-method]: unknown method `to_string` on Int
  t2.xsh:7:18
    let s = "n=" + n.to_string()
                   ^^^^^^^^^^^^^ `to_string` is not defined for Int


Command exited with code 2
  - Structured report: `workers/eval-worker/task-colsum-1/report.json`
- `eval-worker/task-colsum-1`, turn `33`, tool `bash`: sh: syntax error: unexpected "("


Command exited with code 2
  - Structured report: `workers/eval-worker/task-colsum-1/report.json`


### Cycle total

- Workers: `2`
- Assistant turns: `59`
- Bucket tokens: `1115399`
- Cost (USD): `0.028814`
- Nonzero tool results: `4`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-manager/task-colsum

- Role: `eval-manager`
- Result: `pass`
- Report: `workers/eval-manager/task-colsum/REPORT.md`

#### Efficiency and evidence

One trial (`task-colsum-1`), executor result `pass`.

- Assistant turns: 43 (1 user message, 42 toolUse stop, 1 stop).
- Tool calls: 50 (bash 41, write 5, read 4).
- Tool errors: 3, all warnings; each resolved within the next turn.
- Session span: `session_span_ms` 146640 (~2.4 min); `agent_wall_ms` 148213.
- Worker friction: low. The agent did not re-explore prior evals or loop on the
  same error; every tool error was corrected in one iteration (see Tool-error
  findings). Restriction compliance, artifact presence, and review presence all
  `pass`.

#### Handbook or proposal decision

Provisional candidate staged at
`runs/run-1785893827191/phases/01-eval/lineage/handbook-candidate.md`
(one-trial plan). The approved snapshot was copied and one concise rule added to
the `Text and output` section:

> Int has no `to_string()` and `$var` is command-word syntax (invalid inside an
> expression). To embed an Int in composed text, use a display string in
> expression position and then print the value: `let line = f"n=${n}"` then
> `print $line`.

General lesson: exact-output tasks repeatedly need to embed a number in text;
naming the absence of `Int.to_string()` and pointing at the f-string removes
the two most common Int-to-text errors. Replay scope: `runtime/handbook.md`
promotion requires the controller to replay `task-colsum` (and ideally one
other exact-output eval such as `task-tags` or `task-intsum`) against this
candidate; it is not yet trusted.

#### Ticket or product decision

- `/Users/josh/d/laputa-systems/xsh-factory/tickets/task-colsum-001.md` — Open:
  add an explicit fail/error-raise form for deliberate validation failure
  (replaces the `parse_int` sentinel abuse seen in this session). Linked to
  this eval, executor run, manager run, handbook lineage, and XSH commit
  `e5d29c7ec8b4411dc749fd3e44bf472d641ad9f4`.

#### Next action

Replay `task-colsum` (single trial, same executor harness) against the
provisional handbook candidate and XSH commit `e5d29c7ec8b4411dc749fd3e44bf472d641ad9f4`
to confirm the Int-to-text rule does not regress correctness; additionally
replay one other exact-output eval to test the candidate's generality before
promoting it to `runtime/handbook.md`. Post-merge, replay `task-colsum` to
falsify ticket `task-colsum-001` (error-raise form).

#### North-star impact

This run demonstrates a clean, compositional XSH solution to a real
structured-data reduction (named-column sum) with typed reading and parsing, no
subprocess escape, and a byte-exact integer contract — directly advancing the
"practical systems glue" and "explicit boundary" goals. It produced one durable
handbook candidate (Int-to-text embedding) and one general ergonomics ticket
(explicit validation-failure form), both aimed at reducing the sort of
workaround friction the session surfaced. Correctness held on all nine cases,
so the agent efficiency is high and the signal is general.



## Eval proposal review

No CTO eval review was recorded.

## Handbook lineage

Checked-in `runtime/handbook.md`: `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b`
- approved snapshot: `lineage/handbook-approved.md` sha256 `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b` — matches checked-in handbook
- candidate: `lineage/handbook-candidate.md` sha256 `1a0947d69748eee9f546a19743aa3a76f780f7c8a6d2f4302a5621cd85426efc` — DIFFERS; CTO promotion or rejection decision required


## Historical handbook backlog

Historical candidates: 66; differing: 66; ledger-dispositioned: 65; unresolved: 1.
Unresolved candidates requiring one explicit CTO decision:
- `runs/run-1785893827191/phases/01-eval/lineage/handbook-candidate.md` sha256 `1a0947d69748eee9f546a19743aa3a76f780f7c8a6d2f4302a5621cd85426efc`


## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
