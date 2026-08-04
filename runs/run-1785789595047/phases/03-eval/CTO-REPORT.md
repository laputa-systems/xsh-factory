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
  - Turns: `11`; bucket tokens: `366658`; thinking blocks: `10`
  - Tool errors: `0`; cost: `0.013259`; budget: `0.150000`
- `eval-worker/task-envcfg-1` (`eval-worker`): result `pass`; report `workers/eval-worker/task-envcfg-1/report.json`
  - Execution: `pass`; classification: `pass`
  - Turns: `44`; bucket tokens: `973761`; thinking blocks: `35`
  - Tool errors: `4`; cost: `0.023868`; budget: `0.500000`


### Nonzero tool results

- `eval-worker/task-envcfg-1`, turn `9`, tool `bash`: err[check.display-conversion]: value cannot be displayed by print
  /tmp/t.xsh:4:9
    print $r
          ^^ value cannot be displayed by print
---run---
err[check.display-conversion]: value cannot be displayed by print
  /tmp/t.xsh:4:9
    print $r
          ^^ value cannot be displayed by print


Command exited with code 2
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`
- `eval-worker/task-envcfg-1`, turn `32`, tool `bash`: err[check.unknown-method]: unknown method `len` on Str
  envcfg.xsh:8:6
    if leftover.len() == 0 and port.len() > 0 {
       ^^^^^^^^^^^^^^ `len` is not defined for Str
note: available methods include: `byte_len()`, `count_bytes()`, `count_chars()`

err[check.unknown-method]: unknown method `len` on Str
  envcfg.xsh:8:30
    if leftover.len() == 0 and port.len() > 0 {
                               ^^^^^^^^^^ `len` is not defined for Str
note: available methods include: `byte_len()`, `count_bytes()`, `count_chars()`
=== run valid ===
err[check.unknown-method]: unknown method `len` on Str
  envcfg.xsh:8:6
    if leftover.len() == 0 and port.len() > 0 {
       ^^^^^^^^^^^^^^ `len` is not defined for Str
note: available methods include: `byte_len()`, `count_bytes()`, `count_chars()`

err[check.unknown-method]: unknown method `len` on Str
  envcfg.xsh:8:30
    if leftover.len() == 0 and port.len() > 0 {
                               ^^^^^^^^^^ `len` is not defined for Str
note: available methods include: `byte_len()`, `count_bytes()`, `count_chars()`
rc=2
--- file ---
cat: can't open '/tmp/out.cfg': No such file or directory
=== oracle compare ===
diff: can't stat '/tmp/out.cfg': No such file or directory


Command exited with code 2
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`
- `eval-worker/task-envcfg-1`, turn `35`, tool `bash`: sh: bash: not found


Command exited with code 127
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`
- `eval-worker/task-envcfg-1`, turn `39`, tool `bash`: check rc=0
=== valid ===
rc=0
00000000: 686f 7374 3d6e 6f64 652d 610a 706f 7274  host=node-a.port
00000010: 3d39 3030 310a 6465 6275 673d 7472 7565  =9001.debug=true
00000020: 0a                                       .
=== invalid port 5x ===
runtime traceback
executable: /usr/local/bin/xsh
operation: result.propagate
error: parse-int: invalid integer `x`
call path:
  1. proc main at envcfg.xsh:1:1-1:1
rc=3
ls: /tmp/o.cfg: No such file or directory


Command exited with code 1
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`


### Cycle total

- Workers: `2`
- Assistant turns: `55`
- Bucket tokens: `1340419`
- Cost (USD): `0.037127`
- Nonzero tool results: `4`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-manager/task-envcfg

- Role: `eval-manager`
- Result: `pass`
- Report: `workers/eval-manager/task-envcfg/REPORT.md`

#### Efficiency and evidence

Trial 1 (task-envcfg-1), the only configured trial:
- assistant turns: 44
- tool calls: 57 (bash 49, read 4, write 2, edit 2); tool results 57
- tool errors: 4 (all non-blocking; see `## Tool-error findings`)
- session span: 362,036 ms (~6 min); agent wall 363,804 ms
- worker friction: all 4 tool errors were exploratory; three were already
  covered by the approved handbook, one was self-validation. The entry-signature
  mismatch (task-envcfg-007) cost the most idle exploration (turns ~36–58) but
  did not block completion. No budget breach ($0.024 vs $0.50).

#### Handbook or proposal decision

Provisional candidate staged at
`runs/run-1785789595047/phases/03-eval/lineage/handbook-candidate.md`
(approved snapshot + two concise general additions, chosen so the change is a
short general rule rather than a recipe collection):
1. `Source and entry points` — main must use the spread form `(...argv:
   List[Str])`; the non-spread form passes `xsht check` but fails at runtime
   with `runtime.compact-unsupported-main`.
2. Boolean logic uses `and`/`or`/`not`; `&&`/`&`/`||` are parse errors.

Replay scope: this is a one-trial run, so the candidate is NOT yet trusted.
It must be replayed by task-tags and task-ecount (and a future task-envcfg) on
the shared handbook lineage before promotion to `runtime/handbook.md`. The two
edits are deliberately independent of the envcfg task outcome: the main-spread
and boolean-operator facts apply to any entry-point/conditional XSH program.

#### Ticket or product decision

- `tickets/task-envcfg-007.md` — `xsht check` accepts a non-spread `main`
  signature that the runtime rejects with `runtime.compact-unsupported-main`.
  Opened for the NEXT cycle (not dispatched this cycle). General correctness
  defect: checker and runtime disagree on valid entry-point shape. This is the
  single strong reproducible observation; all other observations are covered
  by the handbook or are noise.

#### Next action

Replay `task-envcfg` (and the shared candidates through `task-tags` /
`task-ecount`) against the handbook candidate when promoted, to confirm the
main-spread and `and`-operator notes remove the observed friction and that the
10 correctness cases still pass byte-for-byte. When task-envcfg-007 is merged,
run a post-merge replay asserting `xsht check` gives check-time feedback on the
spread-form requirement with no `runtime.compact-unsupported-main` run-time
round-trip.

#### North-star impact

The run confirms the env/config surface (the newest eval) is discoverable and
composable through the handbook + `xsht api`: a fresh agent produced a
byte-exact, restriction-clean solution in ~6 minutes for under $0.03 with no
blocking errors. The durable signal is learnability: two general XSH facts the
handbook did not state (`main` spread form; `and`/`or` word operators) cost the
worker idle discovery cycles, and one checker/runtime disagreement
(task-envcfg-007) is a genuine correctness gap that undermines trust in
`xsht check` as a gate. Teaching those facts and fixing the check/runtime split
reduce repeated agent friction on every future entry-point task, advancing
ergonomics, correctness, and trust — the north-star goals — rather than a
task-specific recipe.



## Eval proposal review

No CTO eval review was recorded.

## Handbook lineage

Checked-in `runtime/handbook.md`: `97c5d804c42c7742c9edfea4480163828d864279391d391df77aa60ee4a40e83`
- approved snapshot: `lineage/handbook-approved.md` sha256 `97c5d804c42c7742c9edfea4480163828d864279391d391df77aa60ee4a40e83` — promoted by CTO ledger; matches checked-in handbook
- candidate: `lineage/handbook-candidate.md` sha256 `0014e368e601214f6b47a41d94009d9e142b683a53dd656fbd4e6d97b23d3f20` — DIFFERS; CTO promotion or rejection decision required


## Historical handbook backlog

Historical candidates: 27; differing: 25; ledger-dispositioned: 24; unresolved: 1.
Unresolved candidates requiring one explicit CTO decision:
- `runs/run-1785789595047/phases/03-eval/lineage/handbook-candidate.md` sha256 `0014e368e601214f6b47a41d94009d9e142b683a53dd656fbd4e6d97b23d3f20`


## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
