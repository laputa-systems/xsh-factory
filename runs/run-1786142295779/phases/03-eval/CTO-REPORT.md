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

- `report.json`: result `pass`; report `report.json`
- `workers/eval-manager/task-setdiff/report.json`: result `pass`; report `workers/eval-manager/task-setdiff/report.json`
- `workers/eval-worker/task-setdiff-1/report.json`: result `pass`; report `workers/eval-worker/task-setdiff-1/report.json`


## Employee accounting

### Worker metrics

- `eval-manager/task-setdiff` (`eval-manager`): result `pass`; report `workers/eval-manager/task-setdiff/report.json`
  - Execution: `not recorded`; classification: `not recorded`
  - Turns: `12`; bucket tokens: `296619`; thinking blocks: `9`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=12; observed_output_tps=0`
  - Tool errors: `0`; cost: `0.011411`; budget: `0.150000`
- `eval-worker/task-setdiff-1` (`eval-worker`): result `pass`; report `workers/eval-worker/task-setdiff-1/report.json`
  - Execution: `pass`; classification: `pass`
  - Turns: `35`; bucket tokens: `452643`; thinking blocks: `27`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=35; observed_output_tps=0`
  - Tool errors: `6`; cost: `0.011801`; budget: `0.500000`


### Nonzero tool results
### Provider health and latency

Provider retry, latency, and attribution data are in worker `report.json`
`provider_telemetry` fields. Missing telemetry is `unknown`, not evidence of
normal provider health. Provider switching is out of scope and tracked in
`TODO.md`.

### Nonzero tool results

- `eval-worker/task-setdiff-1`, turn `13`, tool `bash`: err[parse.expected-expression]: expected expression
  setdiff.xsh:6:20
      |> where { |l| not set.has(setB, l) }
                     ^^^ expected expression

err[parse.expected-expression]: expected expression
  setdiff.xsh:7:5
      |> unique-by { |l| l }
      ^^ expected expression

err[parse.expected-expression]: expected expression
  setdiff.xsh:8:5
      |> sort()
      ^^ expected expression

err[parse.expected-expression]: expected expression
  setdiff.xsh:9:5
      |> collect()
      ^^ expected expression

err[parse.expected-token]: expected `}` to close block
  setdiff.xsh:14:1
  
  ^ expected `}` to close block
=== fmt ===
err[parse.expected-expression]: expected expression
  setdiff.xsh:6:20
      |> where { |l| not set.has(setB, l) }
                     ^^^ expected expression

err[parse.expected-expression]: expected expression
  setdiff.xsh:7:5
      |> unique-by { |l| l }
      ^^ expected expression

err[parse.expected-expression]: expected expression
  setdiff.xsh:8:5
      |> sort()
      ^^ expected expression

err[parse.expected-expression]: expected expression
  setdiff.xsh:9:5
      |> collect()
      ^^ expected expression

err[parse.expected-token]: expected `}` to close block
  setdiff.xsh:14:1
  
  ^ expected `}` to close block
=== lint ===
err[parse.expected-expression]: expected expression
  setdiff.xsh:6:20
      |> where { |l| not set.has(setB, l) }
                     ^^^ expected expression
err[parse.expected-expression]: expected expression
  setdiff.xsh:7:5
      |> unique-by { |l| l }
      ^^ expected expression
err[parse.expected-expression]: expected expression
  setdiff.xsh:8:5
      |> sort()
      ^^ expected expression
err[parse.expected-expression]: expected expression
  setdiff.xsh:9:5
      |> collect()
      ^^ expected expression
err[parse.expected-token]: expected `}` to close block
  setdiff.xsh:14:1
  
  ^ expected `}` to close block


Command exited with code 2
  - Structured report: `workers/eval-worker/task-setdiff-1/report.json`
- `eval-worker/task-setdiff-1`, turn `15`, tool `bash`: skip
err[parse.expected-expression]: expected expression
  /tmp/t2.xsh:4:20
      |> where { |l| not(set.has(setB, l)) }
                     ^^^ expected expression

err[parse.expected-expression]: expected expression
  /tmp/t2.xsh:5:5
      |> collect()
      ^^ expected expression

err[parse.expected-token]: expected `}` to close block
  /tmp/t2.xsh:8:1
  
  ^ expected `}` to close block


Command exited with code 2
  - Structured report: `workers/eval-worker/task-setdiff-1/report.json`
- `eval-worker/task-setdiff-1`, turn `17`, tool `bash`: err[check.display-conversion]: value cannot be displayed by print
  /tmp/t4.xsh:5:9
    print $out
          ^^^^ value cannot be displayed by print


Command exited with code 2
  - Structured report: `workers/eval-worker/task-setdiff-1/report.json`
- `eval-worker/task-setdiff-1`, turn `18`, tool `bash`: err[parse.expected-expression]: expected expression
  /tmp/t5.xsh:4:30
    let out = r |> where { |l| not set.has(s, l) } |> collect()
                               ^^^ expected expression

err[parse.expected-expression]: expected expression
  /tmp/t5.xsh:4:50
    let out = r |> where { |l| not set.has(s, l) } |> collect()
                                                   ^^ expected expression

err[parse.expected-token]: expected `}` to close block
  /tmp/t5.xsh:7:1
  
  ^ expected `}` to close block


Command exited with code 2
  - Structured report: `workers/eval-worker/task-setdiff-1/report.json`
- `eval-worker/task-setdiff-1`, turn `19`, tool `bash`: err[check.display-conversion]: value cannot be displayed by print
  /tmp/t6.xsh:5:9
    print $out
          ^^^^ value cannot be displayed by print


Command exited with code 2
  - Structured report: `workers/eval-worker/task-setdiff-1/report.json`
- `eval-worker/task-setdiff-1`, turn `22`, tool `bash`: === fmt ===
=== lint ===
warn[lint.path-constructor]: prefer p-string interpolation over `Path(...)`
  setdiff.xsh:2:36
    let setB = set.from(fs.read_text(Path(argv[1]))?.lines() |> collect())
                                     ------------- use path string syntax instead
note: `Path(...)` remains a cast, but p-strings are the preferred path syntax
help: replace with path string -> fp"${argv[1]}"
warn[lint.path-constructor]: prefer p-string interpolation over `Path(...)`
  setdiff.xsh:3:29
    let result = fs.read_text(Path(argv[0]))?.lines()
                              ------------- use path string syntax instead
note: `Path(...)` remains a cast, but p-strings are the preferred path syntax
help: replace with path string -> fp"${argv[0]}"


Command exited with code 1
  - Structured report: `workers/eval-worker/task-setdiff-1/report.json`


### Cycle total

- Workers: `2`
- Assistant turns: `47`
- Bucket tokens: `749262`
- Cost (USD): `0.023212`
- Nonzero tool results: `6`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-manager/task-setdiff

- Role: `eval-manager`
- Result: `pass`
- Report: `workers/eval-manager/task-setdiff/REPORT.md`

#### Efficiency and evidence

Trial 1 (the only configured trial): worker `eval-worker/task-setdiff-1`.
- Assistant turns: 35
- Tool calls: 41 (32 bash, 5 read, 3 write, 1 edit)
- Tool errors: 6 (all in the worker tool_errors array; none in the manager session)
- Session span: 120,232 ms (~2.0 min)
- agent_wall_ms: 132,315
- Stop reasons: 1 stop, 34 toolUse
- Worker friction: ~6 failed `xsht check`/lint invocations before a clean solution;
  all errors were resolved within the session and the final artifact passed.

Only one trial was configured; there is no Trial 2 to compare.

#### Handbook or proposal decision

Provisional candidate staged at
`runs/run-1786142295779/phases/03-eval/lineage/handbook-candidate.md`
(approved snapshot plus one concise line in "Streams and collections"):
Boolean negation is the prefix `!` (e.g. `! set.has(s, l)` or `! flag`);
`not` is not valid XSH syntax. General lesson: teach the boolean-negation
operator so agents stop guessing `not`. Replay scope before promotion: rerun
task-setdiff, and cross-eval replay on stream-filter evals (task-dupcheck,
task-ecount) since the rule applies to any `where`-style guard. Promotion
requires CTO approval and later replay; not trusted yet. The approved
snapshot and `runtime/handbook.md` were not modified.

#### Ticket or product decision

None. The one strong reproducible observation (invalid `not`) is a handbook
learnability gap, not a general XSH ergonomics/correctness defect, so it is
staged as a handbook candidate rather than an engineer ticket.

#### Next action

Replay task-setdiff on the staged lineage
`runs/run-1786142295779/phases/03-eval/lineage/handbook-candidate.md` to check
the `!`-negation note shortens the discover/error loop, then cross-check on
task-dupcheck/task-ecount before any promotion to `runtime/handbook.md`.

#### North-star impact

Directly advances learnability and ergonomics: an agent with the handbook
should not burn three failed checks and two dead `search:not` / `search:boolean`
probes on a basic Boolean negation. Teaching `! expr` as the one negation form
reduces tool-error churn, keeps solutions on the typed, explicit XSH surface
(the `set`/`stream` path rather than string tricks or subprocess escape), and
generalizes to every filter/guard in the language. It is a small, durable
foundation lesson in the "prepare the handbook for agents we will never meet"
mission and is falsifiable via the staged replay.



## Eval proposal review

No CTO eval review was recorded.

## Handbook lineage

Checked-in `runtime/handbook.md`: `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b`
- approved snapshot: `lineage/handbook-approved.md` sha256 `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b` — promoted by CTO ledger; matches checked-in handbook
- candidate: `lineage/handbook-candidate.md` sha256 `0b92e385ad13cccb41b04d798a77836ab62e0d716577de62866d25248ad04c71` — DIFFERS; CTO promotion or rejection decision required


## Historical handbook backlog

Historical candidates: 27; differing: 15; ledger-dispositioned: 13; unresolved: 2.
Unresolved candidates requiring one explicit CTO decision:
- `runs/run-1786142295779/phases/02-eval/lineage/handbook-candidate.md` sha256 `af2b35ff916e42a95757f43811b072d77a1e78a387dfcf80cf254d5d6d8bb8a7`
- `runs/run-1786142295779/phases/03-eval/lineage/handbook-candidate.md` sha256 `0b92e385ad13cccb41b04d798a77836ab62e0d716577de62866d25248ad04c71`


## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
