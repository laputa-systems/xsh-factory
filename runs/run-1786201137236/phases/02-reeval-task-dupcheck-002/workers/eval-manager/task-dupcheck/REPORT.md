# Eval-manager report

## Result

pass

## Effort metrics

Candidate-linked replay of `task-dupcheck-002` (pre-merge validation) for a
single fresh trial (controller executed `1` trial).

- Worker `task-dupcheck-1`: 37 assistant turns, 48 tool calls (38 bash, 3
  read, 3 edit, 4 write), 3 tool errors (all resolved), 1 user message, 1 stop.
- Session span: 217,713 ms (~3.6 min); agent wall 219,152 ms.
- The worker read the reference (agents.md + handbook.md) first, then ran
  `xsht api` discovery before writing `dupcheck.xsh`. No repeated bare
  exploration loops; the solution converged in a handful of write/edit/check
  cycles. Worker friction was ordinary and self-resolved (see Tool-error
  findings and Observation classification).
- Provider telemetry present: retry_count 0, retry_failures 0, provider_errors
  empty, response latency fields 0. No external-health latency signal.
  Correctness, not wall time, is the gate here, and correctness passed.

Per-trial breakdown:
- Trial 1: 37 turns, 3 tool errors, 217.7 s span, result pass.

## Usage and cost

Provider: openrouter/deepseek/deepseek-v4-flash-0731 (single model).

Bucket tokens (worker report):
- input 64,349; output 7,938; cacheRead 474,048; cacheWrite 0.
- provider_total_tokens 546,335; bucket total 546,335 (consistent).
- reasoning_tokens 3,311 (provider-reported; subset of output).

Cost:
- input $0.00579141; output $0.00142884; cacheRead $0.008532864;
  cacheWrite $0; provider total $0.015753114.
- budget $0.50; no budget failures; unknown_costs 0.

Aggregate cost for the run (phase `data.cost`): $0.015753114 across 1 worker.

## Thinking evidence

Worker `thinking_blocks`: 26. Provider reported reasoning tokens: 3,311
(qualitative + quantitative). Thinking text (in `session.jsonl.bz2`) shows the
worker reasoning about which API to consult (`api:fs.files`, `method:Path.*`,
`search:hex`, `search:group`), the hidden default, the content-hash boundary,
and the exact two-space output layout. Thinking correlated with the fixes
that produced a passing artifact (positional `fs.files(root, false, false,
[], true)`, `hash.sha256(path)?`, expression-position string build, `fp"..."`
lint fix). Reasoning tokens were provider-reported for this run.

## Tool-error findings

Three nonzero Pi tool results, all from worker `task-dupcheck-1`, all resolved
by the worker within the session. No tool errors in any manager session.

1. Turn 5 — `xsht api: invalid API query 'api:method.Digest.hex'; expected
   NAME.MEMBER`. The worker used the non-canonical `api:method.X.Y` prefix;
   the correct form `method:Digest.hex` was already covered by the handbook
   and was later used successfully. Self-resolved discovery friction.
2. Turn 11 — same invalid-prefix pattern: `api:method.Path.read_bytes` and
   `api:method.Path.sha256` rejected. Worker recovered by reading the summary
   index and using `method:Path.read_bytes`, which returned exact. Self-resolved.
3. Turn 25 — `err[parse.expected-expression]` at `dupcheck.xsh:15`:
   `let line = $r.digest + "  " + $r.path` used command-word `$var` syntax in
   an expression position. Worker fixed to `r.digest + "  " + r.path` (the
   handbook's expression-position guidance), and output then matched the
   oracle exactly.

All three are accounted for. They are ordinary, handbook-covered discovery
and syntax friction, not product defects or handbook gaps.

## Timing evidence

Evaluator `run.json` candidate/oracle wall times per case (ns):
- public 11,349,409 / 12,389,996
- hidden_empty 13,575,999 / 12,610,788
- hidden_nested 12,316,871 / 13,228,374
- hidden_three 12,463,246 / 13,451,499
- hidden_spaces 12,773,872 / 15,299,880
- hidden_many 12,092,287 / 11,882,577
- hidden_none 11,417,826 / 12,702,580
- hidden_missing candidate 11,749,327 (exit 3) / oracle 10,885,742 (exit 1)

All cases byte-exact; `all_exact = true`; `hidden_missing` exits nonzero with
no stdout on both sides. This eval has no strict candidate/oracle timing gate;
both sides finish in ~11–15 ms per case. Timing is diagnostic only and shows
no concern. Provider telemetry shows zero retries, so the ~3.6 min session
span is agent work (discovery + validation), not provider latency.

## Observation classification

- Correctness: pass — all eight fixture cases byte-exact against the oracle,
  including hidden traversal, three-way duplicates, spaces in paths,
  cross-group digest-first ordering, empty tree, and the missing-root
  failure control. Evidence: `run.json` `correctness.all_exact = true`,
  `restrictions.passed = true`, `protocol.review_ok = true`.
- Candidate acceptance surface exercised: the worker read
  `xsht api api:fs.files` and `api:fs.walk`, which in this candidate build
  render the contract "Function arguments are positional-only; parameters
  marked `= default` may be omitted, but cannot be supplied as `name =
  value`." The worker then used positional `fs.files(root, false, false,
  [], true)` and never attempted a `name = value` call (no such parse error
  in this session). This directly satisfies ticket acceptance criteria 1, 2,
  and 3. Candidate-linked replay is a pass.
- Worker friction (not product/handbook signal, ordinary noise / reusable
  warning only): (a) the `api:method.X.Y` discovery-prefix stumble is already
  contradicted by the handbook's documented `method:X.Y` form, so it is not a
  handbook gap; (b) the `let line = $r.digest + ...` expression-position parse
  error is likewise already covered by handbook print/expression guidance. The
  worker recorded these in `review.md` as `xsht friction`, which is honest but
  does not rise to a durable handbook candidate or product ticket.
- Commit bookkeeping: the assignment lists candidate XSH commit
  `b9cc3ffc6425b365a172c5a897ed9684db235487`, while the phase `report.json`
  records `xsh_commit` `c77b01a3e2fb676cc57cdeddbb7575be7723aa32`. The running
  build demonstrably contains the ticket's fix (positional-only contract text
  on `fs.files`/`fs.walk`), so the acceptance surface was exercised; the
  numeric discrepancy is flagged to the controller for provenance, not treated
  as a blocker by an un-inspectable worktree.

## Handbook decision

Unchanged. No durable handbook gap was observed: the worker's three tool errors
were all already covered by existing handbook guidance (`method:X.Y` discovery
form; print/expression `$var` vs bare-name position; positional-only
defaulted-parameter behavior is now rendered by the candidate build). The
candidate file `lineage/handbook-candidate.md` is a byte-for-byte copy of the
approved snapshot. No new handbook claim to promote or replay here.

## Tickets created

None. This run was a candidate-linked pre-merge validation of the existing
`task-dupcheck-002` ticket; the fix was exercised and passed. No new strong,
reproducible product or handbook observation warrants a new ticket. Pre-existing
manager ticket files were not modified.

## Post-merge decisions

None. The reconciler found no merged tickets for this cycle; there are no
post-merge acceptance assignments to record. `task-dupcheck-002` remains a
pre-merge candidate under review (not merged, not dispatched).

## Next replay

Promote/merge `task-dupcheck-002`'s positional-only `xsht api` contract
rendering, then run the ticket's stated post-merge evaluation against the
merged build: replay `task-dupcheck` plus a second eval that calls a
defaulted-parameter module function (independent `task-histogram` is the
nominated check) to confirm no agent attempts `name = value` after reading the
rendered signature and that existing positional calls (e.g.
`fs.files(root, false, false, [], true)`) remain green. That is the
falsification check that turns this candidate into a trusted general claim.

## North-star impact

This candidate replay advances the north-star ergonomics and trust objectives
directly: `xsht api` no longer renders defaulted-parameter signatures in a way
that invites invalid `name = value` call syntax. The worker read the reference,
saw an honest positional-only contract, and wrote the canonical positional
spelling without a wasted named-argument attempt — the exact repeated-discovery
class the ticket targeted. A general, honest tooling boundary reduces agent
guesses across every eval that calls defaulted-parameter module functions
(fs.files, fs.walk, env helpers). Replay of a second defaulted-parameter eval
after merge will confirm the claim generalizes beyond task-dupcheck before the
handbook or product surface is trusted factory-wide.
