# Factory refactor plan

## Purpose

This document is an implementation plan for a coding agent. It is not an
implementation request. The agent must follow the phases in order, keep each
phase reviewable, and run the native suite after every phase.

The goal is to make the factory a deterministic control plane in which:

- controllers choose every role, worker, input, process boundary, and state
  transition;
- agents receive one immutable assignment and never discover or select work;
- invalid repository boundaries, paths, identities, reports, budgets, and
  workflow transitions fail closed;
- durable evidence proves what the controller admitted and what actually ran;
- the core XSH machinery has one coherent module namespace and stronger types;
- the workflow graph is explicit, typed, auditable, and testable without Pi.

Do not solve ambiguity by adding prompt prose. If a rule matters to safety,
make it a typed value, a controller check, a persisted manifest, or a native
test.

## Operating constraints

1. Read `NORTH-STAR.md`, `FACTORY.md`, `README.md`, `docs/FACTORY-LOOPS.md`,
   and `CTO.md` before editing.
2. Read `AGENTS.md` and inspect both repository statuses before each phase.
3. Use XSH only for factory orchestration and tools. Do not add Python or a new
   orchestration language.
4. Never launch Pi directly. All host-side Pi sessions must pass through the
   controller-owned runner.
5. Do not run paid cycles during this refactor. Use synthetic sessions, fake
   commands, temporary Git repositories, and harmless process doubles.
6. Do not rewrite or delete historical run evidence. Do not reset unrelated
   user work. Do not push to a remote.
7. Do not move files until their imports, module search paths, tests, and
   operator documentation have an explicit migration step.
8. Keep only the required top-level launcher stable. `run.xsh` remains the
   only operator entry point.
9. Do not use compatibility projections as a substitute for a stronger
   contract. Preserve raw evidence, then remove duplicate machine state.
10. Do not commit until the complete refactor passes the native suite and the
    staged migration checks.

## Current architecture and confirmed concerns

The factory has useful pieces, but policy, effects, dispatch, and workflow
state are spread across many top-level files:

- policy and parsing: `factory/control.xsh`;
- effects and reconciliation: `factory/runtime.xsh`;
- report envelope: `factory/schema.xsh`;
- phase controllers: `factory/controllers/ticket.xsh`, `factory/controllers/eval.xsh`, `factory/controllers/design.xsh`,
  `factory/controllers/organization.xsh`, and `factory/controllers/reuse.xsh`;
- top-level admission: `run.xsh`;
- process boundary: `factory/entrypoints/run-agent.xsh`;
- audit and reporting: `factory/tools/audit.xsh`, `factory/tools/report.xsh`, and
  `factory/tools/cto-report.xsh`;
- evaluator boundary: `factory/entrypoints/eval-executor.xsh`, `package-owned evaluator.xsh`, and
  `evals/eval-worker.xsh`.

The recent ticket-ownership and dispatch-manifest fixes address two concrete
failures, but the audit must not assume that the surrounding machinery is now
complete. The following risks are the starting hypotheses to verify.

### P0: dispatch authority and exact graph membership

1. `factory/entrypoints/run-agent.xsh` now checks a dispatch manifest, but the manifest is a
   mutable JSON file without a cryptographic controller/run authority. A caller
   that can write the run directory can manufacture a matching manifest.
2. The runner validates several fields, but the system prompt path and system
   prompt hash are not part of the dispatch identity. The role prompt can be
   swapped while the message remains unchanged.
3. Audit code discovers worker reports, sessions, and manifests from the run
   directory. It does not yet prove that every observed worker was an admitted
   graph node, that every admitted node ran exactly once, or that no required
   node is missing.
4. Worker report identity is not uniformly cross-checked against the dispatch
   manifest. A validly shaped report is not automatically evidence that the
   assigned role and worker produced it.
5. Several controllers construct dispatches independently. There is no single
   typed dispatch-plan validator shared by ticket, eval, design, and
   organization modes.

**Required outcome:** an agent cannot become a worker by choosing a role,
worker ID, ticket, eval, message, prompt, or worktree. The controller must
create a typed dispatch plan, persist it before launch, and the runner must
verify it against the invocation and the run's controller identity.

### P0: repository and path authority

1. Product worktrees belong to `../xsh`; factory code, tickets, eval packages,
   templates, reports, and run evidence belong to the factory checkout. The
   recent factory-ticket incident proves that this boundary must be a machine
   invariant, not only documentation.
2. Path handling is distributed across environment variables, `Path(...)`,
   string interpolation, and controller-specific checks. The audit must find
   every path that can cross the factory root, run root, phase root, product
   root, worktree root, and evaluator-container root.
3. `FACTORY_DIR`, `FACTORY_RUN_DIR`, `FACTORY_PHASE_DIR`, `FACTORY_WORKDIR`,
   message paths, report paths, and worktree paths need canonical-boundary
   checks. Relative paths, symlink escapes, and paths from an unrelated run
   must fail closed.
4. The runner accepts environment-derived paths and a configurable required
   report path. These values need ownership and containment checks before Pi
   starts.

**Required outcome:** every persisted or launched path is represented by a
validated typed path class or a checked boundary function. No worker can write
outside its assigned workspace, no phase can consume another run's evidence,
and no product worker can modify the factory checkout.

### P0: workflow lifecycle and cancellation

1. Lifecycle state is currently represented by strings and per-subject state
   files. The controllers manually emit transitions in several places.
2. The event ledger is append-oriented, but the audit must verify event
   uniqueness, monotonic attempts, subject identity, legal transitions, and
   terminal-state completeness.
3. Process registration is PID-file based. The audit must verify stale PID
   handling, PID reuse hazards, process ownership, nested controller cleanup,
   watcher cleanup, and signal behavior.
4. Normal completion and failure paths do not share one typed finalization
   routine. A controller can produce partial artifacts before later validation
   fails.
5. There is no single invariant that says which child phases may overlap, which
   phase must wait for which predecessor, and which phase is forbidden after a
   failure or budget breach.

**Required outcome:** one typed lifecycle machine and one typed workflow graph
own all state transitions, process ownership, cancellation, and terminal
finalization. The graph rejects impossible transitions before spawning a child.

### P1: report and evidence integrity

1. `factory/schema.xsh` validates a common envelope, but phase and run `data`
   fields are mostly unconstrained. A report can be structurally valid while
   omitting the facts needed for its mode.
2. `factory/tools/audit.xsh` contains mode-specific discovery and aggregation logic. The
   audit must compare expected outputs from the dispatch plan with observed
   reports, manifests, sessions, narratives, patches, and events.
3. Evaluator manifests, worker reports, phase reports, and root reports do not
   yet share one typed evidence-reference model. Paths and identity links can
   drift.
4. Human Markdown reports are checked by heading contracts, but their identity,
   assignment hash, and evidence references are not always machine-bound.
5. Unknown cost, budget failure, missing telemetry, and missing reports need
   distinct typed failure causes. They must not collapse into ordinary worker
   failure or pass through as absent fields.

**Required outcome:** every report references an admitted node and a run-scoped
evidence set. Auditing becomes a proof that expected evidence exists and is
consistent, not merely a directory scan.

### P1: admission and policy boundaries

1. Markdown cycle requests remain a broad input surface. Parsing should produce
   one typed `CycleRequest`, then validate it against the selected mode's
   policy before any run directory or paid child is created.
2. Ticket, eval, and handbook status values are strings spread through policy
   and runtime code. Invalid combinations such as a factory target marked for
   engineer work, a disabled eval selected for paid work, or an undispositioned
   handbook candidate must be represented as explicit admission failures.
3. The organization controller has several branches for explicit tickets,
   auto-selected tickets, reused branches, independent evals, and design.
   These branches need one admission result rather than repeated local checks.
4. The 30-eval cap, two-engineer cap, role ceilings, aggregate budget, and
   trial count are policy values but are not all carried in one admission
   record.
5. The CTO owns factory changes. Factory findings must not become engineer
   tickets. The plan must preserve this distinction in the ticket schema and
   in the workflow admission types.

**Required outcome:** admission returns a typed immutable plan or a typed set of
blocking reasons. No controller may infer work from prose after admission.

### P1: duplicated orchestration and process boundaries

1. `factory/controllers/eval.xsh`, `factory/controllers/design.xsh`, and `factory/controllers/ticket.xsh` each construct role
   environments and launch paths with similar but non-identical logic.
2. `factory/controllers/organization.xsh` has its own child spawning, reuse handling, phase
   waits, and result calculation instead of composing one shared graph engine.
3. Report auditing, process registration, event emission, and cleanup are
   called in different orders across controllers.
4. `package-owned evaluator.xsh` and package evaluators have an ownership boundary that
   needs a single typed evaluator invocation contract.
5. Multiple top-level launch paths make it difficult to tell which path is
   canonical.

**Required outcome:** one process/dispatch API and one graph executor own shared
mechanics. Mode-specific modules provide only plan construction and
mode-specific validation.

### P2: operator and maintenance gaps to verify

The audit must explicitly check, rather than assume, the following:

- stale `factory/*` branches and branch ownership;
- worktree cleanup after dirty, missing, failed, interrupted, and reused runs;
- lock cleanup and stale active markers;
- duplicate event IDs and duplicate dispatch claims;
- signal handling during every child phase and nested Docker execution;
- budget watcher startup failure, watcher crash, unknown cost, and normal stop;
- Docker image identity, staged source hashes, evaluator module paths, and
  package-owned evaluator selection;
- eval count/cap behavior after failed design promotion and disabled evals;
- handbook candidate disposition and lineage hash checks;
- ticket merge reconciliation, stale branch references, and patch hashes;
- report generation after preflight failure, worker failure, evaluator failure,
  cancellation, and aggregate budget breach;
- whether ignored transient files can ever be mistaken for durable evidence;
- whether a second top-level run, direct child controller, or direct Pi launch
  can bypass the admission lock;
- whether environment variables can override controller-selected identity;
- whether system prompts, assignment files, evaluator scripts, and handbook
  snapshots are hashed and bound to the resulting report;
- whether a controller can accidentally dispatch extra workers because a
  worker or director requested them in narrative text.

## Target architecture

Create one consolidated `factory/` module namespace for core factory XSH code.
Keep only `run.xsh` at the repository root as the canonical operator launcher.
Do not move eval package-owned files into this namespace; package contracts
remain under `evals/<id>/`.

Proposed layout:

```text
factory/
├── types.xsh                 # domain types and identifiers
├── policy.xsh                # pure limits, status predicates, admission rules
├── request.xsh               # typed CycleRequest parsing and validation
├── paths.xsh                 # root, run, phase, worker, worktree boundaries
├── graph.xsh                 # typed nodes, edges, plans, lifecycle invariants
├── dispatch.xsh              # immutable dispatch manifests and claims
├── process.xsh               # owned process handles, PID/container registry
├── lifecycle.xsh             # transitions, events, terminal finalization
├── evidence.xsh              # report/session/manifest references and checks
├── tickets.xsh               # ticket ownership, status, merge reconciliation
├── evals.xsh                 # eval admission, image identity, package checks
├── reports.xsh               # report construction and mode-specific checks
├── cleanup.xsh               # run-scoped cleanup and stale-state handling
├── controllers/
│   ├── organization.xsh
│   ├── ticket.xsh
│   ├── eval.xsh
│   ├── design.xsh
│   └── reuse.xsh
├── tools/
│   ├── audit.xsh
│   ├── session.xsh
│   ├── budget.xsh
│   └── cleanup.xsh
└── entrypoints/
    ├── ../run.xsh (the only root operator launcher)
    ├── factory/entrypoints/run-agent.xsh
    └── factory/entrypoints/eval-executor.xsh
```

The exact filenames may change after the audit. The boundaries must not:

- `types`, `policy`, `request`, `paths`, and `graph` are pure where possible;
- `dispatch`, `process`, `lifecycle`, `evidence`, and `cleanup` own effects;
- controllers build typed plans and invoke shared executors;
- entry points parse arguments and delegate; they do not contain policy;
- tests import pure modules directly and use synthetic effects for the rest.

### Strong domain types

Replace unconstrained strings and open records at important boundaries with
small domain types. At minimum define:

```text
FactoryRoot
ProductRoot
RunRoot
PhaseRoot
WorkerRoot
ProductWorktree
FactoryPath
RunPath
PhasePath
WorkerPath
TicketId
EvalId
WorkerId
Role
CycleMode
ChangeTarget = Product | Factory
TicketStatus = Open | Approved | Accepted | Merged | Closed | TooDifficult
EvalStatus = Draft | Approved | Disabled
LifecycleState
NodeId
DispatchId
AssignmentHash
ContentHash
CommitHash
ProcessOwner
Budget
TrialCount
```

Requirements for these types:

1. Constructors validate format, normalization, and containment once.
2. A `FactoryPath` cannot be passed where a `ProductWorktree` is required.
3. A `FactoryTarget` cannot enter an engineer dispatch constructor.
4. A ticket cannot become dispatchable without `ChangeTarget.Product`, a valid
   linked eval, an accepted lifecycle status, and a passed API-surface gate.
5. A worker identity is `(run_id, phase_id, role, worker_id, dispatch_id)`, not
   merely a directory name.
6. Hashes are not interchangeable strings. Assignment, prompt, ticket,
   handbook, evaluator, patch, session, and image hashes need distinct labels
   or a tagged hash type.
7. Budgets carry dollars, role ceiling, aggregate ceiling, and observed-cost
   state. Unknown cost is not zero.
8. Process ownership records include run ID, node ID, PID/container ID,
   controller PID, start marker, and a claim token.

Use explicit `Result` errors for invalid construction. Do not preserve a string
fallback for values that cross a safety boundary.

## Workflow graph invariants

Build a typed graph rather than encoding the organization graph in nested
conditionals. Each `WorkflowPlan` must contain:

- one run identity and mode;
- an immutable set of `NodeSpec` entries;
- typed `Edge` entries with `requires`, `may_overlap`, and `failure_policy`;
- expected role, worker ID, input references, output references, and budget per
  node;
- admission evidence and source hashes;
- terminal result rules.

Required graph invariants:

1. Every node has one owner role, one deterministic ID, one assignment, one
   input set, one output set, one budget, and one lifecycle subject.
2. Every edge references existing nodes and declares whether it is a hard
   predecessor, an overlap-safe dependency, a replay dependency, or a cleanup
   dependency.
3. A node can start only after all hard predecessors reach the required state.
4. A node cannot start after a predecessor's failure unless its edge explicitly
   allows failure continuation.
5. A node cannot be started twice. A dispatch claim and lifecycle state make
   duplicate starts impossible.
6. Every admitted node must reach a terminal state: completed, failed,
   cancelled, budget-breached, or skipped-with-reason.
7. Every observed worker, process output, report, manifest, and session must
   map to exactly one node.
8. No worker may create a new graph node. Narrative recommendations are data,
   not dispatch requests.
9. Ticket implementation precedes its linked replay. Independent eval and
   eval-design may overlap only when their inputs are immutable and disjoint.
10. A reused branch is a replay node, never an engineer node.
11. A budget breach closes the graph according to one policy and prevents new
    paid nodes from starting.
12. Cancellation is a graph transition. Cleanup nodes run from run-scoped
    ownership records and do not depend on agents.
13. The root result is derived from node results and required-output checks; it
    is never inferred from a narrative report.
14. The graph validator must reject cycles, orphan nodes, duplicate node IDs,
    duplicate worker identities, missing terminal rules, and unbounded fan-out.

Implement graph validation as a pure testable function before migrating all
controllers to use it.

## Dispatch contract

Make the dispatch manifest authoritative and immutable for the entire run.
Extend the recent dispatch-manifest work as follows:

1. The controller creates a `DispatchPlan` before any child process starts.
2. The persisted manifest includes run ID, phase ID, node ID, dispatch ID,
   role, worker ID, mode, ticket/eval IDs, exact system prompt path and hash,
   exact message path and hash, work directory, factory/product roots,
   handbook/north-star paths and hashes, source commit, image ID where relevant,
   budget, max turns, max wall time, and parent controller identity.
3. The manifest is written atomically and marked `planned`, then claimed once
   by the runner with a claim token. A second claim fails.
4. The runner verifies the manifest against every invocation argument and
   environment field before starting Pi. It must not trust an agent-supplied
   replacement value.
5. The runner records `started_at`, PID, child PID, and final process state in
   the lifecycle ledger. The runner cannot change role or worker identity.
6. The runner hashes the prompt and message that it actually passes to Pi.
7. The controller passes a dispatch ID, not an ad hoc collection of loosely
   related environment variables.
8. Audit compares the planned dispatch set with the claimed, started,
   completed, reported, and terminated sets and reports every difference.
9. Direct invocation of `factory/entrypoints/run-agent.xsh` without a controller-owned active run,
   valid plan, and matching claim is rejected.
10. The dispatch manifest is evidence, not a generated Markdown projection. Its
    durable JSON form belongs under the run's allowed evidence tree.

Add hostile synthetic tests: altered prompt, altered message, wrong role,
wrong worker, wrong phase, wrong worktree, wrong ticket, wrong eval, stale run,
duplicate claim, missing predecessor, and forged manifest.

## Lifecycle and state model

Define one typed state machine for runs, phases, nodes, workers, processes, and
reports. Keep state transitions in `factory/lifecycle.xsh`; controllers call
it instead of writing state strings directly.

The state machine must define:

- allowed states and transitions;
- who may cause each transition;
- required evidence for each transition;
- idempotency behavior for repeated callbacks;
- terminal-state behavior;
- cancellation and budget-breach consequences;
- reconciliation behavior after process loss or controller restart.

Events must include a unique event ID, run ID, node ID, attempt, caused-by
identity, previous state, next state, timestamp, and content hash where
content is persisted. The ledger validator must detect duplicate IDs,
backwards transitions, orphan subjects, impossible attempts, and missing
terminal events.

Separate desired state, observed process state, and validated evidence state.
A process exit is not a successful phase. A report is not valid merely because
it exists. A phase is not complete until the graph's required evidence
predicate passes.

## Evidence and report model

Create typed evidence references:

```text
EvidenceRef = {
  run_id, node_id, kind, path, sha256, required, state
}
WorkerEvidence
EvaluatorEvidence
EngineerEvidence
PhaseEvidence
RunEvidence
```

Use one validator per node kind. It must verify:

- identity matches the dispatch manifest;
- path is inside the node's permitted root;
- content hash matches the recorded hash;
- required report schema and mode-specific fields are present;
- session archive exists or has a typed missing-evidence failure;
- evaluator manifest matches eval ID, trial ID, image ID, and source hashes;
- engineer patch matches base commit, branch, assignment hash, report hash,
  session hash, and final commit trailers;
- narrative reports reference the same node and do not substitute for machine
  evidence;
- all expected outputs are present and no unexpected worker node is accepted.

Extend `factory/schema.xsh` with typed mode contracts without creating
role-specific projections. Preserve metrics in the common envelope and raw
session. Have `audit.xsh` consume the graph and evidence model rather than
walking arbitrary directories and guessing identity from path substrings.

## Admission and policy model

Parse cycle requests into a typed `CycleRequest` with:

- mode;
- explicitly requested tickets;
- ticket selection policy;
- active eval IDs;
- trial count;
- design count;
- measured-reuse permission and rationale;
- role overrides;
- required outputs;
- aggregate budget request.

Then run one `admit(request, repository_state, portfolio_state)` function that
returns either:

```text
AdmissionPlan {
  run_identity,
  workflow_plan,
  dispatch_specs,
  source_hashes,
  budget_plan,
  required_outputs,
}
```

or a typed list of blocking reasons.

Admission must validate before creating paid children:

- clean product checkout;
- factory root and product root identity;
- ticket ownership and status;
- linked eval existence and status;
- eval cap;
- handbook lineage disposition;
- stale active markers and locks;
- branch/worktree state;
- exact role ceilings and aggregate budget;
- required request fields and no unknown mode-specific fields;
- no duplicate ticket, eval, worker, or node IDs;
- all factory changes routed to the CTO rather than an engineer.

Do not let a controller call `first_approved_tickets` and then separately
reconstruct policy. Selection and validation must produce one plan.

## Consolidation strategy

Use a staged migration. Do not move every file in one commit.

### Phase 0: freeze and inventory

- Record the current clean baseline commit.
- Build a machine-readable map of every top-level XSH file, imported module,
  process boundary, effect set, report writer, and test owner.
- Identify canonical versus compatibility files.
- List every environment variable and its producer/consumer.
- List every run output and its ignore/allowlist rule.
- Write audit findings as a checked-in appendix to this plan or a separate
  machine-readable inventory, not as assumptions in code.
- Establish a rule that no new top-level core factory module may be added.

Exit criteria: inventory is complete, imports are mapped, no paid cycle is
needed to validate the inventory, and `xsht test` passes.

### Phase 1: introduce types and pure policy

- Add `factory/types.xsh`, `factory/paths.xsh`, `factory/request.xsh`, and
  `factory/policy.xsh`.
- Move or wrap pure parsing and policy from `factory/control.xsh`.
- Make all callers import `factory.control` directly; no compatibility export
  layer is retained.
- Define typed change targets, statuses, IDs, roots, budgets, modes, and
  admission errors.
- Add pure tests for normalization, containment, request parsing, status
  combinations, and policy boundaries.

Exit criteria: no controller parses a status or request with a private helper;
all old and new tests pass; invalid values fail before effects.

### Phase 2: introduce graph and dispatch planning

- Add `factory/graph.xsh` and `factory/dispatch.xsh`.
- Define node specs, edges, dispatch specs, claim records, and plan validators.
- Replace ad hoc role/message/environment construction with dispatch specs.
- Bind system prompt hashes and complete input identities.
- Add forged, stale, duplicate, and missing-dispatch tests.
- Keep `factory/entrypoints/run-agent.xsh` as the canonical host process
  boundary.

Exit criteria: every controller can emit a complete plan before spawning;
`factory/entrypoints/run-agent.xsh` cannot start without a valid plan and claim; audit can compare
planned nodes with observed nodes.

### Phase 3: centralize lifecycle, process ownership, and cleanup

- Add `factory/lifecycle.xsh`, `factory/process.xsh`, and `factory/cleanup.xsh`.
- Move event emission, transition checks, process registration, watcher
  ownership, cancellation, lock handling, and run finalization behind shared
  APIs.
- Model PID/container ownership with run and node claim tokens.
- Add restart, stale-state, signal, duplicate-callback, budget, and cleanup
  tests.

Exit criteria: all controllers use one transition API and one process registry;
no controller writes lifecycle state directly; cleanup is run-scoped and
idempotent.

### Phase 4: centralize evidence and auditing

- Add `factory/evidence.xsh` and `factory/reports.xsh`.
- Move report discovery, identity binding, hashes, required-output predicates,
  and mode-specific audit checks out of directory scans.
- Make `factory/tools/audit.xsh` a thin entry point into the typed audit module.
- Validate dispatch-plan completeness, report identity, manifest identity,
  session identity, patch provenance, and terminal graph state.
- Add synthetic evidence matrices for pass, failure, partial, cancellation,
  unknown-cost, missing-report, extra-worker, and forged-report cases.

Exit criteria: audit rejects both missing expected nodes and unexpected nodes;
all durable evidence paths are typed and hash-checked.

### Phase 5: migrate controllers to graph execution

Migrate in this order:

1. `factory/controllers/eval.xsh`;
2. `factory/controllers/design.xsh`;
3. `factory/controllers/ticket.xsh`;
4. `factory/controllers/reuse.xsh`;
5. `factory/controllers/organization.xsh`;
6. `run.xsh` as the final admission wrapper.

For each controller:

- construct a typed plan;
- validate it before creating a child;
- persist dispatch specs;
- execute through shared process/lifecycle functions;
- wait according to graph edges;
- produce typed evidence;
- run the common audit;
- preserve the existing durable output contract;
- delete duplicated local helpers only after the migrated path passes tests.

Exit criteria: each controller has a small plan-construction layer and no
private role-selection, process-registration, lifecycle, or evidence logic.

### Phase 6: consolidate the namespace

- Move canonical core modules under `factory/`.
- Keep only the documented `run.xsh` operator launcher at the repository root.
- Update `XSH_MODULE_PATH` setup and all staged Docker module paths.
- Update source-hash/image identity calculations to hash canonical module paths.
- Update `AGENTS.md`, the factory codemap, README, tests, and operator docs.
- Remove obsolete top-level implementations only after a repository-wide import
  and path audit proves they are unreachable.

Exit criteria: one canonical implementation exists for every core concern;
no compatibility wrappers or duplicate root implementations remain; fresh and
cached Docker/eval builds resolve the same canonical modules.

### Phase 7: prove invariants and close the migration

- Run the full native suite.
- Run static searches for direct Pi launch, private role selection, direct
  lifecycle writes, untyped status comparisons, unvalidated path joins, and
  controller-local report aggregation.
- Run synthetic end-to-end graph fixtures for every mode without Pi.
- Run one deliberately aborted graph and one forged-dispatch fixture.
- Verify the product checkout remains clean and factory-only changes remain in
  the factory checkout.
- Delete every compatibility wrapper and remove its references from source,
  tests, and operator documentation.
- Record a migration report with old/new module hashes, test counts, and known
  limitations.

## Suggested type and module ownership table

| Concern | Canonical owner | Must not own |
| --- | --- | --- |
| IDs, statuses, roots, hashes, budgets | `factory/types.xsh` | process effects |
| Request parsing and admission policy | `factory/request.xsh`, `factory/policy.xsh` | Pi judgment |
| Path containment and canonicalization | `factory/paths.xsh` | string interpolation in controllers |
| Workflow nodes and edges | `factory/graph.xsh` | Markdown narratives |
| Dispatch manifests and claims | `factory/dispatch.xsh` | agent-selected work |
| PID/container ownership | `factory/process.xsh` | qualitative decisions |
| State transitions and event ledger | `factory/lifecycle.xsh` | direct controller writes |
| Evidence references and hashes | `factory/evidence.xsh` | path guessing from filenames |
| Ticket/eval reconciliation | `factory/tickets.xsh`, `factory/evals.xsh` | worker choice |
| Report construction and audit | `factory/reports.xsh` | separate role projections |
| Cleanup and finalization | `factory/cleanup.xsh` | global process discovery |
| Mode-specific graph construction | `factory/controllers/*.xsh` | duplicated shared mechanics |

## Acceptance test matrix

The coding agent must add deterministic native tests for each row before
marking this plan complete.

| Invariant | Required negative test |
| --- | --- |
| Product/factory boundary | factory target cannot enter engineer plan |
| Missing ownership | ticket without `Change target` is rejected |
| Exact role assignment | eval-worker cannot claim eval-manager node |
| Exact worker identity | worker ID from another node is rejected |
| Prompt binding | changed system prompt hash is rejected |
| Message binding | changed assignment message is rejected |
| Worktree boundary | product worker path outside assigned worktree is rejected |
| Factory boundary | product worker cannot target factory path |
| Run boundary | phase cannot consume another run's report |
| Plan completeness | missing expected node fails audit |
| Plan exclusivity | extra/unplanned worker fails audit |
| Graph ordering | replay cannot start before implementation terminal state |
| Graph overlap | dependent nodes cannot overlap unless explicitly allowed |
| Duplicate start | second claim of one node fails |
| State machine | illegal backward transition fails |
| Event ledger | duplicate event ID and impossible attempt fail audit |
| Cancellation | owned descendants terminate and partial evidence remains |
| Budget | unknown cost and aggregate breach stop new paid nodes |
| Evidence identity | wrong report, manifest, session, or patch hash fails |
| Ticket lifecycle | worker cannot change ticket status |
| CTO ownership | factory finding is reportable but not engineer-dispatchable |
| Eval ownership | package evaluator cannot delegate to a shared dispatcher |
| Cap enforcement | 31st eval cannot be admitted |
| Cleanup | stale markers and dirty worktrees do not delete unrelated state |

## Definition of done

The refactor is complete only when all of the following are true:

1. `run.xsh` remains the only top-level paid-cycle entry point.
2. No role can choose its ticket, eval, worker ID, prompt, worktree, or next
   phase.
3. Every child process has one typed graph node, one dispatch manifest, one
   claim, one lifecycle subject, and one evidence predicate.
4. Factory changes are CTO-owned and cannot enter an engineer plan.
5. Product changes enter only isolated product worktrees.
6. The audit rejects missing, extra, forged, stale, cross-run, and mismatched
   evidence.
7. Lifecycle transitions, cancellation, budgets, and cleanup use shared typed
   machinery.
8. Core factory XSH code has one canonical `factory/` namespace; only the
   required root `run.xsh` launcher remains outside it.
9. The native suite covers pure policy, graph validation, dispatch, paths,
   lifecycle, evidence, cleanup, budget, and failure behavior without Pi.
10. The migration preserves historical evidence and operator-visible durable
    outputs.
11. `xsht test` passes with no skipped invariant tests.
12. The final migration report identifies any remaining intentional escape
    hatch and names its owner, boundary, and test.

## Final review questions

Before closing the refactor, the coding agent must answer these questions in a
checked-in migration report:

- Which exact function constructs the complete workflow graph?
- Which exact function proves a worker is authorized to start?
- Which exact function proves a report belongs to that worker?
- Which exact function proves a path belongs to the assigned repository and
  run?
- Which exact function rejects an extra worker?
- Which exact function handles a controller restart or duplicate callback?
- Which exact function stops new paid work after a budget breach?
- Which exact function proves that a factory change cannot reach an engineer?
- Which exact module is canonical for each shared concern?
- Which compatibility wrappers remain, and why?

If any answer is “the prompt tells the agent,” the refactor is not complete.
