# Eval-manager report

## Result

pass

## Effort metrics

Single fresh trial (`task-histogram-1`) run once by the controller against the
candidate XSH build `aaa968c73fd7649f70a6a94e21f77a90bf6a778c` (confirmed by
`xsh-build.state` build-id `aaa968c73fd7649f70a6a94e21f77a90bf6a778c-vc2f469414b8ae5c7`,
which compiled the engineer worktree at
`phases/01-ticket/worktrees/task-histogram-002`). Trial 1 wall span
`session_span_ms = 268959` (~269 s); `agent_wall_ms = 270583`. Assistant turns
68 (1 user message), tool calls 74 (bash 66, edit 2, read 4, write 2), tool
errors 2, thinking blocks 56. Provider telemetry present with `retry_count 0`,
`provider_errors []`, `response_elapsed_ms 0`; no external-health events, so
the ~4.5-minute span is normal agent work, not provider-induced delay.
Result per worker: `pass`; evaluator manifest classification `pass`.

## Usage and cost

Provider total tokens 1,923,674 = input 87,478 + output 21,092 + cache-read
1,815,104 + cache-write 0. Reasoning tokens reported 10,381 (thinking blocks
56). Cost USD 0.04434145199999999 (input 0.007873…, output 0.00379656,
cache-read 0.032671872). Cache-write 0. Budget USD 0.50, no breach
(`budget_state: pass`). Aggregate = single trial, USD 0.0443.

## Thinking evidence

The provider reported reasoning-token counts (10,381) and the session contains
56 thinking blocks in `thinking.md`/session JSONL. The agent reasoned
correctly about the north-star shape (read_text -> parse -> integer-divide ->
group-by -> map key/count -> sort-by -> fold cumulative), about
group-by returning `{key, items}` records, about `/` being integer division
for Int (discovering `//` is invalid), and about requiring validation-before-
print so an invalid value exits nonzero with empty stdout.

## Tool-error findings

Two failed Pi tool results in worker `task-histogram-1`, both benign and
accounted:
- Turn 49 `bash`: `sh: syntax error: bad substitution` (exit 2). The agent's
  shell line used bash-only `${PIPESTATUS[0]}` in BusyBox ash. Worker friction
  only; the xsh invocation itself succeeded and the agent moved on.
- Turn 58 `edit`: "Could not find the exact text in /work/histogram.xsh."
  The edit old-text did not byte-match the file; resolved by rewriting the
  file with `write`. Worker friction only.

Manager session: zero tool errors. No provider retry/error events. Both
observations are ordinary short-task friction, not product, harness, or
evaluator failures.

## Timing evidence

Candidate/oracle per-case times (ns, from `run.json`): public
11.3/12.2, hidden_width 12.0/13.9, hidden_many 15.9/13.7, hidden_sparse
11.4/15.8, hidden_single 11.0/15.0, hidden_ties 14.0/15.2, hidden_empty
14.3/14.6, hidden_bad_width 14.3/15.1, hidden_bad_value 11.6/13.0 — all in the
~11–16 ms range. The eval contract defines no strict candidate/oracle timing
ratio gate; timing is diagnostic only. No gate applies.

## Observation classification

- Correctness: pass (all 9 cases byte-exact, `all_exact: true`, including both
  failure controls exiting nonzero with empty stdout).
- Restrictions: pass — source contains `sort-by`, `parse_int`, and
  `fs.read_text`/`Path.read_text`; no subprocess boundary.
- Protocol: pass (artifact present, review.md with required headings, no
  template placeholders).
- Worker friction (reusable-signal candidates, below-gate): (1) `/` is the
  Int division operator and `//` parses as an error — already covered in the
  approved handbook's "`//` is not a comment marker" note, resolved in a
  couple of turns; (2) a `fold` block that calls `print` fails with the
  cryptic `indexed IR could not encode full_ir_function_blocker`, which the
  agent worked around by computing rows in the fold and printing in a
  separate loop; (3) two trivial tool errors (bash substitution, edit
  mismatch). None rises to a strong reproducible product/tooling defect in
  this one-trial packet.
- Timing: diagnostic only (no ratio gate). Latency attribution: `unknown`
  (telemetry present but `response_elapsed_ms 0` / `output_tokens_per_second
  0`); judgment rests on turns/tokens/tool errors, which are ordinary for the
  difficulty.

## Handbook decision

unchanged. The candidate build, not the handbook, was under test; the sole
strong signal (grouped scalar-key `sort-by`) is a checker fix already packaged
by the candidate commit and needs no handbook text. The worker-observed
frictions (`/` as Int division, fold blocks being effect-free) are already
reflected in the approved handbook or are too narrow to meet the
promote-after-replay bar in a one-trial pre-merge phase. Copied
`handbook-approved.md` unchanged to `lineage/handbook-candidate.md`
(identical SHA-256 `3b56a781…`). No replay of a handbook candidate was
performed, and none is claimed.

## Tickets created

zero. No new ticket this cycle; this was a pre-merge acceptance of
`task-histogram-002`, not a discovery phase.

## Post-merge decisions

Single reconciled ticket under review: `task-histogram-002`
(`tickets/task-histogram-002.md`), candidate implementation commit
`aaa968c73fd7649f70a6a94e21f77a90bf6a778c` on branch
`factory/task-histogram-002/1785900055647` in the clean engineer worktree.
Decision: ACCEPT as pre-merge validated support.
Evidence: the fresh trial was compiled and executed from that exact worktree
(commit `aaa968c`, the "Accept sorting grouped scalar keys" change to
docs/SPEC.md, tests/sema.rs, tests/xsh/stdlib/streams.xsh), and the
`task-histogram` executor reported `pass`: all nine cases byte-exact and the
literal `sort-by` restriction gate satisfied (group-by -> sort-by -> fold
north-star path reached). The candidate packages direct native coverage that
`group-by { |x| x } |> sort-by { |g| g.key }` passes `xsht check` for Int,
Str, Bool, and Path keys (`checker_accepts_group_by_key_sort_by_for_scalar_keys`).
No merge fields were recorded because the branch is still pre-merge; the
reconciler fills `## Merge record` after the CTO merges. Cross-eval generality
tying (task-groupsum / task-ecount replays and the task-bigfiles manifest
named in the ticket's basis) was not part of this phase's active-eval set and
is deferred to next replay, not treated as a blocker for this histogram
acceptance. No revert proposed.

## Next replay

Replay eval `task-histogram` on the merged main lineage once ticket
`task-histogram-002` is merged, confirming the natural `group-by |>
sort-by { |g| g.key }` path still checks on the merged commit and the
restriction gate holds. Additionally run cross-eval generalization replays
(`task-groupsum`, `task-ecount`) and the task-bigfiles manifest check named in
the CTO acceptance gate to confirm the grouped-key fix generalizes beyond
`task-histogram`.

## North-star impact

The candidate makes the everyday grouped-aggregation idiom
"group, then order by the group key" (`group-by |> sort-by { |g| g.key }`)
type-check for scalar Int/Str/Bool/Path keys instead of forcing agents into a
Map + manual `sort()` workaround, removing a checker-grade ergonomics/correctness
hole in the stream boundary. This fresh trial independently confirms the fix on
the canonical binned-cumulative distribution pipeline, keeping XSH's
measurement-summary glue discoverable, composable, and learnable without
subprocess escapes or hard-coded answers.
