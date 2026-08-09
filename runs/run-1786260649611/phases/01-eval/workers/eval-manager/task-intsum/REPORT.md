# Eval-manager report: task-intsum

Eval: `task-intsum`
Run: `runs/run-1786260649611`
Phase: `01-eval`
XSH commit under test: `04fb98f8c63b63cccffce7ef2c3cabde81bb05ba`
Mode: eval, 1 fresh trial (controller-executed), no candidate replay (`not-reevaluation`)

## Result

pass

The single controller-executed trial passed: correctness pass, protocol pass,
restrictions pass, timing pass, `passed: true`. The candidate sha256
(`23890318...`) matches the oracle sha256, so the byte-for-byte numeric cases
agreed and the malformed case exited nonzero as required.

## Effort metrics

Trial 1 (`task-intsum-1`):
- assistant turns: 24
- tool calls: 29
- tool results: 29
- tool errors: 1
- user messages: 1
- thinking blocks: 17
- agent wall time: 91804 ms; session span: 90665 ms
- worker friction: one failed bash probe at turn 11 (see Tool-error findings)

Session stop reasons: 23 toolUse, 1 stop. Tool mix: 21 bash, 5 read, 2 edit,
1 write. This is a short, focused task; the effort is in line with a
single-draft typed-argv implementation, and 24 turns is not excessive.

Provider telemetry present: retry_count 0, retry_failures 0, provider_errors
[], response_elapsed_ms 0. No external-health confounders; not an agent
efficiency concern.

## Usage and cost

Trial 1 (`task-intsum-1`):
- input tokens: 16247, input cost: $0.00146223
- output tokens: 5802, output cost: $0.00104436
- cache read tokens: 243200, cache read cost: $0.0043776
- cache write tokens: 0, cache write cost: $0
- provider total tokens: 265249; bucket total: 265249
- reasoning tokens: 2600 (provider-reported; a subset of output)
- total cost: $0.00688419 (well under $0.50 budget)
- budget failures: 0

Aggregate: $0.00688419 across 1 trial.

## Thinking evidence

Thinking blocks: 17 (trial 1). Provider-reported reasoning tokens: 2600.
The thinking count is consistent with an agent working through typed parsing,
accumulation, and exact-output requirements. Reasoning tokens are a subset of
output tokens. Qualitative thinking evidence will be cross-checked against
`thinking.md`/session after the draft.

## Tool-error findings

Structured `tool_errors` for the worker session (`task-intsum-1/report.json`):
- turn 11, tool `bash`: `sh: syntax error: bad substitution` — Command exited
  with code 2.

This is a single failed exploratory bash command (a bad-substitution probe) in
the worker session. It is a one-off exploration error, not a recurring product
or handbook friction. No manager-session tool errors.

## Timing evidence

Trial 1: `timing: "pass"`. The eval has no strict candidate/oracle timing gate;
timing is diagnostic only. Measured wall times (ns), candidate vs oracle:
- public: 14120656 vs 12778854
- hidden_zero: 12347476 vs 12352642
- hidden_neg: 12258516 vs 11459635
- hidden_mixed: 14146824 vs 13699319
- hidden_large: 14546077 vs 15455667
- hidden_malformed: 12609436 vs 14185533

All cases land in an 11–15 ms band; the candidate is marginally slower on some
cases and faster on the large and malformed cases. No strict ratio gate applies,
and the spread is process-launch noise, not an agent or language signal.

## Observation classification

- Single `bash` bad-substitution error at turn 11: ordinary noise / one-off
  exploration error. The worker corrected course and produced a passing typed
  solution. Not reusable and not a product/harness defect.
- No repeated API-discovery failures, no repeated reads, no provider retry
  evidence in the phase packet.
- Correctness and restriction compliance are clean (all exact, restrictions
  passed with no forbidden operations); this is a successful typed-argv glue
  task.
- Provider telemetry shows zero retries and zero provider errors, so the ~92 s
  session and ~29 tool calls reflect normal agent exploration, not latency.
- Timing spread is ordinary process-launch noise; no gate, no signal.

## Handbook decision

Unchanged. The approved handbook already covers typed parsing, postfix `?`,
`var` accumulation, and exact output. The worker passed without discovering a
reusable lesson missing from the handbook. The candidate file
(`lineage/handbook-candidate.md`) was copied unchanged from the approved
snapshot; no provisional candidate was staged.

## Tickets created

Zero. No strong, reproducible, generalizable observation warrants a product
ticket this cycle.

## Post-merge decisions

None. The reconciler reported no merged tickets (`none`); candidate
re-evaluation is `not-reevaluation`, so no post-merge acceptance decision
applies to this run.

## Next replay

A falsification/regression replay of `task-intsum` against the same handbook
lineage could confirm stability of the typed-argv idiom (mixed, empty, large,
negative, and malformed cases) and detect any drift in string-length or error
semantics. Since no handbook candidate or ticket was produced, the primary
next replay is a routine re-run of this eval on a future XSH commit to confirm
the typed-sum behavior remains correct.

## North-star impact

This run is evidence that the handbook's typed-boundary ethos is learnable:
the agent produced a genuine typed argv-sum solution (typed parsing, `var`
accumulation, postfix `?` failure propagation, exact single-line output) with
no subprocess and no hard-coded answer. It advances ergonomics and
learnability by confirming the typed argument-vector idiom works as documented,
and the explicit failure boundary (malformed argument → nonzero exit, no
numeric stdout) is exercised correctly. The only error is a one-off shell
probe, not a product defect.
