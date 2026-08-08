# Eval-manager report

## Result

pass

## Effort metrics

Trial 1 (eval-worker, `task-pathparts-1`): 13 assistant turns, 16 tool calls
(9 `bash`, 4 `read`, 3 `write`), 16 tool results, 0 tool errors, 1 user
message. Session span 419,419 ms (~7.0 min). Evaluator state, agent state,
budget state, reporting state, and review all `pass`. No budget failure.

Friction: none in tooling. The worker reached a correct solution after a
moderate number of turns; the one recorded friction is documented in
`review.md` (`## xsht friction`) and is a handbook guidance signal, not a
tool failure (see Observation classification).

## Usage and cost

Per trial (provider-reported):
- input 45,830; output 3,265; cacheRead 65,344; cacheWrite 0;
  provider_total 114,439; reasoning 1,376 (subset of output); thinking
  blocks 9.
- cost: input $0.0041247, output $0.0005877, cacheRead $0.001176192,
  cacheWrite $0.000000, total $0.005888592.
- budget $0.50; budget_failures 0.

Aggregate (1 trial / 1 worker): $0.005888592 total, 114,439 bucket tokens,
0 unknown-cost fields.

Provider telemetry present: one `auto_retry` event — provider error
`Stream ended without finish_reason`, retry_delay 2000 ms, retry_successes 1,
retry_failures 0. This is external-health evidence, not an agent regression.

## Thinking evidence

9 thinking blocks; provider reported 1,376 reasoning tokens (subset of
output). The transcript shows the worker reasoning about `dirname`/`basename`
semantics vs the shell oracle (trailing slashes, `.`, `..`, root), extension
edge cases (`.profile` → none, `foo.` → empty string matching the oracle),
and the `print` command-word spacing trap that led it to compose the lines
with f-strings. All of that reasoning is qualitative evidence; the final
artifact and `LINT OK` are the authoritative confirmation.

## Tool-error findings

None.

Every current structured `tool_errors` array (phase, worker) is empty; there
were zero failed Pi tool results and no invalid `xsht api` discovery queries
in the worker or manager sessions.

## Timing evidence

No strict candidate/oracle ratio gate in this eval (both sides finish in
milliseconds; timing is diagnostic). Recorded wall times per case
(candidate / oracle ns):
- public 12,527,388 / 11,709,588
- hidden_deep 13,653,192 / 13,640,026
- hidden_plain 12,389,929 / 12,484,804
- hidden_rel 13,419,523 / 11,398,251
- hidden_dotdir 15,319,336 / 11,066,747
- hidden_dotfile 13,925,945 / 12,289,927
- hidden_targz 15,023,249 / 11,895,548

All within the low-millisecond envelope; candidate/oracle are the same order
of magnitude, and 11–15 ms includes native process-launch noise for a
five-line program. Diagnostic only.

## Observation classification

- **Product/tooling fix validation (accept).** The primary signal of this
  re-evaluation. Candidate commit `f697fa2453f676f686c685171f5a8a9d514f871e`
  ("Fix lint reads in display string shorthand") changes
  `src/syntax/literal.rs` so the display-string parser counts both `${...}`
  and `$name` shorthand interpolations, with regression tests in
  `crates/xsht/tests/lint.rs` and `tests/syntax.rs` plus a `SPEC.md` note.
  On the fresh trial the worker wrote `print f"dir=${dir}"` (display-string
  idiom) and `xsht lint pathparts.xsh` exited 0 (`LINT OK`, no
  `unused-local`), with no `+` concatenation workaround. All 7 cases
  correct, restrictions `no_forbidden`/`path_referenced` pass, protocol
  `artifact_present`/`review_ok` pass. This satisfies the ticket's
  acceptance criteria directly.
- **Reusable handbook guidance (provisional candidate).** Worker friction in
  `review.md`: `print "dir=" $dir` emits `dir= /srv/app` because `print`
  inserts exactly one space between separate command-word arguments, breaking
  a byte-exact `key=value` layout. The worker switched to the f-string form,
  which the handbook already recommends, but the handbook does not state that
  the `print "count" $count` form inserts a space. This generalizes to every
  exact-output eval (task-tags, task-intsum, task-pathparts). Staged as a
  concise provisional candidate; needs replay before promotion.
- **Provider latency (external-health, not agent).** One retry event
  (`Stream ended without finish_reason`, 2 s delay) in the worker session;
  classify as provider-latency signal. Not an agent-efficiency regression.
- **Ordinary noise.** None significant.

## Handbook decision

Provisional candidate staged at
`runs/run-1786177505335/phases/02-reeval-task-pathparts-003/lineage/handbook-candidate.md`.

General lesson: `print` inserts exactly one space between separate
command-word arguments, so for a byte-exact `key=value` line compose the
entire line in a single interpolated display string
(`print f"key=${value}"`) rather than `print "key=" $value`, which emits
`key= value`. This is a short, general rule that removes a repeated trap in
exact-output evals; it does not change the language or the tool.

The approved snapshot is unchanged. The candidate is provisional: it has been
observed in one trial and must be replayed before promotion to
`runtime/handbook.md`. No change to the eval contract, fixture cases, or
oracle.

## Tickets created

Zero.

No new ticket this cycle. The candidate fix `task-pathparts-003` is validated
pre-merge (below), and the print-spacing friction is handled as handbook
guidance rather than a product defect (it is documented `print` behavior, not
a broken surface). No factory-target ticket; no engineer dispatch.

## Post-merge decisions

None.

The controller reconciled no merged tickets (`merged tickets: none`). This
cycle is a **pre-merge validation** of candidate ticket `task-pathparts-003`
against candidate commit `f697fa2453f676f686c685171f5a8a9d514f871e` in the
clean engineer worktree `…/.xsh-factory-worktrees/run-1786177505335/task-pathparts-003`
(matches phase `run.json` `xsh_commit`). Decision: **accept** — the executor
evidence supports the proposed fix. The fresh trial demonstrates the
display-string idiom now passes `xsht lint` (exit 0) with no `+`
concatenation workaround, all seven oracle cases correct, restrictions and
protocol compliant. Ticket merge-record placeholders are left untouched for
reconciliation; do not treat the branch as main and do not dispatch engineer.

## Next replay

1. Replay `task-pathparts` after the CTO merges `f697fa2` to confirm the
   display-string solution continues to pass `check`/`fmt`/`lint` and all
   seven cases on the merged build (post-merge acceptance for
   `task-pathparts-003`).
2. Replay the provisional print-spacing handbook candidate on a second
   exact-output eval (e.g. `task-intsum` or `task-tags`) to falsify or
   confirm that composing a byte-exact line with `print f"key=${value}"`
   (rather than `print "key=" $value`) removes the space-insertion trap, and
   that the negative case (a genuinely unused local still reported by lint)
   holds.

## North-star impact

This run validates a concrete ergonomics/trust fix: `xsht lint` no longer
false-positives the handbook-recommended display-string idiom, so an agent can
follow the documented form without discovering a non-obvious `+`
concatenation workaround. That directly advances the north-star goals of fewer
guesses/workarounds, a trusted learnable surface, and lower agent effort
without sacrificing correctness. The companion provisional handbook sentence
(reuse of the print spacing trap) is a small, general learnability gain for
all byte-exact-output evals. The final solution is a clean five-line typed-Path
program with no subprocess boundary, honoring the explicit-boundary ethos.
