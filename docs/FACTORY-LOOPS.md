# XSH factory loops

The factory has one north-star objective: make XSH a practical, easy-to-learn,
token-efficient systems-glue language that coding agents can use reliably. The
factory therefore improves four coupled surfaces: XSH ergonomics and
correctness, the agent-facing handbook, the isolated evaluation harness, and
the evidence used to decide whether an observation generalizes.

## Inner loop: eval-executor

The inner loop is deliberately pure. `evals/<eval>/executor.xsh` owns one
isolated trial:

1. seed a fresh work directory from the shared handbook snapshot;
2. start the isolated `eval-worker` container;
3. start the separate evaluator container;
4. copy the session, artifact, review, oracle output, and evaluator manifest;
5. render the Pi session report and write `EXECUTOR-REPORT.md`.

The executor does not diagnose, edit the handbook, open tickets, or choose a
model. Its contract is the evidence boundary. The evaluator must distinguish
protocol completion, candidate correctness, restriction compliance, and
timing. A failed container or failed session report is a harness-level signal,
not automatically a product defect.

The worker's Pi session is canonical. `tools/session-report.xsh` extracts
turns, tool calls and errors, thinking blocks, token buckets, provider totals,
optional provider-reported reasoning tokens, cost components, total cost, and
session wall span. `reasoning` is a subset of `output`; thinking text is not a
reliable token counter. Missing provider fields remain unknown.

Every eval image inherits `evals/Dockerfile.base`, which contains the pinned
Alpine runtime, locally built `xsh` and `xsht`, and Pi. An eval Dockerfile is a
thin layer for task-specific packages and runtime files. `task-ecount` adds
only `fd`; the base image is built once per cycle so evals do not duplicate
their large common layers.

## Outer loop: eval-manager

The eval-manager is a monitor and interpreter around the pure executor. It
must preserve the same eval, oracle, XSH input, image, and handbook lineage
while comparing trials. It classifies observations as:

- worker friction;
- reusable handbook guidance;
- XSH language or tooling defect;
- image or harness mismatch;
- evaluator/reporting failure; or
- stochastic noise.

The manager may propose a ticket only when one reproducible observation points
to a general improvement. It may write a provisional shared-handbook candidate
under the run's lineage directory, but never edits the approved or checked-in
handbook during diagnosis. A candidate is trusted only after a replay uses its
hash and the manager records the comparison. Promotion is global: an approved
candidate becomes the next checked-in `runtime/handbook.md` for every eval.

The standard two-trial replay is:

```text
trial 1 -> lineage/handbook-approved.md -> executor evidence
manager diagnosis -> lineage/handbook-candidate.md
trial 2 -> lineage/handbook-candidate.md -> executor evidence
```

An unchanged copy is valid evidence when the first trial yields no handbook
change. The run records both staged handbook hashes so a prompt claiming to use
the candidate cannot silently use the baseline.

## Organization loop

`run.xsh` is the executable cycle boundary. It selects the first eval listed
under `## Active evals` in the cycle request, or accepts an explicit eval ID,
then snapshots provenance before launching Pi:

- the clean XSH commit;
- Docker image ID and platform;
- approved and candidate shared-handbook hashes; and
- every Pi session under `runs/run-<id>/workers/`.

The director launches children through `run-agent.xsh`, which is the only
authorized Pi launcher. Role-specific provider, model, thinking level, tools,
and budget are environment settings with explicit defaults. Ctrl-C is handled
at the cycle boundary and terminates the owned child process groups, including
nested Pi workers, before returning partial evidence.

The director coordinates eval-managers, eval-designers, and already-open
ticket work. It does not merge XSH changes. The user approves new evals and
merges completed XSH SWE branches. A ticket links its reporting eval, manager
lineage, executor evidence, and XSH baseline; after a merge, that eval-manager
accepts or rejects the change with a controlled replay.

## Layer outputs

| Layer | Input | Durable output |
| --- | --- | --- |
| eval-executor | one eval, one handbook snapshot, one image | worker session/report, artifact, manifest, executor classification |
| eval-manager | executor trials and Pi metrics | shared-handbook candidate, manager report, evidence-backed tickets |
| xsh-swe | one controller-assigned ticket snapshot and worktree | branch/worktree, tests, implementation, completion report |
| eval-designer | factory mission and practical task idea | proposed eval contract, scaffolding, dry-run evidence |
| director | approved cycle request | child reports, dispatch status, north-star impact, run summary and cost report |
| user | proposed evals and completed branches | approval or rejection, merge or revert decision |

The system is Markdown-first at the organizational layer. JSON is retained as
the evaluator's derived machine-readable manifest and Pi session reporting
layer; it is not a second configuration language.

The controller's pure contracts and non-Pi tools are covered by native XSH
tests in `tests/`. Those tests use synthetic Pi JSONL, a harmless sleep process
as the budget-watch worker double, and a fake Docker executable for cleanup;
they do not spend model budget or contact an agent.

## Control plane: explicit modes and events

The agents are workers, not the workflow engine. `run.xsh` is the cycle
controller and the only component that admits work, creates product worktrees,
starts the director, validates child outputs, and decides whether the cycle
passed. It waits on process handles; it does not poll Pi sessions for state.
`run-agent.xsh` owns one Pi process and emits its structured session report
after that process exits.

Cycle requests select a mode. The current modes are:

- `eval`: run the selected eval-manager and its pure executor trials;
- `ticket-implementation`: admit only the explicitly listed tickets whose
  checked-in status is `Accepted.`, create one XSH worktree per ticket, and
  dispatch one `xsh-swe` worker per worktree.

Each run also has an `events/` ledger of small Markdown event records. The
controller writes events at admission, worker start, worker completion, and
cycle completion. These are callbacks at the process boundary: a child exit
causes the next deterministic validation/output step. They are deliberately
not a second agent-facing state database, and an agent must not infer authority
from a session transcript or poll another worker's files.

Ticket implementation is therefore a reviewable state transition. The
controller renders one inline assignment per ticket, records its SHA-256 in
`TICKET-DISPATCH.md`, and the shared runner verifies that exact assignment and
claims the worker slot before starting Pi. The cycle validator also requires
the session JSONL to show `read` tool calls for the exact factory north-star
and handbook paths supplied in that assignment:

```text
Accepted ticket
  -> admitted event
  -> isolated worktree at recorded XSH commit
  -> xsh-swe process completion
  -> branch/commit/clean-worktree/report validation
  -> ready-for-review branch (never auto-merged)
```

The next tightening before `task-ecount` is to extend this same controller
contract to eval approval, SWE acceptance/rejection, and post-merge replay:
each transition should have one admissible input, one durable event, one
validator, and one explicit callback/output. Pi remains useful for judgment and
diagnosis, but it should not be responsible for inventing the organization's
state machine.
