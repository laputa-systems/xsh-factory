# Eval-manager report

## Result

pass

Pre-merge validation of `task-jsonfilter-001` candidate commit
`a248267612439dfcfa203fba583ac3e95d37f70c` (engineer worktree
`.xsh-factory-worktrees/run-1786140236250/task-jsonfilter-001`). The single fresh
trial ran cleanly: all ten cases byte-exact, restrictions pass, protocol pass,
lint/check clean. The candidate is a focused lint-suppression fix (option (b) of
the ticket) with a direct regression test; it is accepted as supporting the
proposed fix. A concise JSON-trailing-newline handbook candidate is staged
provisionally.

## Effort metrics

Single trial `task-jsonfilter-1` (eval-worker):
- assistant turns: 22 (21 toolUse stop-reason + 1 stop)
- tool calls: 26; tool results: 26; tool errors: 3
- tools: bash 19, read 4, edit 2, write 1
- session span: 82,919 ms (agent conversation); agent wall 84,475 ms
- provider telemetry present: retry_count 0, retry_errors [], provider_errors [],
  response_elapsed_ms 0, output_tokens_per_second 0
- worker friction: low; 3 tool errors, all during scratch/verification (see
  Tool-error findings), none indicating repeated exploration. The worker
  completed the task in one coherent pass without internalizing-discovered
  rework loops.

Manager session: reads + this write; no tool errors.

## Usage and cost

Worker `task-jsonfilter-1` (provider: openrouter/deepseek/deepseek-v4-flash-0731):
- input tokens 23,849; output 5,332; cacheRead 201,280; cacheWrite 0
- provider total 230,461; bucket total 230,461 (match)
- reasoning tokens 1,927 (provider-reported; a subset of output)
- cost: input $0.00214641, output $0.00095976, cacheRead $0.00362304,
  cacheWrite $0, cache-read cost $0.00362304, total $0.00672921
- budget $0.50; no budget failure; unknown_costs 0
Aggregate: same as the single worker. Reasoning tokens were reported for this
worker.

## Thinking evidence

Worker had 14 thinking blocks and 1,927 provider-reported reasoning tokens.
Thinking was used to reason about the `jq -cS` key-sorting/newline contract
before writing code (turn 15), to reason about failure-control behavior (absent
vs empty vs invalid CFG_DOC), and to decide the review.md content. No thinking
text indicated confusion about the record-typed tail-return trap; the worker
chose the structural-projection path directly. Manager session also used
thinking blocks (not token-reported per-message for the manager; reasoning not
summed separately here).

## Tool-error findings

Worker `task-jsonfilter-1` tool_errors (3):
1. turn 5 — `err[parse.unknown-effect]: unknown effect 'out'` in scratch
   `/tmp/t.xsh`. Worker invented a nonexistent `out` effect during an early
   scratch probe. Agent exploration error, not a product defect.
2. turn 6 — `err[check.bare-print-ident]: bare identifiers in print are
   ambiguous; use $ident` in scratch `/tmp/t.xsh` (`print out`). The approved
   handbook already documents this exact rule, so this is the worker not
   applying handbook guidance on a scratch fixture. Ordinary friction; not a
   new product signal.
3. turn 16 — failure-control verification probe: absent/empty/invalid `CFG_DOC`
   each printed a runtime traceback (env-missing / invalid JSON), exited 3, and
   `ls /tmp/e.json` reported "No such file" — i.e. the desired behavior for the
   failure controls. The bash wrapper returned exit 1 because `ls` on the
   correctly-absent output file failed. False-positive tool error (expected
   behavior), classified as ordinary noise, not a defect.

Manager session tool_errors: none (raw structured array has zero errors from
this session).

## Timing evidence

No strict candidate/oracle timing gate for this eval. run.json per-case
candidate and oracle wall times are all in the ~11–13 ms range and byte-exact;
candidate exit 0 on the eight success cases and exit 3 on both failure
controls (oracle exit 1). Timing is diagnostic only; candidate/oracle
(ms) values, e.g. public 11.97/11.53, hidden_unicode 11.54/13.14,
hidden_malformed 12.46/12.33, hidden_missing 12.76/12.46. Both sides complete
in milliseconds; no latency signal for either side.

## Observation classification

- Candidate fix acceptance (task-jsonfilter-001): the commit implements the
  ticket's option (b) — `lint.redundant-tail-return-binding` is suppressed when
  a tail binding's annotation is a named record-schema type, because the
  suggested rewrite `return {...}: Type` is unparseable. Diff touches only
  `lint.rs` (record_type_names tracking + guard), adds a direct regression test
  `linter_does_not_suggest_unparseable_tail_return_for_typed_records` covering a
  typed record returned from a tail expression and a map/block record cast, and
  updates `docs/SPEC.md`. Sound, minimal, matches the acceptance criteria.
  Classification: correct product fix; accept.
- Agent-path evidence is indirect: this trial's worker never used a typed record
  binding (it projected plain structural records), so the in-session lint run
  does not itself prove the trap is gone. The strongest direct evidence is the
  commit's regression test plus an unchanged, byte-correct eval. The fix is a
  pure lint suppression with no runtime behavior change, so correctness is
  preserved by construction.
- JSON trailing-newline friction (worker review.md + session turn 48): worker
  had to use `json.encode` + `fs.write(out + "\n")` because `json.write`/
  `json.encode` emit no trailing newline. Reusable, generalizable guidance for
  any exact-JSON-file eval. Classified as reusable handbook guidance
  (provisional candidate), not a product ticket: a code change to json.newline
  behavior would alter a public contract and need its own scoped decision.
- Report-level harness gap: the phase `report.json` records `xsh_commit`
  `857154...` (the baseline) and the trial evidence hashes are `unknown`
  (`candidate_sha256`, `handbook_sha256`, `oracle_sha256`), so the candidate
  commit under test is not independently hash-pinned in the phase report. The
  candidate worktree HEAD is `a248267` (parent: the baseline), so the candidate
  is the intended build; this is a factory/reporting observation for the CTO,
  not an engineer ticket.
- Scratch-file parse/print errors (turns 5, 6): ordinary worker friction;
  both are already covered by the handbook or are agent invented-effect guesses.
  Noise.
- Failure-control probe exit code (turn 16): ordinary noise (expected behavior).

## Handbook decision

Provisional candidate staged at
`lineage/handbook-candidate.md` (approved snapshot copied unchanged, one
concise addition to Text and output):
- Lesson: "JSON serializers emit no trailing newline; for an exact-file contract
  that requires a final newline, serialize with `json.encode` and write
  `encoded + "\n"` via `fs.write`; verify key order/compactness against the
  oracle."
This is generalizable to any eval writing a byte-exact JSON file and removes a
discovery the worker had to make by probing the oracle. It is provisional —
not promoted — and requires replay before it becomes trusted. The record-typed
tail-return trap is an engine-side fix (engineer commit, validated here), not a
handbook item, so no record-annotation handbook sentence is added in this
cycle.

## Tickets created

None. No new product ticket is opened this cycle: the json-newline friction is
captured as a handbook candidate (docs/learnability) rather than a code contract
change, and the candidate lint fix is already covered by `task-jsonfilter-001`.

## Post-merge decisions

None. The reconciler found no merged tickets this cycle (`none`).
`task-jsonfilter-001` is a pre-merge candidate validated here; it is NOT marked
Merged, no engineer was dispatched, and the branch is not treated as main. The
pre-merge decision recorded is: ACCEPT — the executor evidence and the commit's
regression test support the proposed fix; recommend the CTO merge
`a248267612439dfcfa203fba583ac3e95d37f70c`.

## Next replay

After the CTO merges `a248267...` (reconciler will mark the ticket Merged and
fill the merge record), replay `evals/task-jsonfilter` at the merged commit and
re-confirm the worker no longer reproduces the
`redundant-tail-return-binding`/parse-error trap while all ten cases remain
byte-exact. Add `evals/task-histogram` as the falsification check that the
lint fix generalizes to another record-producing eval. Replay the staged JSON
trailing-newline handbook candidate across a second exact-JSON-file eval before
promoting it to `runtime/handbook.md`.

## North-star impact

This run validates a focused ergonomics/trust fix: a lint rule that steered
agents into an unparseable rewrite is corrected, so lint advice is safe to
apply for typed-record tail returns — improving learnability and predictable
record typing across every record-producing eval. The staged handbook candidate
makes the JSON output boundary (no trailing newline, exact-file contracts)
explicit and learnable rather than left to oracle probing, advancing XSH's
trustworthy, practical systems-glue mission. Neither change is a task-specific
recipe; each generalizes to other JSON/record workflows.
