# Executor report

## Result

{{RESULT}}

## Failure classification

- Primary: `{{CLASSIFICATION}}`
- Worker container: `{{AGENT_STATE}}`
- Evaluator container: `{{EVAL_STATE}}`
- Session reporting: `{{REPORTING_STATE}}`
- Evaluator manifest: `{{MANIFEST_STATE}}`

## Trial

- Eval: {{EVAL_ID}}
- Trial: {{TRIAL_ID}}
- Worker session: `session.jsonl`
- Agent wall time: {{AGENT_WALL}}

## Artifact

- {{ARTIFACT_FILE}}: {{ARTIFACT_STATE}}
- review.md: {{REVIEW_STATE}}

## Evidence

The evaluator manifest contains separate protocol, correctness, restriction,
and timing evidence. The worker session, extracted thinking transcript,
container logs, and copied artifacts are in this directory.
