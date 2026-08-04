# task-safepath staged dry run

Date: this eval-design cycle.
Image: `xsh-factory-base:latest`, platform linux/arm64, `--read-only`,
`--cap-drop=ALL`, no-new-privileges, tmpfs `/tmp`.

## What was exercised

Ran the materialized package exactly as the executor does — the eval container
executed `xsh /run/evaluate.xsh` (package `evaluate.xsh` -> package-owned
`evaluator.xsh`), with `/work` mounted read-only containing the reference
`reference-candidate.xsh`, `task.md`, `handbook.md`, `agents.md`, and the
template `review.md`; `/session` and `/export` mounted read-write on the same
worker dir.

- Public + 7 hidden cases (1 public, 4 normalize, 4 escape failure-controls)
  matched the external `sh` oracle byte-for-byte and exit-for-exit.
- `/session/run.json` manifest written with `result: pass`,
  `classification: pass`, per-case correctness, timings, input/output sha256.
- Review-heading protocol check passed.
- Forbidden-subprocess restriction check passed on the reference candidate.

## Failure controls (fail closed)

| control | exit | classification |
| --- | --- | --- |
| hard-coded candidate | 1 | `candidate_failed` |
| forbidden subprocess candidate | 1 | `restriction_failed` |
| missing artifact | 1 | `worker_missing_artifact` |
| incomplete review.md | 1 | `protocol_failed` |

## Evidence files

- `run.pass.json` — full pass manifest for the reference candidate.
- `run.candidate-failed.json` — negative-control manifest (hard-coded candidate).
- `reference-candidate.xsh` — the lint-clean reference solution used.
- `oracle.sh` — the external `sh` oracle used by the evaluator.

## Not exercised

A paid Pi agent trial (no PI auth / network spend in this designer dry run).
The proposal remains `Draft.`; a live agent run is deferred to the CTO's
admission gate after approval.
