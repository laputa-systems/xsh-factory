# CTO briefing 01-eval

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
- `workers/eval-manager/task-findexec/report.json`: result `pass`; report `workers/eval-manager/task-findexec/report.json`
- `workers/eval-worker/task-findexec-1/report.json`: result `pass`; report `workers/eval-worker/task-findexec-1/report.json`


## Employee accounting

### Worker metrics

- `eval-manager/task-findexec` (`eval-manager`): result `pass`; report `workers/eval-manager/task-findexec/report.json`
  - Execution: `not recorded`; classification: `not recorded`
  - Turns: `14`; bucket tokens: `474550`; thinking blocks: `11`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=14; observed_output_tps=0`
  - Tool errors: `1`; cost: `0.018085`; budget: `0.150000`
- `eval-worker/task-findexec-1` (`eval-worker`): result `pass`; report `workers/eval-worker/task-findexec-1/report.json`
  - Execution: `fail`; classification: `evaluator_failed`
  - Turns: `22`; bucket tokens: `199145`; thinking blocks: `12`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=22; observed_output_tps=0`
  - Tool errors: `2`; cost: `0.005102`; budget: `0.500000`


### Nonzero tool results
### Provider health and latency

Provider retry, latency, and attribution data are in worker `report.json`
`provider_telemetry` fields. Missing telemetry is `unknown`, not evidence of
normal provider health. Provider switching is out of scope and tracked in
`TODO.md`.

### Nonzero tool results

- `eval-manager/task-findexec`, turn `13`, tool `bash`: 3:## Result
19:## Effort metrics
33:## Usage and cost
46:## Thinking evidence
59:## Tool-error findings
81:## Timing evidence
92:## Observation classification
122:## Handbook decision
142:## Tickets created
150:## Post-merge decisions
156:## Next replay
168:## North-star impact
--- candidate diff vs approved ---
69a70,74
> Boolean conditions are composed with the word-form operators `and` and `or`
> (`e.kind == "file" and e.owner_executable`); the C-style `&&` and `||` are
> rejected at parse time with a message that suggests the word form, so reach
> for the word operators rather than the shell/C form.
>


Command exited with code 1
  - Structured report: `workers/eval-manager/task-findexec/report.json`
- `eval-worker/task-findexec-1`, turn `9`, tool `bash`: err[parse.unsupported-boolean-operator]: unsupported operator '&&': XSH boolean operators are the word forms 'and'
  findexec.xsh:4:37
      |> where { |e| e.kind == "file" && e.owner_executable }
                                      ^^ use 'and' instead of '&&'

err[parse.expected-terminator]: expected statement terminator
  findexec.xsh:4:37
      |> where { |e| e.kind == "file" && e.owner_executable }
                                      ^ expected statement terminator

err[parse.expected-expression]: expected expression
  findexec.xsh:4:37
      |> where { |e| e.kind == "file" && e.owner_executable }
                                      ^ expected expression

err[parse.expected-expression]: expected expression
  findexec.xsh:5:5
      |> sort-by { |e| e.path }
      ^^ expected expression

err[parse.expected-expression]: expected expression
  findexec.xsh:6:5
      |> each { |e| print e.path.display() }
      ^^ expected expression

err[parse.expected-token]: expected `}` to close block
  findexec.xsh:8:1

  ^ expected `}` to close block


Command exited with code 2
  - Structured report: `workers/eval-worker/task-findexec-1/report.json`
- `eval-worker/task-findexec-1`, turn `20`, tool `edit`: Found 2 occurrences of the text in /work/review.md. The text must be unique. Please provide more context to make it unique.
  - Structured report: `workers/eval-worker/task-findexec-1/report.json`


### Cycle total

- Workers: `2`
- Assistant turns: `36`
- Bucket tokens: `673695`
- Cost (USD): `0.023187`
- Nonzero tool results: `3`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-manager/task-findexec

- Role: `eval-manager`
- Result: `fail`
- Report: `workers/eval-manager/task-findexec/REPORT.md`

#### Efficiency and evidence

Trial 1 (evaluator-worker task-findexec-1, single trial plan):

- Assistant turns: 22 (1 user message; 1 normal `stop` + 21 `toolUse` stops)
- Tool calls: 23; tool results: 23; tool errors: 2
- Session span: 74 854 ms (~74.9 s) — very fast, no idle gaps in transcript
- Worker friction: 2 recoverable tool errors (see Tool-error findings); both
  resolved in the following turn with no repeated exploration. The agent read
  `agents.md`/`handbook.md`/`task.md` first, ran 2 targeted `xsht api` probes
  (`api:fs.files`/`api:fs.walk`, `language:stream.sort-by`), built a small
  fixture, and verified byte-equality on four trees before finalizing. No
  unproductive exploration.

#### Handbook or proposal decision

**Provisional candidate** staged at
`runs/run-1785958228987/phases/01-eval/lineage/handbook-candidate.md` —
approved snapshot copied verbatim plus one added sentence under "Values have
explicit types":

> Boolean conditions are composed with the word-form operators `and` and `or`
> (`e.kind == "file" and e.owner_executable`); the C-style `&&` and `||` are
> rejected at parse time with a message that suggests the word form, so reach
> for the word operators rather than the shell/C form.

General lesson taught: XSH boolean composition uses the word operators, not
C/shell symbols — a cross-cutting language fact that any `where`/predicate task
can hit. It is short, general (not task-specific), and removes a guaranteed
first-try parse error for agents coming from shell/C. This is one-trial
evidence only; the candidate must be replayed (see Next replay) and reviewed by
the CTO before promotion to `runtime/handbook.md`. The approved snapshot and
the checked-in `runtime/handbook.md` were not modified.

#### Ticket or product decision

Zero. No XSH product/tooling defect was reproduced that would warrant an
engineer ticket: the candidate was correct, the `&&`→`and` behavior is
intended design with a good diagnostic (handbook candidate instead), and the
only failing component was the evaluation harness, which belongs to the CTO,
not to an engineer ticket.

#### Next action

Re-run `eval task-findexec` (same eval id, same XSH commit
`1cf4ad3d7ee5fde9b3160b11d8073cbd7ce5e7c4`) against the provisional
handbook-candidate lineage **after the CTO fixes the evaluator
`missing-field: status` defect** so a valid `run.json` is produced. The replay
is a falsification check of the one-sentence boolean-operators handbook claim
(a second eval, ideally one using compound `where` predicates such as
`task-manifest` or `task-ecount`, should also replay the global claim before
promotion). The candidate should only be promoted to `runtime/handbook.md`
after that replay agrees and the CTO approves.

#### North-star impact

This run advances the practical, learnable, ergonomic, trustworthy aims of XSH
on three axes: (1) it demonstrates that a systems-administration workflow the
suite previously lacked — executable-file discovery via typed permission
metadata — is reachable through the fs stream with a short, direct, subprocess-
free pipeline that matches the `find` oracle byte-for-byte, strengthening the
case that the typed metadata boundary is usable and discoverable; (2) the
provisional handbook candidate turns a guaranteed first-attempt parse error
(`&&` vs `and`) into one explicit, reusable rule, reducing repeated discovery
for future agents and improving learnability; and (3) the clearly-attributed
evaluator crash separates candidate-correctness evidence from harness
reliability, so the CTO can harden the eval gate without mis-attributing a
product regression. The single reused diagnostic is trustworthy only after
replay across the shared lineage, as the evidence loop requires.



## Eval proposal review

No CTO eval review was recorded.

## Handbook lineage

Checked-in `runtime/handbook.md`: `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b`
- approved snapshot: `lineage/handbook-approved.md` sha256 `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b` — promoted by CTO ledger; matches checked-in handbook
- candidate: `lineage/handbook-candidate.md` sha256 `4542f413f8d314ec90005700608fce925b93e418cfbc445c4b3d811bad5e0912` — DIFFERS; CTO promotion or rejection decision required


## Historical handbook backlog

Historical candidates: 77; differing: 71; ledger-dispositioned: 70; unresolved: 1.
Unresolved candidates requiring one explicit CTO decision:
- `runs/run-1785958228987/phases/01-eval/lineage/handbook-candidate.md` sha256 `4542f413f8d314ec90005700608fce925b93e418cfbc445c4b3d811bad5e0912`


## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
