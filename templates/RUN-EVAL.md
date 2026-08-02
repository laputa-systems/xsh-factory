# Factory run {{RUN_ID}}

## Result

{{RESULT}}

## North-star status

This `{{EVAL_ID}}` cycle measures a practical XSH capability and preserves the
evidence needed for durable handbook or product decisions. See
`DIRECTOR-REPORT.md` and the manager report for the explicit mission impact.

## Cycle

- Request: `CYCLE-REQUEST.md`
- Eval: `{{EVAL_ID}}`
- Trial count: `{{TRIAL_COUNT}}`
- New eval proposals: `{{NEW_EVAL_COUNT}}`
- XSH commit: `{{XSH_COMMIT}}`
- Image: `{{IMAGE}}`
- Image ID: `{{IMAGE_ID}}`
- Build state: `{{BUILD_STATE}}`

## Required outputs

- Director session: `{{DIRECTOR_STATE}}`
- Eval-manager session: `{{MANAGER_STATE}}`
- Eval-designer report: `{{DESIGNER_STATE}}`
- Trial 1 executor: `{{TRIAL1_STATE}}`
- Trial 2 executor: `{{TRIAL2_STATE}}`
- Handbook lineage: `{{LINEAGE_STATE}}`
- Cost report: `{{COST_STATE}}`
- Deterministic audit: `{{AUDIT_STATE}}` (`{{AUDIT_RESULT}}`)
- CTO briefing: `{{CTO_STATE}}`

## Handbook validation

- Approved snapshot unchanged: `{{APPROVED_SNAPSHOT_UNCHANGED}}`
- Checked-in handbook unchanged: `{{CHECKED_IN_HANDBOOK_UNCHANGED}}`
- Candidate SHA-256: `{{CANDIDATE_SHA}}`
- Trial 1 staged handbook SHA-256: `{{TRIAL1_SHA}}`
- Trial 2 staged handbook SHA-256: `{{TRIAL2_SHA}}`

## Evidence

All Pi sessions, extracted thinking transcripts, worker reports, evaluator
manifests, container logs, and artifacts are under `workers/`. See
`PROVENANCE.md`, `LINEAGE.md`, `DISPATCH.md`, `COST.md`, and `AUDIT.md` for the
run inputs, normalized outcomes, and accounting.
