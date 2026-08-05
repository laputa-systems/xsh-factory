# Ticket <id>

## Status

Open.

## Change target

- `product`

Factory changes are CTO-owned. Do not create a factory-target ticket for
engineer dispatch; report the infrastructure change to the CTO instead.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval:
- Shared handbook lineage:
- Manager run:
- Executor run:
- XSH baseline commit:

## Observation

Describe the concrete behavior observed by the eval-worker.

## Evidence

Link the session, thinking transcript, tool results, artifact, evaluator report,
and quantitative metrics that establish the observation.

## Diagnosis or hypothesis

Explain why this looks like a reusable XSH language/tooling issue rather than
task-specific confusion or evaluator noise.

## North-star impact

Explain how resolving this ticket would improve XSH ergonomics, correctness,
learnability, practical systems-glue capability, or efficient agent use. State
what evidence would show that it generalized beyond the source eval.

## Proposed XSH change
## API-surface justification

For any new builtin, keyword, constructor, type, method, or syntax form, state:

- the semantic capability that existing XSH cannot express;
- the closest existing spelling and why it is insufficient;
- whether a desugaring, type-directed rule, declared error family, or library
  API would solve the problem with less surface area;
- the implementation and maintenance cost, including checker, runtime, API
  registry, documentation, and test changes; and
- the evidence and falsification replay required before approval.

An ergonomic shortcut that merely gives a second spelling to an existing
operation is not sufficient justification for product admission.

## Proposed XSH change

Describe the smallest candidate implementation or bug fix. Do not claim that
the change is already implemented.

## Acceptance criteria

State the tests, eval replay, and behavioral contract that must pass.

## Scope and non-goals

State what is deliberately excluded.

## Post-merge evaluation

Name the exact linked eval-manager replay that will accept or reject the merged
change.
