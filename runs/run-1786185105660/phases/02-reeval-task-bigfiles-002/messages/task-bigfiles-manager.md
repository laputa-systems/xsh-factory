# Eval-manager assignment: `task-bigfiles`

Throughput bound: use the structured evidence packet and complete the staged
report promptly. Do not spend a turn rediscovering controller state or reading
raw session history unless a specific structured discrepancy requires proof.
The launcher exposes only `read`, `write`, and `edit` for this role; use those
tools for the bounded evidence review and report, not shell discovery.

Use the `read` tool, not `bash`, `cat`, or `grep`, for the required reads below.
Before any other investigation, make an exact `read` tool call for
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786185105660/phases/02-reeval-task-bigfiles-002/lineage/handbook-approved.md`; the controller proves this exact
call as part of the manager admission contract.

Read `/Users/josh/d/laputa-systems/xsh-factory/NORTH-STAR.md`, `/Users/josh/d/laputa-systems/xsh-factory/roles/pi-session-briefing.md`,
`/Users/josh/d/laputa-systems/xsh-factory/evals/task-bigfiles/EVAL.md`, and `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786185105660/phases/02-reeval-task-bigfiles-002/report.json` first.
Use the exact absolute path `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786185105660/phases/02-reeval-task-bigfiles-002/lineage/handbook-approved.md` as the
handbook snapshot under review; do not substitute a different handbook path or
construct a relative path from the worker directory. If hashing it, hash that
supplied path directly.
The controller dispatch and open-ticket snapshot are structured fields in
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786185105660/phases/02-reeval-task-bigfiles-002/report.json`. The reconciler found these merged ticket files:
`none`. Read each listed ticket directly when the value is
not `none`. The executor is a black box. Every eval consumes the one
factory-wide handbook; do not look for or create an eval-local handbook.

Each merged ticket is a post-merge acceptance assignment. Evaluate its exact
acceptance criteria against this cycle's XSH commit and record an explicit
decision. Do not dispatch a merged ticket back to engineer.

## Candidate re-evaluation

- Ticket: `task-bigfiles-002`
- engineer worktree: `/Users/josh/d/laputa-systems/xsh-factory/../.xsh-factory-worktrees/run-1786185105660/task-bigfiles-002`
- Candidate XSH commit: `c77b01a3e2fb676cc57cdeddbb7575be7723aa32`

When the candidate ticket is not `not-reevaluation`, this is a pre-merge
validation of the exact clean engineer worktree. Do not mark the ticket merged, do
not dispatch engineer, and do not treat the branch as main. Decide whether the
executor evidence supports the proposed fix and record that decision in the
manager report.
For a candidate-linked replay, report `pass` only when the worker actually
exercised the ticket's acceptance criteria. If it used a workaround or did not
exercise the proposed surface, state that explicitly; the controller will
retain the branch for a directed replay.

The controller has completed exactly `1` fresh trial(s). Preserve
separate evidence under `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786185105660/phases/02-reeval-task-bigfiles-002/workers/eval-worker/` and inspect each
worker `report.json`, evaluator `run.json`, artifact, review, and quantitative
results. Consult raw session JSONL only when a structured discrepancy requires
proof; an exhaustive session read is not part of manager closeout. The
controller has staged the required report skeleton at
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786185105660/phases/02-reeval-task-bigfiles-002/workers/eval-manager/task-bigfiles/REPORT.md`; edit it in place
instead of reconstructing the headings. Your `## Tool-error findings` section
must account for every failed Pi tool result in the structured worker and
manager `report.json` files, including invalid `xsht api` discovery queries, or
say `None.` when all current sessions have zero errors.

Before attributing wall-clock growth to agent inefficiency, inspect the worker
report's `provider_telemetry`. Explicit `auto_retry_*` events, provider errors,
retry delays, and elevated response latency are external-health evidence. If
telemetry is absent, say latency attribution is `unknown` and use turns,
tokens, tool calls, tool errors, repeated exploration, correctness, and artifact
quality for the efficiency judgment. Do not recommend switching providers in
this cycle; provider fallback is a future TODO only.

## Trial 1

The controller has already executed the configured trial against the approved
handbook snapshot. Do not launch or rerun the executor. Inspect the executor
report, worker report, thinking transcript, evaluator manifest, artifact,
review, and quantitative session results at the paths in the phase `report.json`.
The manager may stage a provisional candidate in the run lineage after
classifying the evidence. Never edit the approved snapshot or the checked-in
`runtime/handbook.md`.

## Trial 2

The controller has already executed trial 2 when the configured count is `2`.
Compare its recorded inputs and outputs with trial 1; do not launch another
executor.


Follow the trial instructions above exactly. A one-trial plan may stage one
concise provisional handbook candidate when the evidence supports a reusable
lesson. Promotion still requires later replay and CTO approval. A two-trial
plan must state whether its candidate was actually replayed by the controller;
do not claim validation that did not occur.

Begin the narrative output before final analysis: the controller has created
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786185105660/phases/02-reeval-task-bigfiles-002/workers/eval-manager/task-bigfiles/REPORT.md` with a fail-closed
`not-ready` result. Fill it as evidence is classified, change the result only
after every required section is complete, and re-read it before finishing. Do
not paste the full report into the final response; state the path and result
only. Read the skeleton and write a complete first draft as soon as the
structured evidence is available; reserve at most one targeted reproduction
for an unresolved, ticket-relevant discrepancy. If an API question remains
unresolved after two exact probes, classify the friction and proceed.

Compare the requested trials. Classify each meaningful observation as
correctness, restriction, timing, worker friction, reusable handbook
guidance, product/tooling defect, harness mismatch, evaluator failure, or
ordinary noise. Candidate/oracle timing is a diagnostic measurement except
where the eval contract explicitly makes it a gate. Do not call code quality
an objective metric; explain qualitative judgments and their evidence.

If a handbook change is justified, write it only to
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786185105660/phases/02-reeval-task-bigfiles-002/lineage/handbook-candidate.md`; otherwise copy the approved
snapshot there unchanged. Never edit the approved snapshot or the checked-in
`/Users/josh/d/laputa-systems/xsh-factory/runtime/handbook.md`.

Write `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786185105660/phases/02-reeval-task-bigfiles-002/workers/eval-manager/task-bigfiles/REPORT.md` with
exactly these headings:

```markdown
## Result

pass or fail

## Effort metrics

turns, tools, errors, session span, and worker friction per trial

## Usage and cost

input/output/cache buckets, provider total, reasoning tokens when reported,
and dollars per trial and in aggregate

## Thinking evidence

thinking-block counts and findings grounded in `thinking.md`; say when the
provider did not report reasoning-token counts

## Tool-error findings

every nonzero Pi tool result from the structured `tool_errors` arrays, or
`None.` when the current evidence packet has no tool errors

## Timing evidence

candidate/oracle timing and any strict ratio gate

## Observation classification

reusable signal versus noise, with evidence

## Handbook decision

unchanged or provisional candidate, the general lesson, and replay scope

## Tickets created

zero or a list of standardized linked ticket paths

## Post-merge decisions

For each reconciled merged ticket: ticket ID, implementation commit,
accept/reject or needs-replay decision, evidence, and any required revert
proposal.

## Next replay

the exact eval, handbook lineage, and post-merge or falsification check

## North-star impact

how this advances practical, learnable, ergonomic, trustworthy XSH
```

A ticket must use `templates/TICKET.md`, link this eval, this manager run,
the executor evidence, the handbook lineage, and the XSH baseline. New
tickets are for the next cycle. Leave the ticket template's merge-record
placeholders unchanged. A handbook candidate is global and becomes trusted
only after review and replay.

Factory infrastructure changes belong to the CTO. Do not create a factory-target ticket or recommend engineer dispatch for them.
