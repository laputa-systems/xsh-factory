# Eval-manager report: task-setdiff

## Result

pass

## Effort metrics

Trial 1 (the only configured trial): worker `eval-worker/task-setdiff-1`.
- Assistant turns: 35
- Tool calls: 41 (32 bash, 5 read, 3 write, 1 edit)
- Tool errors: 6 (all in the worker tool_errors array; none in the manager session)
- Session span: 120,232 ms (~2.0 min)
- agent_wall_ms: 132,315
- Stop reasons: 1 stop, 34 toolUse
- Worker friction: ~6 failed `xsht check`/lint invocations before a clean solution;
  all errors were resolved within the session and the final artifact passed.

Only one trial was configured; there is no Trial 2 to compare.

## Usage and cost

Trial 1 worker (provider: openrouter/deepseek/deepseek-v4-flash-0731):
- input: 31,699; output: 8,464; cacheRead: 412,480; cacheWrite: 0
- provider total / bucket total: 452,643 (match)
- reasoning tokens: 3,491 (provider-reported, subset of output)
- thinking blocks: 27
- Cost: input $0.00285291; output $0.00152352; cacheRead $0.00742464;
  cacheWrite $0; total $0.01180107
- Budget: $0.50; used 2.4%; no budget breach
- Aggregate = trial 1 only: $0.01180107, 452,643 tokens.
- cacheWrite unknown costs: 0.

## Thinking evidence

27 thinking blocks and 3,491 provider-reported reasoning tokens. The transcript
shows the worker reasoned through the `Str.lines` trailing-newline edge case
(verified empirically against a hexdump that a blank interior line is a real
member) and through the boolean-negation syntax shared between the failure
controls and the filter. Thinking blocks correlate with the repeated
`not`-parse failures: the worker searched `search:not` and `search:boolean`
and could not surface a negation rule from the handbook or `xsht api`, then
discovered `! set.has(...)` by trial. Reasoning tokens are provider-reported.

## Tool-error findings

All six non-zero Pi tool results from the structured worker `tool_errors` array
(phase `report.json` and worker `report.json` agree):

1. turn 13 (`bash`, exit 2): `not set.has(setB, l)` parse
   `expected-expression` cascade in `setdiff.xsh` (where/unique-by/sort/collect
   plus missing `}`).
2. turn 15 (`bash`, exit 2): `not(set.has(setB, l))` parse error in `/tmp/t2.xsh`.
3. turn 17 (`bash`, exit 2): `print $out` -> `display-conversion` "value cannot
   be displayed by print" in `/tmp/t4.xsh` (printing a collected list).
4. turn 18 (`bash`, exit 2): `not set.has(s, l)` parse error in `/tmp/t5.xsh`.
5. turn 19 (`bash`, exit 2): `print $out` -> `display-conversion` in `/tmp/t6.xsh`.
6. turn 22 (`bash`, exit 1): lint `warn[lint.path-constructor]` for
   `Path(argv[i])` under a dismissed `Path(...)` warning; worker fixed by using
   `fp"${...}"`.

Errors 1, 2, 4 share one root cause (invalid `not` negation). Errors 3, 5 are
printing a collection directly. Error 6 is a lint warning already covered by
the approved handbook. The manager session produced no tool errors.

## Timing evidence

No strict candidate/oracle timing gate for this eval (EVAL.md: "no strict
candidate/oracle timing gate; both sides finish in milliseconds, so timing is
diagnostic"). `run.json` records result pass with correctness exactly equal;
per-case candidate/oracle timing was not disaggregated in this packet.
Timing is diagnostic only. Provider telemetry: present, 0 retries, no provider
errors, response_elapsed 0 / output_tokens_per_second 0 (not authoritative),
so no wall-clock inflation attributable to provider health; agent wall time
tracks the 6 failed check loops.

## Observation classification

- **Reusable handbook guidance (strong):** XSH boolean negation is `! expr`;
  `not` is not valid syntax. Repeated 3 times (turns 13, 15, 18) with
  unproductive `search:not` / `search:boolean` probes before the worker found
  `! set.has(...)`, which then compiled and passed all gates. Generalizes
  beyond task-setdiff to any stream filter / guard. Candidate staged.
- **Worker friction (minor / ordinary):** `print` of a collected list rejected
  (turns 17, 19). The handbook already says `print` rejects unconsumed streams
  and shows iteration/join; worker resolved by iterating. Already-covered,
  low signal, no new candidate on its own.
- **Ordinary noise / mature guidance:** `Path(...)` -> `fp"${...}"` lint
  warning (turn 22) is already taught verbatim in the approved handbook;
  worker applied it. No action.
- **No product/tooling defect:** the `not` rejection is correct XSH behavior;
  the gap is documentation, not a parser defect.
- **No evaluator failure, no image/harness mismatch, no correctness or
  restriction issue.** run.json: correctness=exact, protocol=pass,
  restrictions=pass, result=pass. All ten success cases plus two failure
  controls matched (MATCH x7 / 5, missing-file cases exit 3 with no fabricated
  stdout).

## Handbook decision

Provisional candidate staged at
`runs/run-1786142295779/phases/03-eval/lineage/handbook-candidate.md`
(approved snapshot plus one concise line in "Streams and collections"):
Boolean negation is the prefix `!` (e.g. `! set.has(s, l)` or `! flag`);
`not` is not valid XSH syntax. General lesson: teach the boolean-negation
operator so agents stop guessing `not`. Replay scope before promotion: rerun
task-setdiff, and cross-eval replay on stream-filter evals (task-dupcheck,
task-ecount) since the rule applies to any `where`-style guard. Promotion
requires CTO approval and later replay; not trusted yet. The approved
snapshot and `runtime/handbook.md` were not modified.

## Tickets created

None. The one strong reproducible observation (invalid `not`) is a handbook
learnability gap, not a general XSH ergonomics/correctness defect, so it is
staged as a handbook candidate rather than an engineer ticket.

## Post-merge decisions

None. The reconciler found no merged tickets (`none`) for this cycle.

## Next replay

Replay task-setdiff on the staged lineage
`runs/run-1786142295779/phases/03-eval/lineage/handbook-candidate.md` to check
the `!`-negation note shortens the discover/error loop, then cross-check on
task-dupcheck/task-ecount before any promotion to `runtime/handbook.md`.

## North-star impact

Directly advances learnability and ergonomics: an agent with the handbook
should not burn three failed checks and two dead `search:not` / `search:boolean`
probes on a basic Boolean negation. Teaching `! expr` as the one negation form
reduces tool-error churn, keeps solutions on the typed, explicit XSH surface
(the `set`/`stream` path rather than string tricks or subprocess escape), and
generalizes to every filter/guard in the language. It is a small, durable
foundation lesson in the "prepare the handbook for agents we will never meet"
mission and is falsifiable via the staged replay.
