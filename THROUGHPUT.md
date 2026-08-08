# Factory throughput contract

This document is the CTO operating contract for predictable product delivery.
It describes the machinery that turns an approved product observation into a
reviewable engineer commit on XSH `HEAD`, the work that may run beside that
transaction, and the evidence required before throughput is called sustained.

The factory exists to improve XSH, not to maximize agent activity. A passing
eval without a product change is useful evidence, but it is not product
throughput when an approved implementation ticket is ready. Conversely, a
cheap product merge that bypasses its linked replay is not throughput; it is an
untrusted mutation. The contract below keeps those two truths together.

## The operating target

An **eligible delivery cycle** has at least one approved, product-targeted,
branchless ticket whose linked eval is approved and whose CTO review is
recorded. The controller must then reserve one fresh delivery slot and dispatch
one fresh engineer row.

The target for every eligible cycle is:

```text
fresh engineer row >= 1
fresh engineer commit delivered to XSH HEAD >= 1
linked replay correctness = pass
linked replay restrictions = pass
linked replay protocol = pass
linked replay manager decision = accept
provenance and cleanup = pass
```

The target is measured from existing `report.json` and `events.jsonl` data.
There is deliberately no `throughput.json` projection. The run report remains
the one machine report envelope; the productivity and CTO Markdown reports are
navigation views over that evidence.

Three consecutive eligible cycles satisfying the target, with no hand-edited
reports or CTO bypass, establish sustained throughput. One successful cycle is
only a smoke test. A cycle with no approved branchless ticket is not a failed
delivery cycle, but it must be admitted as an eval/discovery cycle before paid
work and must not claim an engineer-throughput result.

The controller cannot manufacture an approved ticket from an empty queue. CTO
inventory should therefore keep two or three evidence-backed product tickets
approved and branchless. The queue is a supply buffer, not permission for
workers to discover or promote work.

## The delivery transaction

The product-critical path is intentionally narrow:

```text
CTO inventory
  -> reserve one fresh approved ticket
  -> fresh engineer in an isolated XSH worktree
  -> report, branch, clean-worktree, patch, and provenance checks
  -> linked replay of the exact candidate behavior
  -> correctness/restriction/protocol/manager gates
  -> validated merge into XSH HEAD
  -> ticket reconciliation and durable delivery event
```

The owners are explicit:

- `factory/tools/cto.xsh` and `factory/runtime.xsh` own deterministic ticket
  inventory, readiness, ordering, and reservation facts.
- `factory/controllers/organization.xsh` owns lane admission, process handles,
  waits, phase boundaries, and the fresh-before-retained merge order.
- `factory/controllers/ticket.xsh` owns the engineer worktree, immutable
  assignment, report/branch/patch/provenance checks, and commit amendment.
- `factory/controllers/eval.xsh` owns linked replay admission and evaluator
  execution. It does not let a manager override a failed package gate.
- `factory/runtime.xsh::merge_validated_ticket` owns the final product-side
  fast-forward or merge decision.
- `factory/tools/audit.xsh` projects admission, delivery, replay, and lane
  metrics into the existing run report.

Fresh delivery is reserved before optional work is admitted. Selection is
deterministic by ticket path, with fresh branchless tickets before retained
branches. An organization batch may contain one fresh ticket and at most one
retained ticket. It must never contain two fresh engineers merely because the
queue is large: the goal is a predictable delivered commit, not a larger
unfinished batch.

When a fresh ticket exists, retained work is secondary. A retained replay may
run for evidence, but its timeout, stale-base merge conflict, or report
deferral cannot delay or relabel a passing fresh delivery. If no fresh ticket
exists, one retained branch may be replayed; that is useful reconciliation but
does not satisfy the fresh-engineer target.

## Queue-pressure allocation

Queue pressure is calculated from deterministic CTO inventory. `Open.` tickets
are pressure evidence only; they are never promoted by a controller. The
dispatchable queue is approved product tickets, split into branchless fresh
rows and retained implementation branches.

The policy is:

| Ready product state | Fresh engineers | Retained rows | Independent discovery evals |
| --- | ---: | ---: | ---: |
| One or more branchless approved tickets | exactly 1 | at most 1 | 0 by default |
| No branchless ticket, one retained branch | 0 | at most 1 | up to the no-ticket bound |
| No approved implementation row | 0 | 0 | 1–4, according to Open-ticket pressure and the eval cap |

The independent lane is optional evidence. It is allocated only when the
fresh delivery slot is not available, unless a request explicitly opts into a
single corroborating eval and the controller proves that the eval cannot block
the delivery transaction. The default product cycle therefore spends its
paid capacity on the fresh engineer and linked replay rather than forcing an
unrelated manager review into the critical path.

The existing coded bounds remain hard:

- at most two rows in a ticket-implementation request;
- one fresh row plus at most one retained row in an organization batch;
- one linked replay for every passing engineer row;
- no more than four independent discovery evals in a ticketless organization
  cycle;
- no more than 30 checked-in eval packages; and
- the aggregate cycle budget remains the top-level shutdown boundary.

If admission finds no fresh row, it records that fact in the queue event and
the run report before paid work. If it finds a fresh row, an eval-only primary
phase is an admission error, not an alternative success mode.

## Lane isolation and outcome semantics

`factory/controllers/organization.xsh` treats the organization as four lanes:

1. **Fresh implementation:** mandatory whenever a ready row exists.
2. **Fresh linked replay:** mandatory hard gate for that implementation.
3. **Retained replay:** bounded, best-effort evidence for an existing branch.
4. **Independent eval:** optional discovery or corroboration.

The fresh implementation and its linked replay are the only lanes that can
produce fresh product delivery. Independent and retained results remain
visible in `report.json`, but their outcomes are separate from product
outcome. The report must preserve the split:

```text
product        = fresh implementation/replay/merge result
evaluator      = independent eval and design result
infrastructure = reports, budgets, paths, lifecycle, provenance, cleanup
cycle          = product AND evaluator AND infrastructure
```

This split is important. A retained timeout must not convert a passing fresh
delivery into an infrastructure failure. A fresh linked replay failure must
remain a product-quality failure even when an independent eval passes. A
manager provider stall must be recorded as bounded closeout evidence, not
silently counted as agent judgment.

The run report should expose at least these throughput facts in its existing
`data.throughput` object:

- admitted ticket identities;
- fresh engineer target and fresh rows actually dispatched;
- retained rows and retained fast paths;
- linked replays dispatched and passed;
- fresh deliveries and total deliveries;
- delivery conversion;
- whether the fresh delivery target was met;
- retained deferrals; and
- handbook quarantines.

Admission events must be written before worker dispatch, so a worker failure is
not incorrectly reported as if no ticket had been admitted. Delivery events
must identify whether the delivered row was fresh or retained. Reconciliation
must remain idempotent after interruption.

## Manager closeout contract

The eval-manager is a bounded interpreter of a controller-prepared evidence
packet, not an open-ended investigator. The packet is the phase `report.json`,
the evaluator's exact `run.json`, the artifact and review paths named by that
manifest, the immutable assignment, and the staged report skeleton.

The manager must:

- use only the assigned `read`, `write`, and `edit` tools;
- read the exact handbook lineage path first;
- after the required structured reads, make the next tool call a `write` or
  `edit` of the staged report;
- replace every `not-ready` and `Fill from`/`Fill every` placeholder in that
  first draft, even when a field is unavailable (use `unknown` or `None.`);
- inspect the exact manifest paths and never guess an `artifacts/` directory;
- account for every structured worker and manager tool error;
- consult raw session JSONL only for a named structured discrepancy;
- write the staged report before optional investigation; and
- finish with one exact machine-readable decision line in the existing report:
  `Candidate acceptance: pass.` or `Candidate acceptance: fail.`

The report-first order is a throughput control, not a qualitative shortcut.
The structured phase report already contains turns, tokens, dollars, tool
errors, worker identities, trial results, handbook lineage, and required
output status. The manager's first draft must classify those facts before it
spends time reading large raw sessions. A manager may refine the draft once,
or perform one targeted reproduction for a named contradiction, but it may
not postpone the report until after an open-ended transcript review. This
prevents the report itself from becoming the bottleneck that blocks a passing
engineer candidate.

The controller owns the semantic gates. The manager may explain evidence, but
cannot override evaluator correctness, restriction, or protocol failure. A
missing or contradictory acceptance line fails closed. Fuzzy synonyms such as
“accepted for merge” are narrative evidence only and cannot advance delivery.

Manager timing is bounded in two ways:

- normal eval-manager closeout: 300 seconds and the coded turn ceiling;
- one report-recovery attempt: 180 seconds, using the same evidence packet.

The session watcher also applies a 120-second inactivity bound to the
eval-manager. This is shorter than the normal 300-second wall bound and the
180-second recovery bound, while allowing one provider turn to spend a minute
reading the controller-prepared packet without being mistaken for a stall.
Inactivity is measured from the controller session file's last modification,
not from a guessed provider state. A timeout terminates the manager, preserves
its report/session attempt, and emits a structured reason. There is never a
second unrestricted full wall-clock window.

For a fresh linked replay, an exhausted manager recovery means the candidate is
retained and delivery is rejected. For retained or independent work, the same
condition emits explicit deferred evidence and cannot block a fresh delivery.

## Replay quality contract

Every product ticket names the defining behavior that distinguishes its fix
from a plausible workaround. The linked package-owned evaluator must contain
at least one discriminating case for that behavior, plus its restriction and
protocol checks. Passing ordinary cases is insufficient when the changed
surface was not exercised.

The replay owns externally observable behavior and the restriction/protocol
boundary. The engineer phase owns native compiler, checker, unit, and API tests.
The manager must not demand that the sandbox redundantly rerun primary-phase
tests, but it must verify that the primary evidence exists and that the replay
tests the distinct behavior that would fail without the fix.

The evaluator's machine results remain authoritative:

```text
correctness = pass/fail
restrictions = pass/fail
protocol = pass/fail
manager acceptance = pass/fail
```

The product controller delivers only when all four are passing and the
provenance/patch/clean-worktree checks independently pass.

## Failure matrix

| Failure | Fresh lane | Retained lane | Independent lane |
| --- | --- | --- | --- |
| No approved branchless ticket | no delivery expectation; preflight records eval mode | may replay one branch | may run discovery |
| Engineer report/branch/patch failure | retain branch; no delivery | not applicable | unaffected |
| Linked correctness/restriction/protocol failure | retain candidate; no delivery | retain branch; defer if applicable | unaffected |
| Fresh manager timeout after retry | retain candidate; no delivery | not applicable | not applicable |
| Retained timeout or stale merge | fresh delivery remains valid | emit retained-deferred evidence | unaffected |
| Independent eval failure | fresh delivery remains independently classified | unaffected | evaluator outcome fails |
| Budget breach or source mutation | stop the owning cycle, preserve evidence, write postmortem | same | same |

No failure class is repaired by relaunching the same paid request. Deterministic
machinery failures get a native regression test and a later explicit request.

When the manager process returns a valid machine `report.json` but leaves the
qualitative `REPORT.md` at `not-ready`, the outcome is an infrastructure
failure, not a delivery. The controller must preserve both attempts, emit the
retry lifecycle events, and withhold the candidate. The CTO then tightens the
report-first handoff and tests the prompt contract before another paid cycle.
The controller must never infer acceptance from a manager's final prose,
session thoughts, evaluator pass, or a partially written report.

## Native validation matrix

The machinery is validated without Pi using `xsht` tests, synthetic sessions,
fake child controllers, and harmless process doubles. The required cases are:

1. one ready ticket reserves one fresh row;
2. a second fresh ticket cannot displace the reserved first row;
3. one retained row may accompany the fresh row but cannot replace it;
4. a ticket cycle may omit the independent eval lane;
5. a ticketless cycle still receives the adaptive discovery target;
6. admission events count a ticket before worker dispatch;
7. fresh and retained delivery events are counted separately;
8. independent failure does not block a passing fresh delivery;
9. retained timeout emits a nonblocking deferral;
10. fresh replay timeout preserves the branch and blocks delivery;
11. the manager retry reuses the exact evidence packet;
12. no manager attempt exceeds its normal or recovery wall bound;
13. inactivity is detected independently of total wall time;
14. exact acceptance lines pass and vague acceptance language fails;
15. evaluator gates cannot be overridden by manager prose;
16. controller interruption/reconciliation is idempotent; and
17. product, evaluator, infrastructure, and overall outcomes remain distinct.

The nearest hard judge is:

```sh
xsht test
```

Before paid qualification, also run deterministic preflight and inspect
`factory/tools/cto.xsh` output for unresolved handbook candidates, stale
factory branches, the eval cap, root/phase path boundaries, and a clean product
checkout.

## Executed implementation ledger

The implementation tranche was committed as `06418ac`, with subsequent
bounded repairs and evidence closeouts kept separate. The machinery now
includes adaptive queue pressure, one-fresh-plus-one-retained selection,
independent-eval suppression under ticket pressure, split product/evaluator/
infrastructure outcomes, provenance-aware delivery accounting, manager retry
bounds, and epoch-correct inactivity detection. It has been exercised by the
141-test native suite.

The paid validation sequence exposed and repaired real boundary failures:

| Run | Admission | Evaluator | Manager/delivery result | CTO disposition |
| --- | --- | --- | --- | --- |
| `run-1786225102047` | retained `task-histogram-005`; independent lane was accidentally admitted | preflight failed on the base image | no worker and no delivery | fixed organization independent-lane gate; built a local qualified image |
| `run-1786225653459` | retained `task-histogram-005`; no independent eval | correctness/protocol pass, restriction fail | manager report incomplete after an epoch-unit bug | fixed session mtime conversion; deferred ticket 005 to `Open.` |
| `run-1786226438672` | retained `task-histogram-006`; no independent eval | correctness/restriction/protocol pass | manager timed out at 60 seconds and retry at 180; no delivery | widened manager inactivity to 120 seconds |
| `run-1786227317528` | retained `task-histogram-006`; no independent eval | correctness/restriction/protocol pass | active manager review survived the old idle bound, but both narrative reports remained `not-ready`; no delivery | tightened report-first manager and retry instructions; validation pending |

Run 4 is an important negative result. It proves that the 120-second idle
repair fixed a false-positive inactivity diagnosis, but it did not yet prove
delivery throughput. The evaluator cost was `$0.052622`, with 3 workers and 62
assistant turns; the root report separated product pass, evaluator pass, and
infrastructure fail. No engineer commit may be counted for this run.

Run 5 (`run-1786228730949`) validated the next repair. The manager completed a
contract-complete report in one attempt, without `81-manager-retry-started`,
and emitted the exact `Candidate acceptance: fail.` decision. The evaluator
passed all nine histogram cases plus restrictions and protocol. Delivery was
still withheld correctly because the worker used the known-good `where` stage
and never exercised `task-histogram-006`'s defining `filter` diagnostic. The
run cost `$0.055660`, used 2 workers and 46 assistant turns, and produced zero
fresh or retained deliveries. This is a factory-robustness success and a
product-throughput non-delivery, not a false positive.

The manager boundary therefore has two separate validated controls:

1. the 120-second inactivity threshold prevents active evidence review from
   being mistaken for a stall; and
2. report-first closeout prevents a complete evaluator from being blocked by
   a missing qualitative report, while the explicit acceptance gate still
   prevents unexercised product changes from merging.

The next quality action is not another blind replay of `task-histogram-006`.
Its ticket is returned to `Open.` with its branch preserved. A directed
package-owned replay must compile `filter { |x| ... }`, assert a readable
stage-level error naming `filter` and recommending `where`, and then rerun the
nine histogram cases. Adaptive selection may proceed to the next retained
Approved branch while that evidence is prepared.

The current queue contains one deferred Open ticket (`task-histogram-005`) and
two retained Approved branches (`task-histogram-006` and
`task-histogram-007`). After Run 5, `task-histogram-006` is Open pending its
directed diagnostic replay, leaving `task-histogram-007` as the remaining
retained Approved branch. Because there is no branchless Approved ticket, the
three-cycle fresh-delivery qualification has not honestly started. Retained
replays may drain pending engineer work, but their commits do not satisfy the
fresh target. CTO inventory must obtain a new branchless Approved ticket before
claiming the first eligible qualification cycle.

## Qualification and closeout

After the implementation tranche is committed, qualification consists of
three consecutive eligible organization cycles. Each cycle is closed with its
durable run evidence, productivity report, and CTO report. The qualification
ledger is:

```text
cycle N:   fresh row 1, fresh delivery 1, linked replay pass
cycle N+1: fresh row 1, fresh delivery 1, linked replay pass
cycle N+2: fresh row 1, fresh delivery 1, linked replay pass
```

Independent evals may be absent from these cycles when the approved queue is
under pressure. That is expected: quality is preserved by the linked replay,
while discovery resumes when no delivery row is available.

Qualification fails if any cycle uses a retained commit to satisfy a fresh
target, if a non-product lane blocks delivery, if a manager consumes an
unbounded retry, or if a passing report is not accompanied by a reachable XSH
commit and provenance event. A failure preserves the branch and evidence and
identifies the exact lane for the next deterministic repair.

The CTO closes the implementation and each qualification run with one scoped
commit. Do not push to a remote, merge unrelated work, or delete evidence.
