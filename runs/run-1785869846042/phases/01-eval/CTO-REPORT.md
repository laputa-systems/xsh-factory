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
- `workers/eval-manager/task-envcfg/report.json`: result `pass`; report `workers/eval-manager/task-envcfg/report.json`
- `workers/eval-worker/task-envcfg-1/report.json`: result `pass`; report `workers/eval-worker/task-envcfg-1/report.json`


## Employee accounting

### Worker metrics

- `eval-manager/task-envcfg` (`eval-manager`): result `pass`; report `workers/eval-manager/task-envcfg/report.json`
  - Execution: `not recorded`; classification: `not recorded`
  - Turns: `12`; bucket tokens: `374884`; thinking blocks: `9`
  - Tool errors: `1`; cost: `0.012282`; budget: `0.150000`
- `eval-worker/task-envcfg-1` (`eval-worker`): result `pass`; report `workers/eval-worker/task-envcfg-1/report.json`
  - Execution: `pass`; classification: `pass`
  - Turns: `25`; bucket tokens: `321913`; thinking blocks: `17`
  - Tool errors: `2`; cost: `0.009069`; budget: `0.500000`


### Nonzero tool results

- `eval-manager/task-envcfg`, turn `5`, tool `bash`: === sha of work/handbook vs approved ===
97c5d804c42c7742c9edfea4480163828d864279391d391df77aa60ee4a40e83  work/handbook.md
shasum: ../../lineage/handbook-approved.md: No such file or directory


Command exited with code 1
  - Structured report: `workers/eval-manager/task-envcfg/report.json`
- `eval-worker/task-envcfg-1`, turn `15`, tool `bash`: == check ==
err[check.unresolved-call]: unresolved pure function call
  envcfg.xsh:8:5
      fail("CFG_PORT must be a decimal integer")?
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ unresolved pure function call
== fmt ==
err[check.unresolved-call]: unresolved pure function call
  envcfg.xsh:8:5
      fail("CFG_PORT must be a decimal integer")?
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ unresolved pure function call
== lint ==
err[check.unresolved-call]: unresolved pure function call
  envcfg.xsh:8:5
      fail("CFG_PORT must be a decimal integer")?
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ unresolved pure function call


Command exited with code 2
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`
- `eval-worker/task-envcfg-1`, turn `19`, tool `bash`: host-empty             xsh_rc=0 oracle_rc=0
  xsh_file: sh: %q\n: invalid format
  oracle:   sh: %q\n: invalid format
port-empty-pres        xsh_rc=3 oracle_rc=1
  xsh_file: sh: %q\n: invalid format
  oracle:   sh: %q\n: invalid format
port-invalid           xsh_rc=3 oracle_rc=1
  xsh_file: sh: %q\n: invalid format
sh: %q\n: invalid format
  oracle:   port-neg               xsh_rc=3 oracle_rc=1
  xsh_file: sh: %q\n: invalid format
  oracle:   sh: %q\n: invalid format
port-plus              xsh_rc=3 oracle_rc=1
  xsh_file: sh: %q\n: invalid format
  oracle:   sh: %q\n: invalid format
port-space             xsh_rc=3 oracle_rc=1
  xsh_file: sh: %q\n: invalid format
  oracle:   sh: %q\n: invalid format
port-leading0          xsh_rc=0 oracle_rc=0
  xsh_file: sh: %q\n: invalid format
  oracle:   sh: %q\n: invalid format
debug-empty            xsh_rc=0 oracle_rc=0
  xsh_file: sh: %q\n: invalid format
  oracle:   sh: %q\n: invalid format
full                   xsh_rc=0 oracle_rc=0
  xsh_file: sh: %q\n: invalid format
  oracle:   sh: %q\n: invalid format


Command exited with code 1
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`


### Cycle total

- Workers: `2`
- Assistant turns: `37`
- Bucket tokens: `696797`
- Cost (USD): `0.021351`
- Nonzero tool results: `3`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-manager/task-envcfg

- Role: `eval-manager`
- Result: `pass`
- Report: `workers/eval-manager/task-envcfg/REPORT.md`

#### Efficiency and evidence

Single trial (controller-configured count `1`), worker `task-envcfg-1` on
`openrouter/deepseek/deepseek-v4-flash-0731`.

- Assistant turns: 25 (1 x `stop`, 24 x `toolUse`)
- Tool calls: 31; tool results: 31; tool errors: 2
- Tool mix: bash 25, edit 1, read 3, write 2
- User messages: 1 (task prompt)
- Session span: 158,579 ms (worker `session_span_ms`); wrapper `agent_wall_ms`
  159,931 ms
- Worker friction: one one-turn wrong-path (`fail(...)`) plus one self-resolved
  local test-harness printf format error. No budget breach (0 failures). All
  three worker gates (`agent_state`, `evaluator_state`, `reporting_state`)
  `pass`; `classification: pass`.

The manager phase itself is the remaining deliverable: the controller staged
this `REPORT.md` fail-closed and left the handbook lineage candidate missing;
both are completed here.

#### Handbook or proposal decision

Provisional candidate staged at
`runs/run-1785869846042/phases/01-eval/lineage/handbook-candidate.md`
(sha `e6f210b0f8f1fa2a605a5d30c145635b13e5e7743fd97974f2dbdce0f115d81b`),
an exact copy of the approved snapshot plus one added note in the
`Effects and errors` section warning agents that `xsht api language:core.fail`
advertises a rule the pinned build rejects as `unresolved pure function call`
and to stay on the typed-conversion failure path.

- General lesson: when an API reference advertises a construct that the
  runtime rejects, warn agents up front so they do not spend a
  `check`/`lint` round discovering it.
- Replay scope: this candidate should be replayed by the next
  `task-envcfg` cycle (and by any future config/validation-boundary eval)
  against the same pinned build. It is a mitigation; the durable fix is the
  product ticket (`fail`/deliberate-error primitive).
- Unchanged otherwise: the approved snapshot already correctly taught the
  `env.get_or` presence-vs-empty semantics, the `env.int`/`env.bool`
  non-strictness, and the parse-failure route, all of which this run
  validated. No eval-local handbook exists; the single factory handbook
  remains the one authority.

#### Ticket or product decision

Zero. The one strong reproducible observation (advertised-but-non-callable
`fail`) is already tracked by open ticket `task-envcfg-001`; creating a
duplicate would violate the one-strong-observation rule.

#### Next action

- Eval: `task-envcfg` (single fresh trial), replaying the approved/candidate
  handbook lineage `runs/run-1785869846042/phases/01-eval/lineage/`.
- Post-merge check: when implementation of `task-envcfg-001`
  (callable deliberate-error `fail`/`Error` primitive) lands and is merged,
  replay `task-envcfg` against that commit and require `xsht api
  search:fail` discovery plus adoption of `fail(...)?` while all ten
  evaluator cases still pass — the ticket's stated acceptance gate.
- Falsification check: the handbook candidate is falsified if a replay shows
  the `fail(...)` warning misleads or is unnecessary (i.e., a callable
  `fail` appears in a later build without this note).

#### North-star impact

This run validated that the single factory handbook transfers to the
environment/config surface: an agent discovered `env.get_or`, applied
presence-vs-empty defaults, and rendered a byte-exact file — all 10 cases
correct — showing practical, learnable, ergonomic XSH for a real
container/sysadmin shape. Two durable signals emerged: (1) the advertised but
non-callable `fail` is a trust-eroding doc/implementation gap that makes
expected failures opaque — exactly the "make expected failures visible"
north-star concern, tracked as `task-envcfg-001`; and (2) a concise handbook
warning can remove the one-turn `fail` detour until the product lands. Both
point at a cleaner, more composable validation boundary rather than a
task-specific trick.



## Eval proposal review

No CTO eval review was recorded.

## Handbook lineage

Checked-in `runtime/handbook.md`: `97c5d804c42c7742c9edfea4480163828d864279391d391df77aa60ee4a40e83`
- approved snapshot: `lineage/handbook-approved.md` sha256 `97c5d804c42c7742c9edfea4480163828d864279391d391df77aa60ee4a40e83` — promoted by CTO ledger; matches checked-in handbook
- candidate: `lineage/handbook-candidate.md` sha256 `e6f210b0f8f1fa2a605a5d30c145635b13e5e7743fd97974f2dbdce0f115d81b` — DIFFERS; CTO promotion or rejection decision required


## Historical handbook backlog

Historical candidates: 56; differing: 37; ledger-dispositioned: 36; unresolved: 1.
Unresolved candidates requiring one explicit CTO decision:
- `runs/run-1785869846042/phases/01-eval/lineage/handbook-candidate.md` sha256 `e6f210b0f8f1fa2a605a5d30c145635b13e5e7743fd97974f2dbdce0f115d81b`


## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
