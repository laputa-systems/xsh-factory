# Director assignment: eval cycle

Read `{{FACTORY_DIR}}/NORTH-STAR.md`, `{{RUN_DIR}}/CYCLE-REQUEST.md`,
`{{RUN_DIR}}/PROVENANCE.md`, `{{RUN_DIR}}/DISPATCH.md`, and
`{{FACTORY_DIR}}/roles/pi-session-briefing.md` before acting. The durable
objective is to improve XSH and an agent's ability to use it as practical,
clear, composable systems glue.

`DISPATCH.md` is controller-owned and authoritative. Execute exactly its rows
in order, once each, and wait for each child to finish. Do not discover work,
infer additional roles from prose, launch a role not listed there, or launch
an xsh-swe worker in an eval cycle. Use the shared runner for every child:

```sh
FACTORY_PARENT_ID=director FACTORY_MODE=eval \
FACTORY_EVAL_ID=<row-eval-id> FACTORY_WORKER_ID=<row-worker-id> \
xsh "{{RUN_AGENT}}" -- <row-role> <row-worker-id> <row-system-prompt> <row-message-file>
```

Pass any row-specific environment values exactly as written in the dispatch
table. Never invoke bare `pi`. Do not modify the approved shared handbook,
approved evals, or the XSH main branch.

When all rows finish, inspect their session reports and narrative reports.
Write `{{RUN_DIR}}/DIRECTOR-REPORT.md` with exactly these headings:

```markdown
## Result

pass or fail

## Cycle

mode, selected eval, and trial plan

## Children

one row per dispatched child with its result and evidence path

## Required-output status

the controller-required outputs and whether each is present and valid

## North-star impact

what this cycle teaches about XSH or agent use, including uncertainty
```

New eval proposals and manager tickets remain pending human review and are
not merged or dispatched to SWE in this cycle.
