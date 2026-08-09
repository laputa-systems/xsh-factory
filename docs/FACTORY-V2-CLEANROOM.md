# Factory V2: a cleanroom epistemic institution

## Decision

Factory V1 is not the substrate on which to make small throughput repairs. It
is a completed experiment: a carefully instrumented transactional assembly
line that demonstrated both useful safety primitives and a decisive limitation.
It can turn an already-good, already-approved, narrowly bounded observation
into a replayed patch. It cannot reliably create the observations that should
enter that pipeline, and queue pressure cannot manufacture them.

Factory V2 is a cleanroom redesign for a different problem:

> Build a persistent, self-improving institution that can form explanations
> about XSH, choose high-information experiments, preserve disagreement,
> learn from outcomes, and experimentally improve the machinery that performs
> those functions.

XSH remains the institutional policy and execution language. That is
intentional: the language, the experiment descriptions written in it, and the
organization that improves both can become one lineage. It does **not** mean
that XSH should become a database language or that controller files should be
the durable workflow engine. The initial implementation is not a bid to rewrite
V1 in a new directory. It is a new set of concepts, invariants, and experiments
with a deliberately small trusted substrate.

V1 must remain preserved and runnable as historical evidence. V2 does not
inherit V1's controller graph, ticket-buffer contract, role hierarchy, or
throughput qualification rules.

## The diagnosis from V1

V1 produced real assets:

- isolated worktrees, clean product boundaries, and reproducible local builds;
- package-owned evaluators, raw sessions, structured reports, budgets, and
  process ownership;
- content hashes, Git provenance, exact assignments, cleanup, rollback, and
  native deterministic tests; and
- a durable record of successes, failed replays, manager failures, and the
  distinction between product, evaluator, and infrastructure outcomes.

Those are excellent *physics*. They should survive.

Its failure was architectural, not merely operational. V1 made a ticket the
unit of knowledge and a delivery transaction the unit of progress:

```text
eval -> ticket -> approval -> engineer -> replay -> merge
```

That construction loses the information that matters before a patch exists:
competing explanations, negative results, uncertainty, predicted consequences,
unresolved design disagreements, and later evidence that changes the original
decision. It also conflates two distinct things:

- a queue is a mechanism for allocating scarce attention; and
- the institution's world model is its account of what is true, uncertain,
  valuable, dangerous, or worth learning.

V1 treated the queue as both. The two-ticket buffer then became a proxy for
health. When clean evals produced no product observations, the system had no
way to improve its research strategy except to rotate more task-shaped evals.
An engineer-commit-per-cycle target amplified that error: it measured conversion
of pre-existing supply, not the institution's ability to discover or assess
important work.

The cleanroom rule is therefore simple:

> No artifact exists merely to make the queue look healthy. A queue is always
> a derived view over a richer causal record.

## V2 thesis

The primary V2 artifact is not a ticket, role, report, or benchmark. It is a
persistent typed causal graph of consequential work.

```text
objective -> question -> competing hypotheses -> experiment -> evidence
                                               \-> conflict -> decision
                                                               -> implementation
                                                               -> outcome
                                                               -> retrospective
                                                               -> lesson
```

Every arrow has a meaning: `motivates`, `tests`, `supports`, `contradicts`,
`predicts`, `decides`, `implements`, `observes`, `revises`, or `supersedes`.
The graph is the institutional memory. Queues, dashboards, agent assignments,
and reports are projections of it for a particular scarce resource.

This lets V2 optimize three rates independently:

1. **Discovery:** warranted new knowledge per unit of scarce work.
2. **Checked propagation:** latency from validated knowledge to the relevant
   active work, policies, evaluators, and future retrieval—with resistance to
   unwarranted propagation.
3. **Metamorphosis:** rate at which evidence about the institution changes its
   own topology, policies, tools, and evaluation practice.

Product commits remain important outcomes. They are no longer the sole proof
that a cycle mattered, nor an eligibility requirement for inquiry.

## V2's immutable physics

The following layer is intentionally boring and hard to mutate. It is the
laboratory that makes organizational evolution meaningful rather than
self-description.

```text
identity and capability permissions
a database-authoritative, typed workflow state machine and event ledger
content-addressed artifacts and immutable input snapshots
Git/product lineage and reproducible worktrees
sandboxed execution and evaluator manifests
budget/resource accounting and leases
deterministic schemas, idempotency, validation, and lifecycle transitions
rollback, cancellation, retention, and independently replayable evidence
```

V1 already contains much of this substance. V2 may port or reimplement it, but
must revalidate each component against a V2 contract rather than invoke a
compatibility layer. The trusted layer must be able to prove at least that:

- an actor cannot edit evidence, history, budget, or authority after the fact;
- a claimed observation identifies its inputs, environment, artifacts, and
  evaluator;
- a proposed organizational change cannot silently become the new evaluator;
- an experiment can be replayed against its recorded world; and
- a product change remains separately reviewable and revertible.

All higher concepts—including role definitions, routing, prompts, graph views,
evaluation procedures, and eventually trace schemas—are mutable experiments.

## Database-owned durable workflow

V2's durable workflow is a shared database, not a collection of XSH state
files, Markdown reports, controller conventions, or parsed logs. One local
SQLite database is initially the authority for the institution's live and
historical state; a content-addressed artifact root holds immutable byte
evidence that the database identifies by safe relative path, length, digest,
and closed role. Neither side substitutes for the other.

The database-owned kernel must atomically own:

- object and revision identity; typed graph edges; causal status; authority;
  immutable command receipts; and the ordered event sequence;
- optimistic state generations, content-sensitive idempotency keys, explicit
  transition validation, cancellation, retry/attempt lineage, leases, claims,
  expiry, budgets, and resource ownership;
- durable references to sealed inputs, evaluator versions, product commits,
  raw sessions, artifacts, and observations;
- scheduler-visible derived readiness and work claims, so no process infers
  whether work is eligible by scanning a directory; and
- projection cursors and an outbox for rebuildable views and notifications.

A mutation is a typed command, not a file write:

```text
principal + authority + command id + expected generation + typed payload
  -> one database transaction
       validate durable invariants
       append an immutable event
       update the current materialized state
       advance projection/outbox cursors
  -> typed state or explicit conflict
```

The schema must keep the semantics that require durable querying and
constraints relational: object identities and revisions, edges, commands,
events, attempts, claims, leases, evidence references, artifacts, permissions,
and projection checkpoints. Node-specific fields that determine eligibility,
authority, propagation, or evaluation must have typed columns/tables and
constraints; an opaque JSON blob or an EAV table cannot become the primary
truth merely because the graph is broad. The kernel may validate the remaining
closed payload variants in compiled code, but it must never let a caller evade
the transactional protocol with arbitrary SQL.

This kernel is a V2-owned Rust component with typed SQLite state, immutable
snapshots and evidence, content-sensitive idempotent events, state generations,
leases, exact resource ownership, and an independent ledger replay audit. V2
needs one organization-wide database and a causal-graph ontology, not a
per-run job/workflow model.

The initial implementation must expose a small versioned V2 protocol and carry
focused transaction, recovery, fault-injection, and state-machine tests from
the outset. Its schema and APIs are V2 contracts, rather than a third-party
dependency or an opaque application runtime.

## The institutional graph

V2 graph nodes have stable content identities, explicit owners where an owner
is needed, and append-only revisions. It is not a free-form knowledge base.
Each node kind has a schema, authority boundary, required evidence, and allowed
transitions. The initial vocabulary is deliberately broad enough for inquiry:

| Node | What it preserves |
| --- | --- |
| Objective | A durable XSH capability, quality, or institutional aim. |
| Question | An uncertainty worth resolving, not an implied implementation task. |
| Hypothesis | A falsifiable explanation with scope, confidence, and predictions. |
| Proposal | A specific intervention and its alternatives, reversibility, blast radius, and expected information gain. |
| Experiment | A reproducible attempt with inputs, evaluator, resource budget, and stop rule. |
| Evidence | An observed fact, source, confidence, environment, and limitations. |
| Conflict | Preserved incompatible claims or tradeoffs; never an averaged score masquerading as truth. |
| Decision | Chosen action, rationale, dissent, constraints, predictions, and revisit trigger. |
| Implementation | A bounded product or factory mutation with provenance and validation. |
| Outcome | Observed short- or long-horizon consequence of a decision. |
| Lesson | A scoped, validated knowledge item with propagation and revocation policy. |
| Organization experiment | A change to actor configuration, routing, authority, context, or evaluation policy. |

There are two equally important distinctions:

1. **Evidence is not interpretation.** A timing measurement, an evaluator
   result, a user report, and a code review observation remain separately
   addressable even when a later claim changes.
2. **A decision is not an outcome.** Every meaningful decision records what it
   expected to happen, when that expectation should be checked, and what would
   reopen it.

A V2 decision packet therefore retains a partial order instead of requiring a
scalar fitness score:

```text
proposal A dominates on: correctness, implementation simplicity
proposal B dominates on: performance, migration cost
unknown: ecosystem impact, long-horizon agent ergonomics
constraint: no silent compatibility break
dissent: preserved with evidence and revisit condition
```

Metrics, tests, benchmarks, and costs are strong evidence. They are never the
whole institutional judgment.

## Queues are metabolism, not ontology

V2 still needs WIP limits, resource accounting, ownership leases, cancellation,
and backpressure. These are distributed-systems primitives, not embarrassing
corporate leftovers. But each queue is a projection over graph nodes and a
specific constrained resource:

```text
question triage       -- scarce: research attention
experiment execution  -- scarce: compute, sandbox capacity
evidence review       -- scarce: adversarial/evaluator attention
integration           -- scarce: product risk and merge bandwidth
outcome follow-up     -- scarce: delayed observation capacity
organization trials   -- scarce: safety envelope and experimental budget
```

Pressure must travel upstream. A backlog of unreviewed evidence suppresses new
hypothesis generation; a shortage of integration capacity favors reversible
experiments; a known compatibility uncertainty can block a broad mutation while
allowing measurement work to proceed. No controller may invent a weak product
proposal simply because an implementation queue is empty.

## Checked propagation and institutional memory

Propagation is a first-class V2 transition, not an incidental handbook edit.
A lesson carries:

```text
claim, scope, confidence, evidence links, contradictions,
applicability conditions, dependents, expiry/revalidation rule,
propagation policy, and revocation path
```

The system must distinguish at least four propagation modes:

| Mode | Example | Effect |
| --- | --- | --- |
| Local observation | One session found a confusing API. | Visible to its parent question only. |
| Provisional guidance | Two independent experiments support an XSH idiom. | Retrieved for matching future work; not a global rule. |
| Enforced invariant | A reproducible compiler soundness bug has a regression test. | Updates evaluators and blocks violating changes. |
| Contested claim | Ergonomics evidence conflicts. | Preserves dissent and schedules a discriminating experiment. |

The optimization target is not minimum propagation latency. It is minimum
latency for warranted knowledge and maximum resistance to false propagation.
Retraction is therefore symmetric: new contradictory evidence finds dependent
decisions and lessons, downgrades or reopens them, and records what was changed.

The rolling handbook becomes one V2 projection: curated guidance backed by
lessons. It is no longer the only memory mechanism or a catch-all for every
observation.

## Actors, institutions, and an evolvable genome

V2 starts with broad functional attractors rather than a permanent corporate
chart:

```text
explore  build  measure  challenge  synthesize  integrate  remember  coordinate
```

An actor is a versioned configuration, not a named profession. Its initial
genome records capabilities, tool permissions, context/memory policy,
epistemic style, authority limits, budget, communication edges, and task
selection policy. Its phenotype is the work it reliably performs in response to
institutional demand.

Stable specializations may emerge and later be named, but names are compressions
over demonstrated behavior—not permanent source-code role classes. V2 may seed
an adversarial challenger or an integration steward because those are known
useful attractors. It must also be able to test whether they help on a defined
problem distribution and retire them when they do not.

The society-level genome is more important than any individual actor:

```text
actor configurations and replication/diversity policy
communication and context edges
authority/escalation and disagreement protocol
graph schema and trace-compression policy
queue/WIP allocation and experiment budgets
evaluator and outcome-follow-up policy
knowledge propagation and retraction policy
```

Every organization experiment is itself a graph node with a parent
configuration, matched cases, pre-registered comparison criteria, resource
budget, and an independently preserved result. V2 must protect diversity:
short-term task completion cannot erase contrarian, exploratory, or
counterexample-seeking configurations merely because their value is delayed.

## Evaluation as a process

For XSH, quality has real dimensions that cannot responsibly be flattened into
a universal score: semantic coherence, correctness, compatibility, explicit
boundaries, performance, implementation simplicity, handbook learnability,
agent fluency, and future language optionality.

V2 evaluates consequential changes through an argument-and-evidence process:

```text
proposal -> independent analysis -> implementation/prototype ->
adversarial challenge -> discriminating evaluation -> decision ->
short-horizon outcome -> delayed outcome -> retrospective
```

The exact circuit is selected by problem class. A one-line parser bug may use a
fast patch/test/replay circuit. A new language semantic may require competing
prototypes, compatibility analysis, adversarial reasoning, and delayed
ecosystem observation. The circuit selection is observable and experimentally
mutable; it is not an unexamined CTO convention.

## XSH as the policy and execution medium

V2 should use XSH from the beginning wherever durable workflow semantics are
not involved. The goal is not aesthetic self-hosting. It creates a high-value
closed loop:

```text
better XSH representation and tooling
  -> clearer institutional records and executable experiments
  -> better evidence about XSH and the organization
  -> better language and institutional machinery
```

XSH owns reproducible experiment definitions, policy variants, bounded
executors, evaluator programs, causal questions, and human-readable
explanations. It invokes the workflow kernel through a narrow typed protocol
and consumes declared projections; it does not emit raw SQL, implement retries
or leases, decide a transition by inspecting files, or parse logs back into
state. The Rust kernel owns storage migrations, transactions, state-machine
validation, recovery, replay audit, and access enforcement. This split puts
each language where it is strongest.

The first XSH modules should use typed paths, explicit errors, structured
protocol boundaries, capability-aware process calls, and stable content
identifiers. Where XSH lacks an expression needed to describe an experiment or
policy clearly, that deficiency becomes a first-class Question node—not an
excuse for hidden host-language machinery or a reason to migrate workflow
semantics out of the database.

The product boundary remains real: V2 may create a product implementation only
after an authorized Decision node enters the product-change circuit. The
institution must never use self-reference to evade review, budgets, tests, or
lineage.

## Cleanroom boundary and migration

V2 begins under a new top-level namespace, for example `v2/`, with no imports
from V1 control-plane modules. Its Rust workflow kernel has a V2-owned schema
and migration history, initially backed by SQLite; XSH reaches it only through
the versioned protocol. Reuse is allowed only through a small, documented
adapter boundary around trusted mechanisms after a direct contract test proves
it safe. There is no compatibility controller and no conversion of all
historical tickets into V2 nodes.

V1 becomes a frozen observational corpus:

- its runs, raw sessions, reports, tickets, replays, and failed closeouts are
  source evidence for V2 questions;
- each imported historical episode is explicitly curated into V2 nodes, with
  links back to immutable V1 artifacts and a statement of what information was
  unavailable or lost;
- V1's ticket and throughput status may be displayed as historical attributes,
  never as V2 state; and
- no paid V2 work begins until the V2 database kernel, event/replay audit,
  artifact-reference contract, replay manifest, and access-control tests exist.

This avoids a fake rewrite in which old assumptions survive under new names.

## The first V2 vertical slice

The first operational slice must be ambitious in architecture but narrow in
world scope. It should demonstrate the entire learning loop on one meaningful
XSH question, not prove another toy program can be written.

Suggested seed question:

> Which XSH boundary failures most reduce an agent's ability to make a correct,
> idiomatic change, and which intervention improves that capability without
> increasing language or compatibility debt?

The slice must contain:

1. an Objective and Question with a falsifiable scope;
2. at least two competing hypotheses, including one that predicts a factory or
   documentation intervention is preferable to a language feature;
3. a reproducible evidence import from V1 plus a fresh discriminating
   experiment;
4. a preserved Conflict when the evidence does not settle the tradeoff;
5. a Decision packet with predictions, dissent, blast radius, and revisit time;
6. at most one bounded XSH/product implementation, if the decision warrants it;
7. a short-horizon replay and a scheduled delayed outcome; and
8. a Retrospective that records whether the selected organizational circuit was
   itself appropriate.

Success is not “one commit.” Success is a complete, queryable, replayable
episode whose later evidence can revise both the product decision and the
institutional process that produced it.

## Organizational evolution program

V2 must not claim recursive improvement merely because it edits a prompt. It
earns that label through controlled comparison.

### Stage 1 — establish the laboratory

Build the typed graph store and transactional event log in the Rust workflow
kernel, alongside content addressing, capability model, experiment-manifest
records, and rebuildable projections. Build the XSH experiment and policy
surface against its typed protocol. Import a deliberately small, representative
V1 episode set. State-machine and fault-injection tests prove append-only
history, idempotency, authority, identity, recovery, replay inputs, budgets,
and that a projection cannot mutate graph facts; native XSH tests prove its
policy and protocol-boundary behavior.

### Stage 2 — establish causal episodes

Run the first vertical slice. Learn whether the graph captures enough causal
structure to explain a later decision without raw-session archaeology. Tighten
the schema only where evidence shows a missing field prevents a useful query or
replay.

### Stage 3 — compare organizational circuits in shadow

Use stratified historical episodes and held-out current questions. Run two or
more candidate circuits under equal capability and budget envelopes without
revealing the historical outcome: for example, implementation-first versus
independent-hypothesis-plus-challenge. Compare decision quality, calibration,
evidence coverage, reversals, cost, and later outcomes. Preserve non-dominated
configurations rather than declaring a single winner prematurely.

### Stage 4 — promote bounded institutional mutations

Permit a successful circuit to govern a defined problem class. Every promotion
has a scope, counterfactual baseline, rollback, diversity guard, and expiry or
revalidation condition. Product safety remains in the trusted substrate.

### Stage 5 — let the language and institution co-evolve

Only after the preceding stages are credible may V2 treat XSH improvements as
candidate improvements to institutional expressiveness, then measure whether
they improve the institution's own decision and experiment productivity under
matched conditions. This is the first meaningful self-referential evaluation.

## Fitness without a lie

V2 records a fitness vector and a decision argument, not a scalar reward:

```text
product: correctness, semantics, compatibility, performance, simplicity
institution: discovery yield, calibration, propagation correctness,
             reversal rate, evidence coverage, cost, diversity, latency
future capacity: ability to express, test, review, and safely modify XSH
```

Constraints can disqualify a candidate. Pareto comparisons can retain several
useful configurations. A human or an explicitly authorized governance circuit
resolves irreducible tradeoffs and records why. Later outcomes test that
judgment. The weights themselves are objects of future organization experiments,
never invisible constants.

## Non-negotiable anti-patterns

V2 must reject these temptations from the outset:

- renaming V1 tickets as graph nodes without preserving hypotheses, conflict,
  predictions, and outcomes;
- measuring its health by agent activity, ticket count, commit count, or a
  synthetic scalar alone;
- allowing a mutable evaluator to certify its own mutation;
- propagating a one-off agent insight globally without scope and confidence;
- replacing preserved disagreement with manager prose or averaged scores;
- hard-coding a permanent CEO/director/engineer taxonomy;
- treating raw model transcripts as the institutional memory;
- importing V1 controllers through a compatibility layer because it is cheaper
  than confronting their assumptions; or
- using self-reference to bypass product safety, reproducibility, or human
  governance where it remains required.

## What "ambitious" means here

Ambition is not starting with unbounded agent swarms or autonomous product
merges. It is committing from day one to the full causal representation,
replayable organization experiments, checked propagation, and a hard boundary
between mutable intelligence and immutable experimental physics.

The first V2 implementation may run few actors, but it must already be capable
of answering the questions that V1 could not:

- What did the institution believe before it acted, and why?
- What alternatives and dissent did it preserve?
- Which evidence changed the decision?
- What did it predict, what later happened, and what did it learn?
- Which organizational configuration produced that result?
- Under what comparable conditions should that configuration be reused,
  challenged, mutated, or retired?

If V2 can answer those questions faithfully in XSH, the language and the
institution have a credible path to cumulative, self-directed improvement.
