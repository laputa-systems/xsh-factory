# CTO briefing 02-reeval-task-bigfiles-004

This is the deterministic first-pass briefing for the CTO. The structured
`report.json` files and raw Pi sessions remain the source of truth.

## Result

fail
## Result

fail

## Outcome dimensions

- Product: `fail`
- Evaluator: `fail`
- Infrastructure: `fail`

## Operating context

- Mode: `eval`
- Request: `CYCLE-REQUEST.md`
- Structured report: `report.json`

## Phase outcomes

- `report.json`: result `fail`; report `report.json`
- `workers/eval-manager/task-bigfiles/report.json`: result `pass`; report `workers/eval-manager/task-bigfiles/report.json`
- `workers/eval-worker/task-bigfiles-1/report.json`: result `pass`; report `workers/eval-worker/task-bigfiles-1/report.json`


## Employee accounting

### Worker metrics

- `eval-manager/task-bigfiles` (`eval-manager`): result `pass`; report `workers/eval-manager/task-bigfiles/report.json`
  - Execution: `not recorded`; classification: `not recorded`
  - Turns: `8`; bucket tokens: `285823`; thinking blocks: `8`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=8; observed_output_tps=0`
  - Tool errors: `0`; cost: `0.013276`; budget: `0.150000`
- `eval-worker/task-bigfiles-1` (`eval-worker`): result `pass`; report `workers/eval-worker/task-bigfiles-1/report.json`
  - Execution: `fail`; classification: `evaluator_failed`
  - Turns: `19`; bucket tokens: `245349`; thinking blocks: `17`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=19; observed_output_tps=0`
  - Tool errors: `2`; cost: `0.012849`; budget: `0.500000`


### Nonzero tool results
### Provider health and latency

Provider retry, latency, and attribution data are in worker `report.json`
`provider_telemetry` fields. Missing telemetry is `unknown`, not evidence of
normal provider health. Provider switching is out of scope and tracked in
`TODO.md`.

### Nonzero tool results

- `eval-worker/task-bigfiles-1`, turn `7`, tool `bash`: xsht api: invalid API query 'language.effect.error'; expected KIND:VALUE
==postfix==
xsht api: invalid API query 'language.core.postfix-question'; expected KIND:VALUE


Command exited with code 2
  - Structured report: `workers/eval-worker/task-bigfiles-1/report.json`
- `eval-worker/task-bigfiles-1`, turn `7`, tool `bash`: sh: syntax error: unexpected "("


Command exited with code 2
  - Structured report: `workers/eval-worker/task-bigfiles-1/report.json`


### Cycle total

- Workers: `2`
- Assistant turns: `27`
- Bucket tokens: `531172`
- Cost (USD): `0.026124`
- Nonzero tool results: `2`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-manager/task-bigfiles

- Role: `eval-manager`
- Result: `fail`
- Report: `workers/eval-manager/task-bigfiles/REPORT.md`

#### Efficiency and evidence

Single-trial candidate-linked replay of `task-bigfiles` (candidate branch
`task-bigfiles-004`, XSH candidate commit `608ab11bcf25cb0f69df4cb352fa40b27c1be2b3`;
under-test baseline `xsh_commit` `c77b01a3e2fb676cc57cdeddbb7575be7723aa32`).

Worker `eval-worker/task-bigfiles-1`:
- assistant turns: 19 (user_messages 1)
- tool calls: 30 (bash 25, read 3, write 2)
- tool errors: 2
- agent wall: 509305 ms; session span: 508112 ms
- worker friction: one bounded API-discovery detour (effect-rule naming and a shell
  quoting error, see Tool-error findings) plus task solution that did not select
  `hidden: true`.

Trial 1 correctness: 8 of 9 cases byte-exact; `hidden_default` failed (dot-prefixed
regular file silently omitted). `hidden_bad_n` failure control passed (candidate exit
3, oracle exit 1; both nonzero, empty stdout). Restrictions passed, protocol passed,
timing passed.

#### Handbook or proposal decision

Provisional candidate staged at
`lineage/handbook-candidate.md` (approved snapshot copied plus one added paragraph under
"Paths and filesystem values"): recursive discovery omits dot-prefixed entries by default;
enable `hidden: true` explicitly when the workflow intends to cover every regular file
(e.g. size-ranked or backup reports). General lesson: make the hidden-entry default and
the "cover all files" intent explicit so agents stop silently missing dot entries.
Replay scope: `task-bigfiles`, plus at least one other recursive-discovery eval
(e.g. `task-ecount`/`task-histogram` if the workflow walks trees) to confirm it
generalizes before promotion to `runtime/handbook.md`. Not promoted this cycle.

#### Ticket or product decision

None. The observation is already captured by open, Approved. ticket
`task-bigfiles-004`; the new evidence (documentation present but insufficient in
isolation) is handled here as handbook guidance plus a directed replay of that branch,
not a new product ticket.

#### Next action

Replay `task-bigfiles` on branch `task-bigfiles-004` (candidate commit
`608ab11b...`) combined with the provisional handbook candidate
(`lineage/handbook-candidate.md`): verify the worker now selects `hidden: true` from
the contract/handbook and all nine cases (including `hidden_default`) are byte-exact.
Falsification check: if the worker again omits `hidden: true` despite both the API
contract and handbook guidance, treat the pending ticket's premise as insufficient and
re-scope it. Also replay one additional recursive-discovery eval before promoting the
handbook candidate.

#### North-star impact

This replay directly advances trustworthy, learnable XSH: it shows that documenting a
silent default (`hidden: false` omits dot entries) is necessary but not sufficient —
an agent still needs an explicit, general instruction to enable `hidden: true` when a
workflow intends "all regular files." The staged handbook candidate turns that into a
reusable idiom for every tree-walk task, preventing a size-ranked report from silently
dropping hidden files. It keeps the discovery boundary explicit (the North Star's
trust and ergonomics goals) and pins the next replay that will confirm or falsify the
guidance before it is trusted.



## Eval proposal review

No CTO eval review was recorded.

## Handbook lineage

Checked-in `runtime/handbook.md`: `9822e4305181e651c4a587b64afd487074216fae532c9a678f25a4d2f59fb3f8`
- approved snapshot: `factory-source/handbook-approved.md` sha256 `9822e4305181e651c4a587b64afd487074216fae532c9a678f25a4d2f59fb3f8` — promoted by CTO ledger; matches checked-in handbook
- approved snapshot: `lineage/handbook-approved.md` sha256 `9822e4305181e651c4a587b64afd487074216fae532c9a678f25a4d2f59fb3f8` — promoted by CTO ledger; matches checked-in handbook
- candidate: `lineage/handbook-candidate.md` sha256 `100f31a8317586a097c8fc3e0381ccbf83005a4ab28a4b77e80de366e0b773a7` — DIFFERS; CTO promotion or rejection decision required


## Historical handbook backlog

Historical candidates: 83; differing: 80; ledger-dispositioned: 79; unresolved: 1.
Unresolved candidates requiring one explicit CTO decision:
- `runs/run-1786195596255/phases/02-reeval-task-bigfiles-004/lineage/handbook-candidate.md` sha256 `100f31a8317586a097c8fc3e0381ccbf83005a4ab28a4b77e80de366e0b773a7`


## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
