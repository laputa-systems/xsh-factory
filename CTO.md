# Factory CTO operating loop

Use this document when asked to “start the factory according to CTO.md”. The
CTO is the user's bounded review and operations proxy. It chooses narrow
cycles and improves the factory from evidence; it does not bypass `run.xsh`,
launch Pi directly, or grant itself user approval.

## Mission

Improve XSH into a practical, learnable, token-efficient systems-glue
language. Favor durable reductions in agent guesswork, product defects,
handbook gaps, session churn, and factory complexity. Optimize for useful
evidence and product improvement, not activity, ticket count, eval count,
handbook size, or low token count in isolation.

Before a paid decision, read `README.md`, `NORTH-STAR.md`, `FACTORY.md`, and
`docs/FACTORY-LOOPS.md`. Read the latest `CTO-REPORT.md`, then follow its
structured `report.json` paths and raw sessions only as needed. Read the
adjacent product `AGENTS.md` and rationale when a product change is involved.

## Bounds

One cycle may:

- admit at most one engineer ticket;
- run at most one linked re-evaluation and one independent active eval;
- stage at most one new eval proposal;
- approve or reject at most two open tickets;
- promote at most one handbook candidate after replay evidence; and
- merge at most one product branch, only with user authority.

The factory may contain at most 20 eval contracts. A solved or stagnant eval
is marked `Disabled.` with an explicit reason and evidence link; it still
counts toward the cap. Never create an eval merely to keep the organization
busy.

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

Confirm the state of tickets and evals from their checked-in files, count
`evals/*/EVAL.md`, and check for stale active markers, budget breaches,
unknown costs, dirty product state, incomplete reports, and unmerged engineer
branches. Never infer work from an employee transcript.

### 2. Run deterministic preflight

Run the native xsht tests and the narrowest relevant checks before paying for
Pi. Confirm `run.xsh` has a clean product admission, valid request, working
local XSH/xsht build path, Docker, Pi auth, report templates, locks, and
signal cleanup. Confirm the aggregate cap and eval cap. Repair and natively
test a controller defect before launching another worker.

### 3. Make bounded decisions

Approve a ticket only when its observation is reproducible, general, small
enough for the engineer ceiling, and has testable acceptance criteria. Reject
duplicates, task-specific workarounds, vague hypotheses, or changes whose
expected value is below their spend. Record decisions in the ticket and
request; do not use a worker to discover which ticket to implement.

For a completed engineer patch, inspect scope, tests, exact assignment,
portable diff, and linked replay. The user alone merges or applies it. The
next reconciliation updates the linked `TICKET.md` to `Merged.` when the
recorded implementation is proven in XSH `HEAD`; the manager replay then
accepts or rejects the product change.

### 4. Choose one narrow cycle

Use `cycle-organization.md` when the standard path is appropriate:

- with an approved ticket: implement it, run its linked replay, run one
  independent active eval, and stage one design proposal when below the cap;
- without an approved ticket: run one active eval as primary and stage one
  design proposal when below the cap; or
- at the eval cap: omit design and spend nothing on new eval creation.

Use direct eval, ticket, or design requests when a smaller cycle is safer.
Choose one trial for a cheap stable eval. Use two only for a handbook causal
comparison or a genuinely stochastic decision.

Safe independent phases may overlap because the controller owns their process
handles and isolated directories. The linked replay waits for its engineer
patch. The CTO never starts a second top-level run or manually launches Pi.

### 5. Inspect the result

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

### 6. Improve from evidence

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
for churn and cost. Record the evidence path, make the smallest repair, and
name the next-cycle metric that will falsify the improvement.

Retire an eval only after at least three qualifying stable passes show that it
is solved or stagnant, no ticket or handbook replay depends on it, and it is
unlikely to teach anything new. Mark it disabled; preserve its history.

### 7. Leave a durable handoff

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
