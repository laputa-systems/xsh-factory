# Eval-manager report

## Result

pass

The `task-grep` candidate is correct: all 9 correctness cases passed byte-exact
against the BusyBox `grep -nF` oracle (including the hidden empty-pattern,
no-match, case, regex-literal, spaces, blank-lines, unicode, and missing-file
controls), and the restriction and protocol checks passed. The phase-level
`cycle: fail` / `evaluator: fail` / `infrastructure: fail` outcome is entirely
an executor-side mislabel caused by an evaluator infrastructure defect, not by
the candidate, the handbook, or XSH tooling. See `## Tool-error findings` and
`## Observation classification` for the full account. The worker session itself
is a clean pass (agent_state `pass`, budget `pass`, reporting `pass`).

## Effort metrics

One fresh trial (worker `task-grep-1`), the controller-confirmed count.

- Assistant turns: 20 (19 `toolUse` stop reasons, 1 `stop`).
- Tool calls: 26 (bash 21, read 3, write 2); tool results 26.
- Tool errors: 2 (both non-fatal, recovered immediately).
- Session span: agent `118.1 s`; worker wall `120.4 s`.
- Worker friction per trial: low. Two quick-fix tool errors on turns 10 and 14
  (see `## Tool-error findings`); no repeated exploration, no rediscovery.

## Usage and cost

Provider: `openrouter/deepseek/deepseek-v4-flash-0731`. One worker, 20 assistant
responses.

- Input tokens: 17,029; output tokens: 4,564; cacheRead: 196,928; cacheWrite: 0;
  provider total: 218,521; total bucket tokens: 218,521 (buckets reconcile).
- Cost: input $0.0015326, output $0.00082152, cacheRead $0.00354470, cacheWrite
  $0, total **$0.005898834** (aggregate and per-trial are the same single trial).
- Reasoning tokens: 1,762 (provider-reported, a subset of output; not added to
  totals).
- Budget: $0.5, no budget failures. Malformed lines: 0.

## Thinking evidence

13 thinking blocks in the session; provider reported 1,762 reasoning tokens.
The transcript (`session.jsonl.bz2.bz2`) shows a deliberately ordered, low-redundancy
search: confirm `xsht` supports `api`, query `fs.read_text` signature, then
`search:lines` / `search:contains` / `search:enumerate` / display-strings
before writing code. The agent verified edge cases empirically (empty pattern,
regex-literal `.b`, trailing-space lines, unicode, empty file, trailing-newline
blank line, and the missing-file nonzero-exit contract) before submitting.
Reasoning-token count is provider-reported and available; thinking-block count
is qualitative corroboration only. The thinking is evidence of fluency, not a
token-derived claim.

## Tool-error findings

Both nonzero Pi tool results from the structured `tool_errors` array, both in
worker `task-grep-1` (`session.jsonl.bz2.bz2`):

1. Turn 10, tool `bash` — `err[check.standard-module-shadow]`: the probe bound
   `let path = fp"${argv[1]}"`, which shadows the standard module `path` and
   fails `xsht check` (exit 2). Agent renamed to `file_path` on the next turn.
   Classified: reusable handbook gap (general rule — do not shadow standard
   module names).
2. Turn 14, tool `bash` — `warn[lint.prefer-in]`: `xsht lint` rejected
   `e.value.contains(pattern)` and exited 1. Agent switched to `pattern in e.value`
   membership syntax, after which check+lint passed. Classified: reusable
   handbook gap (prefer `in` membership for Str substring checks).

No invalid `xsht api` discovery queries were recorded in this worker pattern
(the `method:Str`, `search:to_string`, `search:to_text` probes returned
`missing`/partial with clear `status` fields and caused no errors; they are
ordinary discovery, not tool errors). No other zero/nonzero tool results were
reported. The absent `export/` directory is not a tool error and is covered in
`## Observation classification`.

## Timing evidence

No strict candidate/oracle ratio gate for `task-grep`; timing is diagnostic.
Candidate wall times were comparable to the oracle across all cases (e.g. public
candidate 18.4 ms vs oracle 15.4 ms; hidden_missing candidate 18.4 ms exit 3 vs
oracle 14.6 ms exit 2; timings `passed: true`). No efficiency regression signal
in timing.

## Observation classification

- Product correctness (pass): candidate is byte-exact on all 9 cases; reads via
  `read_text`, filters/numbers via XSH values, no subprocess. `run.json`
  `result: pass`, `classification: pass`, `all_exact: true`.
- Reusable handbook guidance (the two tool errors): both `standard-module-shadow`
  and `prefer-in` are general XSH ergonomics rules that generalize beyond this
  search shape; the handbook did not teach them, and both cost a failed
  `check`/`lint` step. Staged as a concise provisional candidate.
- Factory infrastructure / evaluator mismatch (the phase-level fail): the
  evaluator (`evals/task-grep/evaluator.xsh`) wrote a passing `run.json`, then
  its `copy_results` helper called `fs.copy(..., fp"${session_root}/export/${name}", overwrite: true)?` without creating the `export/` subdirectory. Because the session root
  for this run has no `export/` directory, the final `fs.copy` failed with
  `fs-copy: No such file or directory` (in `evaluator.stderr`), the evaluator
  exited nonzero, and the executor reported `evaluator_state: fail`,
  `classification: evaluator_failed`, and phase `infrastructure: fail`. This is
  an evaluator/harness defect — a factory infrastructure matter for the CTO, not
  an engineer ticket and not an agent or handbook flaw.
- Latency attribution: `unknown`. `provider_telemetry` is present with
  `retry_count 0`, `provider_errors []`, `retry_successes 0`, but
  `output_tokens_per_second 0` and `response_elapsed_ms 0` are unpopulated, so
  no wall-clock latency claim is made; the low turn/tool/error counts and steady
  ~6 s inter-response cadence in the transcript show no agent-efficiency or
  provider-health regression needing action.
- Ordinary noise: none material.

## Handbook decision

Provisional candidate staged at
`runs/run-1786052381421/phases/01-eval/lineage/handbook-candidate.md`
(`handbook-approved.md` copied, with two additions in `## Development loop and
tooling`). General lesson: (1) a binding must not shadow a standard module name
(such as `path`) or `xsht check` fails with `standard-module-shadow`; (2) prefer
the `in` membership operator (e.g. `pattern in text`) over `.contains(...)` or
`xsht lint` fails with `prefer-in`. Both are short, general ergonomics rules
that remove repeated failed tool steps across any eval that reads text or names
a file path variable. Replay scope: promote only after this candidate is
replayed on a nearby text-search case (e.g. `task-setdiff`, `task-total`, and a
`task-grep` repeat) and reviewed by the CTO. Not auto-promoted.

## Tickets created

None. The two handbook lessons are staged as a provisional candidate (not a
product ticket — `check`/`lint` already enforce both with clear messages; the
gap is handbook coverage). The evaluator `export/` crash is a factory
infrastructure finding for the CTO, not an engineer ticket.

## Post-merge decisions

No reconciled merged tickets were supplied (controller snapshot: `none`), and
the candidate re-evaluation is `not-reevaluation`. No post-merge accept/reject
decision is required this cycle.

## Next replay

Re-run `task-grep` on this lineage (`01-eval`, candidate handbook) to confirm
the two new ergonomics rules remove the turn-10/turn-14 tool errors, and replay
the provisional candidate on `task-setdiff` and `task-total` to test whether the
`in`-membership and module-shadow rules generalize before promotion to
`runtime/handbook.md`. Also verify the executor correctly reports a `pass` once
the evaluator `copy_results` `export/` directory issue is fixed (a factory/CTO
infrastructure change), so a clean run is not mislabeled as a cycle failure.

## North-star impact

This run confirms the intended teachable outcome of `task-grep`: an agent that
understands the type-explicit text pipeline (`read_text` → `lines` →
`enumerate` → `where`/`in` → display strings) produced a correct, small,
byte-exact tool in 20 turns with little exploratory friction — exactly the
"replace `grep -nF` with a typed XSH program" ergonomics the north-star targets.
The two staged handbook rules make the check/lint boundary more learnable (fewer
surprise tool failures) without adding task-specific recipes, and the evaluator
`export/` finding is a trust-relevant factory defect: an infrastructure crash
currently turns a real product pass into a reported cycle failure. Fixing the
harness so a passing candidate is reported as a pass is a direct contribution to
the evidence-loop trust the north-star requires.
