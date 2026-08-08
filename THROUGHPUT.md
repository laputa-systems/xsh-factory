# Factory throughput

This is the current CTO plan for keeping the XSH improvement factory supplied
with useful work while preserving the factory's admission, evidence, and budget
contracts. The goal is a steady stream of independently judged product work,
not more concurrent work for its own sake.

## Evidence and operating target

- The checked-in portfolio is at the coded limit of 30 eval contracts: 24 are
  `Approved.` and 6 are `Draft.`.
- The current queue has seven reviewed Open product tickets, but each is deferred
  until a named eval replay or cross-eval confirmation.
- Recent eval work can finish without producing a product ticket; the latest
  `task-ecount` cycle produced a handbook candidate that needs replay before
  promotion.
- The short-term target is two approved, evidence-backed tickets available for
  implementation and at least one engineer commit in every cycle that has a
  ready ticket.

## Recommendations

### 1. Run up to four independent discovery evals in no-ticket organization cycles

When no approved ticket is admitted, select the next one to four distinct
untried approved evals and run them concurrently. Keep one eval worker and one
manager per eval, and retain the aggregate cycle budget as the hard ceiling.
This increases discovery throughput without increasing engineer concurrency or
asking agents to choose work.

The controller must validate every ID, create separate phase directories and
reports, and fail closed if the request is not the deterministic next batch
(unless measured reuse is explicitly allowed). A cycle passes only when every
eval phase passes and infrastructure evidence remains valid.

### 2. Tier ticket admission by risk

Allow a narrow, deterministic bugfix with no new API, syntax, handbook, or
semantic contract to qualify after one strong eval. Keep the two-eval replay
gate for API, syntax, handbook, and semantic changes.

### 3. Replace weak draft evals with harder evals

Do not raise the 30-contract cap. Retire or replace low-yield draft packages
with difficult composition, filesystem, parsing, and failure-recovery tasks
that can discriminate between plausible but incorrect XSH improvements.

### 4. Track eval yield and retire low-value packages

Record, per eval, trial count, actionable finding count, ticket conversion,
replay confirmation, and cost. Review packages with repeated no-finding runs
and either sharpen their oracle or retire them.

### 5. Maintain a bounded work queue

Keep two approved tickets ready for engineers and schedule enough discovery and
replay work that an engineer is not idle for more than one cycle. Queue depth
must remain bounded by the coded engineer ceiling and the aggregate budget.

## Implementation status

The current throughput package is implemented and covered by native tests:

- `factory/entrypoints/run-agent.xsh` snapshots the approved handbook for each
  run-scoped worker and quarantines an accidental live handbook edit as
  evidence, while non-handbook factory mutation still fails closed.
- `factory/controllers/organization.xsh` starts a retained-branch validation
  before waiting on fresh primary work, admits all passing ticket rows before
  waiting on linked replays, and merges validated branches serially.
- A failed primary row is salvaged independently: sibling rows still receive
  their linked replay and delivery decision. `reuse.xsh` records its
  deterministic retained-branch validation as a fast path without launching
  Pi.
- `factory/tools/audit.xsh` projects admitted rows, replay counts, delivery
  conversion, fast-path use, handbook quarantines, and overlap indicators into
  the existing run `report.json`; no second throughput artifact or schema is
  introduced.
- `run.xsh` and `factory/controllers/organization.xsh` apply queue pressure
  deterministically: the approved ready queue selects up to two engineer rows
  and one independent eval; an empty ready queue expands discovery to the four
  eval ceiling. Open tickets are reported as pressure but are never promoted
  without CTO approval.
- `factory/tools/run-status.xsh` gives the CTO a single read-only view of live
  process state, lifecycle progress, adaptive allocation, worker effort, and
  budget markers. The eval controller also snapshots ticket identities around
  manager sessions and fails closed if a pre-existing ticket is overwritten.

The coded bounds remain unchanged: at most two engineer rows, one retained
branch per batch, one linked replay per passing row, and the aggregate budget
remain hard gates. Queue pressure is evaluated after each CTO inventory: a
ready ticket keeps one independent eval beside product work; an empty ready
queue expands to discovery. The next cycle validates these changes against the
approved `task-safepath-002` implementation and its linked replay.
