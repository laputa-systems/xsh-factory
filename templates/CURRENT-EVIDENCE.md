# Current evidence packet

Read this packet before opening raw session JSONL or historical files. The
controller has already selected the work and recorded the current evidence
paths.

## Cycle

- Eval: `{{EVAL_ID}}`
- Trial count: `{{TRIAL_COUNT}}`
- Approved handbook snapshot: `{{HANDBOOK}}`
- Dispatch: `{{DISPATCH}}`
- Open-ticket index: `{{OPEN_TICKETS}}`

## Worker evidence

{{WORKER_ROWS}}

## Tool failures

The trial rows above contain the aggregate count. For every nonzero count,
read its detail file before classifying worker friction. Each detail file
contains the tool name, assistant turn, and complete reported result text for
every failed Pi tool call, including invalid `xsht api` discovery queries.
