# Eval-manager report

## Result

pass

## Effort metrics

Trial 1 (pre-merge candidate validation of `task-colsum-001` at engineer commit
`5f46267067991d5af1d988732e5c2f6f5de5ad04` in worktree
`phases/01-ticket/worktrees/task-colsum-001`):

- assistant turns: 47
- tool calls: 50 (bash 46, edit 2, read 2)
- tool errors: 0
- session span: 153,591 ms (~2.56 min); agent wall 155,211 ms
- stop reasons: 46 toolUse, 1 stop
- worker friction: mild but real — the agent burned several turns
  empirically probing stream/pipeline shapes (`enumerate`, `where`
  block-param vs `.field` shorthand, `|> get(0)?` pipe tail) before the
  submitted spelling worked. This is the same pipeline-sugar discovery loop
  recorded in `review.md`; it is reproducible and general (see
  `## Observation classification`), so it becomes a ticket, not an unlabeled
  miss.

## Usage and cost

Trial 1 (single trial, model `openrouter/deepseek/deepseek-v4-flash-0731`,
budget $0.50):

- input tokens: 31,618; output tokens: 12,885; cache-read: 735,808;
  cache-write: 0; provider total: 780,311; bucket total: 780,311
- cost: input $0.002846, output $0.002319, cache-read $0.013245, total
  $0.018409464
- reasoning tokens: 6,966 (provider-reported); thinking blocks: 40
- no budget breach; 0 malformed lines; 1 user message
- worker-level usage matches phase-level `data.cost` exactly (47 turns,
  $0.018409464, 780,311 bucket tokens), so the executor and worker accounts
  are consistent.

## Thinking evidence

40 thinking blocks, 6,966 provider-reported reasoning tokens. The transcript
(`session.jsonl.bz2.bz2`) shows the decisive discovery: after asking how to fail the
missing-header branch without a generic `Error` constructor, the agent probed
`language:stream.first` (signature `first() -> Result[T, Error]`) and reasoned
that `first()?` on an empty `enumerate(...)|>where ...` stream produces an
expected error → nonzero exit with empty stdout. That path replaced the
`parse_int` sentinel and is what makes the control case pass. Reasoning tokens
were reported in this run.

## Tool-error findings

None. The worker `report.json` reports `tool_errors: 0`, the phase
`report.json` `tool_errors: []`, and a session grep for `isError:true`
returned zero. No failed Pi tool result and no invalid `xsht api` query in the
current evidence packet.

## Timing evidence

No strict candidate/oracle ratio gate for this eval contract (both sides
finish in milliseconds; timing is diagnostic). Per-case wall (ns):
public 12.07/11.25, hidden_order 11.55/14.47, hidden_negative 11.28/13.30,
hidden_many 11.62/13.28, hidden_single 13.60/11.12, hidden_no_data 12.69/11.77,
hidden_extra_cols 12.40/13.58, hidden_missing_header 12.11/12.49,
hidden_bad_value 11.35/13.39 (candidate/oracle). All cases byte-exact and the
two failure controls exit nonzero with empty stdout (candidate exit 3 vs
oracle exit 1/2 — the contract requires nonzero, not identity of the exit
code, so the eval records both as exact/pass). Provider telemetry shows 0
retries, 0 provider errors; latency attribution is normal for this session.

## Observation classification

- Correctness / restrictions / protocol: pass across all nine cases. The
  submitted `colsum.xsh` uses `fs.read_text`, `Str.parse_int`, and no
  subprocess boundary; `run.json` `restrictions.passed`, `protocol`
  artifact/review ok.
- Candidate-fix validation evidence: the missing-header branch is expressed
  with `(parts |> enumerate() |> where .value == header |> first())?` — i.e.
  an absent terminal error, NOT the `parse_int` sentinel and NOT `error.fail`.
  This confirms the acceptance gate "passing all nine cases without the
  sentinel conversion" is met and shows a pre-existing idiomatic fail path
  exists. It does NOT itself prove `error.fail` is exercised (see handbook and
  next-replay notes).
- Reusable handbook guidance: an absent-value terminal (`first()?` on an empty
  stream) is a clean explicit expected-failure mechanism for a not-found
  condition, generalizable across fail-on-condition evals. Staged as a
  provisional candidate.
- Product/tooling defect (strong, reproducible): pipeline-sugar desugar
  inconsistency — `|> get(0)?` pipe tail and plain-local `hr |> split(",")`
  rejected with `pipeline sugar was not desugared`; `where { |e| ... }`
  block-param rejected with `unresolved proc command` while `.field` shorthand
  works. Reproduced multiple times in this session; generalizes to all
  stream-based evals. Opened `task-colsum-002`.
- Other review.md notes (List.get returns `Any`; `match` reserved keyword; api
  summary omits `language.*` rules) are real ergonomics observations but were
  not single-run-gated here; left as review findings, not a separate ticket
  this cycle.
- Ordinary noise: none material; exit-code value differences (3 vs 1/2) on the
  failure controls are within the eval contract (nonzero + empty stdout).

## Handbook decision

Provisional candidate staged at
`runs/run-1785894766939/phases/02-reeval-task-colsum-001/lineage/handbook-candidate.md`
(sha256 of approved snapshot `3b56a781...e126b`). One paragraph under
`## Effects and errors` changed: recommend an absent terminal (`first()?` on an
empty stream) or `error.fail(message)` (when present, kind `validation`,
requires `error` effect) instead of a sentinel conversion for deliberate
validation failure. General lesson: "prefer an explicit absent/expected
failure over a sentinel string routed through a typed conversion." Replay
scope before promotion: at least one additional fail-on-condition eval on the
same lineage, plus the merged `error.fail` path (this trial never called it),
then CTO approval.

## Tickets created

- `tickets/task-colsum-002.md` — pipeline-sugar desugar inconsistency
  (`pipeline sugar was not desugared` / `unresolved proc command` vs working
  shorthand). Links this eval, this manager run, the executor session, the
  handbook lineage, and XSH baseline `e5d29c7` (candidate `5f46267`). Open for
  the next cycle; merge-record placeholders left untouched.

## Post-merge decisions

The reconciler staged no merged ticket (`none`) for this phase, so there is no
post-merge acceptance item to accept/reject. This run is a PRE-MERGE candidate
validation of `task-colsum-001` at engineer commit `5f46267` (branch
`factory/task-colsum-001/1785894767724`, clean worktree, diff = 7 files / 66
insertions adding `error.fail`). Decision: VALIDATE/ACCEPT for the eval gate —
the replay passes all nine cases without the sentinel conversion
(`first()?` used instead), and the committed `error.fail` unit test
(`test_error_fail_constructs_validation_result`) plus SPEC update are sound.
Caveat recorded for the CTO: this trial never invoked `error.fail` (the agent
chose `first()?`), so criterion 2 — a second fail-on-condition eval using the
new form — is not yet replayed; treat `error.fail` cross-eval trust as pending
that replay. No revert proposal.

## Next replay

Replay `task-colsum` (same eval) against the MERGED commit of this candidate
(once CTO merges), asserting all nine cases still pass and the failure paths
need no sentinel; additionally run a second fail-on-condition eval on the same
handbook lineage to exercise `error.fail(message)` directly (criterion 2,
falsification of the provisional handbook paragraph). Re-run a stream eval to
confirm the `task-colsum-002` pipeline-shape contract resolves without an
empirical discovery loop.

## North-star impact

The validated fix and the staged handbook rule remove the sentinel-conversion
abuse for deliberate validation failures (explicit-boundary ethos), while the
pipeline-sugar ticket addresses a genuine ergonomics/learnability gap that
adds token and turn cost across the whole stream-eval family. This run's data
(turns, tokens, one reproducible pipeline discovery loop, clean failure
contracts) supports better agent efficiency and trust without optimizing any
metric independently of correctness.
