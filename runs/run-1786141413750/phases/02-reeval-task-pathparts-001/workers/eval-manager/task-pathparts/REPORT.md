# Eval-manager report

## Result

fail — candidate pre-merge validation concluded **supported**; see below.

Trial 1 against candidate XSH commit `30fabd4e` (`Add POSIX path
decomposition methods`, the engineered implementation of ticket
`task-pathparts-001`) reports `classification: restriction_failed`,
`result: fail`. The submitted artifact is byte-exact on all seven oracle
cases through the typed `Path` surface, so the candidate fix itself is
functionally validated. The eval `fail` is attributable solely to the
evaluator's `path_referenced` restriction gate (`"Path(" in source`) not
recognizing the p-string interpolation `fp"${argv[0]}"` that `xsht lint` and
the handbook both prefer for building a typed `Path` from a runtime string.
That lint-versus-gate conflict is already an Open., deferred ticket
(`task-pathparts-002`), not a defect in the candidate change. Decision: the
executor evidence supports the proposed fix; the candidate is not marked
merged (pre-merge validation), is not re-dispatched to engineer, and requires
the `task-pathparts-002` lint/gate reconciliation before a clean typed-Path
pass is possible.

## Effort metrics

Trial 1 (`task-pathparts-1`, model `deepseek/deepseek-v4-flash-0731`):
- Turns: 21 assistant turns, 1 user message.
- Tool calls: 22 (15 bash, 3 read, 4 write); 22 tool results.
- Tool errors: 2 (see Tool-error findings).
- Session span: `session_span_ms` 98239 (~98 s); `agent_wall_ms` 99414.
- Worker friction: one irrelevant oracle-missing probe (turn 5), one lint
  `exit 1` on an intermediate `Path(...)`/`.display()` draft (turn 12) that
  steered the worker to the `fp"..."` form. Modest effort for a short task;
  no repeated exploration, no wasted discovery beyond the two errors, and no
  provider retries. Agent reached a correct, all-cases-matched artifact.

Worker report result: `pass` (agent_state), evaluator `fail` (evaluator_state),
classification `evaluator_failed`.

## Usage and cost

Trial 1 (provider-reported, single worker):
- input 24,513; output 6,378; `reasoning` 3,580 (a subset of output; not
  added to totals); cacheRead 202,112; cacheWrite 0.
- provider total / bucket total: 233,003 tokens.
- Cost: input $0.00220617, output $0.00114804, cacheRead $0.003638016,
  cacheWrite $0, total $0.006992226. Budget $0.50, no breach.
- Aggregate: same as trial 1 (1 configured fresh trial, 1 worker).

## Thinking evidence

Worker `thinking_blocks` = 15; provider reported `reasoning` token count =
3,580. Thinking is qualitative evidence, not a token estimate. In the
canonical transcript the worker deliberately chose `fp"${argv[0]}"` to keep
`xsht lint` green and used the new `dirname()`/`basename()`/`ext_or()` typed
methods, capturing the intended typed-Path path; the choice that produced the
artifact is exactly the handbook/lint-preferred spelling the eval gate
rejects.

## Tool-error findings

Both structured worker errors accounted for (manager session had no tool
errors):
1. Turn 5, `bash`: `sh: can't open '/tmp/pathparts-oracle.sh'` — the worker
   probed an oracle path that exists only in the evaluator container, not the
   worker image. Ordinary self-test friction / noise; worker recovered and
   built its own edge-case harness (tested `/`, `.`, `.profile`, `a/b.c.d`,
   `file.` etc.).
2. Turn 12, `bash`: `xsht lint` `exit 1` with warnings on an intermediate
   `let p = Path(argv[0])` draft (`lint.path-constructor` prefers p-string;
   redundant interpolation and `.display()`). This is the factory lint
   steering the agent off the literal `Path(` token onto `fp"..."`; acting on
   it is what caused `path_referenced: false`. Reusable signal, already
   tracked as `task-pathparts-002`.

No invalid `xsht api` discovery queries in the worker or manager sessions; the
worker's `method:Path.dirname`/`method:Path.basename`/`search:dirname` probes
all returned `status: exact`.

## Timing evidence

No strict candidate/oracle timing gate for this eval. Measured wall
(candidate vs oracle, ns): public 12,510,834 vs 12,136,164; hidden_deep
13,168,088 vs 11,307,242; hidden_plain 11,247,658 vs 13,271,463; hidden_rel
11,606,244 vs 11,159,033; hidden_dotdir 12,484,416 vs 11,878,413;
hidden_dotfile 12,547,500 vs 13,177,005; hidden_targz 13,270,297 vs
11,214,241. Both sides are ~11–13 ms process-launch; timing is diagnostic
only and shows no divergence. Latency attribution: `unknown` (provider
`output_tokens_per_second` 0, no generation timings); no provider retries or
errors in `provider_telemetry`, so the 98 s session is normal and shows no
agent-inefficiency signal.

## Observation classification

- **Restriction/eval gate mismatch (reusable, strong, reproducible):** the
  evaluator gate `path_referenced = "Path(" in source` rejects the
  p-string typed-`Path` construction `fp"${argv[0]}"` that `xsht lint` (via
  `lint.path-constructor`) and the handbook call lint-preferred. A correct,
  all-seven byte-exact typed-`Path` solution is therefore classified
  `restriction_failed`. Evidence: `run.json` `restrictions.passed:false`,
  `path_referenced:false`, `correctness` all true; session turn 12 lint
  warning and final `fp"..."` artifact; candidate vs oracle stdout identical
  for all seven cases. This is the same reproducible lint-versus-restriction
  conflict documented in Open. ticket `task-pathparts-002`.
- **Candidate fix validated (product/ergonomics signal):** the new
  `Path.dirname()`/`Path.basename()`/`Path.ext_or("none")` methods were
  discovered via `xsht api` (`status: exact`), used to build a byte-exact
  three-line contract on every hidden shape, with no raw `Str`
  reimplementation and no forbidden subprocess (`no_forbidden:true`). This
  satisfies the north-star intent of ticket `task-pathparts-001`.
- **Noise:** the turn-5 oracle-missing probe is ordinary self-test friction.
- **No provider-latency or agent-efficiency regression:** retry_count 0,
  provider_errors []; 21 turns / 22 calls / 2 errors for a short task.

## Handbook decision

Unchanged — the approved snapshot is copied unchanged to
`lineage/handbook-candidate.md` (sha256 `3b56a781...`, identical to approved).
No handbook change is justified this cycle: the handbook already teaches
`fp"${expr}"` as the "interpolated, lint-preferred" dynamic-Path form, which
is correct and not the source of the mismatch. The blocker is the eval's
literal-`Path(` restriction gate and `xsht lint` severity, both already
tracked in `task-pathparts-002`. A provisional handbook candidate would not
remove the lint-vs-gate friction and should not be promoted.

## Tickets created

None new. The strong, reproducible lint-versus-restriction observation from
this run is already captured in the Open. ticket `task-pathparts-002`, so no
duplicate ticket is opened. No factory-target ticket.

## Post-merge decisions

No reconciled merged tickets in this cycle (controller: `none`); nothing to
accept/reject post-merge. Recorded here for the pre-merge candidate
validation instead:

- Candidate ticket: `task-pathparts-001`, implementation commit
  `30fabd4e12181830d146615b978861bef0737f96` (engineer worktree
  `.xsh-factory-worktrees/run-1786141413750/task-pathparts-001`).
- Decision: **supported** — the executor evidence shows the POSIX
  path-decomposition methods make the typed `Path` surface express the
  `dirname`/`basename`/extension contract; the agent used them and matched
  the oracle byte-for-byte on all seven cases without raw string parsing or
  forbidden boundaries.
- Not marked merged (pre-merge validation), not dispatched to engineer, not
  treated as main.
- The single remaining blocker is the `path_referenced = "Path(" in source`
  gate, which is the open lint/gate tension owned by `task-pathparts-002`; a
  clean typed-`Path` pass requires that reconciliation to land with the
  methods. No revert proposed — the candidate change is correct as evaluated.

## Next replay

Replay `task-pathparts` against the build containing both the merged
`task-pathparts-001` methods (commit `30fabd4e`) and the `task-pathparts-002`
lint/gate reconciliation, using lineage
`runs/run-1786141413750/phases/02-reeval-task-pathparts-001/lineage/handbook-approved.md`.
Acceptance criterion: a fresh trial that builds a typed `Path` (via
`fp"${...}"` or a named cast), uses the typed decomposition methods, passes
both `xsht lint` and the `path_referenced` gate, and matches the seven-case
oracle — confirming the fix is usable and no longer misclassified. A
falsification check: a second path-construction eval (e.g. `task-safepath`)
shows the same guidance no longer misleads an agent.

## North-star impact

This run shows the typed-`Path` boundary becoming a trustworthy, learnable
surface: the new POSIX `dirname`/`basename`/`ext_or` methods were discovered
through `xsht api` and used to satisfy a byte-exact systems-administration
contract without falling back to raw string parsing — the exact ergonomics
the north star wants ("connect ... paths ..."). At the same time it exposes a
residual internal inconsistency: `xsht lint` and the handbook steer the agent
to `fp"..."`, while the eval gate requires the literal `Path(` token, so a
correct typed-`Path` solution is misclassified. Removing that friction
(ticket `task-pathparts-002`) lets the language, its tooling, and its eval
contracts agree, which is precisely the "trustworthy, no guesswork" outcome
the factory optimizes for.
