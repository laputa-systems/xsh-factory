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
recorded. The controller reserves exactly one delivery transaction and
dispatches one engineer row.

```text
engineer row >= 1
engineer commit delivered to XSH HEAD >= 1
linked replay correctness/restrictions/protocol = pass
linked replay manager decision = accept
provenance and cleanup = pass
```

Three consecutive eligible cycles satisfying the target establish sustained
throughput. A ticketless cycle is a discovery cycle, not an engineer-throughput
result. The controller cannot manufacture product supply: CTO inventory must
keep evidence-backed tickets approved and branchless. The operating north star
is not a one-time batch: delivery must consume and replenishment must restore a
two-ticket approved, branchless buffer over time.

## The delivery transaction and supply policy

```text
CTO inventory
  -> reserve one branchless approved ticket
  -> engineer in an isolated XSH worktree
  -> fresh debug xsht build and lint autofix; clean-worktree check
  -> report, branch, patch, and provenance checks
  -> linked replay of the exact candidate behavior
  -> correctness/restriction/protocol/manager gates
  -> validated merge into XSH HEAD
  -> ticket reconciliation and durable delivery event
```

`factory/tools/cto.xsh` and `factory/runtime.xsh` own deterministic inventory;
`factory/controllers/organization.xsh` owns the transaction;
`factory/controllers/ticket.xsh` owns engineer evidence and provenance;
`factory/controllers/eval.xsh` owns the linked replay; and
`factory/runtime.xsh::merge_validated_ticket` owns delivery.

An existing unmerged implementation branch is never a controller replay input.
Admission fails closed until the CTO reviews or supersedes it. This deliberately
removes a low-value branch-replay compatibility path: preserved branches remain
auditable historical evidence, not queued work.

Queue pressure has one purpose: maintain product delivery. Organization mode
has a two-ticket approved, branchless low-water mark. With no eligible ticket,
it runs exactly one approved eval selected by least-recently-tried worker
evidence. With one or two approved rows before admission, it reserves one
delivery transaction and runs exactly one isolated supply eval alongside it;
after consuming the admission, the remaining ready queue would otherwise fall
below two. With three or more approved rows, it runs only the delivery
transaction and its linked replay. This rotation prevents an alphabetical or
explicit-reuse escape from repeatedly spending on already-saturated evals.

The supply eval has no product-worktree access, cannot alter the candidate,
and cannot promote a ticket. Its ticket snapshot closes before the controller
performs the final merge, so a controller-owned `Merged.` transition cannot be
misclassified as manager tampering. A useful finding is still recorded as
`Open.` and requires normal CTO evidence review before becoming `Approved.`.
That preserves the delivery gate while making replenishment a bounded,
measurable control loop rather than an afterthought.

The existing hard bounds remain: direct ticket-implementation mode may admit
at most two rows; organization mode admits one row; every passing row receives
one linked replay; the eval portfolio is capped at 30; and the aggregate cycle
budget is the shutdown boundary.

The run report's `data.throughput` contains admitted tickets, whether the cycle
was eligible for delivery, engineer target and rows, linked replays dispatched
and passed, delivered tickets, delivery conversion, delivery-target status,
supply evals dispatched and passed, and handbook quarantines. A ticketless
cycle has `eligible_delivery_cycle: false` and `delivery_target_met: false`;
it cannot make a throughput miss appear successful. Admission events precede
worker dispatch and reconciliation remains idempotent.

## Outcome semantics

The delivery transaction is the product outcome. Ticketless discovery and the
isolated supply lane are evaluator outcomes. Reports preserve:

```text
product        = implementation/replay/merge result
evaluator      = independent eval and design result
infrastructure = reports, budgets, paths, lifecycle, provenance, cleanup
cycle          = product AND evaluator AND infrastructure
```

A linked replay failure is a product-quality failure. A manager provider stall
is bounded closeout evidence, not agent judgment. There is no secondary branch
lane whose result can dilute or substitute for the delivery target.

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
eval-manager when no provider completion is pending. This is shorter than the
normal 300-second wall bound and the 180-second recovery bound. Once the
controller session ends in completed tool results, Pi is waiting for the next
provider turn and the session file cannot advance; that state is governed by
the existing bounded wall limit rather than being misclassified as agent
inactivity. Inactivity is measured from the controller session file's last
modification, while the last session record distinguishes agent silence from a
pending provider completion. A timeout terminates the manager, preserves its
report/session attempt, and emits a structured reason. There is never a
second unrestricted full wall-clock window.

For a linked replay, an exhausted manager recovery preserves the candidate
branch and rejects delivery. A discovery-eval recovery failure is evaluator
evidence; it cannot be relabeled as product delivery.

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

| Failure | Delivery transaction | Discovery cycle |
| --- | --- | --- |
| No approved branchless ticket | no delivery expectation | run one least-recently-tried eval |
| Engineer report/branch/patch failure | preserve branch; no delivery | not applicable |
| Linked correctness/restriction/protocol or manager failure | preserve candidate; no delivery | not applicable |
| Isolated supply eval failure | delivery remains separately classified; buffer is not replenished | evaluator outcome fails |
| Budget breach or source mutation | stop the owning cycle, preserve evidence, write postmortem | same |

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

1. one ready ticket reserves one engineer row;
2. a second ticket cannot displace the reserved first row;
3. an unmerged branch fails admission rather than entering a replay lane;
4. a delivery cycle at or below the two-ticket low-water mark starts exactly one isolated supply eval, while a three-ticket buffer starts none;
5. a ticketless cycle selects one least-recently-tried approved eval;
6. admission events count a ticket before worker dispatch;
7. delivery events identify the ticket and exact merge;
8. linked replay timeout preserves the branch and blocks delivery;
9. the manager retry reuses the exact evidence packet;
10. no manager attempt exceeds its normal or recovery wall bound;
11. inactivity is detected independently of total wall time;
12. exact acceptance lines pass and vague acceptance language fails;
13. evaluator gates cannot be overridden by manager prose;
14. controller interruption/reconciliation is idempotent; and
15. product, evaluator, infrastructure, and overall outcomes remain distinct.

The nearest hard judge is:

```sh
xsht test
```

Before paid qualification, also run deterministic preflight and inspect
`factory/tools/cto.xsh` output for unresolved handbook candidates, stale
factory branches, the eval cap, root/phase path boundaries, and a clean product
checkout.

## Historical implementation ledger

The following is frozen historical evidence for the retired retained-replay
policy. It does not describe an active controller path.

The implementation tranche was committed as `06418ac`, with subsequent
bounded repairs and evidence closeouts kept separate. The historical machinery
included adaptive queue pressure, branch replay, split product/evaluator/
infrastructure outcomes, provenance-aware delivery accounting, manager retry
bounds, and epoch-correct inactivity detection. Later sections retain the
record without reviving that retired admission path.

The paid validation sequence exposed and repaired real boundary failures:

| Run | Admission | Evaluator | Manager/delivery result | CTO disposition |
| --- | --- | --- | --- | --- |
| `run-1786225102047` | retained `task-histogram-005`; independent lane was accidentally admitted | preflight failed on the base image | no worker and no delivery | fixed organization independent-lane gate; built a local qualified image |
| `run-1786225653459` | retained `task-histogram-005`; no independent eval | correctness/protocol pass, restriction fail | manager report incomplete after an epoch-unit bug | fixed session mtime conversion; deferred ticket 005 to `Open.` |
| `run-1786226438672` | retained `task-histogram-006`; no independent eval | correctness/restriction/protocol pass | manager timed out at 60 seconds and retry at 180; no delivery | widened manager inactivity to 120 seconds |
| `run-1786227317528` | retained `task-histogram-006`; no independent eval | correctness/restriction/protocol pass | active manager review survived the old idle bound, but both narrative reports remained `not-ready`; no delivery | tightened report-first manager and retry instructions; validation pending |
| `run-1786230433596` | ticketless; two Open tickets, zero Approved rows; two discovery evals | both phases failed before Pi at local XSH build | zero workers, zero turns, `$0.00`; explicit image tag had been overwritten by the failed prior Docker build | repaired/validated explicit qualified-image selection; created a fresh platform-matched image |
| `run-1786230602946` | ticketless; two Open tickets, zero Approved rows; `task-bigfiles` and `task-colsum` discovery overlap | both nine-case evals passed correctness/restrictions/protocol; both managers passed | four workers, 97 turns, `$0.052743888`; no delivery because no eligible ticket; one provider 503 retry succeeded | validated the image/build repair; cleared a non-semantic handbook snapshot with a native-tested narrow equivalence gate |
| `run-1786231856321` | ticketless; two Open tickets, zero Approved rows; same two discovery evals | both evaluator trials passed; `task-colsum` manager passed; `task-bigfiles` manager and bounded retry left `not-ready` | five workers, 94 turns, `$0.062499888`; no delivery; infrastructure/overall fail | removed the role/assignment evidence-order conflict; native tests protect the report-first contract; validation pending |
| `run-1786233883963` | ticketless; two Open tickets, zero Approved rows; `task-bigfiles` and `task-colsum` discovery overlap | both evaluator trials passed; `task-colsum` manager passed; both `task-bigfiles` manager attempts ended after their prescribed initial reads | five workers, 70 turns, `$0.04274082`; no delivery; infrastructure/overall fail | validated the report-first ordering; the watcher now distinguishes pending provider completion from agent inactivity; validation pending |

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
nine histogram cases. That directed replay was retired; any later concern must
be represented by a new current-HEAD ticket.

Run 7 (`run-1786229388916`) is the first post-hardening delivery result. The
queue selected retained `task-histogram-007`; its evaluator exercised the
unsupported `//` spelling and observed the new readable `/`-on-`Int`
diagnostic, then passed all ten cases, restrictions, and protocol. The manager
completed with an explicit acceptance, and the controller delivered the
amended commit `fdd33b69fb70b2e8ecb2038cd1ff5561f5c99cfc` to XSH `HEAD`
`aef5ddb3396ab78783dd76516d5fdcc25a17df29`. Cost was `$0.026925`, with 2
workers and 45 turns. It was historical replay evidence, not an
eligible-cycle delivery target because no branchless ticket was available.

Run 7 also provided the matched evidence for the concise integer-division
handbook lesson. The CTO promoted candidate
`63fc2207b9c8611ff1b0ee11adab47e37e989d3dc15f4b613e4c17f5e150c204` into the
approved handbook. Promotion is deliberately based on the product diagnostic
being exercised and the merged replay passing, not on a manager suggestion
alone.

Run 8 (`run-1786230105277`) exercised the ticketless queue-pressure path. With
two Open tickets and zero Approved rows, the controller correctly requested
two discovery evals (`task-bigfiles` and `task-colsum`) and zero engineers.
Both eval controllers then rebuilt the default toolchain despite the explicit
qualified image override, and both failed before Pi because the default image
lacked `linux/random.h` and `libunwind`. Cost was `$0.00` and no model worker
started. This is an infrastructure failure, not an evaluator result and not
a fresh-throughput miss.

The deterministic repair is `control.toolchain_build_required`: a present,
platform-matched explicit image suppresses a stale cache-driven default
rebuild, while a missing image or explicit force flag still requires a build.
The repair was covered by 143 native tests and then validated by Run 10.

Run 9 (`run-1786230433596`) was the first attempted validation after that
repair. The policy correctly skipped a stale cache-driven rebuild because an
explicit image was supplied, but the operator supplied the old tag
`xsh-test-throughput-1786225102047`. Run 8's failed Docker build had already
overwritten that tag with an image missing `linux/random.h` and `libunwind`.
Both discovery phases failed at the same local XSH distribution build, before
Pi, at zero cost. This was not evidence that the selection policy was wrong;
it was evidence that a tag is not a durable image identity.

The CTO created a new local image from the cached toolchain, installed the
missing platform dependencies, and tagged it as
`xsh-test-throughput-qualified-1786230433596`. Docker inspection recorded
image `sha256:d3bccbbc5302186bd642455fc7174c3e9d145db8c3102b534ac41672ff894892`
with `linux/arm64` and `/usr/include/linux/random.h` present. This image is
operator-local validation state, not a checked-in factory artifact.

Run 10 (`run-1786230602946`) supplied that image with
`XSH_TEST_IMAGE_BUILD=0`. Both eval phases crossed the build boundary, ran
their workers, and completed report-first managers. `task-bigfiles` passed all
nine cases, restrictions, and protocol with one recovered warn-only lint exit;
`task-colsum` passed all nine cases, restrictions, and protocol after four
self-corrected syntax/API guesses. Both managers found no strong reproducible
product or handbook ticket. The root report was `product=pass`,
`evaluator=pass`, `infrastructure=pass`, `cycle=pass`, with four workers, 97
assistant turns, `$0.052743888`, no budget failures, and one successful
provider 503 retry. It was a factory-robustness success and an evaluator-only
cycle: no engineer commit was expected because there were zero Approved rows.

Run 10 also exposed a bookkeeping edge: the `task-bigfiles` manager described
the approved handbook as unchanged, but its staged candidate changed only
curly apostrophes to straight apostrophes and omitted the final newline. The
CTO recorded candidate hash
`9c3fc917935612d17cd065ad3c78bce13e17945c55e980b81f00fca3fa2ed857` as
non-semantic editorial drift in `runtime/handbook-ledger.md`, and added
`control.handbook_text_equivalent` to keep only that case out of the unresolved
backlog. The native suite now passes 144 tests, including a regression proving
that substantive wording changes still compare unequal. `runtime/handbook.md`
itself was not changed.

At the time of these runs, the queue contained two Open tickets with stale
implementation branches. Both have since been closed as superseded by current
XSH behavior; the next productive cycle requires a new CTO-approved,
branchless ticket before the one-commit gate can be measured.

Run 11 (`run-1786231856321`) revalidated the image path and both evaluator
trials, but exposed a separate manager-closeout regression. The primary
`task-bigfiles` worker passed its nine cases, restrictions, and protocol. Its
manager read the five admission files, then read worker evidence before
drafting and idled into the 120-second inactivity watcher. The bounded retry
read the phase packet and worker evidence but terminated with an error, leaving
both report skeletons at `not-ready`. The independent `task-colsum` manager
did produce a complete report and its phase passed. Root outcomes were
`product=pass`, `evaluator=pass`, `infrastructure=fail`, `cycle=fail`, with five
workers, 94 assistant turns, `$0.062499888`, no budget failures, and no unknown
costs. This was not provider latency and did not involve product delivery.

The root cause was a real contract contradiction: `roles/eval-manager.md`
said to read phase, worker, evaluator, and manager evidence first, while
`templates/EVAL-MANAGER-ASSIGNMENT.md` required the next tool call after its
admission reads to write the staged report. Run 11 followed the former path.
The repair makes the order singular across the role, assignment, and retry:
exactly five admission reads, immediate complete staged-report write/edit, then
worker and evaluator evidence refinement. `tests/tools_test.xsh` now asserts
the three prompt surfaces. The native suite remains 144/144. Because the paid
request already failed, the repair is not relaunched under the same request;
the next explicit cycle is the validation boundary.

Run 12 (`run-1786233883963`) was that boundary. Its primary manager complied
with the repaired ordering: its only assistant response contained exactly the
five admission reads and no worker/evaluator read. The retry likewise made only
its prescribed phase-report and staged-report reads. Neither session received a
second assistant response after the corresponding tool results, so neither
could write a first draft before the 120-second idle watcher terminated it. The
independent `task-colsum` manager used the same five-read first turn, received
its next provider completion, immediately wrote the staged report, and passed.
Thus the prompt contradiction is resolved; the remaining failure is a
controller lifecycle misclassification, not a new evidence-order violation.

`factory/tools/session-watch.xsh` now recognizes a final `toolResult` record as
a pending provider completion. It retains the 120-second idle cap for ordinary
agent silence, but lets the existing 300-second normal or 180-second recovery
wall cap govern that pending state. A synthetic native test proves the watcher
records the wall limit rather than an idle limit for that exact session shape.
The change is pending the next explicit cycle; the current run remains the
falsifying baseline and no paid relaunch is authorized by it.

## Qualification and closeout

After the implementation tranche is committed, qualification consists of
three consecutive eligible organization cycles. Each cycle is closed with its
durable run evidence, productivity report, and CTO report. The qualification
ledger is:

```text
cycle N:   engineer row 1, delivery 1, linked replay pass
cycle N+1: engineer row 1, delivery 1, linked replay pass
cycle N+2: engineer row 1, delivery 1, linked replay pass
```

Independent supply evals run in these cycles while the Approved queue has one
or two rows before admission. That is expected: quality is preserved by the
linked replay while the isolated supply lane works to restore the two-ticket
buffer without substituting for delivery.

Qualification fails if a non-product lane substitutes for delivery, if a
manager consumes an unbounded retry, or if a passing report is not accompanied
by a reachable XSH commit and provenance event. A failure preserves the branch
and evidence and identifies the exact repair.

The CTO closes the implementation and each qualification run with one scoped
commit. Do not push to a remote, merge unrelated work, or delete evidence.
