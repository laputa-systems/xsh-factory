# Ticket task-envcfg-004

## Status

Approved.

## CTO review

- Review cycle: `pre-cycle-1785801503` (2026-08-03)
- Decision: Approved for the next two-engineer ticket cycle.
- Basis: The API reference forces repeated invalid queries and a full-index
  grep to answer a basic type-surface question; the evidence is reproduced
  across `Str`, `Path`, and `Regex`, with a small compatibility-preserving
  acceptance contract.
- Assignment boundary: Add a receiver-scoped member listing or an equally
  discoverable documented query while preserving exact lookups, `search:`, and
  `summary`; do not broaden into unrelated API or handbook changes.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-envcfg` (`evals/task-envcfg/EVAL.md`)
- Shared handbook lineage: `runs/run-1785733794880/phases/03-eval/lineage/handbook-approved.md` (approved `c7c9dd9a…`; candidate `f98a930a…` with one added enumeration sentence)
- Manager run: `runs/run-1785733794880/phases/03-eval/workers/eval-manager/task-envcfg/REPORT.md`
- Executor run: `runs/run-1785733794880/phases/03-eval/workers/eval-worker/task-envcfg-1` (trial 1)
- XSH baseline commit: `ea7dea2f2b436cce34262d7a02105cbb029243dd`

## Observation

`xsht api` has no per-type index query: bare receiver queries are rejected, so
an agent cannot enumerate a type's members without dumping the whole index and
grepping it. The task-envcfg worker needed to browse `Str`, `Path`, and `Regex`
methods and hit a wall of rejected forms before falling back to
`xsht api summary | grep`:

```text
$ xsht api method:Str
xsht api: invalid API query 'method:Str'; expected NAME.MEMBER

$ xsht api method:Str.
xsht api: invalid API query 'method:Str.'; expected NAME.MEMBER

$ xsht api type:Str
xsht api: invalid API query 'type:Str'; unknown selector kind 'type'

$ xsht api NAME.Str
xsht api: invalid API query 'NAME.Str'; expected KIND:VALUE

$ xsht api constructor:Path.parse_bytes
xsht api: invalid API query 'constructor:Path.parse_bytes'; unknown selector kind 'constructor'

$ xsht api api:Path.parse_bytes
query: api:Path.parse_bytes
status: missing

$ xsht api search:parse_bytes      # the only form that resolved
query: search:parse_bytes
status: exact
api: method.Path.parse_bytes
```

The worker then dumped `xsht api summary` to `/tmp/summary.txt` and grepped it
(turns 10–15, ~6 bash probes) to discover `Path.parse_bytes`, `Regex.matches`,
`Str` methods, and the `error` family. The review records the friction verbatim:
"`xsht api` accepts only exact `KIND:NAME.MEMBER` lookups (e.g.
`method:Str.lower`); there is no way to list every method of a receiver
(`method:Str.` and `method:Str` are both rejected). Browsing a type's full
surface required dumping `xsht api summary` and grepping the text output, which
is slow and easy to miss details on. An index query per type (e.g.
`method:Str`) would be easier than the whole `summary`."

## Evidence

- Worker session: `runs/run-1785733794880/phases/03-eval/workers/eval-worker/task-envcfg-1/session.jsonl.bz2` — turns 5–8 (`method:Str`, `NAME.Str`, `Str`, `type:Str`, `method:Str.` all rejected), turns 10–15 (`xsht api summary` + grep), turn 19 (the structured `constructor:Path.parse_bytes` / `api:Path.parse_bytes` / `constructor:Path` error), turn 20 (`search:parse_bytes` resolved).
- Worker review: `runs/run-1785733794880/phases/03-eval/workers/eval-worker/task-envcfg-1/review.md`, section `## xsht friction` quoted above.
- Structured tool error: `runs/run-1785733794880/phases/03-eval/report.json` `data.tool_errors` entry (worker turn 19) and worker `report.json` `tool_errors` entry: `xsht api: invalid API query 'constructor:Path.parse_bytes'; unknown selector kind 'constructor'` plus `api:Path.parse_bytes` status `missing`.
- Quantitative: trial passed 10/10 (`run.json` `correctness.all_exact: true`, `restrictions.passed: true`), so the gap did not block the eval; it cost the worker roughly turns 5–20 (~10 tool calls) of rejected discovery before `summary`/`search:` worked.

## Diagnosis or hypothesis

`xsht api` implements exact `KIND:NAME.MEMBER` lookups and a whole-index
`summary`, but no receiver-scoped index. The handbook teaches exact queries
("`xsht api method:Path.ext`", "`xsht api method:Str.lower`") and overview
prefixes ("`xsht api module:fs`", "`xsht api language:stream`") but never says
how to enumerate a type's methods, so every agent that needs to browse a type
first tries `method:Str` / `method:Str.` / `type:Str` and is rejected, then
falls back to a slow full-index dump. This is a general discoverability
problem, not an envcfg recipe: any eval or script that needs the surface of a
receiver (`Str`, `Path`, `Regex`, `Result`, …) pays the same rejected-query
loop. It is distinct from the empty-signature defect (task-ecount-001, about
`language:stream.*` payloads) and from the missing builtin (task-tags-002,
about `print`); this ticket is about the absence of a per-type index query.

## North-star impact

The north star asks for fewer repeated discoveries and a live reference that is
the source of truth. A reference that cannot answer "what methods does `Path`
have?" except by dumping the entire index forces trial-and-error discovery —
the exact friction the factory exists to remove. A per-type index query (e.g.
accept `method:Str` as "list members", or add a documented `type:`/`index:`
selector) would turn a ~10-turn browse into a one-shot query, in every future
eval that touches a receiver type. Evidence of generalization: after the
change, a replay of any eval (task-envcfg, task-tags, task-ecount) should show
the worker resolving a type's member list from one `xsht api` query instead of
`summary | grep`.

## Proposed XSH change

Smallest candidate, one of:

1. Accept `method:Str` (and other bare `KIND:NAME` receiver forms) as an index
   query that lists that type's members with one-line signatures, or
2. Add a documented `type:Str` selector that returns the same member list, or
3. At minimum, when a bare receiver is rejected, emit a constructive hint:
   `to list a type's members use 'xsht api summary'` (or `search:NAME` for an
   exact name).

Prefer (1): it matches the agent's natural spelling of "list Str methods" and
removes the need to remember a second selector.

## Acceptance criteria

- `xsht api method:Str` (or the documented replacement selector) lists `Str`
  methods without error; `method:Str.lower` still resolves the exact member.
- `xsht api search:parse_bytes` and `xsht api summary` continue to work
  (regression).
- A replay of `task-envcfg` on the merged change shows the worker resolving
  `Path.parse_bytes` / `Regex.matches` / `Str` members from one index query,
  with no rejected `method:Str` / `type:Str` / `constructor:Path` probes in
  the session, and still passes all 10 correctness cases byte-for-byte.

## Scope and non-goals

- No change to exact-lookup semantics, signatures, or runtime behavior.
- Not an envcfg shortcut; the index query must work for every receiver type.
- Does not cover empty `language:stream.*` signatures (task-ecount-001) or the
  missing `print` entry (task-tags-002); those remain separate tickets.

## Post-merge evaluation

The `task-envcfg` eval-manager will run a controlled replay against the merged
XSH commit using the current approved handbook lineage, verify the worker
resolves a type's member list from one `xsht api` index query, confirm all 10
oracle cases still pass, and record acceptance or rejection in that run's
manager report.
