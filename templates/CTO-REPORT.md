# CTO briefing {{RUN_ID}}

This is the deterministic first-pass briefing for the CTO. It consolidates
controller outcomes, employee accounting, qualitative decisions, and the
remaining action queue. The underlying session JSONL and reports remain the
source of truth.

## Result

{{RESULT}}

## Operating context

- Mode: `{{MODE}}`
- Request: `{{REQUEST}}`
- Audit result: `{{AUDIT_RESULT}}`
- Provenance: `{{PROVENANCE}}`

## Phase outcomes

{{PHASES}}

## Employee accounting

### Per-worker metrics

{{WORKERS}}

### Tool-error details

{{TOOL_ERRORS}}

### Role totals

{{ROLE_TOTALS}}

### Cycle total

{{RUN_TOTAL}}

## Employee decisions

{{EMPLOYEE_DECISIONS}}

## CTO action queue

{{ACTION_QUEUE}}

## Evidence index

- Controller summary: `{{RUN_REPORT}}`
- Cost report: `{{COST_REPORT}}`
- Deterministic audit: `{{AUDIT_REPORT}}`
- Provenance: `{{PROVENANCE_REPORT}}`
- Raw employee sessions and reports: `workers/`
