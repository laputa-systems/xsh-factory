# Factory refactor migration report

This report records the deterministic contract layer introduced by
`FACTORY-REFACTOR.md`. The operator entry point remains `run.xsh`; no paid
cycle was run during the migration.

## Canonical ownership

The new `factory/` namespace owns the durable control-plane contracts:

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

Mode-specific plan construction is in `factory/controllers/`. The operator,
host-agent, and eval-executor contracts are in `factory/entrypoints/`; the
existing root launchers remain the stable process entry points.

## Review questions

- The complete graph is constructed by the mode-specific `build` function in
  `factory/controllers/`, then validated by `factory.graph.validate` before a
  child can be admitted.
- A worker is authorized by `factory.dispatch.invocation_authorized`; the
  host runner also enforces the same persisted identity in `run-agent.xsh`.
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

The current full result is 77 passing native tests. The product checkout is
not modified by this migration; pre-existing product work remains untouched.

## Intentional compatibility boundary

The root files `factory_control.xsh`, `factory_runtime.xsh`, `report_schema.xsh`,
the mode controllers, and `audit-run.xsh` retain their operator-visible paths
while callers migrate. `factory_runtime.write_bound_dispatch_record` and the
runner checks are the first live bridge to the new dispatch contract. The
remaining legacy implementation bodies are owned by the corresponding
canonical module migration and are covered by the existing `tests/` contracts;
they must not gain new policy or evidence projections. The inventory and this
report make that boundary searchable until the final wrapper-only migration.
