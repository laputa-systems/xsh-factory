# Eval-manager report: `task-findexec`

Run: `run-1786255756177` / phase `03-supply-eval`
XSH commit under test: `7b4bee1a1cef74fed832331cd6cc5bb6e324c4ee`
Trials requested: 1 (controller executed exactly 1 fresh trial)

## Result

pass

## Effort metrics

Trial 1 (`workers/eval-worker/task-findexec-1`): 37 assistant turns, 41 tool
calls, 0 tool errors, 41 tool results, 1 user message. Session span and worker
friction per trial are recorded in the worker report and `run.json` (refined
below after reading the worker package). Phase-level `tool_errors` array is
empty; the run reports a single worker with zero tool errors.

## Usage and cost

Trial 1 provider-reported buckets (from phase `report.json`):
input 64,993; output 11,593; cache read 489,152; cache write 0;
provider total / bucket total 565,738. Reasoning tokens 6,008 (provider
reported; a subset of output, not added to totals). Cost: input
$0.00584937, output $0.00208674, cache read $0.008804736, cache write $0,
total $0.016740846 against a $0.50 budget. Aggregate: 1 worker, $0.016740846,
565,738 total bucket tokens. Unknown costs: 0.

## Thinking evidence

Phase report records 28 thinking blocks for the worker with 6,008 reasoning
tokens. Qualitative review of `thinking.md`/session content is refined after
reading the worker package.

## Tool-error findings

None. The structured `tool_errors` arrays are empty in both the phase report
and the worker report (0 tool errors); no failed Pi tool results or invalid
`xsht api` queries were recorded in the current sessions.

## Timing evidence

Trial 1 timing = `pass`; this eval has no strict candidate/oracle timing gate
(per EVAL.md, timing is diagnostic until a stable envelope is established).
Candidate/oracle timing values will be refined from `run.json` when read.

## Observation classification

To be finalized after reading the worker report, `run.json`, and artifact/
review. Provisional: the worker solved the task on the first trial with
correctness/restrictions/protocol all `pass` and zero tool errors, suggesting
the handbook's guidance on typed permission fields, `hidden: true`, and the
stream pipeline was sufficient — ordinary successful-task behavior, not a
reusable defect signal.

## Handbook decision

Provisional: unchanged (no new defect observed). Candidate file
`lineage/handbook-candidate.md` will be set to the approved snapshot unless
the worker evidence reveals a generalizable lesson.

## Tickets created

None unless the worker evidence reveals one strong reproducible observation.

## Post-merge decisions

None. The reconciler reported zero merged tickets (`none`) for this run, and
the controller stipulates this is not a candidate-linked replay
(`Candidate re-evaluation: not-reevaluation`). No acceptance token is
required.

## Next replay

Replay `task-findexec` against the same approved handbook lineage on a later
XSH commit to confirm the typed-permission / `hidden: true` guidance remains
stable, and to falsify any provisional handbook candidate if one is staged.

## North-star impact

`task-findexec` exercises the typed fs-stream metadata boundary
(owner-executable filter) plus dotfile inclusion — a learnability/ergonomics
probe aligned with the north-star mission. A clean first-trial pass with zero
tool errors is evidence that the handbook teaches the permission fields and
`hidden: true` discovery well. No product defect or handbook gap is signaled by
this trial.
