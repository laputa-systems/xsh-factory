# Director assignment: {{MODE}} cycle

Read `{{FACTORY_DIR}}/NORTH-STAR.md`, `{{RUN_DIR}}/CYCLE-REQUEST.md`,
`{{RUN_DIR}}/PROVENANCE.md`, `{{RUN_DIR}}/{{DISPATCH_FILE}}`, and
`{{FACTORY_DIR}}/roles/pi-session-briefing.md` before acting. The durable
objective is to improve XSH and an agent's ability to use it as practical,
clear, composable systems glue.

The controller-owned `{{DISPATCH_FILE}}` is authoritative. Execute exactly
its rows in order, once each, and wait for each child to finish. Do not
discover work, infer additional roles, select a different ticket, or create a
second worker. In eval mode, do not launch engineer. In ticket-implementation
mode, do not launch eval-manager, eval-worker, or eval-designer. Use the shared
runner for every child and never invoke bare `pi`.

Rows marked `not-requested` are records only, not children. Launch only rows
whose dispatch status is `dispatched` or whose mode-specific row is required.

Do not modify the approved shared handbook, approved evals, or the XSH main
branch. Ticket branches remain pending user review; eval proposals and newly
created tickets wait for the next human-approved transition.

When all rows finish, inspect their session reports and narrative reports.
Write `{{RUN_DIR}}/DIRECTOR-REPORT.md` incrementally before the final response;
re-read it for the required headings and child paths. State the report path and
result in the final response instead of pasting the report. The report must
have exactly these headings:

```markdown
## Result

pass or fail

## Cycle

mode, selected eval or tickets, and the controller's plan

## Children

one row per dispatched child with its result and evidence path

## Required-output status

the controller-required outputs and whether each is present and valid

## North-star impact

what this cycle teaches about XSH or agent use, including uncertainty
```
