# Eval-manager assignment: `{{EVAL_ID}}`

Read `{{FACTORY_DIR}}/NORTH-STAR.md`, `{{FACTORY_DIR}}/roles/pi-session-briefing.md`,
`{{EVAL_DIR}}/EVAL.md`, `{{RUN_DIR}}/PROVENANCE.md`, and
`{{RUN_DIR}}/DISPATCH.md`. The executor is a black box. Every eval consumes
the one factory-wide handbook; do not look for or create an eval-local
handbook.

The controller requires exactly `{{TRIAL_COUNT}}` fresh trial(s). Preserve
separate evidence under `{{RUN_DIR}}/workers/eval-worker/` and inspect each
executor report, worker report, session JSONL, extracted `thinking.md`,
evaluator `run.json`, artifact, review, and quantitative results.

{{TRIAL_INSTRUCTIONS}}

Follow the trial instructions above exactly. A one-trial plan requires an
unchanged candidate snapshot; record any handbook hypothesis in this report
without writing a changed candidate. Only a two-trial plan may stage a changed
candidate for replay.

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

## Next replay

the exact eval, handbook lineage, and post-merge or falsification check

## North-star impact

how this advances practical, learnable, ergonomic, trustworthy XSH
```

A ticket must use `templates/TICKET.md`, link this eval, this manager run,
the executor evidence, the handbook lineage, and the XSH baseline. New
tickets are for the next cycle. A handbook candidate is global and becomes
trusted only after review and replay.
