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
- `workers/eval-manager/task-ecount/report.json`: result `pass`; report `workers/eval-manager/task-ecount/report.json`
- `workers/eval-worker/task-ecount-1/report.json`: result `pass`; report `workers/eval-worker/task-ecount-1/report.json`


## Employee accounting

### Worker metrics

- `eval-manager/task-ecount` (`eval-manager`): result `pass`; report `workers/eval-manager/task-ecount/report.json`
  - Execution: `not recorded`; classification: `not recorded`
  - Turns: `12`; bucket tokens: `357154`; thinking blocks: `12`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=12; observed_output_tps=0`
  - Tool errors: `0`; cost: `0.014381`; budget: `0.150000`
- `eval-worker/task-ecount-1` (`eval-worker`): result `pass`; report `workers/eval-worker/task-ecount-1/report.json`
  - Execution: `pass`; classification: `pass`
  - Turns: `64`; bucket tokens: `1609786`; thinking blocks: `53`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=64; observed_output_tps=0`
  - Tool errors: `13`; cost: `0.044146`; budget: `0.500000`


### Nonzero tool results
### Provider health and latency

Provider retry, latency, and attribution data are in worker `report.json`
`provider_telemetry` fields. Missing telemetry is `unknown`, not evidence of
normal provider health. Provider switching is out of scope and tracked in
`TODO.md`.

### Nonzero tool results

- `eval-worker/task-ecount-1`, turn `7`, tool `bash`: err[check.type-mismatch]: type mismatch
  probe_test.xsh:2:19
    let root = Path(argv.get(0))
                    ^^^^^^^^^^^ expected Str, found Result[Str, Error]

err[check.effect-violation]: `?` requires the `error` effect
  probe_test.xsh:3:15
    let files = fs.files(root)?
                ^^^^^^^^^^^^^^^ `?` requires the `error` effect


Command exited with code 2
  - Structured report: `workers/eval-worker/task-ecount-1/report.json`
- `eval-worker/task-ecount-1`, turn `15`, tool `bash`: purpose: Wraps text to a requested width.
====INT====


Command exited with code 1
  - Structured report: `workers/eval-worker/task-ecount-1/report.json`
- `eval-worker/task-ecount-1`, turn `22`, tool `bash`: err[parse.expected-expression]: expected expression
  ecount.xsh:7:16
    let spaces = stream.range(0, need) |> map { |_| " " } |> collect() |> List.join("")
                 ^^^^^^ expected expression

err[parse.expected-expression]: expected expression
  ecount.xsh:7:57
    let spaces = stream.range(0, need) |> map { |_| " " } |> collect() |> List.join("")
                                                          ^^ expected expression

err[parse.expected-expression]: expected expression
  ecount.xsh:9:1
  }
  ^ expected expression


Command exited with code 2
  - Structured report: `workers/eval-worker/task-ecount-1/report.json`
- `eval-worker/task-ecount-1`, turn `25`, tool `bash`: err[check.unresolved-name]: unresolved name
  r_test.xsh:2:59
    let ss = range(0, 3) |> map { |_| " " } |> collect() |> List.join("")
                                                            ^^^^ unresolved name


Command exited with code 2
  - Structured report: `workers/eval-worker/task-ecount-1/report.json`
- `eval-worker/task-ecount-1`, turn `26`, tool `bash`: err[parse.expected-record-field]: expected record field
  r_test.xsh:2:61
    let ss = range(0, 3) |> map { |_| " " } |> collect() |> { |l| l.join("") }
                                                              ^ expected record field

err[parse.expected-token]: expected `}` after record
  r_test.xsh:2:61
    let ss = range(0, 3) |> map { |_| " " } |> collect() |> { |l| l.join("") }
                                                              ^ expected `}` after record

err[parse.unsupported-boolean-operator]: unsupported operator '|': XSH boolean operators are the word forms 'or'
  r_test.xsh:2:61
    let ss = range(0, 3) |> map { |_| " " } |> collect() |> { |l| l.join("") }
                                                              ^ use 'or' instead of '|'

err[parse.expected-terminator]: expected statement terminator
  r_test.xsh:2:61
    let ss = range(0, 3) |> map { |_| " " } |> collect() |> { |l| l.join("") }
                                                              ^ expected statement terminator

err[parse.expected-expression]: expected expression
  r_test.xsh:2:61
    let ss = range(0, 3) |> map { |_| " " } |> collect() |> { |l| l.join("") }
                                                              ^ expected expression


Command exited with code 2
  - Structured report: `workers/eval-worker/task-ecount-1/report.json`
- `eval-worker/task-ecount-1`, turn `28`, tool `bash`: err[parse.expected-expression]: expected expression
  ecount.xsh:11:1
  }
  ^ expected expression

err[parse.expected-expression]: expected expression
  ecount.xsh:19:1
  }
  ^ expected expression


Command exited with code 2
  - Structured report: `workers/eval-worker/task-ecount-1/report.json`
- `eval-worker/task-ecount-1`, turn `30`, tool `bash`: err[parse.expected-expression]: expected expression
  fn_test.xsh:3:1
  }
  ^ expected expression
---
err[parse.expected-expression]: expected expression
  fn_test2.xsh:3:1
  }
  ^ expected expression


Command exited with code 2
  - Structured report: `workers/eval-worker/task-ecount-1/report.json`
- `eval-worker/task-ecount-1`, turn `34`, tool `bash`: err[check.standard-module-shadow]: name `path` shadows the standard module `path`
  ecount.xsh:13:13
  pure ext_of(path: Path) -> Str {
              ^^^^^^^^^^ name `path` shadows the standard module `path`

err[check.unsupported-api]: `path.display` is not supported; use `path_value.display()`
  ecount.xsh:14:15
    let parts = path.display().split(".")
                ^^^^^^^^^^^^^^ `path.display` is not supported; use `path_value.display()`

err[check.unknown-method]: unknown method `lower` on Result[Str, Error]
  ecount.xsh:16:5
      parts.get(parts.len() - 1).lower()
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `lower` is not defined for Result[Str, Error]

err[check.missing-return]: function can fall through without returning its declared type
  ecount.xsh:13:32
  pure ext_of(path: Path) -> Str {
                                 ^ function can fall through without returning its declared type


Command exited with code 2
  - Structured report: `workers/eval-worker/task-ecount-1/report.json`
- `eval-worker/task-ecount-1`, turn `36`, tool `bash`: sh: python3: not found
err[check.standard-module-shadow]: name `path` shadows the standard module `path`
  ecount.xsh:13:13
  pure ext_of(path: Path) -> Str {
              ^^^^^^^^^^ name `path` shadows the standard module `path`

err[check.unsupported-api]: `path.display` is not supported; use `path_value.display()`
  ecount.xsh:14:15
    let parts = path.display().split(".")
                ^^^^^^^^^^^^^^ `path.display` is not supported; use `path_value.display()`

err[check.unknown-method]: unknown method `lower` on Result[Str, Error]
  ecount.xsh:16:5
      parts.get(parts.len() - 1).lower()
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `lower` is not defined for Result[Str, Error]

err[check.missing-return]: function can fall through without returning its declared type
  ecount.xsh:13:32
  pure ext_of(path: Path) -> Str {
                                 ^ function can fall through without returning its declared type


Command exited with code 2
  - Structured report: `workers/eval-worker/task-ecount-1/report.json`
- `eval-worker/task-ecount-1`, turn `38`, tool `bash`: err[check.missing-return]: function can fall through without returning its declared type
  ecount.xsh:13:29
  pure ext_of(p: Path) -> Str {
                              ^ function can fall through without returning its declared type
=== candidate ===
cat: can't open 'probe/cand.txt': No such file or directory
=== oracle ===
      1 script
     18 pub
    119 crt
=== diff ===
diff: can't stat 'probe/cand.txt': No such file or directory


Command exited with code 2
  - Structured report: `workers/eval-worker/task-ecount-1/report.json`
- `eval-worker/task-ecount-1`, turn `39`, tool `bash`: err[check.missing-return]: function can fall through without returning its declared type
  if_test.xsh:1:28
  pure choose(x: Int) -> Str {
                             ^ function can fall through without returning its declared type


Command exited with code 2
  - Structured report: `workers/eval-worker/task-ecount-1/report.json`
- `eval-worker/task-ecount-1`, turn `42`, tool `bash`: === candidate ===
     1 script
    18 pub
   119 crt
=== diff ===
--- probe/oracle.txt
+++ probe/cand.txt
@@ -1,3 +1,3 @@
-      1 script
-     18 pub
-    119 crt
+     1 script
+    18 pub
+   119 crt


Command exited with code 1
  - Structured report: `workers/eval-worker/task-ecount-1/report.json`
- `eval-worker/task-ecount-1`, turn `46`, tool `bash`: sh: syntax error: bad for loop variable


Command exited with code 2
  - Structured report: `workers/eval-worker/task-ecount-1/report.json`


### Cycle total

- Workers: `2`
- Assistant turns: `76`
- Bucket tokens: `1966940`
- Cost (USD): `0.058527`
- Nonzero tool results: `13`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-manager/task-ecount

- Role: `eval-manager`
- Result: `pass`
- Report: `workers/eval-manager/task-ecount/REPORT.md`

#### Efficiency and evidence

Trial 1 (only trial):
- assistant turns: 64; stop reasons: 1 normal stop, 63 `toolUse`.
- tool calls: 80 (bash 70, read 4, edit 3, write 3); tool results 80.
- tool errors: 13 (all `bash`; see Tool-error findings).
- session span: 657581 ms (~11 min) worker, `agent_wall_ms` 658895.
- worker friction: high, clustered around XSH function-declaration and
  value-return idiom discovery (`fn` vs `pure`, if/else final expression,
  `List.get` overload, `path` shadowing) and padding-width measurement from the
  oracle. The agent recovered and passed without re-probes beyond the session.

#### Handbook or proposal decision

Provisional candidate staged at
`lineage/handbook-candidate.md` (copy of the approved snapshot plus a new
"Function declarations and value returns" section): `pure` vs `fn`, final-expression returns and the `let`-bound `if`/`else` idiom, the `List.get`
fallback overload, and standard-module parameter shadowing. Single general
lesson: document the function-declaration and value-return idioms once so
agents stop re-discovering them per task. Approved snapshot and checked-in
`runtime/handbook.md` are untouched. The candidate is a hypothesis pending
replay; not promoted.

#### Ticket or product decision

None. The recurring friction is learnability/guidance rather than a confirmed
general product defect within a single trial; staged as handbook candidate and
left for replay evidence rather than an engineer ticket this cycle.

#### Next action

Replay `task-ecount` against `lineage/handbook-candidate.md` with the same
oracle and a nearby filesystem case, and replay at least one other
filesystem/composition eval (e.g. `task-dupcheck` or `task-histogram`) to test
whether the function/`pure`, if-else-return, and `List.get` overload guidance
is general. Promote to `runtime/handbook.md` only after both replays confirm a
reduction in the documented tool errors and turns.

#### North-star impact

Improves XSH learnability and ergonomics — the stated factory focus — by
making effect-free function declarations and value returns explicit and
discoverable, so an agent (or person) reaches a correct, clear program with
fewer failed checks and less exploration. Directly reduces repeated
`fn`/`pure`, missing-return, and `List.get` friction observed this cycle. The
remaining friction (padding width, `python3` absence) is environment/oracle
noise, not product signal, and keeps the composition bar honest rather than
rewarding a task-specific trick.



## Eval proposal review

No CTO eval review was recorded.

## Handbook lineage

Checked-in `runtime/handbook.md`: `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b`
- approved snapshot: `lineage/handbook-approved.md` sha256 `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b` — promoted by CTO ledger; matches checked-in handbook
- candidate: `lineage/handbook-candidate.md` sha256 `2c9a519882a9c0dff1c84e45788d5ed7bd4dbf92f01292047880511a75c92aac` — DIFFERS; CTO promotion or rejection decision required


## Historical handbook backlog

Historical candidates: 9; differing: 4; ledger-dispositioned: 3; unresolved: 1.
Unresolved candidates requiring one explicit CTO decision:
- `runs/run-1786131191668/phases/01-eval/lineage/handbook-candidate.md` sha256 `2c9a519882a9c0dff1c84e45788d5ed7bd4dbf92f01292047880511a75c92aac`


## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
