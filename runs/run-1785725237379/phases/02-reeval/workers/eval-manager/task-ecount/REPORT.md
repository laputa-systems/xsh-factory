# Eval-manager report: task-ecount

- Run: `runs/run-1785725237379` phase `02-reeval`
- Eval: `task-ecount` (`evals/task-ecount/EVAL.md`)
- Approved handbook snapshot: `runs/run-1785725237379/phases/02-reeval/lineage/handbook-approved.md` (`c7c9dd9abb6d50dac60562757a1824900f24d4bc2d38014d5cbf869f56bb0723`), unchanged from prior cycles
- Evaluated XSH commit (authoritative, from evaluator `run.json` and `xsh-build.state` build-id): `c2e1039d8856c04ad8466504d445dc93a341f720` — the exact clean engineer worktree for candidate ticket `task-ecount-003`
- Phase `report.json` top-level `xsh_commit` (`ea7dea2f…`) disagrees with both in-container artifacts; see Observation 6. It does not affect the verdict.

## Result

pass

The controller executed exactly 1 fresh trial against the approved handbook
snapshot and the candidate XSH commit `c2e1039d` (worktree
`runs/run-1785725237379/phases/01-ticket/worktrees/task-ecount-003`). Trial 1
passed every gate: correctness (byte-for-byte stdout match,
`candidate_sha256 == oracle_sha256 == c7c35609…`), restriction compliance (no
subprocess boundary), protocol (artifact present, review headings OK), and
timing (ratio 0.937 within the 0.90..1.10 gate).

This is a **pre-merge validation** of ticket `task-ecount-003`. Decision:
**accept — the executor evidence supports the proposed fix.** The ticket is
not marked merged, no engineer is dispatched, and the branch is not treated as
main. The ticket's merge-record placeholders are left untouched.

## Effort metrics

Trial 1 (`workers/eval-worker/task-ecount-1`):

- Assistant turns: 57 (stop reasons: 1 `stop`, 56 `toolUse`)
- Tool calls: 63 total — 58 `bash`, 3 `read`, 2 `write`; tool results: 63; tool errors: 0
- Session span: 293,381 ms (~4.9 min); agent wall: 295,158 ms
- User messages: 1 (single task dispatch)
- Worker friction: none blocking; two documented `xsht api` discovery frictions (see Observation classification 3 and 4)

## Usage and cost

Trial 1 (provider `openrouter`, model `openrouter/deepseek/deepseek-v4-flash-0731`):

- Input: 55,517 tokens; Output: 21,829; Cache read: 1,853,696; Cache write: 0
- Reasoning (provider-reported): 15,039 tokens (subset of output, not added to totals)
- Provider total tokens: 1,931,042; bucket total (`input+output+cacheRead+cacheWrite`): 1,931,042 — consistent
- Cost: input $0.00499653, output $0.00392922, cache read $0.033366528, cache write $0, **total $0.042292278** (~$0.0423); budget $0.50 → 8.5% used; `unknown_costs: 0`, `budget_failures: 0`
- Aggregate (single trial): $0.0423

## Thinking evidence

- Thinking blocks: 47; reasoning tokens: 15,039 (provider-reported).
- Grounded in `thinking.md`/session thinking blocks: the worker reverse-engineered the BusyBox `uniq -c` field width (min 7, grows with digits), compared `fs.files` vs `fd` file sets and confirmed identical (138 files, no hidden/symlink delta), discovered `group-by`'s `{key, items}` record shape empirically, and adopted the **two-pass stable sort idiom directly from the updated `language:stream.sort-by` contract** (thinking around session line 66: "Since sort-by is stable and supports compound via two-pass…"). The worker never projected a compound record key into `sort-by` and never observed a silent no-op sort in this run.
- The padding trick (`PAD.byte_slice(0, 7 - count_chars())`) was derived after the `tui.left_pad`/`repeat`/format search loop, which is worker friction but not an error.

## Tool-error findings

None.

All structured `tool_errors` arrays are empty: phase `report.json` `tool_errors: []`, worker `report.json` `tool_errors: []`. There are no failed Pi tool results and no invalid `xsht api` discovery queries that surfaced as tool errors in the current evidence packet. (The `method:Str` bare-receiver query was rejected in output text with exit 0, not as a tool error; it is classified as friction in Observation 4.)

## Timing evidence

Trial 1 (`run.json` `timings`):

- Candidate: wall 12,019,252 ns (12.02 ms), user 1,409,000 ns, system 2,818,000 ns
- Oracle: wall 12,827,290 ns (12.83 ms), user 1,381,000 ns, system 4,767,000 ns
- Ratio: 0.937 (candidate/oracle wall), inside the strict 0.90..1.10 gate → `timing: pass`
- Both processes complete successfully. The ratio is diagnostic; both timings are small single-run samples, so no causal timing claim is made.

## Observation classification

1. **Correctness success (ordinary, not noise):** byte-for-byte match on `/usr/share` and on a synthetic fixture with uppercase extensions, dot-in-directory paths, dotfiles, trailing dots, no-extension files, and four count-1 tie extensions (`""`, `data`, `gz`, `png`). Candidate and oracle outputs were IDENTICAL on both trees (session tool results). This confirms the eval contract holds on the candidate commit.
2. **Reusable signal supporting ticket task-ecount-003:** the worker's first `xsht api` query (session line 13) returned the new sort-by contract documenting supported key types, `--desc`, stability, and the two-pass idiom; the worker then used the two-pass idiom directly and correctly with no record-key experiment and no silent-failure discovery loop — exactly the loop the ticket's observation describes on the pre-fix baseline (`a66ade82`). Evidence: thinking blocks and the submitted `ecount.xsh` (two-pass `sort-by r.ext` then `sort-by r.count`).
3. **Product/tooling defect, already tracked:** `xsht api language:stream.group-by` still does not state the emitted `{key, items}` record shape; the worker discovered it by trial and error and documented it in `review.md`. This is the exact gap already tracked by open ticket `task-ecount-001` (stream-stage signatures missing); no new ticket.
4. **Worker friction / handbook gap (new):** `xsht api method:Str` (bare receiver) is rejected as `expected NAME.MEMBER`; the worker needed several summary-index greps (`xsht api summary`, `Str (28 items)`) to enumerate receiver methods. A concise general rule in the handbook ("use `xsht api summary` to enumerate a receiver's methods; a bare receiver query is invalid") would remove this for every eval worker. Staged as a provisional handbook candidate.
5. **Worker friction (mild, not promoted):** the no-pad-builtin discovery loop (`tui.left_pad`, `repeat`, display-strings) cost several turns; the PAD-pool slice idiom worked but is a recipe, not a general rule, so it is not staged as the one candidate.
6. **Harness/controller recording artifact:** phase `report.json` top-level `xsh_commit` (`ea7dea2f…`, worktree commit "fix test", sibling of HEAD) disagrees with the evaluator `run.json` `xsh_commit` and `xsh-build.state` build-id, which both pin `c2e1039d`. The evaluated binary was built from `c2e1039d`; the phase-level field is a controller recording discrepancy. Single occurrence, no impact on the verdict; noted, not ticketed.

## Handbook decision

Provisional candidate — one short, general rule.

`lineage/handbook-candidate.md` = approved snapshot plus one sentence in
`## Development loop and tooling`: enumerate a receiver type's methods via
`xsht api summary`; a bare receiver query such as `method:Str` is rejected
(`expected NAME.MEMBER`), so do not attempt it.

- General lesson: agents should not burn turns on invalid `xsht api` query shapes; the summary index is the enumeration mechanism.
- Replay scope: global — any eval whose worker needs to list methods of a receiver (`Str`, `Path`, `List`, `Map`). Concrete replays: task-ecount (next cycle), task-envcfg, task-tags.
- Promotion still requires review and replay on the shared lineage; this one-trial plan does not claim validation beyond this run.

## Tickets created

zero

No new ticket. The two product-adjacent observations are either already
tracked (`task-ecount-001`, open) or are being addressed by the candidate
commit under validation (`task-ecount-003`). The `method:Str` discovery gap is
staged as handbook guidance, not a product ticket, because the query grammar
constraint is intended behavior and the workaround is one line of reference
usage.

## Post-merge decisions

none

The reconciler found no merged tickets (`none`). Ticket `task-ecount-003` is a
pre-merge validation, not a post-merge acceptance:

- Ticket ID: `task-ecount-003`
- Candidate commit: `c2e1039d8856c04ad8466504d445dc93a341f720`
- Decision: **accept** (pre-merge). Evidence: (a) `xsht api language:stream.sort-by` in the worker's session documents key types, `--desc`, stability, and the two-pass idiom — acceptance criterion 1; (b) compound record keys sort deterministically and non-orderable keys fail loudly — covered by the commit's native tests `test_sort_by_compound_record_keys_and_stability` and `test_sort_by_rejects_non_orderable_keys_at_runtime` (stderr names `sort-by` and the key type) — criterion 2; (c) scalar-key sorting unchanged — the eval candidate sorts by scalar `Str` and `Int` keys and matches the oracle byte-for-byte — criterion 3; (d) two-pass stable idiom equivalent to compound keys — asserted by the native test and demonstrated live by the candidate's tie-containing fixture match — criterion 4; (e) the tie-containing-root replay part of criterion 5 was exercised by the worker's own `/tmp/fx` fixture (four count-1 extensions, `diff` IDENTICAL), while the controller's configured trial ran on the standard `/usr/share` root; the "no trial-and-error stability discovery" part is directly evidenced by the session.
- No revert proposed. Do not dispatch engineer; do not treat the branch as main.

## Next replay

Replay `task-ecount` against the merged `c2e1039d` (if the user merges the
branch) with the same handbook lineage (`c7c9dd9a…` snapshot), a synthetic
tie-containing root as the oracle input, and a check that the worker resolves
compound-key/diagnostic sort behavior from `xsht api` without the discovery
loop. If the new `method:Str` handbook candidate is staged in a later cycle,
the same replay also falsifies or supports it. Separately, ticket
`task-ecount-001` (stream-stage signatures) remains open for a future cycle.

## North-star impact

This run directly tests the trust objective: the previous run's agent believed
a `sort-by` pipeline worked while it silently returned unsorted input. On the
candidate commit, the contract is explicit (supported key types, stability,
two-pass idiom) and the agent reached a byte-exact oracle match without the
silent-failure loop, using the documented idiom on the first pass. That is the
"fewer guesses, fewer repeated discoveries" outcome the north star names, and
it validates the ticket's general claim that loud diagnostics plus documented
stability semantics improve learnability for every pipeline-shaped eval, not
just ecount. The one provisional handbook rule (method enumeration via
`xsht api summary`) targets the same goal at the tooling-discovery layer.
