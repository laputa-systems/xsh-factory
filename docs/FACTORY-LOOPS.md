# Factory loops

The north star is to make XSH a practical, easy-to-learn, token-efficient
systems-glue language that coding agents can use reliably. The loops have
different authorities and outputs.

## Inner loop: `factory/entrypoints/eval-executor.xsh` controller

The executor is pure controller infrastructure, not a Pi role or employee. For
one assigned eval and handbook snapshot, `factory/entrypoints/eval-executor.xsh`:

1. creates the worker workspace;
2. launches the eval-worker in Docker;
3. launches the evaluator script supplied by the eval package against the resulting artifact;
4. preserves the raw Pi session and evaluator `run.json`; and
5. normalizes the worker session into `workers/.../report.json`.

It does not diagnose failures, edit the shared handbook, create tickets, or
choose work. The evaluator package owns protocol, correctness, restrictions, and
candidate-versus-oracle timing. The worker report owns agent effort: turns,
token buckets, optional provider reasoning/cost fields, wall time, tools,
stop reasons, and every nonzero Pi tool result.

Thinking-block count is available when Pi records thinking blocks. A provider
reasoning-token count is shown only when Pi reports one; transcript text is not
converted into a guessed token number.

## Outer loop: eval-manager

The eval-manager is a monitor and interpreter around executor evidence. It
compares like-for-like trials and classifies observations as worker friction,
handbook opportunity, language/tooling defect, harness mismatch, reporting
failure, or noise. It may stage one handbook candidate under the run lineage
and may write a standardized ticket, but it does not change approved state.

Its required qualitative output is the employee `REPORT.md`. Its quantitative
inputs are the phase `report.json`, worker `report.json`, evaluator `run.json`,
and raw sessions. Its report must explicitly account for `tool_errors`, even
when the count is zero, so invalid API discovery calls cannot disappear in a
long narrative.

The shared handbook is `runtime/handbook.md`. Each trial receives a snapshot;
candidate promotion is a CTO-approved global change. A causal handbook
replay uses an approved snapshot for the baseline trial and a candidate
snapshot for the comparison trial.

## Product loop: engineer

The controller admits an approved ticket and creates one isolated XSH worktree
at the clean admission commit. It renders one assignment containing the
ticket text and exact path, passes that assignment to exactly one engineer,
and validates the session's required reads and product commit. The engineer
cannot discover another ticket.

The output is the portable `patches/<ticket>.diff`, the raw session,
`report.json`, and the engineer's `REPORT.md`. After the patch is captured, a
clean temporary worktree is removed. A standalone ticket cycle leaves the
patch for CTO review and application. In an organization cycle, each passing
engineer row gets its own linked replay; one sibling's failure does not
suppress another ticket's replay, and a passing replay authorizes the
controller to deliver the exact provenance commit into XSH `HEAD`. A delivery
failure leaves the branch for review and fails the cycle. Reconciliation then
updates the linked `TICKET.md` to `Merged.`; the linked manager replay decides
whether the change should remain.

## Eval-strength loop: `factory/tools/eval-trends.xsh`

The CTO uses `factory/tools/eval-trends.xsh` before reusing or retiring an eval. It
aggregates persisted eval-worker reports by eval and run, including turns,
tokens, tool errors, wall time, and provider retry/error counts. These are
agent-effort signals, not intrinsic task-difficulty scores. Compare them with
correctness, durable tickets, handbook candidates, and replay status.

An eval may be retained as a cheap regression sentinel even when its worker
sessions are short. Retire it only when the trend shows low information value,
no required replay depends on it, and the CTO records the evidence and a
replacement portfolio role.

## Design loop: eval-designer

The designer proposes at most one substantive practical systems-administration
or programming eval per bounded cycle. `task-bigfiles` and `task-groupsum` are
structural references; proposals must meet or exceed ecount-level composition.
An eval must combine at least two independent XSH data transformations or
stateful aggregation, include a meaningful failure control, and use hidden
cases that punish one-liners or hard-coded answers. A proposal must
include the task, oracle, evaluator, restrictions, runtime scaffolding, cost
expectation, and a dry run. The controller immediately gives the materialized
package to the CTO review gate and promotes it into `evals/` whether that gate
accepts or rejects the proposal. A passing evaluator and strong evidence let
the CTO set `Approved.`; rejected or incomplete packages remain `Draft.` and
stay out of active cycles.

## Organization loop

The top-level request is single-attempt: one user request permits one paid
`run.xsh` invocation. Do not relaunch an organization request to debug a
controller failure. Repair path, dispatch, lifecycle, and schema defects with
native tests, synthetic sessions, harmless process doubles, and preflight;
preserve the failed attempt and require a new explicit cycle request for a
later paid run.

`run.xsh` is a signal-safe dispatcher. Operators pass a request template under
`templates/`; `run.xsh` copies that request into the appropriate run directory
as `CYCLE-REQUEST.md` before paid children start. No top-level `cycle-*.md`
request documents are retained. It performs preflight, holds the
top-level admission boundary, and invokes one mode controller. Controllers
wait on process handles and use lifecycle callbacks after child exit; agents
do not poll each other and do not drive the state machine.

The organization controller can start independent work concurrently:

```text
approved ticket ──> implementation ──> linked re-evaluation
                     │
                     └──────────────> independent eval

optional eval-design ───────────────────────────────┘
```

Implementation must finish before the linked candidate replay because the
replay consumes its worktree or patch. The independent eval and design phase
have disjoint inputs and may overlap with implementation. If no ticket is
admitted, the independent eval becomes the primary phase.

The CTO is the authority for product merges, handbook promotion, eval
approval, and reversion. The organization controller executes the CTO's
bounded merge decision only after its linked replay passes and exact commit
checks succeed; standalone ticket cycles remain review-only. The CTO reviews
the evidence and chooses the next narrow cycle within the coded spend and
eval-count limits.

The CTO closes each user-requested paid cycle once, including a failed or
partial attempt, by committing the reviewed factory changes and that cycle's
durable evidence. A controller repair must not create a chain of close commits:
diagnostic attempts are listed in the primary cycle handoff, while unrelated
historical runs are not bulk-closed. `runs/.gitignore` allowlists the evidence
hierarchy—reports, narratives, manifests, compressed sessions, events, and
patches—while excluding transient controller plumbing such as locks, PIDs,
logs, worktrees, and active markers.

## Durable output hierarchy

```text
runs/run-<id>/
├── report.json
├── CTO-REPORT.md
├── events.jsonl
├── phases/<phase>/report.json
├── workers/<role>/<worker>/
│   ├── session.jsonl.bz2
│   ├── report.json
│   └── REPORT.md
└── patches/<ticket>.diff
```

Each run has one canonical `events.jsonl`. Lifecycle transitions use
`kind: "event"`; completed controller streams use `kind: "process-output"`
with a channel and captured content. Sibling stdout/stderr files are optional
forensic copies.

`report.json` is the machine contract at every controller boundary. The
schema is implemented in `factory/schema.xsh` and described in
[`REPORT-SCHEMA.md`](REPORT-SCHEMA.md). Compressed `session.jsonl.bz2` files
retain canonical raw Pi evidence. The runtime transparently reads them.
`REPORT.md` is one qualitative employee judgment. `CTO-REPORT.md`
is a human navigation view generated from those sources. There are no
generated Markdown cost, audit, dispatch, provenance, current-evidence, or
tool-error projections.

## Signals, budgets, and tests

`run.xsh` handles SIGINT and SIGTERM with zero pre-cancel time. The runtime
registry tracks descendant PIDs and Docker container IDs so cancellation
terminates the owned process tree and preserves partial evidence. The
aggregate cycle watcher is a hard cap; a breach shuts down the cycle and
writes a postmortem. Worker budget breaches have durable consequences:
eval-workers disable their evals, and engineers close their tickets as too
difficult with a link to the attempted run.

`tests/` is the cheap hard judge. Native xsht tests cover JSON report parsing,
session normalization and tool errors, lifecycle transitions, budget and
signal cleanup, exact assignment routing, patch/worktree cleanup, and report
compilation with fake processes. They never launch Pi or Docker.
