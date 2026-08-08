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

Session: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786141413750/phases/03-eval/workers/eval-worker/task-render-1/session.jsonl`

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

- Semantic capability existing XSH cannot express: none — `map.empty()` already
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
- Evidence and falsification replay: `task-render` replay plus a second
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
