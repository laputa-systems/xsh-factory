# Eval-manager report

## Result

pass

## Effort metrics

One fresh trial (`trial_id: 1`, eval `task-ecount`) against the candidate
worktree commit `c2e1039d8856c04ad8466504d445dc93a341f720`.

- Worker `task-ecount-1`: 83 assistant turns (1 user message), 91 tool calls
  (84 `bash`, 2 `edit`, 3 `read`, 2 `write`), 91 tool results, 0 tool errors.
  Stop reasons: 82 `toolUse`, 1 `stop` (normal completion).
- Session span: 211,672 ms (Pi conversation); agent wall 213,350 ms.
- Worker friction: moderate. The session spent roughly turns 24–147 on API
  discovery (Path-to-Str conversion, group-by/fold result shapes, Int-to-Str
  conversion, padding). No sort-by stability discovery loop occurred — see
  Observation classification.
- Evaluator: candidate stdout byte-for-byte equal to the oracle; both
  processes completed successfully; review present; restrictions passed.

## Usage and cost

Provider `openrouter/deepseek/deepseek-v4-flash-0731`, reasoning level `high`.

- Buckets: input 45,161; output 19,447; cacheRead 1,911,552; cacheWrite 0;
  bucket total 1,976,160; provider-reported total 1,976,160 (consistent).
- Cost: total USD 0.041972886; input 0.00406449; output 0.00350046;
  cacheRead 0.034407936; cacheWrite 0. Budget USD 0.50; budget_state `pass`.
- Single trial; aggregate equals the trial above.

## Thinking evidence

69 thinking blocks; provider reported `reasoning_tokens: 9458` (subset of
output, not added to totals). Thinking level was `high` throughout.

Qualitative findings from `thinking.md`-equivalent content in the session
JSONL: the worker confirmed the compound `sort-by` record key contract from
`xsht api` at line 24, then used the compound key directly in its first real
draft (line 119 probe and the submitted `ecount.xsh`), verifying tie ordering
against a synthetic root at line 169. No thinking block shows the
"the sort didn't apply" discovery loop documented in ticket
`task-ecount-003`; the fix removed that loop.

## Tool-error findings

None. The structured `tool_errors` arrays are empty in the phase
`report.json`, the worker `report.json` (`tool_errors: 0`, all 91 tool
results non-error), and the evaluator `run.json`; the manager session also
recorded no failed Pi tool results. Every `xsht api` probe in the session
returned a structured result (some `status: missing` — e.g.
`api:stream.fold`, `api:stream.sort-by`, `method:Path` — which are discovery
misses, not tool failures, and are covered by existing open tickets).

## Timing evidence

Evaluator `run.json` timing (candidate vs. oracle on `/usr/share`):

- candidate wall 13,329,630 ns (~13.33 ms), user 0.881 ms, sys 3.524 ms;
- oracle wall 12,122,300 ns (~12.12 ms), user 1.145 ms, sys 4.567 ms;
- ratio 1.0995957863 — inside the eval's strict `0.90..1.10` window;
  `timing: pass`.

This is a single-trial measurement, so per the eval's manager policy the
ratio is diagnostic support, not yet a causal claim; a repeated trial set
would be needed to treat timing effects as causal.

## Observation classification

- **Product fix validated (reusable signal).** The candidate commit
  `c2e1039` ("streams: order sort/sort-by record keys and reject unsupported
  keys loudly") makes `sort-by` compound record keys order lexicographically
  field by field, keeps the sort stable, rejects non-orderable keys loudly,
  and documents the contract. The worker independently confirmed the updated
  `xsht api language:stream.sort-by` contract at session line 24 (text names
  supported key types, ascending/`--desc` semantics, and stability), then
  used the compound key `{count: r.count, ext: r.ext}` directly (line 119
  probe, final `ecount.xsh`). Tie ordering was verified byte-for-byte
  against the oracle on a synthetic tie-containing root at line 169
  (`/tmp/fix`: `dir/d` vs `gz` both count 1, ext tie order matched). The
  worker did not need the undocumented stability/two-pass discovery loop the
  ticket described. This satisfies acceptance criteria 1, 2, and 5 of
  `task-ecount-003` in-executor; criteria 3 and 4 (scalar-key behavior
  unchanged; two-pass idiom preserved) are covered by the commit's native
  tests (`tests/xsh/stdlib/streams.xsh` adds compound-key, `--desc`,
  stability, and two-pass-equality tests; `tests/sema.rs` adds record-key
  acceptance and rejection cases).
- **Worker friction (already tracked).** The worker burned many discovery
  turns on Path-to-Str conversion, `group-by`/`fold` empty signatures, and
  Int-to-Str conversion (see worker `review.md`). These are product
  discoverability gaps already tracked by open tickets `task-ecount-001`,
  `-002`, `-004`–`-008`; not new tickets here.
- **Harness nuance (ordinary).** The phase-level `data.xsh_commit` records
  baseline main `ea7dea2f…` while the trial `run.json` records the candidate
  `c2e1039d…`. This matches the pre-merge validation setup (candidate is not
  on main) and is not an error.
- **Noise:** none beyond the expected single-run variance.

## Handbook decision

Unchanged. The approved snapshot (`c7c9dd9a…`) already directs agents to
`xsht api language:stream.sort-by` for ordering semantics; the sort-by
contract fix lives in the product's live `xsht api` reference, which is the
authoritative source for the agent. The approved snapshot was copied
unchanged to `lineage/handbook-candidate.md` (sha256
`c7c9dd9abb6d50dac60562757a1824900f24d4bc2d38014d5cbf869f56bb0723`).
Replay scope: any pipeline eval (task-ecount, and future stream/sort evals)
should keep seeing the documented compound-key behavior or the loud
diagnostic — never silent unsorted output.

## Tickets created

None. The validated fix is candidate ticket `task-ecount-003` (already
Approved; this run is its pre-merge validation). No new reproducible defect
beyond the open tickets was found.

## Post-merge decisions

None — the reconciler found no merged tickets this cycle
(`merged ticket files: none`).

Candidate pre-merge validation (recorded here per the dispatch, not a
merged-ticket decision): ticket `task-ecount-003` candidate commit
`c2e1039d8856c04ad8466504d445dc93a341f720` is **accepted** for merge on the
executor evidence. Evidence: trial 1 passed correctness
(`exact_output: true`, oracle/candidate sha256 both
`c7c35609…`), restrictions, protocol, and timing (ratio 1.0996 within
`0.90..1.10`); the worker used the documented compound `sort-by` record key
with correct tie ordering on a synthetic tie root; the commit adds native and
sema tests for compound keys, stability, `--desc`, and the loud failure.
The ticket must not be marked merged by this run; reconciliation marks it
after the user merges the implementation branch.

## Next replay

Post-merge acceptance replay of `task-ecount` on the merged commit
`c2e1039d…` (or its merge ancestor on main), using the same approved
handbook lineage snapshot `c7c9dd9a…` (lineage
`runs/run-1785733794880/phases/02-reeval/lineage/handbook-approved.md`),
with a synthetic tie-containing root in the executor inputs to re-verify
byte-for-byte oracle match and confirm the worker still reaches the compound
sort directly without the stability discovery loop. A second replay on a
nearby filesystem shape (e.g. `/usr/share` after the tree drifts) would
falsify tree-specific luck.

## North-star impact

The validated fix removes a silent correctness trap in the core pipeline
abstraction: `sort-by` previously returned unsorted input with exit 0 for
record keys, which eroded trust and forced trial-and-error discovery. The
candidate makes ordering explicit (documented supported key types, stable
ascending/`--desc` semantics, lexicographic record comparison) and fails
loudly on unsupported keys, matching the north star's demand for explicit
boundaries and no "repeated discoveries." The single fresh trial shows an
agent reaching the byte-exact oracle solution using the documented compound
sort directly — the behavior the ticket promised — at a cost of ~0.042 USD
in 83 turns, with all remaining friction already tracked by other tickets.
