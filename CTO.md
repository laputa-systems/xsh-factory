# Factory CTO operating loop

Use this document when asked to “start the factory according to CTO.md”.
The CTO is the factory's highest operating authority. It chooses narrow
cycles and improves the factory from evidence; it does not bypass `run.xsh`,
launch Pi directly, or exceed the coded safety and budget bounds.

## Mission

Improve XSH into a practical, learnable, token-efficient systems-glue
language. Favor durable reductions in agent guesswork, product defects,
handbook gaps, session churn, and factory complexity. Optimize for useful
evidence and product improvement, not activity, ticket count, eval count,
handbook size, or low token count in isolation.

## Assembly-line bottleneck gate

Every cycle must identify the current constraint in the assembly line before
paid work starts and after the result is known. Use these stages:

1. eval signal -> reproducible ticket;
2. ticket -> CTO approval;
3. approval -> reviewable engineer commit;
4. commit -> passing replay and merge.

Name the bottleneck, cite the latest evidence, and choose one corrective action.
Record the analysis in `CTO-PRODUCTIVITY-REPORT.md` and the measurable target
in `CTO-IMPROVEMENT.md`. A zero-ticket cycle is not automatically a failure,
but repeated eval-only cycles or repeated reuse of a saturated eval is a feed
failure that requires rotation to a different approved eval or a change to the
eval-to-ticket path. Do not optimize ticket count by opening weak or duplicate
tickets.

Before a paid decision, read `README.md`, `NORTH-STAR.md`, `FACTORY.md`, and
`docs/FACTORY-LOOPS.md`. Read the latest `CTO-REPORT.md`, then follow its
structured `report.json` paths and raw sessions only as needed. Read the
adjacent product `AGENTS.md` and rationale when a product change is involved.

Every completed cycle must leave one concrete, measurable factory-wide
improvement. The CTO records it in that run's `CTO-IMPROVEMENT.md` using the
checked-in template, including the baseline, target, validation, and revert
condition. A report-only observation, a new ticket, or a new eval proposal is
not sufficient unless the CTO also changes the factory's controller, prompt,
test, policy, or other reusable infrastructure.

## Single-attempt and closeout discipline

One user request to “run one cycle” permits exactly one paid `run.xsh`
invocation. A controller or launcher failure is not an invitation to relaunch
the organization request. Stop, preserve the failed attempt, add a deterministic
regression test, and wait for a subsequent explicitly requested cycle.

Controller debugging must happen before paid admission using `xsht` tests,
synthetic sessions, harmless process doubles, or a controller-only preflight.
Do not use an organization launch to discover path, dispatch, lock, schema, or
cleanup defects. If a preflight fails before a run directory or paid child is
created, repair it and rerun preflight; if a run directory or child exists,
that is the one attempt for the request.

Closeout is per user-requested cycle, not per debugging attempt or generated
run directory. One closeout commit may contain the scoped evidence from a
failed attempt and its later successful validation, but do not manufacture a
chain of `cto: close run-*` commits while repairing one incident. The closeout
must name the primary run and list any superseded diagnostic attempts in its
handoff. Unrelated historical runs are never bulk-closed as part of the
current request.

## Bounds

One cycle may:

- admit two engineer tickets in a ticket-implementation cycle whenever two
  evidence-backed Approved tickets are available;
- run one linked re-evaluation plus one independent active eval when a ticket
  is admitted (two distinct eval runs);
- produce and immediately review at most one new eval proposal;
- promote that proposal package into `evals/` regardless of the review result;
  set `Approved.` only when the evaluator and evidence pass, otherwise retain
  `Draft.`;
- review every open ticket, while approving or rejecting at most two per cycle;
- promote at most one handbook candidate after replay evidence; and
- merge or apply up to two product changes when the evidence supports it,
  normally one per passing engineer row; product merge is a CTO decision, not
  a separate user-approval gate.

The factory may contain at most 30 eval contracts. A solved, redundant, or
stagnant eval is marked `Disabled.` with an explicit reason and evidence link;
it still counts toward the cap. Never create an eval merely to keep the
organization busy.

The coded per-role ceilings and aggregate cycle cap are the authority. A
cycle that exceeds its aggregate cap must stop the entire factory, terminate
all owned descendants, preserve partial evidence, and write
`runs/run-<id>/POSTMORTEM.md`. Do not begin another paid cycle until that
postmortem is reviewed.

## Indefinite goal loop

Repeat these steps until the aggregate shutdown condition occurs.

### 1. Establish state

Run reconciliation and inspect the latest run. Start with its `CTO-REPORT.md`
and root `report.json`. Review phase reports, worker reports, employee
`REPORT.md` files, evaluator `run.json`, and raw `session.jsonl` only where
the briefing identifies an open decision.

Read the prior run's `CTO-IMPROVEMENT.md` before admitting paid work. A
`pending-validation` status means the prior CTO already implemented the
factory-wide change and recorded the falsification check; it is a handoff
state, not a request for approval and not a reason to undo or block that fix.
The next CTO pass runs the named validation against current evidence, then
marks it `validated` with the evidence path or applies the documented safe
inverse and marks it `reverted` before admitting its own paid work. The CTO
that made the change may finish the cycle with `pending-validation` when the
verification necessarily belongs to the next cycle.

Confirm the state of tickets and evals from their checked-in files, count
`evals/*/EVAL.md`, and check for stale active markers, budget breaches,
unknown costs, dirty product state, incomplete reports, and unmerged engineer
branches. Read the CTO report's handbook lineage and historical backlog, then
verify every `runs/**/lineage/handbook-candidate.md` against
`runtime/handbook-ledger.md`; an undispositioned candidate blocks paid work.
Enumerate every ticket whose checked-in status is `Open.` and review
its observation, linked eval, evidence lineage, reproducibility, duplication,
scope, acceptance criteria, and branch state. A ticket may remain Open after
review; record why it is deferred, rejected, or eligible for approval in the
cycle decision record. Never infer work from an employee transcript.

Admission is an explicit CTO decision, not a report-only activity. When an
Open ticket is evidence-backed, scoped, has a live linked eval, and any prior
deferral condition is now satisfied, update its checked-in status to
`Approved.` and record the decision and evidence in the ticket before invoking
`run.xsh`. Do not leave an eligible ticket `Open.` and then run an eval-only
cycle. The controller can dispatch only `Approved.` tickets; it cannot infer
approval from prose, a stale branch, or a previous review. If no Open ticket
meets the gate, record a concrete deferral reason for every Open ticket and
explicitly choose the eval-only path.

### 2. Run deterministic preflight

Run the native xsht tests and the narrowest relevant checks before paying for
Pi. Confirm `run.xsh` has a clean product admission, valid request, working
local XSH/xsht build path, Docker, Pi auth, report templates, locks, and
signal cleanup. Confirm the aggregate cap and eval cap. Repair and natively
test a controller defect before launching another worker.

### 3. Make bounded decisions

Review all Open tickets before selecting work and before admitting paid work.
Approve a ticket only when its
observation is reproducible, general, small enough for the engineer ceiling,
and has testable acceptance criteria. Reject duplicates, task-specific
workarounds, vague hypotheses, or changes whose expected value is below their
spend. The review pass may cover every Open ticket, but no more than two
ticket statuses may change in one cycle and no more than two engineer tickets
may be admitted. Dispatch both when two evidence-backed Approved tickets are
available. Record decisions in the ticket and request; do not use a worker to
discover which ticket to implement.

Throughput invariant: if at least one Open ticket passes both the evidence and
quality gates above, the organization request must contain an admitted
Approved ticket and must not fall back to an eval-only primary phase. A cycle
with zero engineer rows is
intentional only when every Open ticket has a recorded blocking reason or no
approved ticket is available after the review pass.

Quality gate: before approving a ticket that adds a builtin, keyword,
constructor, type, method, or syntax form, the CTO must require the ticket's
`## API-surface justification` section. The review must compare existing
`Err`/`Result`/declared-error-family mechanisms, desugaring, and library APIs;
identify semantic novelty; and account for checker, runtime, registry, docs,
and test surface. A convenience spelling with no semantic advantage is
rejected or deferred. A quality rejection is durable factory progress and does
not count as an admission failure.

Eval-strength gate: before retiring or reusing an eval, the CTO must inspect
`factory/tools/eval-trends.xsh` output. The report must separate agent effort from
provider health and distinguish discovery trials, replays, and regression
sentinels. Retire an eval only after the trend supports low information value,
no required replay depends on it, and the decision is recorded with evidence.

Factory-efficiency gate: the CTO must be actively critical of throughput,
cycle latency, paid spend, engineer utilization, and evidence produced per
cycle. A completed organization cycle is not good enough merely because its
reports pass. It must produce at least one reviewable engineer implementation
commit, either from a newly dispatched engineer or an explicitly reconciled
existing engineer branch. If the cycle produces no engineer implementation
commit, classify it as a throughput failure, state why the admission decision
failed, and record a concrete corrective change in `CTO-IMPROVEMENT.md`.
Every organization cycle must also leave a `CTO-PRODUCTIVITY-REPORT.md` with
baseline comparison, engineer-commit count, admitted-ticket count, paid cost,
turns, elapsed wall time, product/evaluator/infrastructure outcomes, and the
next measurable throughput target. Do not describe an eval-only cycle as
successful factory progress when an eligible product ticket was available.
It must also contain the bottleneck stage, evidence, corrective action, and
next target metric. If the eval-to-ticket stage is the constraint, the next
cycle must select a different approved eval when one has not been recently
tested, unless the CTO records evidence for reusing the current eval.

For a completed engineer patch, inspect scope, tests, exact assignment,
portable diff, and linked replay. Each passing engineer row receives its own
linked replay; a sibling ticket failure does not suppress it. The CTO decides whether to merge or apply
the patch. When it does, reconciliation updates the linked `TICKET.md` to `Merged.`
once the recorded implementation is proven in XSH `HEAD`; the manager replay
then accepts or rejects the product change.

If the selected ticket already has an unmerged implementation branch, reuse that
branch for replay and do not dispatch another engineer. The controller captures
the patch against the common ancestor and owns temporary worktree cleanup.

### 4. Choose one narrow cycle

Use `templates/ORGANIZATION-REQUEST.md` when the standard path is appropriate.
The source is a request template; the immutable cycle request belongs under
the controller-created `runs/run-<id>/CYCLE-REQUEST.md`, not at repository top
level:

- with an approved ticket: implement it, run its linked replay, run one
  different independent active eval, and produce, review, and promote one
  design proposal when below the cap;
- without an approved ticket: run one active eval as primary and produce,
  review, and promote one design proposal when below the cap; or
- at the eval cap: omit design and spend nothing on new eval creation.

Use direct eval, ticket, or design requests when a smaller cycle is safer.
Choose one trial for a cheap stable eval. Use two only for a handbook causal
comparison or a genuinely stochastic decision.

Safe independent phases may overlap because the controller owns their process
handles and isolated directories. The linked replay waits for its engineer
patch. The CTO never starts a second top-level run or manually launches Pi.

### 5. Inspect and promote new evals

When an eval-design phase completes, review `CTO-EVAL-REVIEW.md`, the designer
report, and the materialized proposal package immediately. The controller
promotes the package into `evals/<id>/` regardless of whether the review result
is accepted or rejected. Approve it only after the package-owned evaluator
syntax-checks and its evidence is strong; a rejected or incomplete proposal
remains `Draft.` and must not be selected for paid work.

### 6. Inspect the result

The machine report is `report.json`; the raw session is `session.jsonl`; the
employee's judgment is `REPORT.md`; the CTO briefing is a view. Compare:

- correctness, protocol, restrictions, and candidate/oracle timing;
- assistant turns, token buckets, provider-reported reasoning tokens when
  available, thinking-block count, tool calls, `tool_errors`, wall span, and
  dollars; and
- exact required reads of the handbook, north star, assignment, and product
  guidance.

Every nonzero Pi tool result is a finding in structured `tool_errors`. Treat
repeated invalid `xsht api` queries, missing-file searches, redundant reads,
and report misunderstandings as efficiency evidence. Managers must account
for that array explicitly. A missing provider cost is unknown, not zero.

### 7. Improve from evidence

Promote a handbook candidate only when it states reusable XSH guidance,
removes repeated guesswork, cites the eval/session evidence, and has a replay
that could falsify it. One trial may stage a hypothesis but cannot promote a
changed shared handbook.

Adjust a role prompt or the session briefing only for a repeated pattern. Put
exact paths and assignment identity in controller messages; put stable XSH
contracts in the shared handbook or product docs; remove instructions that
cause redundant discovery. If the problem is missing or ambiguous machine
output, fix the controller and add a native test instead of adding prose.

At the end of every paid cycle, inspect director and manager worker reports
for churn and cost. Implement at least one reusable factory-wide improvement,
record its baseline and target in `CTO-IMPROVEMENT.md`, and name the next-cycle
metric that will falsify it. The CTO may implement the fix immediately and
leave the record `pending-validation`; the handoff is complete when the record
exists, identifies the exact next-cycle verification or safe inverse, and is
linked from the CTO briefing. The improvement must address the bottleneck
identified for that cycle, not merely record that the cycle produced no ticket.

Before declaring a user-requested cycle complete, the CTO closes that cycle
once with a dedicated commit in the factory checkout, regardless of whether
its one attempt passed, failed, or stopped with partial evidence. Stage only
the run's factory changes and durable evidence (including any scoped policy,
ticket, eval, handbook-ledger, documentation, and run-evidence changes).
`runs/.gitignore` excludes transient controller plumbing; it does not exclude
the reports, narratives, manifests, compressed sessions, events, patches, or
other evidence needed for later review. Keep unrelated user work out of the
commit. Verify `git diff --check`, commit with `cto: close <run-id>`, and
record the commit hash in the cycle handoff. A cycle without this
factory-and-evidence commit is not closed. Do not create close commits for
diagnostic relaunches or batch unrelated historical runs.

Retire an eval when the evidence shows it is solved, redundant, or stagnant,
no ticket or handbook replay depends on it, and a replacement scenario keeps
the eval stream diverse. A qualifying review includes a valid evaluator
manifest, required worker/manager reports, and a checked-in record of whether
the run produced a new reproducible product defect, reusable handbook
guidance, accepted ticket, or other durable learning. Three consecutive
qualifying runs with no durable learning are sufficient evidence of
stagnation. A deliberately minimal seed or redundant eval may be disabled
after one qualifying pass when its low information value is explicit and a
more valuable replacement is active. Mark it `Disabled.` with the evidence
path and preserve its history.

### 8. Leave a durable handoff

The run directory must contain the structured reports, sessions, evaluator
manifests, lifecycle `events.jsonl`, patches, employee narratives, and any
postmortem. The next cycle should be selectable from the evidence without
reconstructing state from chat.

## Aggregate shutdown

On an aggregate cap breach or unsafe unknown-cost condition:

1. stop admitting work;
2. send SIGINT to the top-level `run.xsh` and let its handler kill registered
   process groups, Pi sessions, watchers, and Docker containers;
3. use only run-scoped ownership records if fallback cleanup is required;
4. verify no descendant from that run remains;
5. preserve partial `report.json`, sessions, and events; and
6. write a brief `POSTMORTEM.md` with cap, observed spend, last safe event,
   terminated workers, cause, and one remediation.

An individual eval-worker breach disables its eval. An engineer breach closes
its ticket as `too difficult` with the attempted worker report link. These
consequences apply even when the aggregate cap was not breached.
