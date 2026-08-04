# CTO briefing 03-eval

This is the deterministic first-pass briefing for the CTO. The structured
`report.json` files and raw Pi sessions remain the source of truth.

## Result

fail

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
  - Turns: `21`; bucket tokens: `653281`; thinking blocks: `14`
  - Tool errors: `0`; cost: `0.020016`; budget: `0.150000`
- `eval-worker/task-envcfg-1` (`eval-worker`): result `pass`; report `workers/eval-worker/task-envcfg-1/report.json`
  - Execution: `pass`; classification: `pass`
  - Turns: `30`; bucket tokens: `436192`; thinking blocks: `25`
  - Tool errors: `5`; cost: `0.011312`; budget: `0.500000`


### Nonzero tool results

- `eval-worker/task-envcfg-1`, turn `6`, tool `bash`: err[parse.expected-token]: expected `=>` in match arm
  /tmp/t.xsh:5:9
        ok: v -> f"OK ${s} -> ${v}"
          ^ expected `=>` in match arm

err[parse.expected-expression]: expected expression
  /tmp/t.xsh:5:9
        ok: v -> f"OK ${s} -> ${v}"
          ^ expected expression

err[parse.expected-token]: expected `=>` in match arm
  /tmp/t.xsh:6:10
        err: e -> f"ERR ${s}"
           ^ expected `=>` in match arm

err[parse.expected-expression]: expected expression
  /tmp/t.xsh:6:10
        err: e -> f"ERR ${s}"
           ^ expected expression


Command exited with code 2
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`
- `eval-worker/task-envcfg-1`, turn `13`, tool `bash`: err[check.standard-module-shadow]: name `path` shadows the standard module `path`
  /tmp/path.xsh:2:3
    let path = Path(argv[0])
    ^^^^^^^^^^^^^^^^^^^^^^^^ name `path` shadows the standard module `path`
exit=2
cat: can't open '/tmp/ptest.txt': No such file or directory


Command exited with code 1
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`
- `eval-worker/task-envcfg-1`, turn `20`, tool `bash`: sh: export: line 0: illegal option -f


Command exited with code 2
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`
- `eval-worker/task-envcfg-1`, turn `21`, tool `bash`: FAIL defaults: exit oracle=1 xsh=3
PASS all-set
PASS empty-host
PASS empty-debug
FAIL bad-alpha: exit oracle=1 xsh=3
FAIL bad-neg: exit oracle=1 xsh=3
FAIL bad-plus: exit oracle=1 xsh=3
FAIL bad-space: exit oracle=1 xsh=3
FAIL bad-decimal: exit oracle=1 xsh=3
FAIL bad-empty: exit oracle=1 xsh=3
PASS leading
PASS debug-set


Command exited with code 1
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`
- `eval-worker/task-envcfg-1`, turn `22`, tool `bash`: PASS defaults
PASS all-set
PASS empty-host
PASS empty-debug
FAIL empty-all: stdout: runtime traceback
executable: /usr/local/bin/xsh
operation: result.propagate
error: parse-int: invalid integer `x`
call path:
  1. proc main at /work/envcfg.xsh:1:1-1:1
FAIL bad-alpha: stdout: runtime traceback
executable: /usr/local/bin/xsh
operation: result.propagate
error: parse-int: invalid integer `xabc`
call path:
  1. proc main at /work/envcfg.xsh:1:1-1:1
FAIL bad-neg: stdout: runtime traceback
executable: /usr/local/bin/xsh
operation: result.propagate
error: parse-int: invalid integer `x-5`
call path:
  1. proc main at /work/envcfg.xsh:1:1-1:1
FAIL bad-plus: stdout: runtime traceback
executable: /usr/local/bin/xsh
operation: result.propagate
error: parse-int: invalid integer `x+5`
call path:
  1. proc main at /work/envcfg.xsh:1:1-1:1
FAIL bad-space: stdout: runtime traceback
executable: /usr/local/bin/xsh
operation: result.propagate
error: parse-int: invalid integer `x 5`
call path:
  1. proc main at /work/envcfg.xsh:1:1-1:1
FAIL bad-decimal: stdout: runtime traceback
executable: /usr/local/bin/xsh
operation: result.propagate
error: parse-int: invalid integer `x5.0`
call path:
  1. proc main at /work/envcfg.xsh:1:1-1:1
FAIL bad-empty-port: stdout: runtime traceback
executable: /usr/local/bin/xsh
operation: result.propagate
error: parse-int: invalid integer `x`
call path:
  1. proc main at /work/envcfg.xsh:1:1-1:1
PASS leading
PASS debug-set
PASS port-only-unset-host


Command exited with code 1
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`


### Cycle total

- Workers: `2`
- Assistant turns: `51`
- Bucket tokens: `1089473`
- Cost (USD): `0.031328`
- Nonzero tool results: `5`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-manager/task-envcfg

- Role: `eval-manager`
- Result: `pass`
- Report: `workers/eval-manager/task-envcfg/REPORT.md`

#### Efficiency and evidence

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

#### Handbook or proposal decision

Provisional candidate: `lineage/handbook-candidate.md` = approved snapshot
plus one sentence in "Paths and filesystem values": do not shadow a standard
module name with a local binding (`xsht check`/`lint` reject it, e.g. `let
path = ...`); use a distinct name such as `out_path`. General lesson: local
bindings must not shadow standard module names. Replay scope: task-envcfg and
task-ecount (both path/filesystem-heavy) before promotion to
`runtime/handbook.md`.

#### Ticket or product decision

None. The `path` shadowing finding is best served as a concise handbook
candidate; the absent generic `Error`/`raise` constructor is already
documented in the approved handbook and is a deliberate design state, not a
surprising defect. The empty-`candidate_sha256` harness quirk is metadata-only
and does not warrant a ticket this cycle.

#### Next action

Replay `task-envcfg` against `lineage/handbook-candidate.md` (single trial) to
confirm the shadowing note and the env-config path still pass; cross-check the
same handbook candidate on `task-ecount` to validate the general path-handling
lesson. Promotion to `runtime/handbook.md` requires CTO approval after those
replays.

#### North-star impact

The run validates the core hypothesis that the environment/config surface
(`xsht api module:env`, `env.get_or`, typed helpers, `fs.write`, postfix `?`
propagation) is discoverable and composable — a practical sysadmin workflow
NOT covered by existing evals, with exact byte output and a loud malformed-value
failure. It produced no product defect. The staged handbook candidate improves
learnability/ergonomics for filesystem naming so future path-handling agents
avoid a deterministic linter rejection, advancing the learnable, ergonomic,
trustworthy XSH that the north star calls for.



## Eval proposal review

No CTO eval review was recorded.

## Handbook lineage

Checked-in `runtime/handbook.md`: `97c5d804c42c7742c9edfea4480163828d864279391d391df77aa60ee4a40e83`
- approved snapshot: `lineage/handbook-approved.md` sha256 `97c5d804c42c7742c9edfea4480163828d864279391d391df77aa60ee4a40e83` — promoted by CTO ledger; matches checked-in handbook
- candidate: `lineage/handbook-candidate.md` sha256 `c9b0e03d8c6b050ebf605b2383f3f6dd02a5eae00f74e9094ec17e6efc90130c` — DIFFERS; CTO promotion or rejection decision required


## Historical handbook backlog

Historical candidates: 35; differing: 29; ledger-dispositioned: 27; unresolved: 2.
Unresolved candidates requiring one explicit CTO decision:
- `runs/run-1785804030340/phases/02-reeval-task-ecount-006/lineage/handbook-candidate.md` sha256 `315d310efe3e48088d0a1325a66b8f11a484c5ec835cdff68e795ca1081e359a`
- `runs/run-1785804030340/phases/03-eval/lineage/handbook-candidate.md` sha256 `c9b0e03d8c6b050ebf605b2383f3f6dd02a5eae00f74e9094ec17e6efc90130c`


## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
