# Eval-manager report

## Result

pass

## Effort metrics

Single trial (controller-configured count `1`), worker `task-envcfg-1` on
`openrouter/deepseek/deepseek-v4-flash-0731`.

- Assistant turns: 25 (1 x `stop`, 24 x `toolUse`)
- Tool calls: 31; tool results: 31; tool errors: 2
- Tool mix: bash 25, edit 1, read 3, write 2
- User messages: 1 (task prompt)
- Session span: 158,579 ms (worker `session_span_ms`); wrapper `agent_wall_ms`
  159,931 ms
- Worker friction: one one-turn wrong-path (`fail(...)`) plus one self-resolved
  local test-harness printf format error. No budget breach (0 failures). All
  three worker gates (`agent_state`, `evaluator_state`, `reporting_state`)
  `pass`; `classification: pass`.

The manager phase itself is the remaining deliverable: the controller staged
this `REPORT.md` fail-closed and left the handbook lineage candidate missing;
both are completed here.

## Usage and cost

Trial 1 (whole-run, provider-reported):

- input 23,619; output 9,718; cacheRead 288,576; cacheWrite 0
- bucket total 321,913; provider `totalTokens` 321,913 (consistent)
- cost.input $0.002125710; cost.output $0.00174924; cost.cacheRead
  $0.005194368; cost.cacheWrite $0; provider `cost.total` $0.009069318
  (unknown-cost count 0)
- budget allowance $0.50; spent $0.009069318 (~1.8% of budget)

Provider-reported reasoning tokens: 5,118 (a subset of `output`, not added to
totals). Cached-input dominance (288,576 of 321,913 tokens) reflects a long
handbook/API context reused across the session.

## Thinking evidence

- Thinking blocks: 17; provider reasoning tokens: 5,118.
- The transcript's thinking shows the decisive recovery: the worker queried
  `xsht api language:core.fail`, saw a documented `fail(message) ->
  Result[Unit, Error]` contract, tried `fail("...")?`, hit `unresolved pure
  function call`, then re-read the handbook's "no generic Error constructor /
  use a typed conversion" guidance and switched to the
  `"not-a-decimal-integer".parse_int()?` sentinel. It also reasoned about
  matching the oracle's strict `^[0-9]+$` semantics while preserving `007`
  (hence regex + raw-string output, not `env.int`).
- The thinking-block count and text are qualitative (the provider did report a
  reasoning-token figure, so it is recorded above).

## Tool-error findings

Both nonzero Pi tool results from the structured `tool_errors` arrays
(`tool_errors: 2`), fully accounted for:

1. **Turn 15** (`bash`): `xsht check`/`fmt`/`lint` all reported
   `err[check.unresolved-call]: unresolved pure function call` for
   `fail("CFG_PORT must be a decimal integer")?` at line 8. Cause: the
   `xsht api language:core.fail` reference advertises a callable `fail`
   rule that the pinned runtime rejects; there is no callable deliberate-error
   primitive. Worker recovered by switching to `parse_int` on a literal
   invalid string. Product-docs contradiction; already tracked (see
   `task-envcfg-001`).
2. **Turn 19** (`bash`): the worker's own local verification harness used
   BusyBox `printf ... %q\n`, which that printf rejects as `invalid format`,
   so every comparison line printed the format error and the whole command
   exited 1. Purely a worker-authored test-harness quirk; the worker rewrote
   the harness (rc + `od` comparison) and confirmed all cases match. Not a
   product defect, not reusable guidance.

No other nonzero results in the current worker/manager sessions.

## Timing evidence

Evaluator `run.json` candidate/oracle wall times per case (ns), all ~11-13 ms:

- public 12,415,606 / 11,447,475
- defaults 13,470,453 / 12,580,704
- partial 12,028,195 / 12,168,625
- empty 13,464,244 / 12,990,367
- spaces 12,132,080 / 11,956,897
- zero 13,057,082 / 13,248,224
- utf8 13,528,542 / 12,973,074
- debug_false 13,382,987 / 11,198,952
- malformed 11,334,131 / 11,642,451
- empty_port 11,750,127 / 13,395,821

No strict candidate/oracle ratio gate exists for this eval (both sides finish
in milliseconds); timing is diagnostic only, and there is no timing signal
here.

## Observation classification

- **Correctness:** pass. All 10 evaluator cases byte-exact, including both
  failure controls (`hidden_malformed`, `hidden_empty_port`) which exit
  nonzero and create no file; `restrictions.passed` (env referenced, no
  forbidden subprocess); `review.md` present with both required headings.
- **Product/tooling defect (general):** `xsht api language:core.fail`
  advertises a non-callable `fail` in the pinned build (`unresolved pure
  function call`). Reproducible in one targeted `xsht check`. This is a
  docs/implementation surface contradiction, an XSH ergonomics problem that
  generalizes to any validation boundary. It is already tracked verbatim by
  open ticket `task-envcfg-001` (same symptom, same sentinel workaround), so
  no new ticket is opened.
- **Worker friction (minimal, self-resolved):** the one-turn `fail(...)`
  detour (turn 15) and the BusyBox-`printf %q` harness error (turn 19). The
  `fail` detour is partly attributable to the api advertisement; a one-line
  handbook warning would remove it. The printf error is noise.
- **Harness/evaluator:** no evaluator or harness mismatch; the evaluator and
  oracle behaved as designed.
- **Noise:** the rc-value difference the worker saw (xsh 3 vs oracle 1 on
  failure) is expected — the task requires only a nonzero exit; evaluator
  treats both as pass.

## Handbook decision

Provisional candidate staged at
`runs/run-1785869846042/phases/01-eval/lineage/handbook-candidate.md`
(sha `e6f210b0f8f1fa2a605a5d30c145635b13e5e7743fd97974f2dbdce0f115d81b`),
an exact copy of the approved snapshot plus one added note in the
`Effects and errors` section warning agents that `xsht api language:core.fail`
advertises a rule the pinned build rejects as `unresolved pure function call`
and to stay on the typed-conversion failure path.

- General lesson: when an API reference advertises a construct that the
  runtime rejects, warn agents up front so they do not spend a
  `check`/`lint` round discovering it.
- Replay scope: this candidate should be replayed by the next
  `task-envcfg` cycle (and by any future config/validation-boundary eval)
  against the same pinned build. It is a mitigation; the durable fix is the
  product ticket (`fail`/deliberate-error primitive).
- Unchanged otherwise: the approved snapshot already correctly taught the
  `env.get_or` presence-vs-empty semantics, the `env.int`/`env.bool`
  non-strictness, and the parse-failure route, all of which this run
  validated. No eval-local handbook exists; the single factory handbook
  remains the one authority.

## Tickets created

Zero. The one strong reproducible observation (advertised-but-non-callable
`fail`) is already tracked by open ticket `task-envcfg-001`; creating a
duplicate would violate the one-strong-observation rule.

## Post-merge decisions

None. The controller reconciler found no merged ticket files for this cycle
(`none`); the two open tickets (`task-envcfg-001`, `task-tags-003`) remain
Open and are not post-merge acceptance assignments. No revert proposal.

## Next replay

- Eval: `task-envcfg` (single fresh trial), replaying the approved/candidate
  handbook lineage `runs/run-1785869846042/phases/01-eval/lineage/`.
- Post-merge check: when implementation of `task-envcfg-001`
  (callable deliberate-error `fail`/`Error` primitive) lands and is merged,
  replay `task-envcfg` against that commit and require `xsht api
  search:fail` discovery plus adoption of `fail(...)?` while all ten
  evaluator cases still pass — the ticket's stated acceptance gate.
- Falsification check: the handbook candidate is falsified if a replay shows
  the `fail(...)` warning misleads or is unnecessary (i.e., a callable
  `fail` appears in a later build without this note).

## North-star impact

This run validated that the single factory handbook transfers to the
environment/config surface: an agent discovered `env.get_or`, applied
presence-vs-empty defaults, and rendered a byte-exact file — all 10 cases
correct — showing practical, learnable, ergonomic XSH for a real
container/sysadmin shape. Two durable signals emerged: (1) the advertised but
non-callable `fail` is a trust-eroding doc/implementation gap that makes
expected failures opaque — exactly the "make expected failures visible"
north-star concern, tracked as `task-envcfg-001`; and (2) a concise handbook
warning can remove the one-turn `fail` detour until the product lands. Both
point at a cleaner, more composable validation boundary rather than a
task-specific trick.
