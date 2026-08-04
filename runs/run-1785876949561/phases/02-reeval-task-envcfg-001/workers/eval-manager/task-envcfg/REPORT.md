# Eval-manager report

## Result

pass

## Effort metrics

Trial 1 (worker `task-envcfg-1`, the only configured trial; one-trial plan):
- assistant turns: 24 (1 user message, 23 tool-use turns, 1 stop)
- tool calls: 30; tool results: 30; tool errors: 0
- tool mix: bash 22, read 3, write 2, edit 3
- session span: 136,615 ms (agent wall 138,088 ms)
- worker friction: minimal. The agent read `/work/task.md`, `agents.md`, and
  the handbook, then discovered the correct env/fs API surface through
  `xsht api`. It twice probed unavailable string methods (`search:is_empty`,
  `search:isEmpty` -> `status: missing`) and made one malformed `xsht api`
  query (`language.core.path-literals` -> `invalid API query`), recovering on
  the next probe. It hit one `||` parse error and self-corrected to `or`
  (word form). No repeated exploration or churn beyond that.

## Usage and cost

Trial 1 (aggregate = whole run):
- input tokens: 19,576; output tokens: 5,658; cacheRead: 260,928;
  cacheWrite: 0; bucket total: 286,162; provider total: 286,162 (match).
- reasoning tokens: 2,621 (provider-reported; subset of output).
- cost: input $0.00176184, output $0.00101844, cacheRead $0.004696704,
  cacheWrite $0, total $0.007476984. Budget $0.50, budget breach: none.
- Twelve thinking blocks (qualitative); reasoning-token count reported by
  provider.

## Thinking evidence

The worker report records 12 thinking blocks and 2,621 provider-reported
reasoning tokens. Thinking text in `session.jsonl.bz2.bz2` shows the agent reasoning
about `env.get_or` absence-vs-empty semantics, byte-exact decimal validation,
preserving the raw port string rather than converting with `env.int`, and
adopting `fail(...)?` for the deliberate failure control. Reasoning is
qualitative evidence and is consistent with correct final behavior.

## Tool-error findings

None. The structured `tool_errors` arrays in the phase `report.json` and the
worker `report.json` are both empty, and the session JSONL contains zero
`isError: true` tool results. The `xsht api` discovery misses
(`search:is_empty`, `search:isEmpty`, and the malformed
`language.core.path-literals` query) all returned text inside successful
(`isError: false`) bash results and were not surfaced as tool errors; they are
recorded as recoverable agent discovery friction in Observation
classification.

## Timing evidence

Candidate vs oracle wall times per case are all ~11–13 ms and match the
oracle's magnitude (e.g. public candidate 11,104,739 ns vs oracle
12,326,151 ns; malformed candidate 12,029,860 ns vs oracle 12,644,732 ns).
This eval has no strict candidate/oracle ratio gate; both sides run in
milliseconds, so timing is diagnostic only. Provider telemetry shows zero
retries, zero provider errors, and no elevated latency signal; latency
attribution is therefore not an agent-efficiency concern.

## Observation classification

- Correctness: pass — all ten evaluator cases byte-exact (`all_exact: true`),
  including both failure controls (`hidden_malformed`, `hidden_empty_port`).
  The artifact uses `fail("CFG_PORT must be a non-empty decimal integer")?`
  and never writes a partial file on the failure controls. (reusable signal)
- Restriction: pass — `env.` referenced, forbidden subprocess boundary absent,
  stdout kept clean.
- Candidate re-evaluation: supported. The linked replay discovered `fail` via
  `xsht api language:core.fail`, adopted `fail(...)?`, and passed all ten
  evaluator cases, satisfying the ticket's acceptance gate. (reusable signal)
- Product/tooling: the merged `fail(message)?` deliberate-error primitive works
  as designed and is discoverable through `xsht api`. No new product defect.
- Handbook gap (reusable): the approved handbook's error section still says
  "this build has no generic `Error(...)` constructor ... use a typed
  conversion" — now stale. The agent had to discover `fail` via `xsht api`
  because the handbook did not mention it. (reusable handbook guidance)
- Harness/evaluator reporting quirk: `run.json` records
  `candidate_sha256 = e3b0c442...` (SHA-256 of the empty string) while the
  actual artifact envcfg.xsh hashes to `2ab1e31e...` with the verified final
  content. All byte-for-byte comparisons passed against the real content, so
  this is a reporting inconsistency, not a correctness defect. (noise / minor
  harness note; not ticket-worthy)
- Worker friction: two `xsht api search:is_empty/isEmpty` misses, one malformed
  `language.core.path-literals` query, and one `||` parse error — all quickly
  self-corrected; ordinary short-task discovery noise.

## Handbook decision

Provisional candidate staged. The standalone observation: teach the
deliberate-validation primitive. The approved handbook directs agents to
route a deliberate rejection through an unrelated typed conversion because
"this build has no generic `Error(...)` constructor"; that guidance is now
obsolete because `fail(message)?` exists and is discoverable via
`xsht api language:core.fail`. Candidate replaces those lines with a rule to
use `fail(...)?` for deliberate validation failure and to prefer it over a
sentinel typed conversion.

Staged at
`runs/run-1785876949561/phases/02-reeval-task-envcfg-001/lineage/handbook-candidate.md`
(one targeted edit; otherwise identical to the approved snapshot
`97c5d804...`). Global scope: the lesson applies to any eval gating on a loud
nonzero config/args-validation exit (e.g. `task-ecount`, `task-tags`), not just
`task-envcfg`. Promotion requires a later replay plus CTO approval.

## Tickets created

Zero. The candidate fix (XSH `fail` primitive) is already implemented in the
engineer worktree at commit `754fcba` and passes this replay; no new product
ticket is warranted. The single reusable handbook change is staged as a
candidate for replay, not a ticket.

## Post-merge decisions

No merged tickets were supplied by the reconciler (`none`); this run is a
pre-merge validation of candidate ticket `task-envcfg-001` (engineer commit
`754fcba`, clean worktree `factory/task-envcfg-001/1785876950208`).
Decision: accept / pre-merge supported. Evidence: the replay discovered `fail`
through `xsht api`, adopted `fail(...)?`, and passed all ten evaluator cases.
Do not mark the ticket merged and do not dispatch engineer; reconciliation
fills merge fields after the CTO merges the implementation branch.

## Next replay

Replay `task-envcfg` once more against the approved handbook that promotes the
`fail(...)?` deliberate-error lesson (after CTO approval), and optionally
replay `task-ecount`/`task-tags` to confirm the lesson generalizes across
validation-boundary evals. Also confirm the stale "no generic `Error`"
sentence is fully removed from the promoted handbook.

## North-star impact

This run validates the first-class deliberate-error primitive (`fail(message)?`
propagating through `?` with kind `validation`), which lets programs reject
malformed config clearly and exit nonzero without creating a partial file —
exactly the structured-error, expected-failures-visible goal in the north
star. It removes the opaque `parse_int` sentinel workaround that previously
contradicted the handbook's own guidance. The parallel handbook candidate
teaches this reusable lesson globally so agents stop rediscovering `fail` via
`xsht api` in every future validation eval.
