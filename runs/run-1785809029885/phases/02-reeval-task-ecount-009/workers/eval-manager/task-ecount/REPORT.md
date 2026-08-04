# Eval-manager report

## Result

pass — pre-merge validation of candidate ticket `task-ecount-009`.

This phase re-evaluated the clean engineer worktree at candidate XSH commit
`95dd3b643588c290d035d2d99a28d0839001d731` ("Fix `?` inside stream-stage
closures followed by a method call"). The single fresh trial achieved full
pass: `correctness.passed`, `restrictions.passed`, `protocol.passed`,
`timing.passed`, byte-for-byte oracle match, and exact-output match
(candidate and oracle `sha256` both `c7c35609…`).

Candidate re-evaluation decision: **supported.** The executor evidence plus a
direct probe of the built candidate confirm the ticket's acceptance criteria:

1. The ticket's exact failing form
   `s |> map { |x| (x.split(".") |> last())? } |> collect()` now compiles
   (`xsht check` exit 0) with no `err[compact.indexed-build]` /
   `full_ir_function_blocker` and no mislocated error at the `proc` line.
2. `xsht check` and `xsh` agree: the inline `?`-then-method form and the bare
   trailing `?` form both check cleanly and run; a genuine failure inside a
   closure propagates as a normal runtime error (`result.propagate`,
   `empty-stream`, exit 3) — not an IR blocker.
3. The `List.get`/index and `Path.ext` workarounds continue to behave; the
   worker's winning solution used index access and matched byte-for-byte.
4. The `task-ecount` replay on the candidate still matches the
   `fd | awk | sort | uniq -c | sort -n` oracle exactly and passes the
   timing gate (ratio `1.013`).

Per dispatch, the ticket is NOT marked merged, no engineer is dispatched, and
the branch is not treated as main. The evidence supports the proposed fix;
promotion to merged remains a CTO decision pending the engineer's native
regression tests already present in the change
(`tests/xsh/stdlib/streams.xsh` lines 76–92).

## Effort metrics

Single trial (worker `task-ecount-1`, trial 1): `assistant_turns=40`,
`tool_calls=51`, `tool_results=51`, `tool_errors=1`, `user_messages=1`,
`thinking_blocks=31`. Tools: `bash=43`, `edit=2`, `read=3`, `write=3`.
Session span `session_span_ms=259515` (~259.5 s), agent wall
`agent_wall_ms=260978`. One tool error (see Tool-error findings) during
iterative padding fix — resolved within the same session; no worker friction
remaining (`review.md` reports `## xsht friction: None`).

## Usage and cost

Provider: `openrouter/deepseek/deepseek-v4-flash-0731`, reasoning `high`.

- `input_tokens=65155` ($0.00586395)
- `output_tokens=15128` ($0.00272304)
- `cache_read_tokens=669184` ($0.012045312)
- `cache_write_tokens=0` ($0)
- `total_bucket_tokens=749467` (= provider `totalTokens=749467`, no mismatch)
- provider total cost `$0.020632302`; budget `$0.50`; budget_state pass.

Single trial, so aggregate equals the above.

## Thinking evidence

Provider reported `reasoning_tokens=9364` (subset of output; not added to
output or total). `thinking_blocks=31`. Thinking evidence is qualitative: the
session advanced from fd-awk-oracle matching through a leading-padding
mismatch (turn 24) to a width-7 `tui.left_pad(f"${count}", 7)` final layout,
consistent with the byte-exact output. No reasoning text needed to explain a
discrepancy; the structured records are internally consistent.

## Tool-error findings

The structured `tool_errors` array contains exactly one worker tool error
(`tool= bash`, `turn= 24`):

- A `diff` between `/tmp/oracle.txt` and `/tmp/mine.txt` exiting 1, showing a
  leading-padding mismatch: oracle `      1 script` / `     18 pub` /
  `    119 crt` (7-wide) versus the candidate's then-current `     1 script`
  / `    18 pub` / `   119 crt` (6-wide).

This is an expected "files differ" signal from a mid-development padding-width
bug, not a Pi-tool failure and not a product defect: the worker corrected to
width 7 and the final candidate matched byte-for-byte. No invalid `xsht api`
discovery queries occurred, and the manager session produced zero tool errors.
Manager side: `None.`

## Timing evidence

Candidate/oracle (ns): candidate `wall=11504468`, `user=969000`,
`system=2909000`; oracle `wall=11352217`, `user=1935000`, `system=4501000`.
Ratio `candidate_wall/oracle_wall = 1.0134`, within the strict gate
`0.90..1.10` (timing `passed=true`). This is a diagnostic measurement here;
the eval contract makes the ratio a gate and it passed, so no timing failure
is reported separately.

## Observation classification

- **Correctness (reusable product signal, positive):** the candidate commit
  removes the `full_ir_function_blocker` for `?` inside stream-stage closures.
  Direct probe: `map { |s| (s.split(".") |> last())?.lower() }` checks exit 0
  and a failing closure propagates `empty-stream` as a normal runtime error
  (exit 3). This is the general fix the ticket intended, not an ecount
  shortcut; evidenced by the regression tests in
  `tests/xsh/stdlib/streams.xsh` (lines 76–92) covering `?`-then-method and
  bare trailing `?`.
- **Ordinary worker noise:** the single turn-24 leading-padding diff mismatch
  was self-corrected to width 7; not a defect.
- **Not-a-defect / non-goal:** worker `review.md` notes a `group-by`-terminal
  composability gap and the lack of an `Int->Str`/`%d` formatting primitive.
  These are qualitative product observations not reproduced or gated here, and
  they are out of scope for this candidate; no ticket opened on the basis of
  this run.

## Handbook decision

Unchanged. `lineage/handbook-candidate.md` is an exact copy of the approved
snapshot (`sha256 97c5d804…` both). The approved handbook already describes
postfix `?` as the standard error-propagation idiom and never documented the
blocker or a workaround, so no sentence needs revising; the validated fix makes
the documented idiom work as written. Replay scope: next `task-ecount` run on
the merged commit should again pass byte-for-byte and the timing gate with no
`full_ir_function_blocker`.

## Tickets created

None. No new ticket is opened; this run validates an existing Approved
candidate (`task-ecount-009`) on the shared handbook lineage and candidate
worktree.

## Post-merge decisions

None. The reconciler found no merged ticket files (`none`) for this cycle, so
there are no post-merge acceptance assignments. The pre-merge decision on the
`task-ecount-009` candidate is recorded in `## Result`: **supported.**

## Next replay

Eval `task-ecount`, shared handbook lineage
`runs/run-1785809029885/phases/02-reeval-task-ecount-009/lineage/handbook-approved.md`
(current snapshot `97c5d804…`), against the merged implementation of
`task-ecount-009` (expected commit `95dd3b6` or its merge successor). The
post-merge check should confirm: (1) the `?`-in-closure forms still avoid
`full_ir_function_blocker` and `xsht check`/`xsh` agree; (2) `task-ecount`
still byte-for-byte matches the `fd | awk | sort | uniq -c | sort -n` oracle;
(3) candidate/oracle wall ratio stays within `0.90..1.10`. This is the
falsification check that would reject the fix if it regressed under the same
oracle and a nearby filesystem shape.

## North-star impact

Validating this fix directly advances the north star's trust and learnability
goals: postfix `?` is the documented standard error-propagation idiom, and it
now works inside stream-stage closures instead of crashing the compact IR
builder with an unlocated `full_ir_function_blocker`. Agents writing real
pipeline glue (task-ecount, task-tags, task-envcfg, or future ports) no longer
need a discovery workaround loop for an expected failure inside a `map`/`where`
block, reducing turns and repeated discoveries while keeping errors explicit,
typed, and source-located. The eval still byte-for-byte matches the Unix
oracle with no subprocess boundary, preserving the explicit-boundary ethos of
the mission.
