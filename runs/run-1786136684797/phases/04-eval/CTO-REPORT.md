# CTO briefing 04-eval

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
- `workers/eval-manager/task-propsort/report.json`: result `pass`; report `workers/eval-manager/task-propsort/report.json`
- `workers/eval-worker/task-propsort-1/report.json`: result `pass`; report `workers/eval-worker/task-propsort-1/report.json`


## Employee accounting

### Worker metrics

- `eval-manager/task-propsort` (`eval-manager`): result `pass`; report `workers/eval-manager/task-propsort/report.json`
  - Execution: `not recorded`; classification: `not recorded`
  - Turns: `14`; bucket tokens: `413773`; thinking blocks: `13`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=14; observed_output_tps=0`
  - Tool errors: `1`; cost: `0.012255`; budget: `0.150000`
- `eval-worker/task-propsort-1` (`eval-worker`): result `pass`; report `workers/eval-worker/task-propsort-1/report.json`
  - Execution: `fail`; classification: `evaluator_failed`
  - Turns: `24`; bucket tokens: `235733`; thinking blocks: `14`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=24; observed_output_tps=0`
  - Tool errors: `4`; cost: `0.005960`; budget: `0.500000`


### Nonzero tool results
### Provider health and latency

Provider retry, latency, and attribution data are in worker `report.json`
`provider_telemetry` fields. Missing telemetry is `unknown`, not evidence of
normal provider health. Provider switching is out of scope and tracked in
`TODO.md`.

### Nonzero tool results

- `eval-manager/task-propsort`, turn `10`, tool `bash`: d9c18b999618bd757177d25568065b5bbd17bc65
---
d9c18b9 cto: close four-way discovery cycle 1
3db703a cto: add paired discovery throughput
fc8e0b1 cto: close run-1786131191668
---commit under test---


Command exited with code 128
  - Structured report: `workers/eval-manager/task-propsort/report.json`
- `eval-worker/task-propsort-1`, turn `6`, tool `bash`: query: language:stream.sort-by
status: exact

api: language.stream.sort-by
kind: language
purpose: Sorts stream items by a projected key.
contract: The key projection controls ordering and the stage materializes the input before emitting results. Supported key types are Int, Str, Bool, Path, and Records whose fields are themselves supported keys; records compare field by field in sorted field-name order. The default order is ascending and --desc reverses it. The sort is stable, so items with equal keys keep their source order and the two-pass idiom (sort by the secondary key first, then by the primary key) produces a reliable compound ordering. Other key types are rejected at check time and fail with a runtime diagnostic that names the stage and key type.
effects: none
signature: sort-by(--desc: Bool = false, block) -> Stream[T]
tags: stream, sorting, projection, stable
===LIST===


Command exited with code 1
  - Structured report: `workers/eval-worker/task-propsort-1/report.json`
- `eval-worker/task-propsort-1`, turn `9`, tool `bash`: err[check.effect-violation]: `?` requires the `error` effect
  /tmp/probe.xsh:2:11
    let t = p"/tmp/t2.txt".read_text()?
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^ `?` requires the `error` effect


Command exited with code 2
  - Structured report: `workers/eval-worker/task-propsort-1/report.json`
- `eval-worker/task-propsort-1`, turn `12`, tool `bash`: err[parse.expected-terminator]: expected statement terminator
  propsort.xsh:2:31
    let path = p"${argv.get(0, "")}"
                                ^^^^ expected statement terminator
===FMT===
err[parse.expected-terminator]: expected statement terminator
  propsort.xsh:2:31
    let path = p"${argv.get(0, "")}"
                                ^^^^ expected statement terminator
===LINT===
err[parse.expected-terminator]: expected statement terminator
  propsort.xsh:2:31
    let path = p"${argv.get(0, "")}"
                                ^^^^ expected statement terminator


Command exited with code 2
  - Structured report: `workers/eval-worker/task-propsort-1/report.json`
- `eval-worker/task-propsort-1`, turn `17`, tool `bash`: err[check.standard-module-shadow]: name `path` shadows the standard module `path`
  propsort.xsh:3:3
    let path = fp"${name}"
    ^^^^^^^^^^^^^^^^^^^^^^ name `path` shadows the standard module `path`

err[check.unknown-module-api]: unknown module API
  propsort.xsh:4:14
    let text = path.read_text()?
               ^^^^^^^^^^^^^^^^ unknown module API

err[check.bare-print-ident]: bare identifiers in print are ambiguous; use `$ident` to dereference or `"text"` for a literal
  propsort.xsh:12:11
      print l
            ^ bare identifiers in print are ambiguous; use `$ident` to dereference or `"text"` for a literal
help: use `$` shorthand -> $l
===FMT===
err[check.standard-module-shadow]: name `path` shadows the standard module `path`
  propsort.xsh:3:3
    let path = fp"${name}"
    ^^^^^^^^^^^^^^^^^^^^^^ name `path` shadows the standard module `path`

err[check.unknown-module-api]: unknown module API
  propsort.xsh:4:14
    let text = path.read_text()?
               ^^^^^^^^^^^^^^^^ unknown module API

err[check.bare-print-ident]: bare identifiers in print are ambiguous; use `$ident` to dereference or `"text"` for a literal
  propsort.xsh:12:11
      print l
            ^ bare identifiers in print are ambiguous; use `$ident` to dereference or `"text"` for a literal
help: use `$` shorthand -> $l
===LINT===
err[check.standard-module-shadow]: name `path` shadows the standard module `path`
  propsort.xsh:3:3
    let path = fp"${name}"
    ^^^^^^^^^^^^^^^^^^^^^^ name `path` shadows the standard module `path`
err[check.unknown-module-api]: unknown module API
  propsort.xsh:4:14
    let text = path.read_text()?
               ^^^^^^^^^^^^^^^^ unknown module API
err[check.bare-print-ident]: bare identifiers in print are ambiguous; use `$ident` to dereference or `"text"` for a literal
  propsort.xsh:12:11
      print l
            ^ bare identifiers in print are ambiguous; use `$ident` to dereference or `"text"` for a literal
help: use `$` shorthand -> $l


Command exited with code 2
  - Structured report: `workers/eval-worker/task-propsort-1/report.json`


### Cycle total

- Workers: `2`
- Assistant turns: `38`
- Bucket tokens: `649506`
- Cost (USD): `0.018215`
- Nonzero tool results: `5`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-manager/task-propsort

- Role: `eval-manager`
- Result: `fail`
- Report: `workers/eval-manager/task-propsort/REPORT.md`

#### Efficiency and evidence

Single trial (`task-propsort-1`), eval-worker:
- Assistant turns: 24 (1 user message)
- Tool calls: 28; tool results: 28; tool errors: 4
- Worker friction: 4 resolved dev-loop errors (see Tool-error findings). All
  were the model learning the effects contract, path interpolation, and lint
  feedback; none were blockers and all were corrected within the session.
- Session span: 55,891 ms (agent wall 59,902 ms) — fast, no latency concern.

Provider telemetry present; `retry_count` 0, `provider_errors` [], retry
delays 0. No external-health signal. Latency attribution: not a factor;
efficiency judged from turns/tokens/tool errors/correctness.

#### Handbook or proposal decision

Unchanged. Copied `lineage/handbook-approved.md`
(`sha256 3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b`)
to `lineage/handbook-candidate.md` unchanged (same hash). No agent friction
justified a new rule: the dev-loop errors were already covered by existing
handbook guidance (effects, `fp"${expr}"`, `print $var`), and the one real
finding is an evaluator restriction heuristic that no handbook sentence can
cure. No candidate to promote; no replay of a candidate occurred.

#### Ticket or product decision

None. The restriction-proxy false negative is an eval-evaluator issue, not a
general XSH ergonomics/correctness product problem, and not factory shared
infrastructure. Per manager policy it is reported as an evaluator/harness
finding rather than a ticket; no engineer dispatch.

#### Next action

No handbook candidate to falsify. The useful next step is a fresh
`task-propsort` trial after the eval designer decides whether `Path.read_text()`
(and any typed, non-hard-coded read) should satisfy the "reads through XSH
filesystem/text APIs" restriction gate, or whether the `"fs."` proxy should be
relaxed to check for subprocess escape and hard-coded output only. A
subsequent trial under the same `handbook-approved.md`
(`3b56a781...`) would then measure whether the eval's stated fs-facade
hypothesis is exercised.

#### North-star impact

Muted, infrastructure-leaning. The agent produced a correct, small,
subprocess-free program through the typed `Path.read_text()` host API,
tentatively confirming that the text/file/stream read->filter->sort->exact
output pipeline is reachable. But because the eval's restriction proxy
rejected that correct read, the run did not cleanly test the design
hypothesis (discoverability of the `fs` read facade) and recorded a false
fail. No durable product or handbook improvement emerged this cycle; the
durable takeaway is a request to correct the eval's restriction heuristic so
the eval measures the intended capability rather than a literal `"fs."`
substring.



## Eval proposal review

No CTO eval review was recorded.

## Handbook lineage

Checked-in `runtime/handbook.md`: `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b`
- approved snapshot: `lineage/handbook-approved.md` sha256 `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b` — promoted by CTO ledger; matches checked-in handbook
- candidate: `lineage/handbook-candidate.md` sha256 `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b` — promoted by CTO ledger; matches checked-in handbook


## Historical handbook backlog

Historical candidates: 19; differing: 11; ledger-dispositioned: 8; unresolved: 3.
Unresolved candidates requiring one explicit CTO decision:
- `runs/run-1786136684797/phases/01-eval/lineage/handbook-candidate.md` sha256 `417e9281eb2d40e6d5e17a03dfcd06085764a4c3357df074580a44c91e34d2b7`
- `runs/run-1786136684797/phases/02-eval/lineage/handbook-candidate.md` sha256 `51468c5c14cb9152128239fc804c521fac8389aa428f53cf20b97d282886c814`
- `runs/run-1786136684797/phases/03-eval/lineage/handbook-candidate.md` sha256 `83b0202d30fbfb80eb0755582bfd015f69adf5d538ecd1d5c360ee6b2e08dba3`


## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
