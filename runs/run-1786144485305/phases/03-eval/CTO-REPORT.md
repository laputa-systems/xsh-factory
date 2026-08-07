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
- `workers/eval-manager/task-treecmp/report.json`: result `pass`; report `workers/eval-manager/task-treecmp/report.json`
- `workers/eval-worker/task-treecmp-1/report.json`: result `pass`; report `workers/eval-worker/task-treecmp-1/report.json`


## Employee accounting

### Worker metrics

- `eval-manager/task-treecmp` (`eval-manager`): result `pass`; report `workers/eval-manager/task-treecmp/report.json`
  - Execution: `not recorded`; classification: `not recorded`
  - Turns: `22`; bucket tokens: `706123`; thinking blocks: `20`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=22; observed_output_tps=0`
  - Tool errors: `1`; cost: `0.019564`; budget: `0.150000`
- `eval-worker/task-treecmp-1` (`eval-worker`): result `pass`; report `workers/eval-worker/task-treecmp-1/report.json`
  - Execution: `pass`; classification: `pass`
  - Turns: `56`; bucket tokens: `1225216`; thinking blocks: `47`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=56; observed_output_tps=0`
  - Tool errors: `0`; cost: `0.027835`; budget: `0.500000`


### Nonzero tool results
### Provider health and latency

Provider retry, latency, and attribution data are in worker `report.json`
`provider_telemetry` fields. Missing telemetry is `unknown`, not evidence of
normal provider health. Provider switching is out of scope and tracked in
`TODO.md`.

### Nonzero tool results

- `eval-manager/task-treecmp`, turn `15`, tool `bash`: 3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b  lineage/handbook-approved.md
--- candidate exists? ---
total 24
drwxr-xr-x   3 josh  staff     96 Aug  7 16:14 .
drwxr-xr-x  24 josh  staff    768 Aug  7 16:24 ..
-rw-r--r--   1 josh  staff  10305 Aug  7 16:14 handbook-approved.md
--- runtime handbook map.empty/for/bool ---


Command exited with code 1
  - Structured report: `workers/eval-manager/task-treecmp/report.json`


### Cycle total

- Workers: `2`
- Assistant turns: `78`
- Bucket tokens: `1931339`
- Cost (USD): `0.047399`
- Nonzero tool results: `1`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-manager/task-treecmp

- Role: `eval-manager`
- Result: `pass`
- Report: `workers/eval-manager/task-treecmp/REPORT.md`

#### Efficiency and evidence

Single fresh trial (`task-treecmp-1`) against approved handbook snapshot
`lineage/handbook-approved.md`
(sha256 `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b`),
XSH commit `a248267612439dfcfa203fba583ac3e95d37f70c`.

- assistant turns: 56
- tool calls: 68 (63 bash, 1 edit, 4 read)
- tool results: 68
- tool errors: 0 (structured `tool_errors` arrays empty)
- thinking blocks: 47
- session span: 244418 ms (~244 s)
- stop reasons: 1 `stop`, 55 `toolUse`

Worker friction: moderate but productive. The agent followed the documented
`xsht api` discovery path, issuing many small API queries (fs, stream stage,
method:Map, method:Path, Str/Int conversions) before assembling the program.
No repeated tool failures, no dead-end loops that would indicate a harness or
provider problem.

#### Handbook or proposal decision

Provisional candidate staged. The approved snapshot is unchanged; a candidate
was written to
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786144485305/phases/03-eval/lineage/handbook-candidate.md`
(sha256 differs from approved), adding three short, general rules:

1. No Map literal — `{"a": 1}` is a Record; create an empty map with
   `map.empty()` and add with `set` / check with `has`.
2. No `for` loop — iterate via stream stages and accumulate into an outer
   `var`.
3. Boolean logic uses word operators `and`/`or`; `&&`/`||` cause a parse error.

These are general XSH idioms that reduce repeated discovery across all future
evals that build keyed lookups, aggregate over collections, or write compound
conditions. They do not teach a treecmp-specific trick. Promotion requires
replay and CTO approval.

#### Ticket or product decision

None. The run passed cleanly; the frictions observed are generalizable handbook
facts now captured as a provisional candidate rather than a product-defect
ticket. No strong reproducible product/tooling defect was observed in this
single trial.

#### Next action

- Eval: `task-treecmp` (replay the staged provisional
  `lineage/handbook-candidate.md`).
- Also replay a cross-eval that exercises `Map` construction and stream
  accumulation to test whether the no-Map-literal / no-`for` / `and`/`or`
  rules generalize, e.g. an approved keyed-merge eval (`task-keyjoin`) or
  aggregation eval (`task-groupsum` / `task-svcstat`) with the candidate
  handbook.
- Falsification check: the candidate is trusted only if a later replay with the
  candidate handbook reaches correctness with fewer discovery turns (no
  re-derivation of `map.empty()`, word operators, or stream accumulation) and
  still passes all cases.

#### North-star impact

This run advances the practical, learnable, ergonomic, trustworthy-XSH mission
by demonstrating, on a substantive dual-source reconciliation task (manifest →
keyed lookup, tree walk → relative path + size, three-way merge), that the
current handbook is sufficient to reach a byte-exact, restriction-clean
solution across all 12 cases including the two loud failure controls. It also
surfaces three general language idioms — no Map literal, no `for` loop, boolean
`and`/`or` — whose absence caused the dominant discovery effort. Capturing those
in a provisional handbook candidate reduces repeated agent exploration for keyed,
aggregating, and conditional work, which is exactly the "fewer guesses,
workarounds, and repeated discoveries" ergonomics goal in the North Star, and
the cross-eval replay plan keeps the claim honest until it generalizes beyond
this single task.



## Eval proposal review

No CTO eval review was recorded.

## Handbook lineage

Checked-in `runtime/handbook.md`: `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b`
- approved snapshot: `lineage/handbook-approved.md` sha256 `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b` — promoted by CTO ledger; matches checked-in handbook
- candidate: `lineage/handbook-candidate.md` sha256 `d71b018bb714011fded996e535a5ea2ac3ba630c525ced52ea41c98184f27ec7` — DIFFERS; CTO promotion or rejection decision required


## Historical handbook backlog

Historical candidates: 30; differing: 17; ledger-dispositioned: 16; unresolved: 1.
Unresolved candidates requiring one explicit CTO decision:
- `runs/run-1786144485305/phases/03-eval/lineage/handbook-candidate.md` sha256 `d71b018bb714011fded996e535a5ea2ac3ba630c525ced52ea41c98184f27ec7`


## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
