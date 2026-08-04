# Eval-manager report

## Result

pass

## Effort metrics

One fresh trial (trial 1) for `task-envcfg` against XSH commit
`7c939dbedcd680e812aadfef2cb248da8e824360`, approved handbook snapshot
`lineage/handbook-approved.md`, and the controller's `task-envcfg` worker
`task-envcfg-1`.

Per worker `report.json`: 39 assistant turns, 41 tool calls, 41 tool results,
2 tool errors, 1 user message; session span 260858 ms (~4.3 min), agent wall
262806 ms; stop reasons 1 `stop` + 38 `toolUse`. The worker's interactive
beginning (turning a natural-language config spec into XSH, then probing
integer validation semantics) drove the turn count; it settled on a valid
solution and self-corrected the two tool errors. No budget breach, and budget
is not a hard constraint measured against a numeric target here.

## Usage and cost

Worker `task-envcfg-1` provider-reported (deepseek-v4-flash-0731 via
OpenRouter):

- input 46568, output 16749, cacheRead 748608, cacheWrite 0 tokens;
  bucket total = provider total = 811925 tokens (match).
- reasoning 10948 tokens (subset of output; provider-reported).
- costs: input 0.00419112, output 0.00301482, cacheRead 0.013474944,
  cacheWrite 0; provider total 0.020680884 USD (~2.1% of the 0.50 budget).
- unknown_costs 0, malformed_lines 0.

Total for the run: 1 worker, 811925 bucket tokens, 0.020680884 USD. The heavy
`cacheRead` bucket reflects the long, tool-dense session re-reading the
handbook/`xsht api` output.

## Thinking evidence

33 thinking blocks recorded; provider reported 10948 reasoning tokens. The
thinking transcript shows the substantive exploration centered on the
CFG_PORT validation: the worker established (with probe scripts) that
`parse_int` is not a byte-exact validator — it accepts `-5`, `+5`, `1_0`
(→ 10), and `"5 "` (→ 5) — and that there is no generic error/fail/assert
constructor, before settling on the explicit digit-run check plus a
guaranteed-failing typed conversion (`"".parse_int()?`). This matches the
worker `review.md` sections `## XSH language proposals` and `## xsht friction`.
Thinking is qualitative evidence; the correct, byte-exact result is confirmed
independently by the evaluator's 10/10 case comparison.

## Tool-error findings

Current structured `tool_errors` arrays (worker `task-envcfg-1/report.json` and
phase `report.json`) contain exactly two failed Pi tool results, both recovered:

1. `bash` (turn 12): `xsht check` / `fmt` / `lint` exited 2 with
   `err[parse.unsupported-boolean-operator]: unsupported operator '||'` (use
   the word form `or`), plus cascading `expected-token` / `expected-expression`
   errors. The worker's first draft used `||`; the parser diagnostic is clear
   and the worker fixed it with ` or `. Ordinary early-draft friction, not a
   product defect.
2. `edit` (turn 25): `Could not find the exact text in /work/envcfg.xsh` — the
   target block had already been rewritten (the prior `||` fix via `sed`), so
   the exact `oldText` no longer matched. The worker re-read the file and
   applied the edit successfully on the next turn. Worker-tooling friction, not
   an XSH defect.

`xsht api` discovery in this session produced no nonzero tool results. Its
`search:` probes (`fail`, `assert`, `panic`, `unreachable`, `Err`) returned
`missing` or unrelated matches (5 `missing` statuses captured) while the worker
hunted for an error-construction primitive; those are ignored discovery
friction (isError `false`), not tool errors, and are classified under
Observation classification below.

## Timing evidence

No strict candidate/oracle timing gate for this eval (both sides finish in
milliseconds). Candidate vs oracle wall times per case (~11–15 ms each, e.g.
public 13.46/12.61 ms; hidden_malformed 11.56/11.33 ms; hidden_utf8
14.17/13.63 ms) are all in the same narrow envelope with no outliers. Timing is
diagnostic only and shows nothing unusual.

## Observation classification

- Ordinary draft friction (noise): the `||`→`or` parse error and the `edit`
  oldText mismatch were single, quickly-recovered mistakes; neither generalizes.
- Reusable handbook signal: the worker spent many turns discovering that
  `Str.parse_int` is permissive (signs, `_` separators, leading zeros, trailing
  whitespace) and therefore cannot serve as a byte-exact decimal validator. The
  approved handbook only warns that `env.int`/`env.bool` are not strict
  validators; it does not warn about `parse_int`. This is a factual, general
  XSH semantic lesson that will recur in any integer-validation task → staged
  as a provisional handbook candidate.
- Already-tracked product/tooling gap (no new ticket): the absence of a
  first-class `fail`/`assert`/error constructor, forcing obscure
  guaranteed-failing conversions, is re-observed here (worker again searched
  `fail`/`assert`/`panic`/`Err`). This is the identical observation already
  owned by `tickets/task-envcfg-001.md` (Status `Closed.`, budget breach
  "too difficult"). Re-opening a duplicate is out of scope; the re-observation
  is recorded here so the CTO may choose to reopen. No duplicate ticket created.
- Harness/evaluator: none. All 10 cases (incl. both failure controls) passed
  byte-for-byte, restrictions pass (`env.` referenced, no forbidden subprocess),
  protocol/review pass. The `candidate_sha256` in `run.json` is the empty-string
  hash because the deliverable is a file and the candidate's stdout is empty;
  this is a manifest-reporting quirk, not a correctness issue (the actual
  artifact `envcfg.xsh` hashes `d388db87…`).

## Handbook decision

Provisional candidate staged at `lineage/handbook-candidate.md`. Approved
snapshot is unchanged; the candidate adds one general sentence to the
`Environment and configuration` section documenting that `Str.parse_int` is
permissive (accepts sign, `_` separators, leading zeros, surrounding
whitespace) and that byte-exact digit contracts must be enforced explicitly
rather than relying on `parse_int`. General lesson: "integer parse helpers in
XSH are permissive readers; exact digit-run contracts must be checked
explicitly." Replay scope: this candidate is for the next cycle; it should be
promoted only after `task-envcfg` replays it (and ideally `task-ecount`, which
also does numeric/stream work) still pass. The eval itself passed on the
approved snapshot, so this is an optional enhancement, not a blocker.

## Tickets created

None. The one strong reproducible ergonomics observation (missing
error/fail/assert constructor) is already tracked by `tickets/task-envcfg-001.md`
(Closed); no duplicate was opened. No other observation met the bar for a new
ticket.

## Post-merge decisions

None. The reconciler found zero merged tickets for this cycle, so there are no
post-merge acceptance decisions to record.

## Next replay

- Eval: `task-envcfg`.
- Handbook lineage: this run's `lineage/handbook-candidate.md` (parse_int
  permissiveness sentence), pending CTO review.
- Post-merge/falsification check: replay the candidate on `task-envcfg` to
  confirm 10/10 byte-exact correctness and that the worker no longer spends
  turns re-discovering `parse_int` permissiveness; a second replay on
  `task-ecount` would test generalization across a numeric eval. Also confirm
  whether `tickets/task-envcfg-001.md` (missing error-construction primitive)
  should be reopened given the re-observed friction here.

## North-star impact

The run confirms the `env`/`fs`/`?`-propagation surface is discoverable and
composable: an agent reached a byte-exact, restriction-clean solution that
passed all ten oracle cases. The provisional handbook candidate directly serves
the ergonomics and learnability goals by turning a ~15-turn `parse_int`
permissiveness discovery into one reusable sentence, reducing repeated
exploration for any future numeric-validation task. Re-observed friction around
controlled deliberate failure (no `fail`/`assert` constructor) reinforces the
trust/explicit-boundary goal and is flagged for the CTO to decide whether the
closed `task-envcfg-001` should be reopened — a decision the north star's
"precise, explicit failures" ethos supports.
