# Eval-manager report

Eval: `task-dupcheck` · run `02-reeval-task-dupcheck-001` · mode `eval`
Candidate XSH commit under test: `aaa968c73fd7649f70a6a94e21f77a90bf6a778c`
Re-evaluation of candidate ticket `task-dupcheck-001` (pre-merge validation).

## Result

fail

The configured trial executed 0 of 1 trials. The worker agent produced a
correct, oracle-verified `dupcheck.xsh`, but the packaged evaluator again
failed to start in its isolated container. The candidate XSH commit under test
does NOT satisfy ticket `task-dupcheck-001`'s acceptance criteria: the
evaluator never starts and no `run.json` eight-case manifest is produced.

## Effort metrics

Trial 1 (the only worker, `task-dupcheck-1`):

- Assistant turns: 21
- Tool calls: 28 (bash 24, read 3, write 1); tool results 28
- Tool errors: 2 (both discovery friction, see `## Tool-error findings`)
- Thinking blocks: 18
- Session span: 104246 ms (`session_span_ms`); agent wall 105933 ms
  (`agent_wall_ms`)

Worker friction: minimal for the agent. The agent read `agents.md`,
`handbook.md`, `task.md`, ran `xsht api` discovery, built a fixture, matched
the oracle byte-for-byte on hidden-file, spaces, symlink, three-member and
no-duplicate trees, ran check/fmt/lint, and left `dupcheck.xsh` and
`review.md`. The only documented friction is the two `xsht api` discovery
misses below.

## Usage and cost

Trial 1 (provider: openrouter/deepseek/deepseek-v4-flash-0731), provider
reported:

- input 21922, output 5490, cacheRead 287296, cacheWrite 0
- reasoning 2367 (subset of output), thinking blocks 18
- provider total 314708; bucket total 314708 (no mismatch)
- cost: input $0.00197298, output $0.0009882, cacheRead $0.005171328,
  cacheWrite $0, total $0.008132508

Aggregate (1 trial): 0.008132508 USD. Budget $0.50, no breach.

## Thinking evidence

18 thinking blocks across 21 assistant turns. Provider reported
`reasoning_tokens: 2367`. The transcript (`session.jsonl.bz2.bz2`) shows the agent
reasoning through API discovery: confirming `api:hash.sha256`, deciding
`fs.walk(root,false,false,true)` for `hidden: true`, `Hash` path-overload,
`?.hex()`, group-by filter on `items.len() > 1`, and two-pass stable sort
(sort by path inside group, sort groups by digest). The reasoning is coherent
and directly led to a correct, oracle-matching artifact. Thinking-block text
is qualitative evidence; correctness is confirmed by the oracle diff, not by
the reasoning text alone.

## Tool-error findings

Two nonzero Pi results, both in `task-dupcheck-1/report.json#tool_errors`:

1. Turn 7, tool `bash`: "(no output)" / exit code 1. Source: the agent piped
   `xsht api method:Path | grep "kind: method" -A0 | grep "api: method"`, a
   grep that matched nothing and exited 1. Trivial, recovered immediately by
   an alternate query. Discovery friction, not a product defect.

2. Turn 12, tool `bash`: invalid API query `'language.core.display-strings'`;
   expected KIND:VALUE, exit code 2. The agent guessed a dotted id
   (`language.core.*`) instead of the documented `<KIND>:<VALUE>` form
   (`language:stream.*` / `search:TERM`). The handbook already documents the
   `KIND:VALUE` requirement and the dot-form rejection; the agent recovered on
   the next query and used `search:` / `language:stream`. Single, recoverable
   discovery miss; no evidence of a handbook gap warranting a change.

No other failed tool results in the current worker or manager sessions.

## Timing evidence

Candidate/oracle timing: none — the evaluator never started, so zero
candidate/oracle comparisons were recorded. This eval has no strict
candidate/oracle timing gate (both sides finish in milliseconds on small
fixtures); timing is diagnostic only, but here it is absent entirely because
the evaluator container failed before trial execution.

Latency attribution: unknown. `provider_telemetry` is marked `present: true`
with `retry_count 0`, `provider_errors []`, `retry_failures 0`, but the
referenced events file `session.jsonl.bz2.bz2.events.jsonl` is absent from the worker
directory, so no per-response latency/throughput values were captured. No
provider retries or errors are recorded. The ~104 s agent session at 21 turns
/ 28 tool calls / 314k tokens is consistent with normal measured work and does
not itself indicate an agent regression; latency attribution remains unknown.

## Observation classification

- **Correctness (agent):** `dupcheck.xsh` is a correct pure-XSH solution. It
  uses `fs.walk(root,false,false,true)` with `hidden: true`,
  `hash.sha256(e.path)?` + `?.hex()`, `group-by .digest`, `where
  items.len() > 1`, per-group `sort-by .path`, outer `sort-by .digest`, and
  prints `f"${digest}  ${path}"`. `xsht check/fmt/lint` pass; output matched
  the find|sha256sum|sort|awk oracle byte-for-byte on duplicate,
  hidden-file/hidden-dir, space-in-name, symlink-ignore, three-member, and
  no-duplicate trees. Strong evidence the handbook's streams, typed-path, and
  digest idioms transfer to content-level filesystem work.
- **Harness mismatch / image defect (blocking):** `evaluator.stderr` now reads
  `docker: Error response from daemon: Duplicate mount point:
  /run/evaluator.xsh.` The evaluator container cannot be created, so
  `evaluator_state = fail`, `evaluator_manifest = ""`,
  `classification = evaluator_failed`, and the phase reports
  `trial-count expected 1 observed 0` plus `missing-evaluator-manifest`.
- **Reporting inconsistency (noise):** the worker `report.json` top-level
  `result: "pass"` (agent side) coexists with `execution.result: "fail"` /
  `classification: evaluator_failed`. The phase-level `outcomes` correctly
  record evaluator/infrastructure/product/cycle all `fail`. The top-level
  "pass" reflects only the agent half; the authoritative trial outcome is the
  evaluator failure. Noted as reporting noise, not a correctness signal.
- **Tool errors / discovery friction (noise):** the two `xsht api` misses in
  `## Tool-error findings` are recoverable single misses, already covered by
  the handbook's `KIND:VALUE` guidance.

## Handbook decision

Unchanged. The approved snapshot was copied unchanged to
`lineage/handbook-candidate.md`. The agent's run succeeded using exactly the
current handbook guidance (streams, `group-by` with `key`/`items`, two-pass
stable sort, `?.hex()`, `fp"${...}"`, `language:stream`/`search:` query form);
nothing in the run is blocked or slowed by a handbook gap, and the two minor
`xsht api` misses are already addressed by existing text. No provisional
candidate is warranted.

## Tickets created

None. The blocking harness defect is already tracked by the existing approved
candidate ticket `task-dupcheck-001` (same evaluator-container provisioning
problem, new failure mode). No new ticket is opened this cycle.

## Post-merge decisions

No reconciled merged tickets were supplied for this cycle (reconciler reported
`none`). Candidate re-evaluation decision for `task-dupcheck-001`
(pre-merge, engineer worktree at `aaa968c`):

- Ticket: `task-dupcheck-001` — candidate commit `aaa968c73...`
- Decision: needs-replay / NOT accepted for merge. Executor evidence does NOT
  support the proposed fix.
- Evidence: the evaluator still fails to start. The previous failure
  (`factory_control.xsh` unreadable) is replaced by a new deterministic
  failure, `Duplicate mount point: /run/evaluator.xsh`, so the packaged
  evaluator still cannot run; zero trials, `evaluator_state = fail`,
  `evaluator_manifest = ""`. Acceptance criteria (evaluator starts, eight-case
  `run.json` manifest, candidate passes all eight cases) are unmet.
- Revert proposal: none — nothing was merged. The candidate branch must be
  revised so the evaluator container mounts `/run/evaluator.xsh` (and
  `factory_control.xsh` / `XSH_MODULE_PATH`) without colliding, then replayed.

## Next replay

Replay `task-dupcheck` trial 1 against a revised candidate that resolves the
evaluator-container mount collision (`Duplicate mount point:
/run/evaluator.xsh`), using the unchanged approved handbook lineage
`lineage/handbook-approved.md`. Success gate: `evaluator_state = pass` and a
`run.json` manifest covering all eight cases (including `hidden_missing`
nonzero control), with the candidate matching the BusyBox oracle byte-for-byte.
This is also the falsification check for the pre-merge decision recorded above.

## North-star impact

The agent half of this run is strong positive evidence for the north-star
hypothesis: an agent with the shared handbook successfully composed
`fs.walk(hidden: true)` → `hash.sha256(...)?.hex()` → `group-by .digest` →
filter → two-pass stable sort to replace the classic
`find | sha256sum | sort | awk` pipeline with no subprocess, verified
byte-for-byte against the oracle. That is exactly the learnable, ergonomic,
composable content-level filesystem glue XSH is meant to provide.

However, the factory cannot yet trust or formally measure that evidence because
the eval-executor's evaluator container still fails to launch, so the
north-star claim about content-level composition is not formally validated this
cycle. Unblocking the evaluator packaging is the prerequisite durable step;
until then every paid trial of this eval (and any eval whose package evaluator
mounts `/run/evaluator.xsh`) returns zero measurable trial evidence. This run
is product-positive but infrastructure-blocked, and is recorded as such.
