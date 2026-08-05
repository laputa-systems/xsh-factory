# Ticket task-dupcheck-001

## Status

Open.
## CTO review

- Review cycle: next organization cycle.
- Decision: Deferred; do not approve or dispatch.
- Basis: The evaluator container failed before trial execution because `factory_control.xsh` was unavailable, and the ticket's first review also found the linked package ID malformed. The ID is now normalized to `task-dupcheck`, but the evaluator module-provisioning defect remains unrepaired; approval would create another paid harness failure.
- Next evidence: repair evaluator module provisioning and run a valid eight-case manifest before admission. Keep `Open.`.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-dupcheck`
- Shared handbook lineage: `runs/run-1785894766939/phases/03-eval/lineage/handbook-approved.md`
- Manager run: `runs/run-1785894766939/phases/03-eval/workers/eval-manager/task-dupcheck/`
- Executor run: `runs/run-1785894766939/phases/03-eval/workers/eval-worker/task-dupcheck-1/`
- XSH baseline commit: `e5d29c7ec8b4411dc749fd3e44bf472d641ad9f4`

## Observation

The task-dupcheck evaluator never starts. Its container fails at module load
before any fixture case runs, so the trial produces zero candidate/oracle
comparisons and the phase report records `missing-evaluator-manifest` and
`trial-count expected 1 observed 0`. The package-owned evaluator
`evals/task-dupcheck/evaluator.xsh` opens with `use factory_control as
control`, and the evaluator container cannot resolve that module.

`evaluator.stderr`:

```
err[parse.module-read]: failed to read module
  /run/evaluator.xsh:3:1
  use factory_control as control
  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ failed to read module; tried `/run/factory_control.xsh`: No such file or directory (os error 2). Set XSH_MODULE_PATH to add module search roots
```

The executor (`eval-executor.xsh`) mounts `evaluate.xsh` and `evaluator.xsh`
into the evaluator container at `/run/` but neither copies `factory_control.xsh`
into the container nor sets `XSH_MODULE_PATH`, so `use factory_control` cannot
resolve. The controller pre-staged dry-run passed on the host because
`factory_control.xsh` is on the host's local module path; the isolated
container lacks that root.

## Evidence

- Worker report: `task-dupcheck-1/report.json` → `execution.classification =
  "evaluator_failed"`, `evaluator_state = "fail"`, `evaluator_manifest = ""`.
- `task-dupcheck-1/evaluator.stderr`: the `parse.module-read` failure shown
  above.
- Phase report: `phases/03-eval/report.json` findings `missing-evaluator-manifest`
  and `trial-count expected 1 observed 0`; `outcomes.infrastructure = fail`.
- Candidate agent work itself is present and self-verified against a local
  oracle re-implementation (`task-dupcheck-1/work/dupcheck.xsh` reached
  `ALL-OK` and matched byte-for-byte on duplicate, hidden-file, spaces, and
  no-duplicate trees), but the packaged evaluator never exercised the eight
  hidden fixture cases.

## Diagnosis or hypothesis

This is an image/harness packaging defect in the shared eval-executor's
evaluator container setup, not an XSH language problem and not a
task-specific miss by the agent. Any eval whose package evaluator depends on
the shared `factory_control` module (task-dupcheck, task-col2, task-jsonfilter,
task-keyjoin, task-manifest, task-uniqcat) will hit the same wall unless the
evaluator container is given the module. It is deterministic and reproducible:
every paid trial of this eval will fail identically until the container can
resolve the module.

## North-star impact

This eval exists to test whether the `fs` / `hash` / stream
group-flatten-sort idiom is composable for a real "replace the find|sha256sum
pipeline" systems-glue task. As long as the evaluator cannot start, the eval
produces no evidence either way, so the north-star hypothesis about
content-level filesystem composition cannot be validated. Fixing the evaluator
container packaging unblocks the eval and lets the contributed, already-correct
agent solution be formally measured against the eight-case oracle.

## Proposed XSH change

None (no XSH language change is proposed). Proposed infrastructure change: in
`eval-executor.xsh`, make the shared `factory_control` module resolvable inside
the evaluator container — copy/mount `factory_control.xsh` into the container
(for example to `/run/` or a module root) and/or set `XSH_MODULE_PATH` so
`xsh /run/evaluate.xsh` can load `use factory_control as control`.
## API-surface justification

Not applicable — this ticket proposes a harness packaging fix, not a new XSH
builtin, keyword, constructor, type, method, or syntax form.

## Proposed XSH change

Provide `factory_control.xsh` to the evaluator container (mount or copy it and
set `XSH_MODULE_PATH`), matching how the module is already resolved on the host
so the dry-run and the isolated run agree.

## Acceptance criteria

- A fresh task-dupcheck trial produces `evaluator_state = pass` and a
  `run.json` manifest covering all eight fixture cases (including
  `hidden_missing` failing-nonzero control).
- The packaged evaluator loads `factory_control` in the isolated container
  with no `parse.module-read` failure.
- The contributed `dupcheck.xsh` candidate passes all eight cases against the
  BusyBox oracle.

## Scope and non-goals

- No XSH language, handbook, or agent-prompt change.
- No change to the task contract or the eight fixture cases.
- Provider fallback / switching is out of scope.

## Post-merge evaluation

Replay `task-dupcheck` trial 1 in a new cycle after the merged harness fix;
the eval-manager must confirm the evaluator starts and the eight cases are
measured before accepting the eval as `pass`.
