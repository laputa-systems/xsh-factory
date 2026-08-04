# Controller-assigned engineer ticket

This is an immutable controller assignment for one implementation worker.
The controller, not the worker, selected the ticket, snapshot, worktree, and
branch.

## Assignment authority

- Ticket ID: `task-envcfg-004`
- Ticket snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785801609594/phases/01-ticket/tickets/task-envcfg-004.md`
- Ticket snapshot SHA-256: `673a19f0c081eaa08f8247ab69d8cee667c90391c4b9ab51c63dd1f8d6116687`
- Dedicated XSH worktree: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785801609594/phases/01-ticket/worktrees/task-envcfg-004`
- Branch: `factory/task-envcfg-004/1785801610686`
- XSH base commit: `7c939dbedcd680e812aadfef2cb248da8e824360`
- engineer report: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785801609594/phases/01-ticket/workers/engineer/task-envcfg-004/REPORT.md`
- Factory root: `/Users/josh/d/laputa-systems/xsh-factory`
- Run evidence root: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785801609594/phases/01-ticket`

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

<!-- CONTROLLER_TICKET_SNAPSHOT_END -->

## Factory context required before coding

The factory documents below are outside the XSH worktree. Before coding, use
the `read` tool on each exact absolute path. This is required so the session
JSONL proves that the worker consumed the current factory guidance:

- North star: `/Users/josh/d/laputa-systems/xsh-factory/NORTH-STAR.md`
- Shared handbook: `/Users/josh/d/laputa-systems/xsh-factory/runtime/handbook.md`

Then use the `read` tool on the product worktree's exact guidance files:

- Product agent guide: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785801609594/phases/01-ticket/worktrees/task-envcfg-004/AGENTS.md`
- XSH rationale: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785801609594/phases/01-ticket/worktrees/task-envcfg-004/docs/CHAPTER-01-why-xsh.md`

## Implementation contract

Work only in `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785801609594/phases/01-ticket/worktrees/task-envcfg-004` on branch `factory/task-envcfg-004/1785801610686`. Do not edit XSH main, the
factory main tree, or the ticket diagnosis. Make the smallest general XSH
language, tooling, test, or canonical-documentation change supported by the
ticket. Run the narrowest relevant checks, commit the product change on this
branch, and leave the worktree clean.

The controller has staged a fail-closed `not-ready` report at
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785801609594/phases/01-ticket/workers/engineer/task-envcfg-004/REPORT.md`. Complete that file in place; do not spend turns
reconstructing its headings. Keep `## Result` as `not-ready` until the
acceptance checks, commit, and clean-worktree validation are complete.

Write `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785801609594/phases/01-ticket/workers/engineer/task-envcfg-004/REPORT.md` with these exact headings:

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
