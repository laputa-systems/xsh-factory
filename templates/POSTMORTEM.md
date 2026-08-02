# Factory cycle postmortem

## Result

The factory stopped because the aggregate cycle budget was exceeded.

## Budget

- Run: `{{RUN_DIR}}`
- Hard cap: `${{CAP}}`
- Observed spend: `${{OBSERVED_SPEND}}`
- Controller PID: `{{CONTROLLER_PID}}`

## Shutdown

- Reason: `{{REASON}}`
- Cleanup: `{{CLEANUP}}`

## Follow-up

Review the worker reports and cost report before approving another cycle. Reduce
churn or tighten the cycle request before retrying.
