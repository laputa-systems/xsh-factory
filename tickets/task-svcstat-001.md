# Ticket task-svcstat-001

## Status

Open.

## Change target

- `factory`

This is a historical factory finding. The CTO owns its implementation; it is
not eligible for engineer dispatch.

## CTO review

- Review cycle: post-cycle-1785947947500.
- Decision: Deferred; do not approve or dispatch.
- Basis: The observation was produced by an independent eval whose
  evaluator failed before producing a manifest because of the shared duplicate
  mount defect. It is a harness report, not a validated product signal; the
  executor repair must be replayed first. Keep the ticket Open until a fresh
  `task-svcstat` run produces a populated manifest and the manager confirms a
  reproducible XSH finding.
- Next evidence: replay `task-svcstat` after the executor fix and require
  evaluator start, all eight cases, and manager classification before any
  approval decision.

Open.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-svcstat`
- Shared handbook lineage: `runs/run-1785947947500/phases/03-eval/lineage/handbook-approved.md`
- Manager run: `runs/run-1785947947500/phases/03-eval/workers/eval-manager/task-svcstat/REPORT.md`
- Executor run: `runs/run-1785947947500/phases/03-eval/workers/eval-worker/task-svcstat-1/`
- XSH baseline commit: `aaa968c73fd7649f70a6a94e21f77a90bf6a778c`

## Observation

The eval-worker's agent session completed successfullly (artifact `svcstat.xsh`
produced, local `xsht check`/`fmt`/`lint` and a representative run passed), but
the evaluator container never started. `evaluator.stderr` contains only:

```
docker: Error response from daemon: Duplicate mount point: /run/evaluator.xsh.
See 'docker run --help'.
```

As a result `evaluator.stdout` is empty, no evaluator `run.json` was emitted,
and the executor marked the trial `evaluator_state: fail` /
`classification: evaluator_failed` with an empty `evaluator_manifest`.

## Evidence

- Executor mount list: `the factory evaluator process boundary` lines 147–148 both bind
  `${evaluator_file}` to `/run/evaluator.xsh,readonly` — a duplicated mount
  entry in the same `eval_mounts` array.
- Worker session: `runs/run-1785947947500/phases/03-eval/workers/eval-worker/task-svcstat-1/session.jsonl`
  (agent reached a stop; session truth is the canonical session JSONL).
- Failure output: same worker dir `evaluator.stderr` (104 bytes, the Docker
  duplicate-mount error), empty `evaluator.stdout`.
- Phase report: `runs/run-1785947947500/phases/03-eval/report.json` —
  `outcomes.infrastructure: fail`, finding `missing-evaluator-manifest`.

## Diagnosis or hypothesis

This is a harness/infrastructure defect in the generic eval-executor, not a
task-specific or XSH-language problem. `eval_mounts` declares the same
`/run/evaluator.xsh` bind mount twice, and `docker run` rejects duplicate mount
points before the container launches. The defect is not specific to
`task-svcstat`: any eval that runs through the generic evaluator path would hit
the same duplicate mount and never execute its oracle, so no evaluation result
or candidate/oracle timing can be produced for this cycle.

## North-star impact

The eval-executor is the shared admission harness for every eval. A duplicated
mount point silently blocks all evaluator runs, so the factory cannot measure
correctness, restriction compliance, or candidate/oracle timing — the very
evidence the north-star evidence loop depends on. Fixing this single
reproducible harness bug (removing the duplicate `/run/evaluator.xsh` mount)
unblocks evaluator admission for every eval and lets `task-svcstat` produce
real byte-exact comparisons and timing. The generalization test is that a
replayed `task-svcstat` trial (beyond this one) actually yields a populated
`run.json` and byte-exact per-case results.

## Proposed XSH change

No XSH language change. This is a factory harness fix in `the factory evaluator process boundary`:
remove the duplicated `--mount … dst=/run/evaluator.xsh,readonly` entry so
`/run/evaluator.xsh` is mounted exactly once (and the package-owned
`evaluator.xsh` is still visible to `the shared evaluator dispatcher` via the
`FACTORY_EVAL_EVALUATOR` contract).

## API-surface justification

Not applicable — no new builtin, keyword, constructor, type, method, or syntax
form is proposed. The change is a one-line de-duplication in the executor's
container mount list.

## Proposed XSH change

Correct `the factory evaluator process boundary` so `eval_mounts` mounts the evaluator file to
`/run/evaluator.xsh` exactly once, matching the generic `the shared evaluator dispatcher`
contract that reads it via `env.path("FACTORY_EVAL_EVALUATOR", p"/run/evaluator.xsh")`.

## Acceptance criteria

- `docker run` for the evaluator starts without a "Duplicate mount point" error.
- A `task-svcstat` trial emits a populated evaluator `run.json` with all eight
  cases (public + 7 hidden, including the malformed failure control) and
  byte-exact stdout comparison plus per-case candidate/oracle timing.
- The generic evaluator admission still binds the package-owned `evaluator.xsh`
  at `/run/evaluator.xsh` and finds it from `the shared evaluator dispatcher`.

## Scope and non-goals

- Not a change to the task, oracle, evaluator.xsh logic, or handbook.
- Not a change to provider selection or fallback.
- Does not validate `task-svcstat` correctness by itself; it only unblocks the
  evaluation that does.

## Post-merge evaluation

Replay: eval `task-svcstat` against the shared handbook lineage (unchanged
approved snapshot) on the merged executor fix. The linked eval-manager should
confirm a populated `run.json` and byte-exact results before the fix is trusted,
and the same executor path should be spot-checked across one other eval to
confirm the generic fix generalizes.
