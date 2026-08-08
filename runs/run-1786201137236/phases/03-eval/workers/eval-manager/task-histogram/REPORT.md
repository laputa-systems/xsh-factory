# Eval-manager report

## Result

pass

## Effort metrics

Single trial (`task-histogram-1`), controller-executed against the approved
handbook snapshot; XSH commit under test
`c77b01a3e2fb676cc57cdeddbb7575be7723aa32`.

- Assistant turns: 43
- Tool calls: 52 (bash 44, edit 4, read 3, write 1)
- Tool results: 52
- Tool errors: 1 (a bash exploration command, exit 1)
- Session span: ~330.2 s (agent wall ~331.5 s)
- Worker friction: low. The agent authored a clean, typed solution in
  normal development-loop iterations (check/fmt/lint/xsh) and reached a
  pass on the first execution. The one tool error is a bash trial command,
  not a repeated friction, product defect, or provider issue.

## Usage and cost

Provider-reported usage (worker `task-histogram-1`):

- input tokens: 30,743
- output tokens: 13,042
- cache read tokens: 678,208
- cache write tokens: 0
- total bucket tokens: 721,993 (matches provider total)
- reasoning tokens: 7,481 (provider-reported subset of output)
- cost: input $0.002767, output $0.002348, cache read $0.012208, total
  $0.017322; budget $0.50, no budget breach

Single trial, so per-trial and aggregate are the same. `reasoning` was
reported by the provider (7,481), so reasoning-token counts are available and
are not added to the token total.

## Thinking evidence

31 thinking blocks recorded. Provider reported 7,481 reasoning tokens.
The transcript (qualitative) shows the agent reasoning through typed parsing
(`Str.parse_int`), integer division with `/` after finding `//` is a parse
error, group-by counting, and the cumulative fold, then validating against
the oracle. This correlates with a correct, restriction-compliant artifact on
the first execution; no evidence of guessing or workaround.

## Tool-error findings

Exactly one nonzero Pi tool result in the current evidence packet (worker
report `tool_errors`):

- turn 38, tool `bash`, exit 1. The command was a development-loop trial
  (`=== width 100 ...` followed by a `/usr/share` directory listing that
  ended in an unavoidable nonzero shell status). It did not produce or
  corrupt the submitted artifact and did not recur. Classified as worker
  friction / noise, not a product or harness defect.

No invalid `xsht api` discovery query failures appear in the structured
`tool_errors` array or the worker report. No manager-session tool errors.

## Timing evidence

No strict candidate/oracle timing ratio gate for this eval (contract states
timing is diagnostic). Per-case candidate/oracle wall (ns), all exact:

- public: 11,420,118 / 11,301,534
- hidden_width: 10,978,700 / 14,346,002
- hidden_many: 14,962,879 / 11,243,950
- hidden_sparse: 14,548,169 / 15,145,921
- hidden_single: 15,891,548 / 15,945,923
- hidden_ties: 14,426,418 / 12,468,079
- hidden_empty: 11,536,035 / 12,415,830
- hidden_bad_width: 14,483,752 / 12,782,371
- hidden_bad_value: 15,251,213 / 11,749,703

Both sides complete in ~10–16 ms; no envelope concern. Provider telemetry is
present with `retry_count = 0`, `provider_errors = []`; the ~330 s session
span over 43 turns is agent-driven (correct, in budget), not a provider
latency regression.

## Observation classification

- **Correctness / protocol / restrictions — pass (signal).** All nine cases
  (public, six hidden, two failure controls) byte-exact; restrictions and
  protocol checks passed; `review.md` preserves both headings with no
  placeholders. This is the eval's primary signal: the transform-to-bin +
  keyed count + sorted cumulative fold is discoverable and composable from
  the approved handbook.
- **Worker friction — minor (noise).** One bash trail-command tool error
  (turn 38); single occurrence, no recurrence, no correctness impact.
- **Tooling / ergonomics observations in `review.md` — ordinary friction, not
  this cycle's failure signal.** (a) `//` truncated-quotient token is a parse
  error while the task's literal wording uses `//`; the handbook already
  documents that `//` is not a comment marker and integer division is `/`.
  (b) `xsht api` `KIND:VALUE` vs dotted-id form; already documented in the
  handbook's `xsht api` guidance. (c) `$name` in expression vs command
  position; already documented in the handbook's print/command-word rules.
  Each is already covered by approved handbook text and did not cause
  repeated friction or failure, so none warrants a new product ticket this
  cycle.
- **Latency attribution — not a signal.** Provider telemetry normal
  (zero retries/errors); the session is a correct agent session within
  budget.

## Handbook decision

Unchanged. `lineage/handbook-candidate.md` is carried as a byte-identical
copy of the approved snapshot. The lessons the worker needed (typed
`parse_int` + `?`, `/` integer division, group-by counting, `sort-by` +
`fold` cumulative reduction, command-word stage syntax) are already present
and correct in the approved handbook; the worker reached a correct artifact
on the first submission. No new reusable lesson surfaced that would
generalize beyond the existing text. Any later change (e.g. a friendlier
error or alternate token for integer division) would first need a product
ticket, an implementation, and a directed replay.

## Tickets created

None. No strong, reproducible, general product/tooling defect emerged; the
review's observations are already documented in the approved handbook and did
not recur or block correctness.

## Post-merge decisions

None. The reconciler found no merged tickets (`none`) in this cycle, so there
are no post-merge acceptance assignments to adjudicate against
`c77b01a3e2fb676cc57cdeddbb7575be7723aa32`. The candidate ticket field is
`not-reevaluation`; no candidate-linked replay was required.

## Next replay

Replay `task-histogram` against the unchanged handbook lineage on a future
XSH commit to confirm the typed parse / group-by / sort+fold composition
continues to pass and to gather a second data point before any ergonomics
change is considered. Because the run produced no handbook candidate and no
ticket, no falsification/revert check is pending for this cycle. The
`//`-operator ergonomics observation in `review.md` is a candidate for a
future product ticket only if it recurs across multiple evals.

## North-star impact

This run confirms a canonical measurement-summary workflow — typed integer
parsing, integer binning, keyed counting, sorted cumulative reduction — is
learnable and composeable from the approved handbook on a single trial,
producing a byte-exact, restriction-compliant artifact. That is direct
evidence for the north-star practicality/learnability goal: an agent with the
handbook performed a real ops-adjacent transform without workarounds,
subprocess escape, or hard-coding, at low cost ($0.017) and reasonable turns.
The review's friction notes (operator token, `xsht api` spelling, `$name`
position) are recorded for future ergonomics consideration but were not
strong enough for a ticket this cycle, honoring the factory's standard that
product change requires reproducible, generalizable evidence rather than a
single clean passing run.
