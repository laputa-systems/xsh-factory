# Ticket task-grep-001

## Status

Approved.

## Change target

- `product`

## CTO review

- Review cycle: cycle 23 close.
- Decision: Approved for implementation in the next organization cycle.
- Basis: The manager's independent `task-grep` trial reproduced a general
  checker-diagnostic mismatch, the evaluator passed all nine cases, and the
  proposed change has a narrow product scope with explicit acceptance and
  non-goals. This is a product ergonomics ticket, not a factory change.
- Evidence: `runs/run-1786202908216/phases/03-eval/workers/eval-manager/task-grep/REPORT.md`
  and `runs/run-1786202908216/phases/03-eval/workers/eval-worker/task-grep-1/run.json`.

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

- Eval: task-grep (evals/task-grep/EVAL.md, Approved)
- Shared handbook lineage: runs/run-1786202908216/phases/03-eval/lineage/handbook-approved.md
- Manager run: runs/run-1786202908216/phases/03-eval/workers/eval-manager/task-grep/REPORT.md
- Executor run: runs/run-1786202908216/phases/03-eval/workers/eval-worker/task-grep-1/run.json
- XSH baseline commit: 608ab11bcf25cb0f69df4cb352fa40b27c1be2b3

## Observation

The eval worker wrote an initial `grep.xsh` with a local binding named `path`
(`let path = Path.parse_bytes(...)?`). `xsht check` then surfaced two
diagnostics: a `warn[check.standard-module-shadow]` on the binding itself, and
a misleading primary `err[check.unknown-module-api]` on the method call
`path.read_text()` ("unknown module API"). The worker, reading the errors, at
first thought the `read_text()` call was the actual defect and renamed the
binding to `file` only after reading the secondary shadow warning. The final
artifact passed all nine evaluator cases by renaming the binding (`file`).

## Evidence

- Session JSONL: runs/run-1786202908216/phases/03-eval/workers/eval-worker/task-grep-1/session.jsonl (turns ~14-16: first script, then check output showing both diagnostics, then rename and pass).
- Tool result: `err[check.standard-module-shadow]: name `path` shadows the standard module `path`` AND `err[check.unknown-module-api]: unknown module API` at `path.read_text()`.
- Final artifact runs/run-1786202908216/phases/03-eval/workers/eval-worker/task-grep-1/grep.xsh (binding renamed to `file`).
- Worker self-report: review.md `## xsht friction` explicitly records "Naming a local binding `path` shadows the standard `path` module and makes the `check` stage report a confusing `unknown-module-api` ... A pointer in that error message would save debugging time."
- run.json correctness: all 9 cases exact, result pass.

## Diagnosis or hypothesis

This is a general XSH checker ergonomics issue, not task-specific noise. `path`
is a natural variable name for a file-path program, and any eval in which an
agent reaches for a module-name binding (`path`, `env`, `fs`, `json`, ...) will
hit the same pair of diagnostics. The misleading part is that the primary error
`unknown-module-api` points at the method call site as if the API did not
exist, while the actual cause — the shadowing binding — is reported only as a
secondary `standard-module-shadow` warning. A warning is easy to miss, and the
error text steers an agent toward debugging a method that is valid, wasting a
turn. The fix is a diagnostic-clarity improvement: when a frozen/standard
module is shadowed, surface the shadow as the primary, actionable error (or
have the dependent method error point to the shadow), so the agent sees one
clear cause instead of a misleading API error plus a buried warning.

## North-star impact

Improving the diagnostic makes XSH check output trustworthy and reduces agent
friction (fewer turns and less guesswork) when a local binding collides with a
standard module name. Evidence of generalization: a later eval/trial that names
a module-name binding and, from the improved check output alone, renames it
immediately (one turn) without the `unknown-module-api` dead end. This is an
ergonomics and learnability win consistent with the north-star goal of "fewer
guesses, workarounds, tool errors, and repeated discoveries."

## Proposed XSH change

Make `standard-module-shadow` a primary, actionable diagnostic (error rather
than a secondary warning) when a binding shadows a standard module, or make the
dependent `unknown-module-api` error cite the shadowing binding as the cause.
Do not claim this is implemented; this is the smallest candidate change.

## Acceptance criteria

- `xsht check` on `let path = Path.parse_bytes(...)?; ... path.read_text()?`
  reports the shadow as the primary error and does not misattribute the fault
  to a nonexistent (unknown) module API.
- Existing standard-module users that do not shadow still pass lint/check.
- The task-grep replay reaches the final correct script with the shadow renamed
  in one turn and without the misleading `unknown-module-api` probe.

## Scope and non-goals

- Scope: improve the shadowing diagnostic's clarity and primary/error ordering.
- Non-goal: renaming the standard `path` module, changing `read_text`, or
  altering the task output contract.

## Post-merge evaluation

The next task-grep manager replay (same eval and handbook lineage) accepts if a
worker that names a binding `path` gets a clear, primary shadow diagnostic and
renames it in one turn; rejects if the misleading `unknown-module-api` persists.
