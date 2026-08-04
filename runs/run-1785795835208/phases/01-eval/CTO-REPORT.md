# CTO briefing 01-eval

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
  - Turns: `11`; bucket tokens: `512690`; thinking blocks: `10`
  - Tool errors: `0`; cost: `0.021714`; budget: `0.150000`
- `eval-worker/task-envcfg-1` (`eval-worker`): result `pass`; report `workers/eval-worker/task-envcfg-1/report.json`
  - Execution: `pass`; classification: `pass`
  - Turns: `52`; bucket tokens: `1046657`; thinking blocks: `43`
  - Tool errors: `4`; cost: `0.024969`; budget: `0.500000`


### Nonzero tool results

- `eval-worker/task-envcfg-1`, turn `3`, tool `bash`: query: api:env.get
status: exact

api: module.env.get
kind: module-function
purpose: Reads one environment variable as text.
contract: Missing variables and invalid host bytes remain distinguishable results.
effects: env
signature: env.get(name: Str) -> Result[Str, Error]
tags: env, get, lookup, utf8
---WRITE---
query: api:fs.write
status: exact

api: module.fs.write
kind: module-function
purpose: Writes text or bytes to a path.
contract: The input type selects the boundary explicitly and the write replaces the destination according to host filesystem policy.
effects: fs
signature: fs.write(path: Path, data: Bytes) -> Result[Unit, Error]
signature: fs.write(path: Path, data: Str) -> Result[Unit, Error]
tags: fs, write, filesystem
example:
  fs.write(p"output.txt", "done\n")?
---


Command exited with code 1
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`
- `eval-worker/task-envcfg-1`, turn `39`, tool `edit`: Could not find the exact text in /work/envcfg.xsh. The old text must match exactly including all whitespace and newlines.
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`
- `eval-worker/task-envcfg-1`, turn `44`, tool `bash`: [CFG_HOST=a CFG_PORT=9001 CFG_DEBUG=true] OK OUTMISMATCH  orc_exit=0 xsh_exit=0
/tmp/harness.sh: eval: line 4: syntax error: unexpected ";"


Command exited with code 2
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`
- `eval-worker/task-envcfg-1`, turn `48`, tool `bash`: check OK
lint OK
=== final run ===
exit=0
00000000: 686f 7374 3d6e 6f64 652d 610a 706f 7274  host=node-a.port
00000010: 3d39 3030 310a 6465 6275 673d 7472 7565  =9001.debug=true
00000020: 0a                                       .
=== invalid no file ===
exit=3
ls: /tmp/out3.cfg: No such file or directory


Command exited with code 1
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`


### Cycle total

- Workers: `2`
- Assistant turns: `63`
- Bucket tokens: `1559347`
- Cost (USD): `0.046682`
- Nonzero tool results: `4`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-manager/task-envcfg

- Role: `eval-manager`
- Result: `pass`
- Report: `workers/eval-manager/task-envcfg/REPORT.md`

#### Efficiency and evidence

One controller-executed fresh trial (`task-envcfg-1`) against the approved
handbook snapshot `lineage/handbook-approved.md` (sha256 `97c5d804...`) and XSH
commit `c2402341d7f3cf29b504ca8c22b89be2cf7a3eba`.

Worker `task-envcfg-1`:
- assistant turns: 52
- tool calls: 52 (42 bash, 4 edit, 4 read, 2 write)
- tool results: 52
- tool errors: 4 (all worker-side; see Tool-error findings)
- user messages: 1
- stop reasons: 51 toolUse, 1 stop
- session span: 243,763 ms (~4.1 min); agent wall 245,352 ms
- worker friction: moderate. The worker explored the strict-decimal
  validation problem heavily (parse_int/env.int leniency, no generic
  Error constructor, no require/assert guard); this drove a large share of
  the 52 turns and 4 tool errors. No restart, budget breach, or agent-state
  issue (agent_state pass, budget_state pass).

#### Handbook or proposal decision

Provisional candidate staged at
`lineage/handbook-candidate.md` (approved snapshot copied forward with two
concise additions). General lessons:
1. Strict byte-exact decimal contracts are not served by `parse_int`/`env.int`
   (leniency: signs, whitespace, hex, leading zeros); validate the raw string
   with `regex.compile("^[0-9]+$")?` and, on match failure, propagate an
   expected error via a deliberately-rejected typed conversion (e.g.
   `"".parse_int()?`).
2. `not` is not a negation keyword (`== false` instead); Result match arms use
   parenthesized patterns; Error values cannot be interpolated into display
   strings.

Replay scope: this is a one-trial plan; the candidate is provisional and is
NOT claimed as validated by replay (the controller executed one trial). It
must be replayed across the shared handbook lineage — primarily task-envcfg and
any future eval with a byte-exact config/numeric contract — before promotion to
`runtime/handbook.md`. The environment/config section already carried the
general "typed readers are not strict validators" rule and that part is
confirmed; the concrete regex+`?` idiom is the new guidance to replay.

#### Ticket or product decision

None. All four tool errors were worker-side noise, the run passed all gates,
and the strict-decimal/require-guard observations are a handbook-guidance
signal already addressed in the provisional candidate rather than a
reproducible XSH product defect warranting a same-cycle ticket.

#### Next action

Replay `task-envcfg` (one trial, same XSH commit `c2402341...`) against the
provisional `lineage/handbook-candidate.md` on the shared handbook lineage to
confirm the strict-decimal idiom removes the `parse_int`/guard exploration
friction and still passes all ten cases. A second, independent eval that
requires a byte-exact numeric/config contract would strengthen the candidate's
generality before promotion; if a later replay shows the sentinel `?` idiom is
task-specific or harmful, falsify and revert the candidate.

#### North-star impact

task-envcfg probes the environment/config surface that no prior approved eval
covered (typed env reads, byte-exact file delivery, loud malformed-value
failure). A handbook-and-agent-only run passed all ten cases including the two
failure controls, confirming that the `env`/`fs` modules, `get_or` absence-only
defaulting, and Result/`?` propagation are discoverable and composable from the
handbook. The one durable, reusable signal — that byte-exact decimal contracts
require an explicit regex + `?` sentinel rather than the lenient typed readers
— becomes concise handbook guidance that removes repeated agent trial-and-error
for any future config-validation or exact-numeric eval. The run advances
learnability (concrete strict-validation idiom), ergonomics (fewer turns spent
rediscovering parse leniency), and trust (a reproducible, exact-output config
shape with a correct failure control) in line with the XSH mission.



## Eval proposal review

No CTO eval review was recorded.

## Handbook lineage

Checked-in `runtime/handbook.md`: `97c5d804c42c7742c9edfea4480163828d864279391d391df77aa60ee4a40e83`
- approved snapshot: `lineage/handbook-approved.md` sha256 `97c5d804c42c7742c9edfea4480163828d864279391d391df77aa60ee4a40e83` — promoted by CTO ledger; matches checked-in handbook
- candidate: `lineage/handbook-candidate.md` sha256 `d9a2e262a449a28552b523f7a0d34c3542e7932f6c60a0761de28798229e8d35` — DIFFERS; CTO promotion or rejection decision required


## Historical handbook backlog

Historical candidates: 29; differing: 26; ledger-dispositioned: 25; unresolved: 1.
Unresolved candidates requiring one explicit CTO decision:
- `runs/run-1785795835208/phases/01-eval/lineage/handbook-candidate.md` sha256 `d9a2e262a449a28552b523f7a0d34c3542e7932f6c60a0761de28798229e8d35`


## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
