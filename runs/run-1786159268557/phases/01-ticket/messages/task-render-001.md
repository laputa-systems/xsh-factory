# Controller-assigned engineer ticket

This is an immutable controller assignment for one implementation worker.
The controller, not the worker, selected the ticket, snapshot, worktree, and
branch.

## Assignment authority

- Ticket ID: `task-render-001`
- Ticket snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786159268557/phases/01-ticket/tickets/task-render-001.md`
- Ticket snapshot SHA-256: `b0630cd068bca890228a14e4054b8a1411202bab7690fa365fb7d767ff9c9b08`
- Dedicated XSH worktree: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786159268557/task-render-001`
- Branch: `factory/task-render-001/1786159269627`
- XSH base commit: `ac37f8137c7f8c902abb88621f891fc01f27d375`
- engineer report: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786159268557/phases/01-ticket/workers/engineer/task-render-001/REPORT.md`
- Factory root: `/Users/josh/d/laputa-systems/xsh-factory`
- Run evidence root: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786159268557/phases/01-ticket`

You are an implementation worker, not a ticket selector. Implement only the
ticket identified above and inlined below. Do not search for open tickets,
choose another ticket, or broaden this assignment. Do not create or modify a
ticket assignment. If the ticket ID, worktree, branch, or snapshot is missing
or conflicts with the runner's `FACTORY_TICKET_ID` or `FACTORY_WORKDIR`, stop
and report the assignment problem; do not guess.

The snapshot path is retained for provenance. The inlined snapshot below is
the controller's authoritative task input, so no ticket-discovery read is
required. Relative links in that snapshot resolve from the factory root above,
not from the XSH product worktree; use exact paths under that root if linked
evidence needs to be consulted.

## Ticket snapshot

<!-- CONTROLLER_TICKET_SNAPSHOT_BEGIN -->
# Ticket task-render-001

## Status

Approved.

## CTO decision — throughput validation cycle 2026-08-07

- Decision: Approved for one bounded implementation and linked-replay cycle.
- Basis: The source `task-render` trial passed correctness and restrictions,
  and the independent `task-dupcheck` evidence corroborates the same Map
  construction discoverability gap. The cycle's independent `task-dupcheck`
  eval supplies the required second map-building signal while the linked
  `task-render` replay gates delivery.
- Scope: API-reference indexing/documentation only; no new Map syntax or
  runtime semantics.
- Evidence: `runs/run-1786141413750/phases/03-eval/workers/eval-worker/task-render-1/run.json`
  and `runs/run-1786128115649/phases/03-eval/workers/eval-worker/task-dupcheck-1/run.json`.

## CTO review

- Review cycle: ramp-04 discovery review, 2026-08-07.
- Decision: Deferred; do not approve or dispatch in the next eval-only cycle.
- Basis: The Map-construction discoverability observation is strong and
  reusable, but it needs replay against `task-render` and a second
  map-building eval before paid implementation is admitted.
- Admission: Keep `Open.` and preserve the proposed tooling-only fix; require
  the existing API-surface justification and cross-eval evidence at the next
  review.

## Change target

- `product`

Factory changes are CTO-owned. Do not create a factory-target ticket for
engineer dispatch; report the infrastructure change to the CTO instead.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-render`
- Shared handbook lineage: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786141413750/phases/03-eval/lineage/handbook-approved.md`
- Manager run: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786141413750/phases/03-eval/workers/eval-manager/task-render/REPORT.md`
- Executor run: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786141413750/phases/03-eval/workers/eval-worker/task-render-1/run.json`
- XSH baseline commit: `a248267612439dfcfa203fba583ac3e95d37f70c`

## Observation

An agent building a string-keyed `Map[Str]` from parsed text cannot discover
how to obtain a `Map` value in the first place. `xsht api method:Map.*` exposes
only Map instance methods (`get`, `has`, `keys`, `len`, `push`, `remove`,
`set`, `values`) and no constructor. The `{}` literal resolves to a Record,
whose `.set` is rejected (`err[check.unknown-method]: unknown method `set` on
Record`). The only way to create an empty map is the module function
`map.empty() = Map[Any]`, which is indexed under the `map` module in the
summary, not under the `Map` type.

## Evidence

Session: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786141413750/phases/03-eval/workers/eval-worker/task-render-1/session.jsonl.bz2`

The worker probed five construction forms before locating `map.empty()`:

- `let m = {}` then `m.set(...)` → `unknown method `set` on Record`
- `Map.from([])` → `unresolved name`
- `map([])` → `unresolved pure function call`
- `{}::Map` and `{:}` → `parse.expected-term` / `expected record field`
- `Map([])` → `unresolved pure function call`
- `grep -ni "map" /tmp/sum.txt` → line 240 `map (1 items)`, then
  `xsht api api:map.empty` → `module.map.empty` (`map.empty() -> Map[Any]`).

`search:map` at this point returned only `language.stream.map`,
`method.Map.*`, and stream map stages — no constructor. The worker review
(`review.md`, "XSH language proposals" and "xsht friction") records the same
two findings. The worker otherwise passed (evaluator `run.json` `exact: true`,
restrictions passed, `check`/`fmt`/`lint` clean).

## Diagnosis or hypothesis

This is a general XSH ergonomics and tooling gap, not task-specific confusion.
Map construction from parsed text is a core systems-glue idiom (dupcheck,
histogram, envcfg-style config builds, template rendering), so every eval that
assembles a `Map` will pay the same discovery cost. The root cause is split
across two surfaces: (1) the language offers no obvious Map constructor — the
`{}` literal is a Record and there is no `Map(...)` / map-literal spelling — and
(2) `xsht api` does not cross-index the `module.map.empty` constructor under
the `Map` type, so type-first discovery dead-ends at the instance-method list.

## North-star impact

Resolving this improves learnability and ergonomics for the core "fold parsed
lines into a typed Map" shape that XSH is meant to carry. The largest, most
direct win is the tooling surface: having `method:Map.*` or the summary point
to `map.empty()` would let a type-directed agent construct the map without
five failed probes. A dedicated map-literal or documented `Map` constructor
would make the intended path self-evident. Evidence of generalization: another
map-building eval (task-dupcheck, task-histogram, task-jsonfilter) should no
longer need the exploratory `grep summary | map.empty` detour and should build
its map on the first attempt.

## Proposed XSH change

Smallest surface first: index the `module.map.empty` constructor beneath the
`Map` type in the `xsht api` summary and in `method:Map.*` / the Map
type-documentation entry, so a type-first agent finds how to construct a Map.
If a native-tests/API-surface change is warranted, add a canonical
"map construction" doc entry that states `{}` is a Record and that an empty
Map is created with `map.empty()` and grown with `Map.set`.

## API-surface justification

- semantic capability existing XSH cannot express: none — `map.empty()` already
  constructs an empty string-keyed Map. The gap is discoverability/ergonomics,
  not missing capability.
- Closest existing spelling and why it is insufficient: `{}` compiles but yields
  a Record, so `{}` `.set` fails at check time; `Map(...)` and `map(...)` are
  unresolved. There is no type-directed way to learn `map.empty()` from the Map
  type's own index.
- Lower-surface alternative: the primary fix is an API-registry/`xsht api`
  indexing and documentation change (cross-index `map.empty` under `Map`), which
  needs no new runtime/type surface. A second, larger option is a dedicated
  map-literal or `Map` constructor; that is not required to remove the observed
  friction.
- Implementation/maintenance cost: API-registry index entry plus canonical
  documentation for `map.empty` and the Record-vs-Map `{}` distinction; runtime
  and checker are unchanged for the minimal option.
- evidence and falsification replay: `task-render` replay plus a second
  map-building eval must construct their Map on the first attempt (no
  `grep summary | map.empty` detour) after the fix; otherwise the indexing
  change did not generalize.

## Proposed XSH change

See "Proposed XSH change" above: cross-index `module.map.empty` under the `Map`
type in the `xsht api` registry and add the canonical "create a Map with
`map.empty()`; `{}` is a Record" documentation/tooling note.

## Acceptance criteria

- `xsht api summary | grep -A20 Map` includes a constructor reference to
  `module.map.empty`.
- An agent resolving `method:Map.*` for how to build a Map finds `map.empty()`
  without probing the `map` module summary.
- `task-render` and one other map-building eval replay with the worker building
  the map on the first attempt and `check`/`fmt`/`lint` clean.
- Behavioral contract unchanged: `{}` remains a Record; `map.empty()` remains
  `Map[Any]`.

## Scope and non-goals

- Primary: `xsht api`/API-registry indexing and canonical documentation so Map
  construction is discoverable.
- Non-goal: adding a new map-literal syntax or `Map` constructor in this ticket
  unless the index change proves insufficient.
- No change to Map runtime semantics or to `Str`/stream behavior.

## Post-merge evaluation

Replay `task-render` on the merged XSH commit; accept only if the Map is built
on the first construction attempt and the byte-exact oracle comparison still
passes across the edge cases. Falsification: if a worker still requires
the `grep summary | map.empty` detour, reject and re-scope.

<!-- CONTROLLER_TICKET_SNAPSHOT_END -->

## Factory context required before coding

The factory documents below are outside the XSH worktree. Before coding, use
the `read` tool on each exact absolute path. This is required so the session
JSONL proves that the worker consumed the current factory guidance:

- North star: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786159268557/phases/01-ticket/guidance/NORTH-STAR.md`
- Approved handbook snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786159268557/phases/01-ticket/guidance/handbook.md`
- Handbook candidate: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786159268557/phases/01-ticket/lineage/handbook-candidate.md`

The approved snapshot is a run-scoped copy of the checked-in handbook. Read it
as an input and never edit it or the checked-in handbook. If this ticket
produces a reusable lesson, add it to the run-scoped candidate path above; the
candidate is shared review input and is promoted only after CTO review. If no
handbook improvement is justified, leave the candidate unchanged.

Then use the `read` tool on the product worktree's exact guidance files:

- Product agent guide: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786159268557/task-render-001/AGENTS.md`
- XSH rationale: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786159268557/task-render-001/docs/CHAPTER-01-why-xsh.md`

## Implementation contract

Work only in `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786159268557/task-render-001` on branch `factory/task-render-001/1786159269627`. Do not edit XSH main, the
factory checkout, the approved handbook snapshot, or the ticket diagnosis.
Make the smallest general XSH language, tooling, test, or
canonical-documentation change supported by the ticket. Run the narrowest
relevant checks, commit the product change on this branch, and leave the
worktree clean.

For ordinary product tickets, use `xsht lint --fix` for linting, then rerun the
relevant checks. If this ticket specifically targets lint, parsing, or
diagnostics, preserve the behavior under test and follow its explicit
acceptance procedure instead of auto-fixing away the evidence.

The controller has staged a fail-closed `not-ready` report at
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786159268557/phases/01-ticket/workers/engineer/task-render-001/REPORT.md`. Complete that file in place; do not spend turns
reconstructing its headings. Keep `## Result` as `not-ready` until the
acceptance checks, commit, and clean-worktree validation are complete.

Write `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786159268557/phases/01-ticket/workers/engineer/task-render-001/REPORT.md` with these exact headings:

```markdown
## Result

ready-for-review

## Branch

<branch name>

## Commit

<commit hash>

## Files changed

<short list>

## Tests

<commands and results>

## North-star impact

<how this improves XSH or agent use>

## Remaining risks

<known limitations, or None.>
```

Change `## Result` to `ready-for-review` only when the branch is committed, the worktree is
clean, and the relevant checks passed. Do not merge the branch or update the
ticket status; the deterministic controller records it for CTO review.
