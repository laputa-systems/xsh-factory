# Factory agent guide

This repository is the XSH improvement factory: its controllers, evals,
prompts, tickets, shared handbook, and run evidence. The adjacent
`../xsh` repository is the XSH product. Keep those boundaries explicit.

## Start here

Read these files in this order before making a substantive decision:

1. [`NORTH-STAR.md`](NORTH-STAR.md) for the product mission.
2. [`FACTORY.md`](FACTORY.md) for layer contracts, invariants, and coding rules.
3. [`README.md`](README.md) for supported actions and operator commands.
4. [`docs/FACTORY-LOOPS.md`](docs/FACTORY-LOOPS.md) for the inner, outer, and
   organization loops.

If acting as the CTO, read [`CTO.md`](CTO.md) after the files above. It is the
bounded operating loop for inspecting evidence, making at most the permitted
decisions, and starting one cycle. Do not invent a broader autonomous loop.

Read only the role, cycle request, eval contract, ticket, template, or tool
files relevant to the task after this entry-point pass. The latest run's
`CTO-REPORT.md` is the first place to look when reviewing a completed cycle;
follow its links into `report.json`, employee narratives, evaluator manifests,
and raw Pi sessions only as needed.

## Repository boundary

The product checkout is `../xsh`. Its local contract is
[`../xsh/AGENTS.md`](../xsh/AGENTS.md). The stable XSH rationale is in
[`NORTH-STAR.md`](NORTH-STAR.md), so factory employees should use that single
briefing instead of following a second rationale link.

The product guide applies when editing files in `../xsh`; it is not the
factory's guide. For factory work, this file and the factory documents above
are authoritative. Engineer assignments must read the product guide because
they modify an isolated XSH worktree.

## Factory working contract

- Use XSH for factory controllers and tools. Do not add Python or another
  orchestration language.
- Keep orchestration deterministic and testable without Pi. Controllers own
  admission, exact assignments, process boundaries, cancellation, state
  transitions, and validation; agents own qualitative judgment.
- Do not put generated prompts, reports, or assignments inline in controller
  source. Store Markdown in `templates/` and substitute explicit fields.
- Add or update native XSH tests for pure parsing, lifecycle, reconciliation,
  cleanup, budget, and failure behavior. Use mocks and synthetic Pi sessions;
  do not spend model budget to test deterministic infrastructure.
- Preserve run evidence and user changes. Never reset unrelated work, merge
  product branches, or push to a remote without explicit instruction.
- Treat `run.xsh` as the only top-level launch path. Do not launch Pi directly
  or ask an employee to discover unassigned work.
- Keep cycles bounded by the coded role limits and aggregate cap. A budget
  breach must stop the factory cleanly and leave its postmortem/evidence.

## First checks

From this directory, inspect both repositories before editing:

```sh
git status --short
git -C ../xsh status --short
XSH_MODULE_PATH=. xsht test
```

For a cycle, use the documented request through `run.xsh`; run its preflight
and let the controller create the run directory, structured reports, child
sessions, lifecycle ledger, and CTO briefing. Do not bypass the controller.

For a product-language change, read the nearest product contract and test map
in `../xsh/docs/`, then follow `../xsh/AGENTS.md`. For a factory change, start
with the nearest controller/tool and its native test under `tests/`.

## Terminology

Use the current Pi role names: `CTO`, `director`, `eval-designer`,
`eval-manager`, `eval-worker`, and `engineer`. `eval-executor.xsh` is
controller-owned infrastructure, not a role or employee. Older references to
“automator” or “xsh-swe” are legacy terminology, not new role names.

## Factory infrastructure codemap

The factory is an XSH control plane around two repositories. This map is the
navigation contract for controller work; use it to find an owner before
grepping broadly.

### Repository boundary and durable state

- `NORTH-STAR.md` is the product mission and rationale briefing shared by all
  roles. `FACTORY.md` defines orchestration invariants and authority. `README.md`
  documents operator commands. `CTO.md` defines the bounded CTO inspection,
  decision, cycle, and closeout loop.
- `../xsh` is the product repository. Factory controllers create isolated
  worktrees there, but the factory checkout owns admission, assignments,
  reports, patches, tickets, eval packages, and run evidence.
- `runtime/handbook.md` is the approved rolling agent handbook;
  `runtime/handbook-ledger.md` records candidate dispositions. `tickets/*.md`
  are the checked-in product observations and lifecycle records. `evals/*/`
  are package-owned eval contracts, tasks, artifacts, executors, and
  evaluators. `runs/run-*/` is durable checked-in evidence. Close commits
  include the reports, narratives, manifests, compressed sessions, lifecycle
  ledger, patches, and other files allowed by `runs/.gitignore`; transient
  controller plumbing remains ignored.

### Top-level dispatch and cycle controllers

- `run.xsh` is the only top-level launcher. It performs preflight, admission,
  locks, aggregate-budget setup, signal cleanup, and dispatches exactly one
  mode controller.
- `run-organization.xsh` composes the bounded organization graph: approved
  ticket implementation, linked replay, independent eval, and optional eval
  design. It owns overlap and waits on process handles; it does not ask agents
  to select work.
- `run-ticket.xsh` creates clean XSH worktrees, renders immutable engineer
  assignments, dispatches engineer rows through `run-agent.xsh`, validates
  reports/branches/commits/worktrees, amends validated engineer commits with
  provenance, and captures portable patches.
- `run-ticket-reuse.xsh` validates an already-existing factory branch in a
  detached worktree for an organization replay; it is not a second engineer
  dispatch path.
- `run-eval.xsh` builds the local XSH image/runtime, dispatches eval workers
  through `eval-executor.xsh`, and then dispatches the eval-manager. It owns
  trial admission and evaluator manifests, not qualitative diagnosis.
- `run-design.xsh` dispatches one eval-designer and gates materialization,
  evaluator syntax checks, CTO review, and promotion into `evals/`.
- `run-cto.xsh` is deterministic ticket inventory/reconciliation input for the
  CTO; it does not launch paid work.

### Shared runtime, contracts, and process boundaries

- `factory_control.xsh` contains pure policy and parsing: role defaults,
  provider/model/budget/turn/wall ceilings, request parsing, ticket/eval
  lifecycle predicates, report-template validation, assignment checks, and
  template substitution. Change policy here before changing a controller.
- `factory_runtime.xsh` contains effectful shared operations: process/PID
  registration and cancellation, locks, event-ledger writes, CTO handoffs,
  eval promotion, ticket reconciliation, worktree/patch cleanup, handbook
  lineage checks, exact session-read checks, and engineer commit provenance.
- `report_schema.xsh` is the single machine-report envelope validator for
  `worker`, `phase`, and `run` reports. Do not add role-specific machine
  projections; preserve metrics in `report.json` and raw session JSONL.
- `audit-run.xsh` compiles controller outputs into a phase/run report.
  `factory_report.xsh` and `tools/cto-report.xsh` render human navigation
  views from structured evidence; the views are not state.
- `run-agent.xsh` is the one Pi process boundary. It creates the worker
  directory, invokes Pi with role settings, persists compressed `session.jsonl.bz2`, runs
  session/budget watchers, and normalizes the worker report. Never launch Pi
  directly.
- `tools/session-report.xsh` parses Pi JSONL into worker metrics: assistant
  turns, token buckets, provider totals, reasoning tokens when reported,
  thinking blocks, cost, stop reasons, tool counts, tool errors, and session
  span. Engineer commit trailers are derived from this normalized report plus
  the hashed raw session, not from narrative prose.
- `tools/session-watch.xsh`, `tools/budget-watch.xsh`, and
  `tools/cycle-budget-watch.xsh` enforce worker and aggregate shutdown bounds.
  `tools/cleanup-run.xsh` and `tools/clean-factory.xsh` are cleanup operators;
  they must preserve branches, tickets, and evidence according to their scope.

### Roles, prompts, and report ownership

- `roles/engineer.md` implements one controller-assigned product ticket in one
  isolated worktree. `templates/ENGINEER-ASSIGNMENT.md` is the immutable
  assignment contract and `templates/ENGINEER-REPORT.md` is the qualitative
  output contract. The engineer commits product code; the controller amends
  that commit only after report, branch, commit, and clean-worktree checks pass.
- `roles/director.md` and `templates/DIRECTOR-{REQUEST,REPORT}.md` cover
  ticket-cycle reconciliation only. The director never chooses tickets or
  launches duplicate engineer rows.
- `roles/eval-worker.md`, `roles/eval-manager.md`, and
  `roles/eval-designer.md` pair with their assignment/report templates. Workers
  produce isolated artifacts, managers interpret evidence and may stage
  handbook/ticket candidates, and designers propose at most one eval package.
- `roles/pi-session-briefing.md` is shared session guidance. The handbook and
  north-star reads are proved from raw sessions by controller-side path checks.
- `templates/` contains human-authored prompts, assignments, lifecycle
  requests, report skeletons, postmortems, tickets, and CTO handoffs. Generated
  Markdown must not be embedded in controller source.

### Eval package and evidence flow

- Each approved `evals/task-*/EVAL.md` owns its task contract, restrictions,
  oracle, evaluator, metrics, and manager policy. `executor.xsh` is package
  selection/scaffolding; `evaluator.xsh` is the package-owned correctness and
  restriction boundary. `evaluate_common.xsh` is shared mechanics only and
  must not accumulate task-specific dispatch logic.
- `eval-executor.xsh` is controller infrastructure, not a Pi role. It launches
  the isolated worker, runs the selected package evaluator, and preserves
  compressed `session.jsonl.bz2`, worker `report.json`, evaluator `run.json`, and artifacts.
- The evidence hierarchy is compressed raw `session.jsonl.bz2` -> normalized worker
  `report.json` -> phase `report.json` -> run `report.json`, with employee
  `REPORT.md` and `CTO-REPORT.md` as qualitative/navigation layers.
  `events.jsonl` is the canonical lifecycle/process-output ledger.

### Engineer provenance path

`run-ticket.xsh` first verifies `report.json`, required reads, expected branch,
new `HEAD`, and an empty product worktree. It captures the portable patch and
its SHA-256, then calls `factory_runtime.amend_engineer_commit`. That helper
reads the normalized worker report, hashes the report and raw session archive,
receives the assignment and patch hashes, invokes Git's
`commit --amend --no-edit --trailer` once, and independently verifies the
expected trailers by reading them back from Git. The controller updates the
controller-owned engineer report, emits a provenance event containing the
amended commit and all input hashes, and only then permits cleanup/replay.
`Factory-Source-Commit` preserves the pre-amend hash; the final report and
patch use the amended hash. Synthetic missing-evidence, dirty-worktree,
trailer-verification, idempotency, patch-hash, and cleanup cases live in
`tests/tools_test.xsh`.

### Native test map

- `tests/factory_control_test.xsh` covers pure policy, request parsing,
  admission, lifecycle, ticket inventory, handbook gates, and role ceilings.
- `tests/tools_test.xsh` covers report normalization, tool-error retention,
  process/event behavior, budget and cleanup consequences, worktree/patch
  boundaries, organization reuse, eval promotion, and engineer provenance
  amendment.
- The nearest hard judge for factory changes is
  `XSH_MODULE_PATH=. xsht test`. Use synthetic sessions, Git repositories, and
  harmless process doubles; deterministic infrastructure must not consume Pi
  budget.

## Current CTO hardening priorities

Before the next paid cycle, verify the factory's root/phase path boundary,
keep the checked-in eval portfolio at or below the coded cap of 30, inspect
stale `factory/*` branches through `run-cto.xsh`, and preserve the outcome
split in reports: product, evaluator, infrastructure, and overall cycle.
