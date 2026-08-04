# Factory contract

The factory exists to improve XSH ergonomics, correctness, learnability, and
AI token efficiency. It should prove XSH as a practical systems-glue language
through small, reproducible tasks. The product rationale is linked directly
from `NORTH-STAR.md` and the adjacent XSH checkout.

## Organization

```text
CTO
├── eval cycle controller
│   ├── eval-executor.xsh (controller program, not a Pi role) ── eval-worker
│   ├── eval-manager
│   └── eval-designer
└── director (ticket-implementation only)
    └── engineer
```

| Role | Owns | Does not own |
| --- | --- | --- |
| CTO | Cross-cycle strategy, ticket/eval portfolio, policy, factory improvements, and validation/revert decisions | Per-trial execution, worker implementation, or direct Pi launching |
| eval-manager | Trial interpretation, effort evidence, handbook candidates, and reproducible ticket recommendations | Executor reruns, product edits, or ticket selection |
| eval-designer | New eval contracts, scaffolding, oracle design, and proposal dry runs | Approving or enabling an eval, editing approved evals, or product changes |
| director | Ticket-cycle dispatch, engineer process supervision, and output reconciliation | Eval-mode review, ticket selection, product decisions, handbook promotion, or merge |
| engineer | One controller-assigned product implementation in an isolated worktree | Ticket selection, scope expansion, merge, or ticket-status changes |
| eval-worker | One isolated eval artifact and its task review | Host/factory/oracle inspection, handbook edits, or evaluator changes |

The controller assigns work. Agents interpret evidence and make qualitative
decisions inside their assignments. `eval-executor.xsh` is a controller-owned
inner-loop program that launches the isolated `eval-worker`; it is not an
agent, employee, or Pi role. The director never searches for work and an
engineer never chooses a ticket. There is one process launcher,
`run-agent.xsh`, and one top-level dispatcher, `run.xsh`.

## Engineering rules

- Simplicity is a hard requirement. Prefer one owner, one state transition,
  one durable output, and one parameterized template. Delete obsolete layers
  instead of preserving compatibility projections.
- Factory orchestration and tools are XSH. External commands are limited to
  explicit system boundaries such as Git, Docker, and the local XSH build.
- Controllers contain no inline Markdown report, prompt, assignment, or event
  bodies. Put Markdown inputs and human narratives on disk in `templates/` or
  role files. Structured facts belong in JSON.
- Separate orchestration from judgment. Controllers own admission, exact
  assignment, process boundaries, cancellation, state transitions, and
  validation. Pi roles own interpretation, diagnosis, and recommendations.
- Fail closed at boundaries: validate paths, exact assignments, commits,
  report schema, handbook lineage, image identity, budgets, and required reads.
- Every behavior that can be tested without Pi gets an xsht native test.
  Synthetic sessions, fake commands, and harmless process doubles are the
  default. Do not spend model budget to test deterministic infrastructure.
- Preserve a useful evidence chain without producing duplicate reports.
  `report.json` is the machine contract; compressed `session.jsonl.bz2` is
  canonical Pi evidence; `REPORT.md` is the employee's one qualitative narrative;
  `CTO-REPORT.md` is a navigation briefing.
- The CTO may merge product branches, apply patches, and promote handbook
  candidates when the evidence supports those decisions. The CTO reviews each
  newly materialized eval immediately and promotes its package into `evals/`
  even when the review does not accept it. A passing evaluator and strong
  evidence may set `Approved.`; otherwise the package remains `Draft.` and is
  not admitted to paid work.

## Report contract

The report envelope is implemented in `report_schema.xsh` and constructed by
the controllers or `tools/session-report.xsh`:

```text
schema_version, kind, identity, state, result, data, findings, artifacts
```

The allowed boundary kinds are `worker`, `phase`, and `run`. Worker metrics
include turns, token buckets, optional provider reasoning/cost fields, timing,
models, stop reasons, tools, and structured `tool_errors`. Phase reports join
worker reports with evaluator `run.json` evidence, handbook lineage, and
findings. Organization reports join phase reports. See
[`docs/REPORT-SCHEMA.md`](docs/REPORT-SCHEMA.md) for the complete layout.

There are deliberately no generated `COST.md`, `AUDIT.md`, `RUN.md`,
`PROVENANCE.md`, `DISPATCH.md`, `CURRENT-EVIDENCE.md`, `TOOL-ERRORS.md`, or
role-specific worker report files. Removing a projection must not remove the
raw evidence that made it useful: costs and errors remain structured fields,
and session text remains in compressed `session.jsonl.bz2` archives.

Markdown still has a clear purpose. Cycle requests, eval contracts, tickets,
assignments, role prompts, postmortems, and employee `REPORT.md` files are
human-authored inputs or judgments. They are not machine-to-machine state.

## Cycle boundaries

`run.xsh` admits one explicit mode after preflight:

- `eval`: build the local XSH/xsht distribution, run one or two pure eval
  trials through `eval-executor.xsh`, then dispatch the manager and optional
  designer review;
- `ticket-implementation`: create up to two isolated worktrees and one
  inlined ticket assignment per approved ticket, dispatching the admitted
  engineer rows concurrently, then capture a portable patch per ticket;
- `eval-design`: dispatch one designer, review its package, and promote one
  proposal while preserving `Draft.` status; or
- `organization`: compose the bounded implementation, linked replay,
  independent eval, and optional design phases.

Child phases may overlap only when their inputs and product state are
independent. Ticket implementation completes before each ticket's candidate
replay; a passing engineer row is re-evaluated independently even when a
sibling ticket fails.
The independent eval and eval-design phase may run concurrently with it.
Process handles and lifecycle events, not polling agents, advance the state
machine. `events.jsonl` is the canonical cycle ledger: lifecycle transitions
and normalized controller stdout/stderr are JSON lines there. Per-process log
files are optional forensic copies, not required to reconstruct the run.

The inner eval executor is pure controller infrastructure: it runs the assigned
worker and the evaluator script supplied by that eval package, then writes the worker report and evaluator manifest. The
eval-manager reads
those outputs, measures effort and qualitative friction, and may propose a
handbook candidate or standardized ticket. It does not repair the product in
place. An engineer works only on a controller-assigned approved ticket in an
isolated product worktree.

## Product and handbook authority

There is one shared rolling handbook at `runtime/handbook.md`. Trial workspaces
receive snapshots; a candidate lives under the run until a CTO-approved
decision promotes it. `runtime/handbook-ledger.md` records each candidate
disposition, and an undispositioned candidate blocks the next paid cycle. Every
eval reads the same approved handbook lineage.
Eval packages follow a separate path: the CTO promotes them into `evals/`
immediately, then sets `Approved.` only after the evaluator and evidence pass.
`Draft.` status keeps rejected or incomplete packages out of paid admission.

The CTO reviews and promotes new eval packages, admits work to active cycles,
and decides product merges. Reconciliation examines the linked ticket's
recorded implementation and changes only that `TICKET.md` status to `Merged.`
when the merge is proven. A linked manager replay can then accept or reject the
product change with evidence.

## Budgets and shutdown

Role settings are coded in `factory_control.xsh`; all roles have independent
provider, model, thinking, tools, turn, wall, and dollar settings. The
aggregate cycle cap is enforced by `tools/cycle-budget-watch.xsh` and is a
hard stop. A breach terminates the full process tree, writes a postmortem,
and leaves structured partial evidence. An eval-worker budget breach disables
that eval in its `EVAL.md`; an engineer breach closes its assigned ticket as
`too difficult` with the attempted run link.

The factory is intentionally frugal. The CTO should stop running inactive or
solved evals, inspect worker error arrays and session churn, and improve the
prompts or handbook only when the evidence warrants it.

## Verification

The nearest hard judge for factory changes is:

```sh
XSH_MODULE_PATH=. xsht test
```

Then run a minimum user-facing cycle through `run.xsh`, inspect its
`report.json` and `CTO-REPORT.md`, and verify that the persisted tree contains
only the declared outputs. Never run formatters, autofixers, pre-commit hooks,
or direct Pi commands as part of this contract.
