# Factory refactor migration report

This report records the deterministic contract layer introduced by
`FACTORY-REFACTOR.md`. The operator entry point remains `run.xsh`; no paid
cycle was run during the migration.

## Canonical ownership

The `factory/` namespace now owns the durable control-plane implementation:

| Concern | Canonical module |
| --- | --- |
| IDs, status values, modes, budgets, ownership records | `factory/types.xsh` |
| Repository and run path boundaries | `factory/paths.xsh` |
| Markdown request parsing | `factory/request.xsh` |
| Admission limits and gates | `factory/policy.xsh` |
| Graph nodes, edges, readiness, root result | `factory/graph.xsh` |
| Dispatch identity, manifests, claims | `factory/dispatch.xsh` |
| Process ownership | `factory/process.xsh` |
| Lifecycle and event validation | `factory/lifecycle.xsh` |
| Evidence references and hashes | `factory/evidence.xsh` |
| Report construction and exact-node audit | `factory/reports.xsh` |
| Ticket and eval admission | `factory/tickets.xsh`, `factory/evals.xsh` |
| Run-scoped cleanup | `factory/cleanup.xsh` |
| Shared control settings and templates | `factory/control.xsh` |
| Shared effects, reconciliation, and provenance | `factory/runtime.xsh` |
| Common report envelope | `factory/schema.xsh` |
| Evaluator ownership | Every `evals/task-*/evaluate.xsh` invokes its sibling `evaluator.xsh` directly |
| Session normalization and process watchers | `factory/tools/session.xsh`, `factory/tools/session-watch.xsh`, `factory/tools/budget-watch.xsh`, `factory/tools/cycle-budget-watch.xsh` |
| Cleanup, CTO reporting, and eval trends | `factory/tools/cleanup-run.xsh`, `factory/tools/clean-factory.xsh`, `factory/tools/cto-report.xsh`, `factory/tools/eval-trends.xsh` |

Mode-specific execution is in `factory/controllers/`. The host runner and
eval executor are in `factory/entrypoints/`; audit, CTO, reconciliation, and
human report tools are in `factory/tools/`.

The only root script is the canonical `run.xsh` admission launcher. All other
controllers, process boundaries, reporting commands, and maintenance tools
are invoked from their explicit `factory/` paths. The old top-level launcher
and evaluator compatibility layers were removed rather than retained as
delegates.

## Review questions

- The complete graph is constructed by the mode-specific `build` function in
  `factory/controllers/`, then validated by `factory.graph.validate` before a
  child can be admitted.
- A worker is authorized by `factory.dispatch.invocation_authorized`; the
  host runner also enforces the same persisted identity in `factory/entrypoints/run-agent.xsh`.
- A report belongs to its worker only when
  `factory.evidence.report_identity_ok` matches run, node, role, worker, and
  dispatch identity.
- A path belongs to its assigned repository and run when
  `factory.paths.within` succeeds after `canonical_absolute` rejects relative
  and traversal paths. Effectful cleanup is additionally restricted to the run
  root.
- An extra worker is rejected by `factory.reports.audit_plan`.
- Duplicate callbacks and impossible event histories are rejected by
  `factory.lifecycle.validate_events`; duplicate process and dispatch claims
  are rejected by `factory.process.register` and
  `factory.dispatch.claim_once`.
- New paid work stops when `factory.tools.budget.stops_new_work` sees unknown
  or breached cost; the existing aggregate watcher remains the process-level
  shutdown authority.
- A factory change cannot reach an engineer because
  `factory.policy.admit` and `factory.dispatch.validate_spec` require the
  product change target for engineer rows.
- No role can request a new node: graph membership is the controller-created
  plan, and narrative text is not an input to graph construction.

## Validation

The native suite covers the new contracts without Pi:

- `tests/factory_types_test.xsh`: identifiers, paths, requests, admission;
- `tests/factory_graph_test.xsh`: graph cycles, duplicate identities, exact
  dispatch binding, prompt/message changes, and claims;
- `tests/factory_lifecycle_test.xsh`: transitions, event ledgers, process
  ownership, and evidence-preserving cleanup;
- `tests/factory_evidence_test.xsh`: required/cross-run evidence, forged
  reports, mode contracts, missing nodes, and extra workers.

The current full result is 78 passing native tests. The product checkout is
not modified by this migration; pre-existing product work remains untouched.

## Compatibility boundary

No shared implementation remains at the repository root. Historical operator
paths are preserved only where they are part of the documented entrypoint
surface; each retained root script is a small delegate and contains no policy,
dispatch, lifecycle, report, or evaluator implementation. Package-owned eval
contracts remain under `evals/<id>/`; their container-facing paths
Package evaluators are mounted directly at `/run/evaluator.xsh`; no shared
task dispatcher or fallback evaluator is included in the image.
