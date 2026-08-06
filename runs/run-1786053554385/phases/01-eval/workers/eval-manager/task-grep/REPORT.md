# Eval-manager report

## Result

fail

The single configured trial (`task-grep` trial 1) produced no usable evidence.
The eval worker container was launched (agent `agent.cid` and `evaluator.cid`
exist) but never emitted its canonical `session.jsonl.bz2.bz2`, wrote no `grep.xsh`
into `/work`, and exited `1` with empty `container.stdout`/`container.stderr`
and empty `evaluator.stdout`/`evaluator.stderr`. The phase executor reported
`missing session:
.../workers/eval-worker/task-grep-1/session.jsonl.bz2.bz2` (exit 1). This is a factory
infrastructure failure in the executor/worker path, not an XSH product or
handbook signal. Because no candidate artifact, evaluator manifest, worker
report, or session transcript exists, there is nothing to evaluate and no
lesson to extract. The run is classified as an infra failure for the CTO.

## Effort metrics

- Trials configured: `1`; trials with recorded evidence: `0`.
- Worker sessions: `0` (no `session.jsonl.bz2.bz2` produced).
- Assistant turns: `0`. Tool calls: `0`. Tool errors: `0`.
- Session span: n/a (no Pi conversation began/recorded).
- Worker friction: n/a — no agent ran to completion.

## Usage and cost

- No provider usage was recorded: `cost_usd = 0.0`, total bucket tokens `0`,
  `assistant_turns = 0`, `workers = 0`.
- Reasoning/thinking-token counts: not reported — the provider was never
  engaged because the worker produced no session.
- No per-trial or aggregate dollars to report.

## Thinking evidence

- Thinking-block count: `0` (no session transcript exists).
- Provider reasoning-token counts: unavailable — no assistant response was
  ever recorded. There is no `thinking.md` to ground any claim.

## Tool-error findings

None. The current evidence packet contains zero Pi tool results and zero
entries in any structured `tool_errors` array; the failure is at the executor
container boundary (empty worker output), not a Pi tool failure.

## Timing evidence

- Candidate/oracle timing: none — no candidate was produced and the evaluator
  never ran (`evaluator.stdout`/`evaluator.stderr` are empty).
- This eval has no strict candidate/oracle timing gate; timing is diagnostic
  only. There is nothing to measure.
- The XSH image/toolchain build was a cache hit (`toolchain=cache-hit`,
  `eval-image` built, `wall-ms=26010`), so build timing is not implicated.

## Observation classification

- **Factory infrastructure failure (executor/worker):** The agent container
  started (cid present) but exited `1` with empty stdout/stderr, no
  `session.jsonl.bz2.bz2`, and no candidate in `/work`. The `container.stdout`/
  `container.stderr` and `evaluator.*` files are all zero bytes. The `--rm`
  flag removed the container before a manager could inspect its exit path, so
  the root cause (agent startup, Pi auth/session write, or container crash) is
  not observable from the retained artifacts. This is infrastructure, not a
  product defect, and is out of engineer scope.
- **Not product/tooling defect:** No XSH syntax, API, or handbook behavior was
  exercised. Absence of evidence is not evidence of an XSH problem.
- **Not evaluator failure:** The package evaluator never ran; its stdout/stderr
  are empty. The failure preceded evaluation.
- **Not handbook signal:** No agent session means no friction to convert into
  reusable guidance. A handbook candidate would be fabrication.
- **Not noise:** A failed worker is deterministic infra failure, not stochastic
  variance.

## Handbook decision

Unchanged. The approved snapshot `lineage/handbook-approved.md` (sha
`3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b`, identical
to the checked-in `runtime/handbook.md`) is staged unchanged as
`lineage/handbook-candidate.md` (same sha). No provisional candidate is
justified: there was no agent session from which to derive a reusable lesson.
Promotion requires a successful replay, which this run could not produce.

## Tickets created

None. The observed failure is a factory infrastructure issue (executor failed
to produce the worker's canonical session artifact). Per policy, factory
infrastructure changes belong to the CTO, not to an engineer ticket, so no
`templates/TICKET.md` product ticket is opened.

## Post-merge decisions

None. The reconciler found `none` merged tickets for this cycle; no accepted
ticket needed post-merge acceptance review.

## Next replay

Re-run `task-grep` (one trial) against the identical approved handbook lineage
after the CTO resolves the executor/worker infra failure. The replay must
produce a real `eval-worker/task-grep-1/session.jsonl.bz2.bz2`, a candidate
`grep.xsh`, an evaluator `run.json`, and a worker `REPORT.md` before any
manager-side evaluation, handbook candidate, or ticket decision is meaningful.

## North-star impact

No XSH capability was exercised this run: the single trial failed at the
factory executor boundary before an agent could read the handbook, write a
typed text-pipeline program, or be measured for correctness, learnability, or
ergonomics. The run therefore produces no product signal and no north-star
advance. Its only durable value is a factory finding — the worker session
artifact pipeline did not run — that the CTO must repair so a future
`task-grep` trial can actually measure whether XSH's line-stream text APIs
compose humanely for real sysadmin glue work.
