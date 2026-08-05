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
- `workers/eval-manager/task-histogram/report.json`: result `pass`; report `workers/eval-manager/task-histogram/report.json`
- `workers/eval-worker/task-histogram-1/report.json`: result `pass`; report `workers/eval-worker/task-histogram-1/report.json`


## Employee accounting

### Worker metrics

- `eval-manager/task-histogram` (`eval-manager`): result `pass`; report `workers/eval-manager/task-histogram/report.json`
  - Execution: `not recorded`; classification: `not recorded`
  - Turns: `23`; bucket tokens: `1051756`; thinking blocks: `16`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=23; observed_output_tps=0`
  - Tool errors: `1`; cost: `0.027736`; budget: `0.150000`
- `eval-worker/task-histogram-1` (`eval-worker`): result `pass`; report `workers/eval-worker/task-histogram-1/report.json`
  - Execution: `fail`; classification: `evaluator_failed`
  - Turns: `46`; bucket tokens: `1076490`; thinking blocks: `41`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=46; observed_output_tps=0`
  - Tool errors: `0`; cost: `0.028945`; budget: `0.500000`


### Nonzero tool results
### Provider health and latency

Provider retry, latency, and attribution data are in worker `report.json`
`provider_telemetry` fields. Missing telemetry is `unknown`, not evidence of
normal provider health. Provider switching is out of scope and tracked in
`TODO.md`.

### Nonzero tool results

- `eval-manager/task-histogram`, turn `11`, tool `bash`: Traceback (most recent call last):
  File "<string>", line 5, in <module>
    w=d['workers'][0]
      ~^^^^^^^^^^^
KeyError: 'workers'
phase tool_errors: None


Command exited with code 1
  - Structured report: `workers/eval-manager/task-histogram/report.json`


### Cycle total

- Workers: `2`
- Assistant turns: `69`
- Bucket tokens: `2128246`
- Cost (USD): `0.056682`
- Nonzero tool results: `1`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-manager/task-histogram

- Role: `eval-manager`
- Result: `fail`
- Report: `workers/eval-manager/task-histogram/REPORT.md`

#### Efficiency and evidence

One trial (`task-histogram-1`), electron model
`openrouter/deepseek/deepseek-v4-flash-0731`. The worker produced a single
byte-exact histogram artifact and a complete review.

- assistant_turns: 46 (1 user message, 45 toolUse stops + 1 final stop)
- tool_calls: 51 (46 bash, 3 read, 1 edit, 1 write); tool_results: 51
- tool_errors: 0
- thinking_blocks: 41
- session_span_ms: 390005 (agent_wall_ms 391542), ~6.5 minutes
- budget: 0.028945 US$ of a 0.5 budget

The session was efficient and converged: the worker reasoned about the
group-by vs Map alternatives in-stream, compiled the final Map+fold approach,
ran all validation branches (bad width, negative, hex, bad value), and emitted
a 13-line solution without repeated dead-end loops. No worker friction beyond
the single `sort-by` type rejection (see `## Observation classification`).

#### Handbook or proposal decision

Provisional candidate staged at
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785899099112/phases/01-eval/lineage/handbook-candidate.md`
(approved snapshot copied, one general paragraph added to the
"Streams and collections" section).

- General lesson: a `group-by` record's `key` field is generic, so
  `sort-by { |g| g.key }` is rejected at check time even for Int/Str keys;
  project the key to a concrete sortable type (parse_int/cast) before
  `sort-by`, or collect concrete keys and sort that list.
- Replay scope: this lesson is global and should be replayed by
  task-ecount / task-groupsum (group-by then order by key) before promotion to
  `runtime/handbook.md`. It removes repeated discovery of the same type
  rejection anywhere a grouped result must be ordered.

#### Ticket or product decision

One product ticket for the next cycle:

- `tickets/task-histogram-002.md` — `sort-by` rejects a group-by record's
  generic `key` field at check time even when the key values are a supported
  scalar type (Int), forcing a Map+`sort()` or parse-then-sort workaround and
  failing literal `sort-by` restriction gates. General XSH ergonomics issue,
  not a task-specific miss.

#### Next action

Replay `task-histogram` and `task-ecount` (and `task-groupsum`) against the
provisional candidate on lineage `run-1785899099112/phases/01-eval/lineage/
handbook-candidate.md` once the CTO accepts the ticket and the sort-by
generic-key behavior is addressed or documented. If the sort-by key rejection
is a product defect, replay `task-histogram` should reach the documented
north-star path (group-by -> sort-by -> fold) and satisfy the literal
`sort-by` gate; otherwise the handbook candidate's sort-path guidance is the
falsification check.

#### North-star impact

The eval correctly keeps correctness as the gate (all nine cases byte-exact),
but the run exposed a learnability/ergonomics defect in XSH's stream sorting:
the canonical grouped-key ordering idiom (`group-by` then `sort-by` on the
key) is rejected at check time for generic keys, so an agent must discover a
parse-then-sort workaround. This is exactly the kind of glue-language
boundary the factory is meant to make explicit: ordering grouped keys is
common systems work, and the rejection adds guesswork and pushes solutions off
the documented path. Fixing or documenting the group-key sort behavior, plus
the provisional handbook lesson, directly improves practical, learnable,
ergonomic XSH and reduces agent exploration on any grouped-aggregation eval.



## Eval proposal review

No CTO eval review was recorded.

## Handbook lineage

Checked-in `runtime/handbook.md`: `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b`
- approved snapshot: `lineage/handbook-approved.md` sha256 `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b` — promoted by CTO ledger; matches checked-in handbook
- candidate: `lineage/handbook-candidate.md` sha256 `a1b5fef60a1e56c8d1f0eec8e91ae99f5d963a15ca7c374bd20ca8c8c35995f5` — DIFFERS; CTO promotion or rejection decision required


## Historical handbook backlog

Historical candidates: 71; differing: 68; ledger-dispositioned: 67; unresolved: 1.
Unresolved candidates requiring one explicit CTO decision:
- `runs/run-1785899099112/phases/01-eval/lineage/handbook-candidate.md` sha256 `a1b5fef60a1e56c8d1f0eec8e91ae99f5d963a15ca7c374bd20ca8c8c35995f5`


## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
