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
- `workers/eval-manager/task-grep/report.json`: result `pass`; report `workers/eval-manager/task-grep/report.json`
- `workers/eval-worker/task-grep-1/report.json`: result `pass`; report `workers/eval-worker/task-grep-1/report.json`


## Employee accounting

### Worker metrics

- `eval-manager/task-grep` (`eval-manager`): result `pass`; report `workers/eval-manager/task-grep/report.json`
  - Execution: `not recorded`; classification: `not recorded`
  - Turns: `15`; bucket tokens: `399030`; thinking blocks: `11`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=15; observed_output_tps=0`
  - Tool errors: `0`; cost: `0.011420`; budget: `0.150000`
- `eval-worker/task-grep-1` (`eval-worker`): result `pass`; report `workers/eval-worker/task-grep-1/report.json`
  - Execution: `pass`; classification: `pass`
  - Turns: `29`; bucket tokens: `305260`; thinking blocks: `16`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=29; observed_output_tps=0`
  - Tool errors: `6`; cost: `0.007890`; budget: `0.500000`


### Nonzero tool results
### Provider health and latency

Provider retry, latency, and attribution data are in worker `report.json`
`provider_telemetry` fields. Missing telemetry is `unknown`, not evidence of
normal provider health. Provider switching is out of scope and tracked in
`TODO.md`.

### Nonzero tool results

- `eval-worker/task-grep-1`, turn `5`, tool `bash`: err[check.effect-violation]: `?` requires the `error` effect
  /tmp/t.xsh:2:14
    let text = fs.read_text(p"data.txt")?
               ^^^^^^^^^^^^^^^^^^^^^^^^^^ `?` requires the `error` effect


Command exited with code 2
  - Structured report: `workers/eval-worker/task-grep-1/report.json`
- `eval-worker/task-grep-1`, turn `6`, tool `bash`: err[compact.main-missing-spread]: proc main must use the spread form `(...argv: List[Str])` to receive script arguments; a fixed parameter of this type cannot bind script arguments in the compact runtime
  /tmp/t.xsh:1:1
  proc main(args: List[Str]) [fs, error] {
  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ proc main must use the spread form `(...argv: List[Str])` to receive script arguments; a fixed parameter of this type cannot bind script arguments in the compact runtime


Command exited with code 2
  - Structured report: `workers/eval-worker/task-grep-1/report.json`
- `eval-worker/task-grep-1`, turn `11`, tool `bash`: err[check.unknown-method]: unknown method `display` on Int
  /tmp/t4.xsh:3:11
    let s = n.display()
            ^^^^^^^^^^^ `display` is not defined for Int


Command exited with code 2
  - Structured report: `workers/eval-worker/task-grep-1/report.json`
- `eval-worker/task-grep-1`, turn `16`, tool `bash`: err[check.standard-module-shadow]: name `path` shadows the standard module `path`
  grep.xsh:3:3
    let path = Path(argv[1])
    ^^^^^^^^^^^^^^^^^^^^^^^^ name `path` shadows the standard module `path`
err[check.standard-module-shadow]: name `path` shadows the standard module `path`
  grep.xsh:3:3
    let path = Path(argv[1])
    ^^^^^^^^^^^^^^^^^^^^^^^^ name `path` shadows the standard module `path`


Command exited with code 2
  - Structured report: `workers/eval-worker/task-grep-1/report.json`
- `eval-worker/task-grep-1`, turn `19`, tool `edit`: Could not find edits[1] in /work/grep.xsh. The oldText must match exactly including all whitespace and newlines.
  - Structured report: `workers/eval-worker/task-grep-1/report.json`
- `eval-worker/task-grep-1`, turn `25`, tool `bash`: sh: syntax error: bad substitution


Command exited with code 2
  - Structured report: `workers/eval-worker/task-grep-1/report.json`


### Cycle total

- Workers: `2`
- Assistant turns: `44`
- Bucket tokens: `704290`
- Cost (USD): `0.019309`
- Nonzero tool results: `6`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-manager/task-grep

- Role: `eval-manager`
- Result: `pass`
- Report: `workers/eval-manager/task-grep/REPORT.md`

#### Efficiency and evidence

Trial 1 (`task-grep-1`, model openrouter/deepseek/deepseek-v4-flash-0731):
- assistant turns: 29
- tool calls: 33 (bash 24, edit 4, read 3, write 2)
- tool errors: 6
- session span: 130,376 ms (~130 s); agent wall 132,835 ms
- stop reasons: 1 `stop`, 28 `toolUse`
- user messages: 1

The worker read the task, the approved handbook, and `agents.md`, then probed
`xsht api` for `fs.read_text`, `Str.lines`, `Str.contains`, and path/Int
queries, ran a series of small `/tmp` scratch scripts to nail effects,
spread-main, line handling, and Int→text rendering, wrote `grep.xsh`, ran
`xsht check/fmt/lint`, and did a mini test battery (literal `.`, blank pattern,
no-match, missing file) before submitting. No repeated re-reads or long idle
spans. 29 turns for a correct, restricted, byte-exact solution is efficient;
friction is concentrated in the Int→text rendering exploration described below.

#### Handbook or proposal decision

Provisional candidate staged at
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786135120835/phases/01-eval/lineage/handbook-candidate.md`
(approved snapshot, sha256
3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b, plus one
added sentence in the "Text and output" section).

General lesson: "There is no `Int.to_str`/`display`/`str` conversion method in
this build; to render a number into an exact output contract use display-string
interpolation `f"${n}"` in expression position, not a guessed conversion
method."

This is short, general, and removes a repeated 7-guess exploration that the API
discovery section does not pre-empt. It is NOT auto-promoted: it must be
replayed on a nearby line-numbering / aggregation eval before it becomes trusted
in `runtime/handbook.md`. The approved snapshot and `runtime/handbook.md` are
unchanged.

#### Ticket or product decision

None. The only strong observation (Int→text rendering) is best served by the
provisional handbook candidate plus a replay, not by a product ticket. The one
trial passed; there is no reproducible product/tooling defect to open a ticket
against in this cycle.

#### Next action

Replay `task-dupcheck` (a nearby line-numbering text eval) and re-run
`task-grep` against the candidate handbook lineage
`runs/run-1786135120835/phases/01-eval/lineage/handbook-candidate.md` on the
same XSH commit 857154dfe505f0d01053c1b5311f44422070eb34. If the worker reaches
a correct solution without the multi-guess Int→text search, the candidate is
supported; if the candidate introduces no friction and the eval still passes,
promote to `runtime/handbook.md` via CTO review. A failing or noisier replay
falsifies and drops the candidate.

#### North-star impact

The run shows XSH's typed, explicit text pipeline composes correctly for the
classic `grep -nF` shape with no subprocess fallback and byte-exact output,
supporting the "replace grep with a typed XSH program" promise of practical,
clear systems glue. The one generalizable finding is ergonomic/learnable:
the approved handbook leaves number-to-text rendering implicit, so the agent
burned seven method guesses before using the documented display-string rule.
Teaching "render Int with `f\"${n}\"`, no conversion method exists" shortens
future exploration across the line-numbering and aggregation evals, improving
AI efficiency without sacrificing correctness, while keeping the language's
explicit-boundary, no-implicit-conversion ethos intact. Provider telemetry was
healthy (zero retries), so the friction is a genuine language/handbook
learnability signal rather than an external-health artifact.



## Eval proposal review

No CTO eval review was recorded.

## Handbook lineage

Checked-in `runtime/handbook.md`: `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b`
- approved snapshot: `lineage/handbook-approved.md` sha256 `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b` — promoted by CTO ledger; matches checked-in handbook
- candidate: `lineage/handbook-candidate.md` sha256 `76be68bc0027fb110bdddf0b8b2950072238472dfcd77a80867021ab819b4f7d` — DIFFERS; CTO promotion or rejection decision required


## Historical handbook backlog

Historical candidates: 15; differing: 8; ledger-dispositioned: 5; unresolved: 3.
Unresolved candidates requiring one explicit CTO decision:
- `runs/run-1786135120835/phases/01-eval/lineage/handbook-candidate.md` sha256 `76be68bc0027fb110bdddf0b8b2950072238472dfcd77a80867021ab819b4f7d`
- `runs/run-1786135120835/phases/03-eval/lineage/handbook-candidate.md` sha256 `5f8e62935443becb4cef30adc28ce72aa0a697ce96df0c0d3b56fc4f3893457b`
- `runs/run-1786135120835/phases/04-eval/lineage/handbook-candidate.md` sha256 `b2069c71aa8f20b8e34b0cec2d2415f5152d81492feaa47a24df5c46a0a3dbb8`


## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
