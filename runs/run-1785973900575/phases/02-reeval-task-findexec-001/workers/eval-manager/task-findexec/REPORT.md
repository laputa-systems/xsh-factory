# Eval-manager report

## Result

pass

## Effort metrics

One fresh trial was executed against the candidate XSH commit
`500a9a6a6dcc82b8ba70be4c2bd3e4afcf5ede50` (build confirmed by
`xsh-build.state`: `build-id=500a9a6a6dcc82b8ba70be4c2bd3e4afcf5ede50-vd43e848bb2fa7f4e`).

Candidate worker `task-findexec-1`:
- assistant turns: 18 (17 `toolUse` stops + 1 `stop`)
- tool calls: 22 (16 bash, 4 read, 2 write); tool results 22
- tool errors: 2 (both benign agent-friction, corrected within the session)
- session span: 60,127 ms agent conversation (`agent_wall_ms` 61,549)
- Worker friction: minimal. Two short self-corrected probe errors only.
  Result `pass` (agent_state, evaluator_state, reporting_state, budget_state all
  pass).

The manager session is the current authoritative narrative; no manager-side
Pi tool errors were introduced in this review (manager used only file inspection).

## Usage and cost

Provider-reported per the worker report (model `openrouter/deepseek/deepseek-v4-flash-0731`):
- input tokens 21,214 (input cost $0.00190926)
- output tokens 3,657 (output cost $0.00065826)
- cacheRead 137,088 (cacheRead cost $0.002467584); cacheWrite 0
- provider total tokens 161,959 = bucket total 161,959 (input+output+cacheRead+cacheWrite)
- provider-reported reasoning tokens 1,287 (subset of output; not added to totals)
- total cost $0.005035104 vs budget $0.50 (1.0% of budget; budget_state pass)
- Trial aggregate: 1 worker, $0.005035104 total, 161,959 bucket tokens.
- Unknown costs: 0. No budget failure.

## Thinking evidence

Thinking-block count: 14 for the worker; provider reported reasoning tokens
1,287 (subset of output). Thinking was productive and on-task: the worker
correctly identified `fs.files` exposes `owner_executable`, `kind`, and `path`,
reasoned that `hidden` defaults to false (needs `hidden: true`), chose `where
.kind == "file"` + `where .owner_executable`, verified `sort-by` on the display
string against the `find ... | sort` oracle on both a local fixture and
`/usr/share`, and only then finalized. The worker never attempted a bare
`if`/`else` stream tail in this session, so the ticket's direct fix surface was
not exercised here (verified in canonical session JSONL).

## Tool-error findings

All current sessions (worker and manager) have exactly two nonzero Pi tool
results, both in `workers/eval-worker/task-findexec-1/report.json`; both were
self-corrected and are agent-friction, not product defects:

1. `err[check.effect-violation]` (turn 6, tool bash): `let r = fs.files(root,
   hidden: true)?` rejected because `?` requires the `error` effect; the worker
   added `[fs, error]` and it passed. Correct use of the typed Result effect
   contract.
2. `warn[lint.path-constructor]` (turn 11, tool bash): `Path(argv[0])` flagged
   in favor of `fp"${argv[0]}"`; the worker applied the lint-preferred p-string
   and `xsht check`/`lint` then both passed. This lint preference is already
   documented in the approved handbook.

No invalid `xsht api` discovery queries were issued (all `api:`/`method:`/
`language:` queries in the session returned `status: exact`). Provider telemetry
shows `retry_count 0`, `provider_errors []`, `retry_errors []`, so no external
health signal; both errors above are the sole tool errors and are accounted for.

## Timing evidence

This eval has no strict candidate/oracle timing gate; timing is diagnostic.
Candidate/oracle timing was flake-free: the submitted `findexec.xsh` produced
74 bytes of stdout that matched the BusyBox `find "$ROOT" -type f -perm -u+x |
sort` oracle byte-for-byte (`candidate.stdout` == `oracle.stdout`, diff exit 0).
Session wall span ~60 s is consistent with an 18-turn single-fixture loop and no
repeated exploration. Latency attribution: `unknown` in the sense that the
provider did not report response elapsed timings (response_elapsed_ms 0, no
output_tokens_per_second), but retry_count 0 and no provider errors indicate no
external lateness; the session shows no agent-inefficiency signal.

## Observation classification

- Correctness: pass. Candidate matched oracle on the evaluator fixture and the
  worker additionally verified locally on `/tmp/fx` and `/usr/share`.
- Restriction compliance: pass. No `run`/process/spawn/shell in the submitted
  program; uses typed `fs.files` pipeline only. The submitted solution is a
  clean, direct pipeline: `where .kind == "file"` + `where .owner_executable`
  + `map display` + `sort-by` + `collect` + `each print`.
- Reusable handbook signal (weak but general): discovering that `fs.files`
  defaults `hidden` to false required one extra probe (`t2.xsh`); the approved
  handbook does not document the `hidden` default or the typed permission
  booleans. This is general to any tree-traversal eval that must include
  dotfiles or filter by permission. Classified as reusable handbook guidance,
  not a product defect.
- Product/tooling defect: none observed. The ticket's original "map requires a
  tail value" defect did not reproduce because the worker did not need a
  conditional tail.
- Evaluator failure / harness mismatch: none. Trial `run.json`: correctness
  `exact: true`, protocol `artifact_present: true`/`review_ok: true`,
  restrictions `passed: true`, result `pass`.
- Ordinary noise: none material.
- Note: the phase `report.json` lists `xsh_commit: 1cf4ad3d…` (the ticket base),
  but `xsh-build.state` and the independent-eval image inspect confirm the trial
  ran the candidate `500a9a6…`; the candidate is a single clean commit on top of
  that base.

## Handbook decision

Provisional candidate staged at
`lineage/handbook-candidate.md` (identical to the approved snapshot plus one
concise, general rule under "Paths and filesystem values"): filesystem
streaming functions exclude hidden entries by default and require
`hidden: true`, and stream records expose typed permission booleans
(`owner_executable`, `group_executable`, `other_executable`, `executable`) and
`mode` so a permission bit is filtered as a typed field rather than a mode
string. General lesson: for a tree-walk, encode dotfile inclusion and typed
permission filtering as explicit options/fields. This is the concept the
`task-findexec` manager policy names and it is reusable across any fs-traversal
eval. It was NOT replayed in a second trial this cycle (single-trial plan);
promotion to `runtime/handbook.md` requires later replay and CTO approval. The
approved snapshot `lineage/handbook-approved.md` and checked-in
`runtime/handbook.md` are untouched.

## Tickets created

None. No new strong reproducible defect was observed; the two tool errors are
benign, already-documented agent friction with no product or cross-eval
reproducibility. No proposal is open for the next cycle.

## Post-merge decisions

None. The reconciler reported no merged ticket files for this phase, and
`task-findexec-001` is a pre-merge candidate under validation, not a merged
ticket. Decision on the candidate is recorded in `## Next replay` / this
report's candidate validation: the executor evidence SUPPORTS the proposed fix.

## Next replay

Candidate `task-findexec-001` (commit `500a9a6a6dcc82b8ba70be4c2bd3e4afcf5ede50`)
is a pre-merge validation: the eval passed correctness/restrictions/protocol on
the candidate, and the commit's own native regression
`test_if_else_is_a_stream_stage_tail_value` (in `tests/xsh/stdlib/streams.xsh`)
directly covers the ticket's acceptance criteria (map/where/each `if`/`else`
tails in single- and multi-line form) and SPEC.md documents the rule. Because
this eval session never used a bare conditional tail (it used `where
.owner_executable`), the decisive direct evidence for the fix is the commit's
native test suite; the replay's own no-workaround pass is consistent but not
directly exercising. Recommend, after merge, a post-merge replay that runs the
native `streams.xsh` suite on the merged commit and a fresh `task-findexec`
replay to confirm the conditional-tail path end-to-end. The experimental
handbook candidate (hidden-typed-permission lesson) should be replayed by
`task-findexec` and at least one other fs-traversal eval (e.g. `task-manifest`,
`task-ecount`) before promotion.

## North-star impact

This run advances practical, learnable, ergonomic, trustworthy XSH in two ways.
(1) It validates — pending merge — a genuinely general ergonomics fix: a
first-class `if`/`else` expression accepted as a stream-stage tail removes an
expression-position asymmetry and the bind-then-tail workaround, giving agents
one mental model for conditionals everywhere in pipelines; the eval replay
confirms no regression and no workaround dependency. (2) The staged handbook
candidate teaches the discoverable typed permission boundary (`hidden: true`,
`owner_executable`) consistent with XSH's explicit-typed-metadata ethos, which
this run's worker used cleanly to produce a byte-exact oracle match. Both
directions serve the mission of a learnable, ergonomic systems glue language
rather than a task-specific recipe.
