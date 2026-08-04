# Eval-manager report — task-ecount (phase 02-reeval)

## Result

pass. The single fresh trial executed by the controller passed every executor
gate: `correctness.exact_output: true`, `restrictions.passed: true`,
`protocol.review_ok: true`, `timing.passed: true`, `result: pass`
(`workers/eval-worker/task-ecount-1/run.json`). Candidate output is
byte-identical to the `fd | awk | sort | uniq -c | sort -n` oracle
(`candidate_sha256 == oracle_sha256 == c7c35609…`, verified against
`candidate.stdout`/`oracle.stdout`). The phase `report.json` marks the phase
`fail` only because the manager report and handbook-lineage artifacts were
absent at controller time; both are produced by this report.

Candidate re-evaluation task-ecount-003 (pre-merge validation of clean
engineer worktree at commit `c2e1039d8856c04ad8466504d445dc93a341f720`):
**ACCEPT**. The executor evidence and source review support the proposed fix.
The worker image ran the candidate commit (run.json `xsh_commit: c2e1039d…`);
the worker read the new `sort-by` contract from the live `xsht api` inside the
container (session turn 19) and applied the documented two-pass stable idiom
directly, with no stability discovery loop, and validated tie ordering against
the GNU oracle on a synthetic tie-containing root with a byte-for-byte MATCH.
This satisfies the ticket's acceptance criteria (details in Observation
classification).

## Effort metrics

Trial 1 (only trial; controller completed 1 fresh trial):
- Assistant turns: 85 (stop reasons: 84 `toolUse`, 1 `stop`)
- Tool calls: 105 total (bash 78, edit 7, read 6, write 14); tool results 105
- Tool errors: 3 (see Tool-error findings)
- Session span: `session_span_ms` 319,747 (~5.3 min); `agent_wall_ms` 321,255
- Worker friction: a ~7-tool-call detour on the bare-terminal runtime error
  ("lowered return type mismatch", already tracked as task-ecount-005); one
  invalid `xsht api` probe loop with guessed method names; one
  `python3: not found` attempt; one stale `edit` oldText mismatch. All
  recovered within the session; no budget failure (`budget_failures: 0`).

## Usage and cost

Trial 1 (single trial; aggregate equals trial):
- Buckets: input 68,302; output 28,724; cacheRead 3,454,464; cacheWrite 0
- Provider totalTokens 3,551,490 = bucket total (3,551,490); malformed lines 0
- Reasoning: 16,795 provider-reported reasoning tokens (subset of output,
  never added to totals)
- Cost: input $0.00615, output $0.00517, cacheRead $0.06218, cacheWrite $0.00,
  total $0.07350 (budget $0.50; unknown costs 0)
- Model: `openrouter/deepseek/deepseek-v4-flash-0731`

## Thinking evidence

59 thinking blocks in the session; provider reported 16,795 reasoning tokens
(subset of output). Thinking-block text is qualitative evidence. Key
correlations:
- Block at turn ~47 derives GNU `sort -n` tie semantics and confirms `Str`
  keys are orderable from the api contract.
- Block at turn ~127 derives the output field width `max(7, digits+1)` and
  picks `tui.left_pad`.
- Block at turn ~139 diagnoses the `lowered return type mismatch` after
  successful output and discovers the `let _ =` binding workaround (matches
  task-ecount-005).
- Block at turn ~178 builds a synthetic tie fixture to verify the two-pass
  sort against GNU tie-breaking; result MATCH.
Reasoning-token counts are provider-reported; the report does not derive exact
token counts from thinking text.

## Tool-error findings

All three structured `tool_errors` from the worker report are accounted for;
the manager session issued no Pi tool calls (no `xsht api` discovery probes),
so `None.` for the manager side.
1. Turn 8 (bash, exit 1): loop `for m in contains last_index_of index_of split
   substring slice chars; do xsht api method:Str.$m …` — `Str.last_index_of`,
   `Str.index_of`, `Str.substring`, `Str.slice`, `Str.chars` are unknown
   methods in this image; the failing queries made the loop exit 1. API
   discovery with guessed names; recovered same turn. Not a product defect.
2. Turn 17 (bash, exit 127): `sh: python3: not found` — worker tried to parse
   `xsht api search:path --format jsonl` with python3, which the minimal gym
   image intentionally lacks (handbook: no other language runtimes). Agent
   friction; recovered with grep/sed.
3. Turn 72 (edit): `Could not find edits[0] in /work/ecount.xsh` — stale
   oldText against current file; recovered by reading the file and editing
   correctly. Ordinary tooling friction.

## Timing evidence

- Candidate wall 11,007,757 ns (~11.0 ms); oracle wall 10,856,965 ns
  (~10.9 ms); ratio **1.0139** — within the strict 0.90..1.10 gate
  (`timing.passed: true`).
- User/system: candidate 1.03/3.09 ms; oracle 3.54/2.56 ms.
- Session span (Pi conversation) and candidate/oracle timing are separate
  clocks; timing passed independent of the 5.3-min agent session.

## Observation classification

- **Product fix validation (task-ecount-003, reusable product signal)** —
  ACCEPT. Commit `c2e1039d` implements the ticket: record sort keys compare
  lexicographically field-by-field in sorted field-name order
  (`compare_lowered_record_sort_keys`); non-orderable keys fail loudly with a
  runtime `stream-sort-key` diagnostic naming the stage and key type and a
  check-time `check.stream-sort` error; `sort`/`sort-by` are now stable
  (`sort_by` replaces `sort_unstable_by`); the `xsht api language:stream.sort-by`
  contract documents key types, ascending/--desc, stability, and the two-pass
  idiom (verified both in `crates/xsh-registry/src/reference.rs` and in the
  live container output the worker received at turn 19). Scalar keys unchanged.
  Native tests (`tests/xsh/stdlib/streams.xsh`) assert the ticket's exact
  `{c, n}` projection orders count-major/name-minor, equal the two-pass idiom,
  preserve stability, and that a `List` key fails loudly. Executor evidence:
  worker read the new contract and immediately used the documented two-pass
  idiom (no trial-and-error stability discovery), and a synthetic tie root
  matched the GNU oracle byte-for-byte. No silent no-op this run.
- **Reusable handbook guidance** — a bare stream terminal (`each { … }`) as a
  procedure's final expression passes `xsht check` but exits at runtime with
  `lowered return type mismatch` after producing output; binding the result
  (`let _ = …`) fixes it. Recurred in this session (minimal `t9.xsh`
  reproduction and `ecount.xsh`), general to any pipeline script. Product root
  cause already tracked as task-ecount-005; a concise general agent rule is
  staged as a provisional handbook candidate.
- **Worker friction / noise (not product defects)** — guessed Str method
  names (turn 8); python3 attempt (turn 17); stale edit oldText (turn 72).
  All recovered quickly with no budget impact.
- **Already-tracked gaps (no new tickets)** — empty signature lists in
  `language:stream.*` and the undocumented `group-by` key/items shape
  (task-ecount-001); checker/runtime disagreement on terminal-as-final-
  expression (task-ecount-005); the worker's review friction items are the
  same signals.
- **Low-priority proposals (noise)** — `Path.parse(Str)` convenience and
  `Int → Str`/format/`max` helpers. The worker succeeded via
  `Path.parse_bytes(bytes.from_text(s))?` and f-string + `tui.left_pad`;
  not strong reproducible defects this cycle.
- **Minor controller bookkeeping note** — phase `report.json`
  `data.xsh_commit` is `ea7dea2f…` while the evaluator `run.json` records
  `xsh_commit: c2e1039d…` and the session shows the new sort-by contract text
  (which exists only at `c2e1039d`). The trial is a valid pre-merge
  validation of the candidate; the phase field appears to record a baseline
  rather than the trial image commit. Not ticket-worthy.

## Handbook decision

Provisional candidate staged at
`lineage/handbook-candidate.md`: one sentence in "Streams and collections"
instructing agents to bind a terminal stage when it ends a procedure
(`let _ = files |> each { … }`), because a bare terminal can pass
`xsht check` yet fail at runtime with a confusing type error after output.
General lesson — not an ecount recipe — applicable to any pipeline eval.
Approved snapshot unchanged; checked-in `runtime/handbook.md` untouched.

## Tickets created

zero. The session's only strong product signal (terminal-as-final-expression
checker/runtime disagreement) is already tracked as task-ecount-005; no new
strong reproducible observation warrants a ticket this cycle.

## Post-merge decisions

None — the reconciler found zero merged ticket files for this cycle
(`merged: none`).

## Next replay

Replay `task-ecount` on the same approved handbook lineage
(`lineage/handbook-approved.md`, sha `c7c9dd9a…`) with the staged candidate,
at the merged task-ecount-003 implementation commit once merged, including the
synthetic tie-containing root check. A second replay after task-ecount-005's
fix lands should verify the bare-terminal runtime error is gone, in which case
the handbook candidate's warning may be trimmed (the `let _ =` binding remains
good style).

## North-star impact

The replayed sort-by fix makes ordering explicit, deterministic, stable, and
loud on unsupported keys, restoring trust in the core stream-pipeline
abstraction and removing a silent-wrong-order trap that forced trial-and-error
discovery. The provisional handbook rule (bind a terminal stage at the end of
a procedure) removes a repeated discovery loop for pipeline agents. Both are
general learnability/efficiency gains consistent with the XSH rationale:
typed, composable, explicit boundaries with fewer guessing loops. Scalar-key
behavior is unchanged, so no compatibility cost.
