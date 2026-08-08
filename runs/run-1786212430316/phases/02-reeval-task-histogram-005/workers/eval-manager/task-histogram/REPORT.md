# Eval-manager report

## Result

fail

## Effort metrics

Single trial (Trial 1, `task-histogram-1`) for candidate-linked replay of
`task-histogram-005` (`parse_uint` candidate at XSH commit under test
`2d255aa8297671339564f1f93587ec69c5f96cb5`).

- Assistant turns: 29; tool calls: 43; tool errors: 2; user messages: 1.
- Session span: 302101 ms (~5.0 min); agent wall 304332 ms; budget_state pass
  (budget 0.5 USD, spend 0.0117 USD).
- Worker friction: low-to-moderate, all resolved within the session. The worker
  used `parse_uint()` directly (the candidate surface) for both the width and
  the measurement values, and expressed the positive-width rejection as
  `let _ = 1 / width` (see Observation / ticket 009). The two tool errors are
  development-loop probes, not unresolved discovery.
- Per-trial result: `pass` worker report; evaluator `run.json` classification
  `restriction_failed`, `result` fail (correctness pass, restrictions fail).

## Usage and cost

Single worker session (provider openrouter/deepseek/deepseek-v4-flash-0731):

- Input tokens 25777, output tokens 11755, cache read 402432, cache write 0,
  bucket total 439964; provider total 439964.
- Reasoning tokens 7024 (reported); thinking blocks 25.
- Cost: input 0.00231993, output 0.0021159, cache read 0.007243776, cache write
  0, total 0.011679606 USD. Malformed lines 0; unknown costs 0.
- Provider telemetry present; retry_count 0, provider_errors [], retries 0;
  no provider-latency signal. `output_tokens_per_second` and
  `response_elapsed_ms` are 0 (client did not derive meaningful rates), so no
  latency attribution is drawn from them.

## Thinking evidence

25 thinking blocks, provider-reported reasoning tokens 7024. The session
transcript (reading the artifact and review) shows the worker: parsed the width
and each measurement through `parse_uint()?` as the intended typed unsigned
parse; discovered/kept the integer-division-on-Int spelling `v / width`; and
deliberately chose `let _ = 1 / width` to reject a non-positive width because
`parse_uint` accepts `0` and there is no typed positive/Error path. Thinking
correlates with the final artifact and the divide-by-zero SIGFPE rejection.

## Tool-error findings

Structured `tool_errors` arrays (worker `report.json`) report 2 bash tool
errors; no `xsht api` discovery errors appear in this run, so no invalid API
query to account for:

1. turn 18 — `let c = a // b` rejected: `err[parse.expected-terminator]` at
   `//`. This is the worker probing `//` as an integer-division operator, which
   XSH does not have; the working spelling is `/` on Int. Matches the
   already-tracked division-discoverability surface (`task-histogram-007`);
   development-loop probe, not unresolved.
2. turn 22 — a Bash test harness driving the candidate against edge cases
   (empty file, blanks, negative, bad line, width 0, width non-int) ended with
   `sh: syntax error: bad substitution` and exit code 2. The negative/bad/value
   cases correctly show `parse-uint` errors (exit 3); `width 0` shows exit 133
   (SIGFPE). The `bad substitution` is test-shell noise in the worker's Bash
   harness, not a product or candidate error.

Both are accounted for; the current evidence packet has no unresolved Pi tool
error.

## Timing evidence

No strict candidate/oracle timing gate for this eval; both sides finish in
milliseconds. Per-case candidate wall ns vs oracle: public 11.6ms/11.6ms,
hidden_width 64.1ms/11.1ms, hidden_many 11.2ms/11.7ms, hidden_sparse
11.2ms/11.2ms, hidden_single 11.1ms/12.7ms, hidden_ties 11.1ms/12.5ms,
hidden_empty 12.7ms/12.4ms, hidden_bad_width 11.2ms/13.1ms, hidden_bad_value
11.4ms/12.6ms. The single ~64ms candidate outlier on hidden_width is
process-launch noise, well within the diagnostic (non-gating) envelope.

## Observation classification

- Worker exercised the candidate surface (parse_uint), 9/9 correctness
  byte-exact → correctness pass; this is reusable signal for
  `task-histogram-005` acceptance. The worker did not use a workaround for the
  ticket's core scope: the artifact uses `parse_uint()` for both the width and
  the values, directly exercising the proposed surface. Candidate acceptance:
  pass.
- Restriction mismatch (evaluator): `restrictions.passed = false` solely
  because the task-histogram evaluator's restriction checker requires the
  source to reference `parse_int` literally, and the candidate solution uses
  `parse_uint` (the very surface the candidate ticket adds). The typed integer
  parse requirement is satisfied by `parse_uint`; the checker pattern is stale.
  Classify as **evaluator/harness mismatch** (factory-owned), not a product
  defect. This is precisely the replay the ticket's acceptance criteria 1-2
  target, so the candidate is not rejected on substance.
- Positive-width rejection via divide-by-zero (SIGFPE, exit 133 / exit -1) →
  general XSH ergonomics gap (no typed `> 0` parse or Error/fail constructor)
  → opened `task-histogram-009`. Strong, reproducible, generalizes to any
  positive-integer validation boundary.
- `path` binding shadow (`check.standard-module-shadow`) → reusable handbook
  guidance (stage in handbook candidate), low-friction naming note.
- All correctness/timing/usage metrics show no agent-efficiency regression;
  provider telemetry clean.

## Handbook decision

Provisional candidate staged at
`phases/02-reeval-task-histogram-005/lineage/handbook-candidate.md`. Two concise
general lessons added (everything else copied from the approved snapshot):

1. In Effects and errors: for a strict unsigned decimal use `parse_uint()?`
   (rejects any sign) rather than layering a regex on `parse_int`; note there
   is still no typed positive-exclusive parser or generic `Error(...)`, so a
   `> 0` bound has no clean typed rejection.
2. In Paths and filesystem values: do not name a binding `path` (shadows the
   standard `path` module and is rejected at check time); use a distinct name.

These are general, short rules that remove repeated friction. They require
replay across more than one eval before promotion to `runtime/handbook.md`; the
next task-histogram replay and a second numeric-parse eval both apply.

## Tickets created

- `tickets/task-histogram-009.md` — new Open product ticket: typed
  positive-exclusive (or generic boolean-failure) rejection so a `> 0` width
  no longer requires a divide-by-zero SIGFPE abort. Links this eval, lineage,
  manager report, executor run, and baseline. Merge-record placeholders left
  untouched.

## Post-merge decisions

None. The controller reconciled no merged tickets for this cycle (`none`).
`task-histogram-005` is a pre-merge candidate under validation, not yet on
main; no merge fields exist to accept or reject.

## Next replay

- Eval: `task-histogram`; lineage:
  `phases/02-reeval-task-histogram-005/lineage/` (candidate staged). After the
  controller (or CTO) updates the evaluator's restriction checker to accept a
  typed unsigned parse (`parse_uint`) alongside `parse_int`, re-run
  `task-histogram` against the `parse_uint` candidate branch to confirm
  restrictions now pass while correctness stays 9/9 — a directed replay of the
  same candidate.
- A second numeric-parse eval replay is required before promoting the handbook
  candidate or to falsify `task-histogram-009`'s positive-bound gap.

## North-star impact

This cycle validates, on the candidate branch, that the ticket's `parse_uint`
surface is discoverable and exercises a strict sign-rejecting typed parse
(ergonomics and trust: no silent signed acceptance), and keeps `task-histogram`
9/9 byte-exact. It exposes two durable signals: (1) a factory-side evaluator
restriction checker that must recognize the very typed-parse surface it is
supposed to require, and (2) an unmapped positive-bound gap that still forces a
SIGFPE abort instead of a typed rejection. Both, plus the general handbook
notes on `parse_uint` and the `path` shadow, advance XSH's clarity,
learnability, and ergonomics mission for numeric-validation and Path-handling
glue.
