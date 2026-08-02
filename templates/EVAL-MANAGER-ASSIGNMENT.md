# Eval-manager assignment: `{{EVAL_ID}}`

Read `{{FACTORY_DIR}}/NORTH-STAR.md`, `{{FACTORY_DIR}}/roles/pi-session-briefing.md`,
`{{EVAL_DIR}}/EVAL.md`, `{{RUN_DIR}}/PROVENANCE.md`, and
`{{RUN_DIR}}/DISPATCH.md`. The reconciler found these merged ticket files:
`{{MERGED_TICKET_PATHS}}`. Read each listed ticket directly when the value is
not `none`. The executor is a black box. Every eval consumes the one
factory-wide handbook; do not look for or create an eval-local handbook.

Each merged ticket is a post-merge acceptance assignment. Evaluate its exact
acceptance criteria against this cycle's XSH commit and record an explicit
decision. Do not dispatch a merged ticket back to SWE.

## Candidate re-evaluation

- Ticket: `{{CANDIDATE_TICKET}}`
- SWE worktree: `{{CANDIDATE_WORKTREE}}`
- Candidate XSH commit: `{{XSH_COMMIT}}`

When the candidate ticket is not `not-reevaluation`, this is a pre-merge
validation of the exact clean SWE worktree. Do not mark the ticket merged, do
not dispatch SWE, and do not treat the branch as main. Decide whether the
executor evidence supports the proposed fix and record that decision in the
manager report.

The controller requires exactly `{{TRIAL_COUNT}}` fresh trial(s). Preserve
separate evidence under `{{RUN_DIR}}/workers/eval-worker/` and inspect each
executor report, worker report, session JSONL, extracted `thinking.md`,
evaluator `run.json`, artifact, review, and quantitative results.

{{TRIAL_INSTRUCTIONS}}

Follow the trial instructions above exactly. A one-trial plan requires an
unchanged candidate snapshot; record any handbook hypothesis in this report
without writing a changed candidate. Only a two-trial plan may stage a changed
candidate for replay.

Begin the narrative output before final analysis: create
`{{RUN_DIR}}/workers/eval-manager/{{EVAL_ID}}/MANAGER-REPORT.md` with all
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
`{{RUN_DIR}}/lineage/handbook-candidate.md`; otherwise copy the approved
snapshot there unchanged. Never edit the approved snapshot or the checked-in
`{{FACTORY_DIR}}/runtime/handbook.md`.

Write `{{RUN_DIR}}/workers/eval-manager/{{EVAL_ID}}/MANAGER-REPORT.md` with
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
