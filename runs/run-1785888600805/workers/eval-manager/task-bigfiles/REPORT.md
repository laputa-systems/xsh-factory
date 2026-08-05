# Eval-manager report

## Result

pass

## Effort metrics

Single trial (`task-bigfiles-1`) against XSH commit `a67599b7865707d0ddbfdaf04bd1620f511556b8` and the approved handbook snapshot `lineage/handbook-approved.md`.

- Assistant turns: 49 (48 `toolUse` stops + 1 `stop`)
- Tool calls / results: 53 / 53 (bash 44, read 5, write 2, edit 2)
- Tool errors: 9 (all intermediate development-loop frictions; none blocked the final solution)
- Session span: 152,034 ms (~152 s) for 49 turns; agent-state `pass`.
- Worker friction: modest. The worker re-discovered the `sort-by --desc` flag-placement issue (turns 36–37) and switched to `0 - e.size`; it also worked around `parse_int` leniency for the strict-decimal failure control. Both resolved within the session.

Result: `pass` — all 9 cases byte-exact, restrictions, protocol, and reporting all pass (`run.json` `result: pass`, `classification: pass`).

## Usage and cost

Per worker `task-bigfiles-1`:

- Tokens (provider buckets): input 28,051; output 13,359; cacheRead 795,648; cacheWrite 0; bucket total 837,058. Provider-reported total 837,058 — no mismatch.
- Reasoning tokens: 7,451 (provider-reported; subset of output, not added to totals).
- Cost: total $0.019250874; input $0.00252459; output $0.00240462; cacheRead $0.014321664; cacheWrite $0; budget $0.50, no breach.
- Thinking blocks: 30.

## Thinking evidence

30 thinking blocks, 7,451 provider-reported reasoning tokens. Thinking (qualitative) correlates with the tool-error path: the worker reasoned through the `sort-by --desc` rejection twice (turns 36–37), then pivoted to `0 - e.size` for descending order; it also reasoned through the strict-decimal validation and built the `delete()` + forced-`parse_int()?` workaround. Reasoning-token counts were reported by the provider.

## Tool-error findings

All 9 nonzero Pi tool results from the structured `tool_errors` array (worker `task-bigfiles-1`), each accounted for:

1. Turn 11 (bash, exit 1, no output) — exploratory command; ordinary probe noise.
2. Turn 20 (bash, exit 1, no output) — exploratory command; ordinary probe noise.
3. Turn 24 (bash, exit 2) — `s.count_bytes() > 0 && rest == ""`: XSH rejects `&&`; emits `unsupported-boolean-operator` and asks for word form `and`. Language syntax discovery; resolved by the worker.
4. Turn 35 (bash, exit 2) — worker tested `0x10`; `parse_int` accepted hex (`x0x10` rejected after a prefixed probe). Also a BusyBox `sh: syntax error: bad substitution` from the shell harness wrapper (harness/`sh` quirk in a scratch probe). Evidence of the strict-decimal gap.
5. Turn 36 (bash, exit 2) — `sort-by { |e| e.size } --desc`: `err[check.unresolved-name]` on `--desc`, with a downstream fs type-mismatch masking it. This is the exact general named-option/block diagnostic the approved open ticket `task-bigfiles-001` describes; it recurs in this run.
6. Turn 37 (bash, exit 2) — `sort-by({ |e| e.size }, --desc = true)`: parse error, second `--desc` placement attempt. Confirms the flag-placement discovery loop.
7. Turn 38 (bash, exit 2) — candidate printed correct ranked output (5 files) but the scratch `sh` wrapper again raised `bad substitution`; a `sh`-wrapper harness quirk, not a candidate fault.
8. Turn 40 (bash, exit 1) — `xsht lint` warnings (`path-constructor` on `Path(argv[0])`, `redundant-command-interpolation` and `redundant-path-display` on `e.path.display()`) cause `lint` to exit 1; `fmt` passed. The final artifact addresses all three (uses `fp"..."` and bare `$e.path`), so the submitted solution is lint-clean.
9. Turn 41 (edit) — `Could not find edits[1]` in `/work/bigfiles.xsh`: edit-tool oldText mismatch; worker re-applied via a later edit. Ordinary tooling noise.

No `xsht api` discovery query failed in this session; all discovery was done via `xsht api api:fs.files` / `language:stream.sort-by` without error. No provider errors, no retries.

## Timing evidence

No strict candidate/oracle timing gate (eval contract: diagnostic only). Per case (candidate_ns / oracle_ns): public 12.1/11.4 ms; hidden_default 11.1/11.7; hidden_n2 11.0/11.1; hidden_single 12.5/11.4; hidden_deep 11.8/12.2; hidden_spaces 11.6/12.2; hidden_utf8 12.1/12.7; hidden_empty 11.2/11.4; hidden_bad_n 11.7/13.0. Both sides ~11–13 ms; candidate is not slower. `timings.passed: true`. On the failure control the candidate exited 3 and the oracle exited 1 (both nonzero, both print nothing), satisfying the contract. Timing is neutral.

## Observation classification

- **Product/tooling defect (general, already tracked):** `sort-by ... --desc` → `err[check.unresolved-name]` and `sort-by({...}, --desc=true)` parse error (turns 36–37). This is the same general named-option/block diagnostic-and-signature mismatch captured by approved open ticket `task-bigfiles-001` (which this run independently reproduces). Not a new ticket — this run is pre-implementation baseline evidence corroborating the approved ticket.
- **Reusable handbook guidance:** `parse_int` leniency (accepts hex/signs/whitespace) forces a non-obvious strict-decimal workaround for the `hidden_bad_n` failure control (turn 35 + `review.md`). The handbook's existing "deliberate validation / `?`" guidance does not warn that `parse_int` is not a strict validator. This is general and reusable (CLI counts/ports/sizes). Staged as a one-lesson provisional handbook candidate.
- **Ordinary noise / harness quirk:** bash probes with no output (turns 11, 20), the `sh: syntax error: bad substitution` from scratch `sh` wrappers (turns 35, 38), and the edit-tool oldText mismatch (turn 41). Not durable signal.
- **Agent efficiency:** 49 turns / 53 tools / 9 intermediate errors for a correct result on a short task is acceptable; the friction clusters on the two real discoveries above, not on repeated redundant exploration. Provider telemetry present with zero retries/errors, so latency is not a factor.

## Handbook decision

Provisional candidate staged at `lineage/handbook-candidate.md` (approved snapshot copied, one general paragraph added under "Effects and errors"): `parse_int` is lenient (hex/signs/whitespace), so for a byte-exact non-empty decimal contract, check the digit set (`delete("0123456789") == ""`) before parsing and force a rejected value through a typed conversion so postfix `?` exits nonzero and prints nothing.

Global, not eval-specific; applies to any CLI count/port/size validation. Requires later replay before promotion to `runtime/handbook.md`. No change to the approved snapshot or checked-in handbook.

## Tickets created

None. The only reproducible general defect this run surfaced (`sort-by --desc`) is already captured by approved open ticket `task-bigfiles-001` with merge-record placeholders untouched; a duplicate would add no signal. The `parse_int` strictness observation is staged as handbook guidance rather than a product ticket because the leniency is documented behavior and a workaround exists; it becomes a candidate ticket only if it recurs after replays.

## Post-merge decisions

None. The reconciler reported `none` merged tickets this cycle. Approved open ticket `task-bigfiles-001` remains pre-implementation; its `## Merge record` is untouched and it is not a post-merge acceptance assignment.

## Next replay

Replay `task-bigfiles` against the approved handbook snapshot plus `handbook-candidate.md` (strict-decimal validation lesson) to verify the `hidden_bad_n` case is reached without the `delete()`/forced-parse discovery loop. After `task-bigfiles-001` is implemented and merged, replay again to confirm the `sort-by --desc` flag-placement loop (turns 36–37) is removed and check a second stream-stage eval (e.g. `task-ecount`) for the same diagnostic. Both are falsification checks for the staged candidate and the approved ticket's fix.

## North-star impact

This run confirms XSH's practical systems-glue hypothesis: an agent with the handbook composes `fs.files` → `where` → `sort-by` → `take` → `each` and byte-matches the `find | wc | sort | head` oracle across every case, including empty-tree and malformed-count bounds, entirely in typed values with no subprocess escape. The eval surfaces two durable lessons: (a) the named-option/block call diagnostic misleads agents (already ticketed), and (b) strict-decimal validation needs an explicit idiom because `parse_int` is lenient (staged handbook candidate). Both improve learnability and ergonomics for exactly the boundaries the north star cares about — typed, explicit, composable glue without shell-style implicit text conventions.
