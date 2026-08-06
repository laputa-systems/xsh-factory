# Eval-manager report

## Result

pass

## Effort metrics

- Trial 1 (`task-histogram-1`): 79 assistant turns, 89 tool calls
  (83 bash, 3 read, 1 edit, 2 write), 89 tool results, 2 tool errors, session
  span 741927 ms (agent wall 743883 ms). Stop reasons: 1 `stop`, 78 `toolUse`.
- Worker friction: moderate. The agent reached a correct, clean solution but
  spent roughly 30 turns probing Result / error / match / require / halt /
  assert discovery after the `?` helper restriction blocked its first
  `parse_uint` helper, and 4–5 turns confirming the integer-division operator
  (`/`, with no `//`). The remaining pipeline (read_text, sort-by, group-by,
  fold, fp interpolation) was straightforward from the handbook.
- The 2 tool errors are ordinary self-test friction (missing `/work/s.txt`
  during a pre-submission test), not eval or handbook impact.

## Usage and cost

- Trial 1: input 131475, output 30930, cacheRead 1977088, cacheWrite 0,
  provider-total 2139493, bucket-total 2139493 (match). Reasoning tokens 20632
  reported (subset of output). Thinking blocks 60.
- Cost: cost_usd 0.052987734; budget 0.5; input $0.01183275, output
  $0.0055674, cacheRead $0.035587584, cacheWrite $0. No unknown-cost fields.
- Single worker this cycle; no aggregate beyond trial 1.

## Thinking evidence

Provider reported 20632 reasoning tokens and the session records 60 thinking
blocks across 79 turns. Thinking is qualitative: the blocks show a deliberate,
spiral of API discovery around Result/error propagation and arithmetic
operators, consistent with the tool-call pattern in the session JSONL. The
final solution is clean and correct, so the extended thinking is best read as
genuine discovery friction rather than confusion.

## Tool-error findings

The structured worker `report.json` `tool_errors` array lists exactly 2 failed
Pi tool results (both `bash`); the manager session has zero tool calls, hence
zero errors.

- Turn 71 (session): re-run of `xsh histogram.xsh /work/s.txt 3` after a
  `== lint == / == fmt ==` pass, producing
  `fs-read: No such file or directory (os error 2)` and exit 3.
- Turn 72 (session): `ls: /work/s.txt: No such file or directory` followed by
  the same `fs-read` traceback and exit 3.

Both are the worker testing its artifact against `/work/s.txt` before that
file existed (it then created the file and re-ran successfully; test data was
cleaned up). This is correct expected behavior for a missing input file and is
ordinary self-test noise — not a handbook gap, product defect, or embedding
problem. No invalid `xsht api` discovery queries were recorded as failed Pi
tool results in either structured report; API queries returned text, and the
informative `check.try-context` / `parse.expected-terminator` outputs were
check-feedback the worker iterated on, not harness tool errors. All structured
tool errors are therefore accounted for above.

## Timing evidence

No strict candidate/oracle ratio gate; both sides finish in milliseconds so
timing is diagnostic. Trial 1 candidate 11.8–15.6 ms per case; oracle
11.5–15.7 ms per case; `hidden_bad_width` candidate 14.3 ms / oracle 14.2 ms,
`hidden_bad_value` candidate 14.3 ms / oracle 15.0 ms. No timing signal.

## Observation classification

- Correctness (reusable signal): 9/9 byte-exact including both failure
  controls; restrictions `pass` (typed read_text + parse_int + sort-by, no
  subprocess escape); protocol `pass`. The handbook's Result/`?`, typed-path,
  sort-by, and fold idioms transferred cleanly to a measurement-summary task.
- Product/tooling defect (strong, reproducible): postfix `?` is rejected in a
  value-returning `[error]` helper (`check.try-context: `?` requires a
  Result-returning context`) while it works in `main`/`Unit` and in stream
  blocks nested in `main`. Confirmed by multiple session reproductions and the
  worker's `review.md`. General, not task-specific → opened ticket
  `task-histogram-004`.
- Handbook gap (reusable): the handbook's broad `?` statement omits the
  Result-returning-context requirement, and it does not document that integer
  division is `/` with no `//` operator (the agent burned turns discovering
  both). Staged as a provisional handbook candidate.
- Discoverability/noise: `Str.parse_int` permissiveness (accepts `+5`, `-5`,
  hex, separators, leading zeros) is a contract nuance already partially
  covered by the handbook's "typed conversion" guidance; noted but not a
  separate ticket.
- Ordinary noise: the 2 fs-read missing-file self-test errors.

## Handbook decision

Provisional candidate staged at
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785965138991/phases/03-eval/lineage/handbook-candidate.md`.
It is a one-trial plan (single controller trial), so it was NOT replayed this
cycle. Two general, short additions:
1. postfix `?` requires a Result-returning (or Unit `main`) context — a plain
   value-returning `[error]` helper cannot use `?`; inline or return `Result`.
2. integer division is `/` (truncated quotient), remainder `%`, with no `//`
   operator.
Replay scope: any future eval with typed validation helpers or integer-division
binning should confirm the `?`-context note removes the helper wall and the
division note removes operator guesswork. Promotion to `runtime/handbook.md`
requires CTO review and replay across more than one eval.

## Tickets created

- `/Users/josh/d/laputa-systems/xsh-factory/tickets/task-histogram-004.md`
  (Open, product): postfix `?` should be accepted in any proc declaring the
  `error` effect, removing the Result-returning-context asymmetry. Merge-record
  placeholders left untouched. Open for the next cycle.

## Post-merge decisions

None. The reconciler found no merged tickets for this cycle (open tickets
`task-findexec-001` Approved, `task-histogram-003` Open are not merged and not
post-merge acceptance assignments).

## Next replay

Re-run `task-histogram` (and one additional helper-heavy eval) against the
staged handbook candidate and against the merged `task-histogram-004` change
(if approved). Verify: (a) the `?`-context and division notes remove the
~30-turn discovery wall while keeping 9/9 byte-exact, and (b) the checker
relaxation is accepted with no regression. This is the falsification check for
both the handbook candidate and the ticket.

## North-star impact

The eval demonstrates that XSH's typed read/parse/sort/fold idioms compose
into a correct binned cumulative distribution with no subprocess escape —
directly advancing the "practical systems glue" mission. The main product
signal is a reproducible ergonomics asymmetry in postfix `?` error propagation
that forces inlining of small validation helpers, and a discoverability gap
around integer division. Documenting the `?`-context rule and proposing a
checker relaxation target the north-star goal: fewer repeated discoveries and
clearer, more composable error handling for every future agent, with a
specific replay named to validate the change.
