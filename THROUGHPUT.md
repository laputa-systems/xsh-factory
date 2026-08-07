# Factory throughput

This is the current CTO plan for keeping the XSH improvement factory supplied
with useful work while preserving the factory's admission, evidence, and budget
contracts. The goal is a steady stream of independently judged product work,
not more concurrent work for its own sake.

## Evidence and operating target

- The checked-in portfolio is at the coded limit of 30 eval contracts: 24 are
  `Approved.` and 6 are `Draft.`.
- The current queue has six reviewed Open product tickets, but each is deferred
  until a named eval replay or cross-eval confirmation.
- Recent eval work can finish without producing a product ticket; the latest
  `task-ecount` cycle produced a handbook candidate that needs replay before
  promotion.
- The short-term target is two approved, evidence-backed tickets available for
  implementation and at least one engineer commit every one or two cycles.

## Recommendations

### 1. Run two independent discovery evals in no-ticket organization cycles

When no approved ticket is admitted, select the next two distinct untried
approved evals and run them concurrently. Keep one eval worker and one manager
per eval, and retain the aggregate cycle budget as the hard ceiling. This
increases discovery throughput without increasing engineer concurrency or
asking agents to choose work.

The controller must validate both IDs, create separate phase directories and
reports, and fail closed if the request is not the deterministic next pair
(unless measured reuse is explicitly allowed). A cycle passes only when both
eval phases pass and infrastructure evidence remains valid.

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

Recommendation 1 is implemented first. The organization request may name up to
two active evals for a no-ticket discovery cycle. `run.xsh` admits only the next
deterministic untried approved evals, and
`factory/controllers/organization.xsh` runs the second eval in a separate
independent phase concurrently with the primary eval. The remaining
recommendations are intentionally proposals until their contracts, metrics,
and tests are separately defined.
