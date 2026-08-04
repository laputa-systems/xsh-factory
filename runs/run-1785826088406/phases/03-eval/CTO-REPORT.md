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
  - Turns: `9`; bucket tokens: `191353`; thinking blocks: `9`
  - Tool errors: `0`; cost: `0.009426`; budget: `0.150000`
- `eval-worker/task-envcfg-1` (`eval-worker`): result `pass`; report `workers/eval-worker/task-envcfg-1/report.json`
  - Execution: `pass`; classification: `pass`
  - Turns: `45`; bucket tokens: `920011`; thinking blocks: `38`
  - Tool errors: `1`; cost: `0.025246`; budget: `0.500000`


### Nonzero tool results

- `eval-worker/task-envcfg-1`, turn `37`, tool `edit`: Could not find the exact text in /work/envcfg.xsh. The old text must match exactly including all whitespace and newlines.
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`


### Cycle total

- Workers: `2`
- Assistant turns: `54`
- Bucket tokens: `1111364`
- Cost (USD): `0.034672`
- Nonzero tool results: `1`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-manager/task-envcfg

- Role: `eval-manager`
- Result: `pass`
- Report: `workers/eval-manager/task-envcfg/REPORT.md`

#### Efficiency and evidence

Single trial (`task-envcfg-1`) as configured. Per worker report:
- assistant turns: 45
- tool calls: 52 (bash 42, edit 3, read 4, write 3)
- tool results: 52
- tool errors: 1 (edit at turn 37, stale file state)
- user messages: 1
- stop reasons: 44 `toolUse`, 1 `stop`
- session span: 275372 ms
- worker friction: minimal; the one failed edit was recovered on the very next
  turn with a smaller targeted edit (see Tool-error findings). Discovery friction
  was modest (see Tool-error findings for malformed `xsht api` probes).

#### Handbook or proposal decision

Unchanged. The approved snapshot is accurate for the build under test
(`env.int`/`parse_int` non-strict; no generic `Error(...)`; explicit digit
checking required). No candidate is staged. The persistent friction is not a
handbook gap — it is the unmerged registry defect in ticket `task-envcfg-002`.
Wrote `lineage/handbook-candidate.md` = approved snapshot unchanged (copy).

#### Ticket or product decision

None. The one strong reproducible observation (indiscoverable `fail`
primitive) is already captured and Approved as `tickets/task-envcfg-002.md`;
this run is a second independent live reproduction confirming it. A duplicate
ticket would add noise, not signal. The observation should proceed through
ticket 002's existing acceptance flow.

#### Next action

Re-run `evals/task-envcfg` against the merged implementation of ticket
`task-envcfg-002` (once `fail(message)` is registered in the `xsht api`
registry). Acceptance: the eval agent discovers `fail` from the reference alone
and writes `fail(...)?` on the malformed/empty-port branches (no sentinel
`parse_int`) with all ten cases and both failure controls still passing.
Optionally replay `task-ecount`/`task-tags` loud-exit boundaries to confirm the
discoverable primitive generalizes. That replay is the falsification check for
this report's classification.

#### North-star impact

This run demonstrates the environment/config surface is discoverable and
composable: with the approved handbook alone the worker produced a
byte-exact config renderer passing all ten cases, kept stdout clean, and made
expected failures visible (nonzero exit, no partial file) — core "glue that
speaks to system state" behavior. It also sharpens a durable trust lesson:
a language feature is not learnable if it is invisible to the reference the
handbook directs agents to. Confirming ticket `task-envcfg-002` drives the
north-star outcome that deliberate validation failures are both structured and
discoverable, so future agents replace an opaque sentinel with a first-class,
documented `fail`, reducing turns and sludge without a task-specific hack.



## Eval proposal review

No CTO eval review was recorded.

## Handbook lineage

Checked-in `runtime/handbook.md`: `97c5d804c42c7742c9edfea4480163828d864279391d391df77aa60ee4a40e83`
- approved snapshot: `lineage/handbook-approved.md` sha256 `97c5d804c42c7742c9edfea4480163828d864279391d391df77aa60ee4a40e83` — promoted by CTO ledger; matches checked-in handbook
- candidate: `lineage/handbook-candidate.md` sha256 `97c5d804c42c7742c9edfea4480163828d864279391d391df77aa60ee4a40e83` — promoted by CTO ledger; matches checked-in handbook


## Historical handbook backlog

Historical candidates: 49; differing: 34; ledger-dispositioned: 34; unresolved: 0.
No unresolved candidate content is present.

## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
