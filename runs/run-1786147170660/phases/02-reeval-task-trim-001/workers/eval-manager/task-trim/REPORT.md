# Eval-manager report

## Result

fail

The phase is a pre-merge delivery check for approved ticket `task-trim-001`
(candidate XSH commit `2e244e4ac8c724c2e4720e8840405f8faaee1fb1`; build-id in
`xsh-build.state` confirms the trial image was built from that commit). The
linked `task-trim` replay did not go green: correctness passed byte-exactly
(`correctness.exact = true`) but `restrictions.passed = false`, so the
executor result is `fail` and, per `CYCLE-REQUEST.md`, the implementation
branch must be retained for review rather than merged. The candidate's own
proposed fix (the `[]` effect-marker diagnostic) was itself validated by the
evidence — the agent adopted `[]` for the pure helper without any
`[pure]`/`[none]`/`[no_effects]` guessing that the baseline run exhibited —
so the failure is attributable to an independent evaluator restriction-check
brittleness, not to the candidate change. Detailed decision in
`## Observation classification` and `## Next replay`.

## Effort metrics

One fresh trial (trial 1 only; configured count `1`), worker
`task-trim-1`:

- Assistant turns: 52 (1 user message)
- Tool calls: 54 (bash 44, write 4, read 4, edit 2); tool results 54
- Tool errors: 8 (structured `tool_errors` in phase and worker reports)
- Session span: 163,298 ms (~2.7 min); `agent_wall_ms` 165,046
- Stop reasons: 1 `stop`, 51 `toolUse`
- worker `result`: `pass` (agent_state pass, artifact present, budget pass,
  review present); evaluator `result`: `fail`

## Usage and cost

Provider `openrouter/deepseek/deepseek-v4-flash-0731`, one worker:

- Tokens: input 33,596; output 13,222; cacheRead 848,448; cacheWrite 0;
  bucket total 895,266 (provider `totalTokens` 895,266 — match)
- Reasoning tokens: 6,018 (provider-reported; subset of output, not added)
- Cost: input $0.00302364; output $0.00237996; cacheRead $0.015272064;
  cacheWrite $0; total $0.020675664; budget $0.50, budget_state pass
- No `unknown_costs`, no malformed usage lines, no budget failures
- No provider retries/errors; `response_elapsed_ms` and
  `output_tokens_per_second` both reported as 0 (undiagnostic), so latency
  attribution is neutral-to-unknown; there is no provider-health signal.

## Thinking evidence

- Thinking blocks: 39 (counted in session JSONL; matches worker `report.json`).
- Provider-reported reasoning tokens: 6,018; there is no separate `thinking.md`
  in the evidence packet, so raw thinking lives in `session.jsonl.bz2`.
- Grounded findings: the blocks correlate with the file-I/O discovery loop
  (turns ~7–11: `fs.read_bytes` rejected → `Path.read_bytes` discovered), the
  `func`/`proc` and boolean-operator parse iterations (turns ~18–26), and the
  bytes-reassembly work (turns ~30–34). The thinking carried the agent to a
  byte-exact artifact, but did not steer it to the `fs.`-prefixed form the
  evaluator requires, which is the source of the restriction failure.

## Tool-error findings

All 8 nonzero Pi tool results from the structured arrays (worker `report.json`
and phase `report.json` agree):

1. turn 8 — `check.unknown-module-api`: `fs.read_bytes` does not exist.
2. turn 10 — `check.effect-violation`: `?` on `read_bytes()` without the
   `error` effect (test script had `[fs]` only).
3. turn 15 — `parse.expected-ident`: `let in = ...` uses reserved name `in`.
4. turn 16 — `compact.main-missing-spread`: `main(argv: List[Str])` fixed
   param rejected; spread form `(...argv)` required.
5. turn 19 — `parse.unsupported-boolean-operator` (`&&`) plus hex-literal
   `0x20` and `||` parse cascades.
6. turn 21 — further binary-operator/hex parse errors with `or`.
7. turn 36 — `check.standard-module-shadow` (`bytes`), `unresolved-name`
   (`Bytes.lines`), `check.effect-violation` for `strip_edges` unrestricted —
   this message now names the `[]` fix — and `unknown-method` `to_bytes`.
8. turn 39 — `runtime.error`: `join` expected `List[Str]` (joining Byte lines).

Every structured error is accounted for. The `xsht api language:core.procs`
rejection noted in `review.md` was a discovery-query rejection contained in a
bash command whose overall exit was 0, so it is recorded as an observation
below, not as an additional structured tool error. No manager-session tool
errors (0).

## Timing evidence

No candidate/oracle per-case timing is recorded in `trial-1/run.json`; the
eval has no strict ratio gate (`EVAL.md`: timing is diagnostic until a stable
envelope is established). Worker session span 163,298 ms is the Pi
conversation clock and is not a program-timing measurement. Both sides run in
milliseconds; no envelope concern.

## Observation classification

- **Reusable progress — candidate fix validated (ticket task-trim-001).** On
  the candidate commit the unrestricted-proc diagnostic reads: "if it is
  side-effect-free, declare it with an empty effect list `[]`". `src/sema/check.rs`
  diff (4 lines) and `tests/sema.rs` (`checker_suggests_empty_effect_list_for_unrestricted_callee`,
  34 lines) confirm the change; `docs/SPEC.md` documents it. In the trial the
  agent hit the `strip_edges is unrestricted` error and went straight to
  `proc strip_edges(...) [] -> Bytes` — zero occurrences of `[pure]`,
  `[none]`, or `[no_effects]` in the session. The baseline run referenced in the
  ticket (run-1786146336183) required three invalid marker guesses. This is a
  genuine learnability/ergonomics improvement and supports the ticket's
  proposed fix.
- **Harness/evaluator mismatch — restriction false-negative (blocking, but
  unrelated to the candidate).** The submitted `trim.xsh` is byte-exact on all
  cases (non-hard-coded: it reads the file at runtime via `Path.read_bytes()`
  and writes via `Path.write()`), yet `evaluator.xsh` gates on the literal
  substring `"fs." in source`. The worker used the equally-valid Path-method
  read/write surface instead of the `fs.<fn>` spelling the checker greps for,
  so `restrictions.passed = false` despite the semantic intent ("no hard-coded
  text workaround") being met. The check measures an implementation spelling,
  not the capability. This is the sole reason the replay is not green.
- **Reusable handbook guidance — file I/O surface discoverability.** The agent
  spent several turns discovering how to read file content: `fs.read_bytes`
  does not exist, `Path.read_bytes()`/`Path.write()` do. `EVAL.md` expects the
  `fs`-module/text-read path; the approved handbook names `fs.write` but does
  not systematically list the file read/write methods (`fs.read_text`,
  `path.read_bytes`, `path.write`). A short general note removes repeated
  discovery friction and generalizes to any file-processing eval. Staged as a
  provisional `handbook-candidate.md`.
- **Minor product/learnability observations (no ticket this cycle).** Hex
  literals `0x20` are rejected (decimal only) — documented in `review.md`;
  boolean operators are `and`/`or` rather than `&&`/`||` (the `&&` message
  hints `and`); `func` is not a declaration keyword and errors are cryptic;
  `xsht api language:core.procs` is rejected even though the handbook cites
  `language:core.*`. These are real but individually weak/reproducible-only-
  once and not the ticket's scope; the task-trim `[]` diagnostic already
  demonstrates the preferred fix shape for the strongest one.
- **Latency/effort:** no provider retries/errors; session is short; wall time
  is agent-driven, not a provider-health regression.

## Handbook decision

Provisional candidate staged at
`runs/run-1786147170660/phases/02-reeval-task-trim-001/lineage/handbook-candidate.md`
(copy of the approved snapshot plus one paragraph added to the "Paths and
filesystem values" section). General lesson: file content read/write is
available on both the `fs` module (`fs.read_text`, `fs.write`) and Path
methods (`path.read_bytes()`, `path.write()`), failures propagate with `?`
under the `error` effect, and the exact member should be confirmed via
`xsht api method:Path.*`. Replay scope before promotion to
`runtime/handbook.md`: `task-trim` and at least one other file/config-writing
eval (e.g. `task-envcfg`, `task-ecount`) to confirm the note removes the
multi-turn read/write-API discovery and does not regress correctness. The
approved snapshot and checked-in `runtime/handbook.md` are unmodified.

## Tickets created

None. The deliverable blocker is an evaluator restriction-check brittleness
(eval-harness acceptance logic measuring a literal `"fs."` spelling rather than
the semantic capability), which is a CTO/designer harness decision and not a
general XSH product defect; no engineer product ticket is opened this cycle.
The already-approved `task-trim-001` remains the candidate under review.

## Post-merge decisions

None. The reconciler found no merged ticket files, so there are no post-merge
acceptance assignments. Candidate re-evaluation decision for `task-trim-001`
(pre-merge, not merged, not dispatched): the executor evidence **supports** the
proposed diagnostic fix — the agent reached `[]` with no effect-marker guessing
and the on-disk diff/tests implement exactly the ticket's smallest candidate.
However the linked `task-trim` replay did not clear the delivery gate
(restrictions failed on the unrelated `fs.`-literal check), so the
implementation branch `2e244e4` is **retained for review**, not merged. No
revert is proposed — the change works and should not be reverted; the
restriction-check brittleness must be resolved first.

## Next replay

Re-run `task-trim` on candidate commit `2e244e4ac8c724c2e4720e8840405f8faaee1fb1`
with the current handbook lineage
(`runs/run-1786147170660/phases/02-reeval-task-trim-001/lineage/`), after the
evaluator restriction check is revised (per the CTO/designer) to recognize
runtime file I/O (e.g. `Path.read_bytes()`/`Path.write()`) rather than the
literal `"fs."` substring, OR after the staged handbook candidate steers the
agent to the `fs.`/`fs.read_text` canonical form — but not both fixes bundled
so attribution stays clean. Verify correctness and restrictions both green.
Separately, replay a helper-using eval (e.g. `task-histogram` or
`task-dupcheck`) on the candidate commit to corroborate the `[]`-diagnostic
improvement across evals, which is the falsification check the ticket itself
names.

## North-star impact

The `task-trim-001` change measurably advances XSH learnability and
ergonomics: an agent writing a common effect-using helper no longer guesses
`[pure]`/`[none]`/`[no_effects]`; the checker now names the `[]` fix, reducing
rejected probes and reaching a correct script faster — precisely the "fewer
guesses, workarounds, tool errors, and repeated discoveries" target. The
handbook candidate improves the file-I/O learnability that underpins XSH's core
"connect processes, files, paths, streams" mission. The surfaced restriction-
check brittleness is a harness-quality matter: the factory should measure
agent capability (correctness + no hard-coding), not an implementation
spelling, so that a byte-exact, non-hard-coded solution is not mistaken for a
workaround. That distinction is part of keeping the evidence loop trustworthy.
