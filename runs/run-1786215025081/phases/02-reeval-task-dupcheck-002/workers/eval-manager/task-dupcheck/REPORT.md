# Eval-manager report

## Result

pass

## Effort metrics

- Trials reviewed: 1 fresh trial (controller-configured count).
- Worker `task-dupcheck-1`: result `pass`, state `completed`, agent_state `pass`,
  budget_state `pass`, reporting_state `pass`.
  - assistant_turns: 25; tool_calls: 29 (bash 21, read 4, write 2, edit 2);
    tool_results: 29; tool_errors: 3; user_messages: 1; thinking_blocks: 14.
  - session span: 73,271 ms (Pi conversation); agent_wall_ms: 74,624.
  - stop_reasons: 1× stop, 24× toolUse.
- Worker friction: low. The 3 tool errors (turns 5, 6, 8) were all standard-idiom
  probe misses (print `$`/field-access spelling, `proc main` spread form, bare
  print identifier) resolved within a couple of turns each. The worker did not
  attempt any `name = value` named argument, so no named-argument parse-error
  friction recurred.

## Usage and cost

Worker `task-dupcheck-1` (single trial):
- input_tokens 15,425; output_tokens 8,217; cache_read_tokens 339,456;
  cache_write_tokens 0; provider_total_tokens 363,098; bucket total 363,098.
- reasoning_tokens 4,006 (provider-reported; subset of output).
- cost: input $0.00138825, output $0.00147906, cache_read $0.006110208,
  cache_write $0, total $0.008977518.
- budget_usd 0.50; budget_state pass.
- Aggregated across the run: 25 assistant turns, $0.008977518, 0 budget
  failures, 0 unknown costs.

## Thinking evidence

- Provider reported 14 thinking blocks and 4,006 reasoning tokens for the
  worker session; reasoning tokens are provider-reported and were not summed
  into totals (kept as a subset of output).
- `thinking.md` evidence in session: the worker consciously recognized the
  positional-only constraint from the rendered `fs.files` contract ("positional-only
  means I can't use name = value"), chose the canonical positional call
  `fs.files(root, false, false, [], true)`, and planned the group/flatten/sort
  idiom (composed line strings whose fixed-length hex digest governs the
  compound sort). The recorded reasoning matches the final artifact.

## Tool-error findings

Every nonzero Pi tool result in the structured worker `report.json`
(`task-dupcheck-1`, 3 total):
1. turn 5 — `err[check.bare-print-ident]`: field access in `print` requires
   `$` (`print e.kind ":" e.path.display()`); corrected to `$e.kind`.
2. turn 6 — `err[compact.main-missing-spread]`: `proc main(args: List[Str])`
   must use the spread form `(...argv: List[Str])`; corrected.
3. turn 8 — `err[check.bare-print-ident]`: bare identifier `root` in `print`
   is ambiguous; corrected to `$root`.

No invalid `xsht api` discovery queries or named-argument parse errors occurred
in this run. Manager session has no tool errors. The recorded candidate-side
parse errors were emitted without `isError` in the transcript and are not in
the structured error arrays; all structured failed tool results are accounted
for above.

## Timing evidence

- No strict candidate/oracle timing gate (eval contract: timing diagnostic).
- Evaluator `run.json` per case (candidate / oracle, ns):
  - public 13,198,576 / 11,947,371; hidden_empty 10,907,792 / 13,404,908;
    hidden_nested 12,726,451 / 12,610,702; hidden_three 13,385,533 / 12,166,204;
    hidden_spaces 12,521,077 / 12,292,953; hidden_many 13,283,783 / 12,401,620;
    hidden_none 10,885,042 / 13,511,657; hidden_missing 13,158,408 / 13,127,867.
  - `timings.passed = true`; both sides finish in milliseconds on the small
    fixtures; no ratio gate.

## Observation classification

- **Product/tooling improvement (validated):** The candidate ticket
  `task-dupcheck-002`'s Option-1 reference remedy is live. `xsht api api:fs.files`
  now renders "Function arguments are positional-only; parameters marked
  `= default` may be omitted, but cannot be supplied as `name = value`." The
  worker read it, did not attempt named arguments, and used the positional
  call. Reusable signal: a reference-rendering fix removed a repeated-discovery
  class with no grammar change. Evidence is deterministic and directly
  exercised (see Handbook decision and Candidate acceptance below).
- **Worker friction (ordinary):** the 3 probe errors were standard
  print/spread-idiom misses already covered by the handbook; resolved quickly.
  Not a new handbook gap or product defect.
- **Agent efficiency:** 25 turns / 29 tools for a correct eight-case solution;
  latency attribution normal — provider telemetry present, retry_count 0,
  retry_failures 0, provider_errors [].
- **Harness note (noise, not a ticket):** the worker report's
  `provider_telemetry.events_path` points to `session.jsonl.events.jsonl`,
  which was ENOENT on read, while the structured telemetry block already
  carries the retry/error fields. Minor bookkeeping only; no product signal.

## Handbook decision

Unchanged. Copied the approved snapshot to lineage/handbook-candidate.md
byte-for-byte. The validated change in this trial is a product/tooling
reference fix (the `xsht api` contract rendering), not a handbook gap; the
handbook already documents block-stage command-word spelling and the
positional/defaulted-parameter surface. No new handbook candidate is justified
by this single trial.

Candidate acceptance: pass.

The worker actually exercised the ticket's acceptance criteria rather than a
workaround:
1. `xsht api api:fs.files` renders the positional-only constraint explicitly —
   satisfied by the live contract text.
2. A fresh trial read that signature and attempted no `name = value` calls —
   the three tool errors were unrelated print/spread misses; no
   `expected ')' after call arguments` named-arg parse errors occurred.
3. Existing positional calls parse and pass the eight-case oracle — final
   artifact `dupcheck.xsh` uses `fs.files(root, false, false, [], true)` and
   `run.json` reports `correctness.all_exact = true`, `passed = true`,
   `restrictions.passed = true`, `protocol.artifact_present = true`,
   `review_ok = true`.

Internal-consistency note for the controller: the phase `data.xsh_commit` field
(`26d59eb844b670365931d91ffb15ae8c109bae12`) differs textually from the
controller-supplied candidate commit (`b9cc3ffc6425b365a172c5a897ed9684db235487`).
Because the running image demonstrably contains the candidate's contract
change (observed live in session turn 2), the candidate surface was exercised
regardless; the controller should confirm the commit-string mapping when
recording the merge.

## Tickets created

None. No new strong, general, reproducible product defect beyond the already
approved and now validated `task-dupcheck-002`.

## Post-merge decisions

None. The reconciler found no merged ticket files for this cycle; this run is a
pre-merge candidate validation, not a post-merge acceptance assignment.

## Next replay

Replay `task-dupcheck` plus one additional eval that calls a defaulted-parameter
module function (e.g. `task-histogram` or `task-envcfg`) against the merged
candidate to confirm generalization before promoting to
`runtime/handbook.md`. Post-merge check: confirm no agent attempts
`name = value` after reading the reference and that positional calls remain
green. Falsification: an eval whose agent still tries named arguments after
reading the corrected reference would reopen the ticket.

## North-star impact

Validates an ergonomics and trust improvement: `xsht api` now honestly renders
that calls are positional-only, removing a repeated-discovery class (named
`name = value` attempts that the parser rejects) without adding grammar
surface. This directly serves the XSH rationale's "honest, explicit
boundaries" and the factory's ergonomics goal ("fewer guesses, workarounds,
tool errors, and repeated discoveries"), across every eval that calls a
defaulted-parameter module function, pending generalization replay.
