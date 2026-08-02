# Run audit

This is a deterministic normalization of the run's canonical Pi session
JSONL, derived worker reports, evaluator manifests, controller reports, and
provenance. It records observed outcomes; it does not replace the raw
evidence or make a subjective quality claim.

## Result

{{RESULT}}

## Scope

- Run: `{{RUN_ID}}`
- Mode: `{{MODE}}`
- XSH commit: `{{XSH_COMMIT}}`
- Image: `{{IMAGE}}`
- Requested eval: `{{EVAL_ID}}`
- Expected trials: `{{EXPECTED_TRIALS}}`
- Observed sessions: `{{SESSION_COUNT}}`
- Observed evaluator manifests: `{{MANIFEST_COUNT}}`
- Observed ticket reports: `{{TICKET_COUNT}}`

## Integrity

- Provenance: `{{PROVENANCE_STATE}}`
- Cost report: `{{COST_STATE}}`
- Lineage: `{{LINEAGE_STATE}}`
- Controller reports: `{{CONTROLLER_STATE}}`
- Worker reports: `{{WORKER_STATE}}`
- Evaluator evidence: `{{EVALUATOR_STATE}}`
- Ticket evidence: `{{TICKET_STATE}}`

## Evidence

The session column points to the raw Pi JSONL. The manifest column points to
the evaluator's structured result. The report column points to the derived
human-readable report used by the controller.

| Kind | Identifier | Outcome | Classification | Contract | Session | Report | Manifest | Metrics |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
{{ROWS}}

## Findings

{{FINDINGS}}
