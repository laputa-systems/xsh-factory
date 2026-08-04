# Eval-manager assignment: `task-ecount`

Read `/Users/josh/d/laputa-systems/xsh-factory/NORTH-STAR.md`, `/Users/josh/d/laputa-systems/xsh-factory/roles/pi-session-briefing.md`,
`/Users/josh/d/laputa-systems/xsh-factory/evals/task-ecount/EVAL.md`, and `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785726325461/phases/02-reeval/report.json` first.
Use `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785726325461/phases/02-reeval/lineage/handbook-approved.md` as the exact handbook snapshot
under review; do not substitute a different handbook path.
The controller dispatch and open-ticket snapshot are structured fields in
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785726325461/phases/02-reeval/report.json`. The reconciler found these merged ticket files:
`none`. Read each listed ticket directly when the value is
not `none`. The executor is a black box. Every eval consumes the one
factory-wide handbook; do not look for or create an eval-local handbook.

Each merged ticket is a post-merge acceptance assignment. Evaluate its exact
acceptance criteria against this cycle's XSH commit and record an explicit
decision. Do not dispatch a merged ticket back to engineer.

## Candidate re-evaluation

- Ticket: `task-ecount-003`
- engineer worktree: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785726325461/phases/01-ticket/worktrees/task-ecount-003`
- Candidate XSH commit: `c2e1039d8856c04ad8466504d445dc93a341f720`

When the candidate ticket is not `not-reevaluation`, this is a pre-merge
validation of the exact clean engineer worktree. Do not mark the ticket merged, do
not dispatch engineer, and do not treat the branch as main. Decide whether the
executor evidence supports the proposed fix and record that decision in the
manager report.

The controller has completed exactly `1` fresh trial(s). Preserve
separate evidence under `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785726325461/phases/02-reeval/workers/eval-worker/` and inspect each
worker `report.json`, session JSONL, evaluator `run.json`, artifact, review,
and quantitative results. Your `## Tool-error findings` section must account
for every failed Pi tool result in the structured worker and manager
`report.json` files, including invalid `xsht api` discovery queries, or say
`None.` when all current sessions have zero errors.

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
lesson. Promotion still requires later replay and human approval. A two-trial
plan must state whether its candidate was actually replayed by the controller;
do not claim validation that did not occur.

Begin the narrative output before final analysis: create
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785726325461/phases/02-reeval/workers/eval-manager/task-ecount/REPORT.md` with all
required headings, then fill it as evidence is classified. Re-read the file
before finishing. Do not paste the full report into the final response; state
the path and result only. If an API question remains unresolved after two
exact probes, classify the friction and proceed.

Compare the requested trials. Classify each meaningful observation as
correctness, restriction, timing, worker friction, reusable handbook
guidance, product/tooling defect, harness mismatch, evaluator failure, or
ordinary noise. Candidate/oracle timing is a diagnostic measurement except
where the eval contract explicitly makes it a gate. Do not call code quality
an objective metric; explain qualitative judgments and their evidence.

If a handbook change is justified, write it only to
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785726325461/phases/02-reeval/lineage/handbook-candidate.md`; otherwise copy the approved
snapshot there unchanged. Never edit the approved snapshot or the checked-in
`/Users/josh/d/laputa-systems/xsh-factory/runtime/handbook.md`.

Write `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785726325461/phases/02-reeval/workers/eval-manager/task-ecount/REPORT.md` with
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
