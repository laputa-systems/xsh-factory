# Eval-manager report

- Eval: `task-envcfg` (run `02-reeval-task-envcfg-002`)
- Mode: eval (candidate re-evaluation of ticket `task-envcfg-002`)
- Candidate under test: commit `2d423c166b9c06aee44b9f4e720554ebeee1216b` (in `phases/01-ticket/worktrees/task-envcfg-002`)
- Build under test: `build-id=2d423c...-va919a0654dd01dad`, `eval-tag=v71491e78cef43d08`
- Approved handbook: `lineage/handbook-approved.md` (sha256 `97c5d804...4a40e83`)
- Worker model: `openrouter/deepseek/deepseek-v4-flash-0731`

## Result

pass

## Effort metrics

Single fresh trial (Trial 1), as configured in `CYCLE-REQUEST.md` (`Count: 1`).
Eval-worker `task-envcfg-1`:

- assistant turns: 11
- tool calls: 12 (7 `bash`, 3 `read`, 2 `write`)
- tool results: 12
- tool errors: 0 (structured `tool_errors` empty)
- thinking blocks: 11
- stop reasons: 10 `toolUse`, 1 `stop`
- agent wall (session): `agent_wall_ms=108520`, `session_span_ms=106931`
- review.md present, both headings preserved, no placeholders

The eval-manager session (`workers/eval-manager/task-envcfg/session.jsonl.bz2`)
recorded 0 errored tool results. No worker friction: the agent discovered the
`env` module and `env.get_or` / `env.int` / `env.bool` cleanly on first
queries, never failed an `xsht api` probe, and passed `check` / `fmt` / `lint`
on the artifact.

## Usage and cost

Eval-worker `task-envcfg-1` (provider-reported):

- input tokens: 21720 ($0.0019548)
- output tokens: 3966 ($0.00071388)
- cache read: 74880 ($0.00134784)
- cache write: 0 ($0)
- reasoning tokens: 2380 (provider-reported, subset of output)
- total bucket tokens: 100566; provider total: 100566 (buckets match)
- provider cost: $0.00401652 (budget $0.50; 0 budget failures)

Aggregate = the single trial: $0.00401652. The session is short and
low-cost, consistent with a clean, fluent solve by an agent that did not need
to rediscover the `env`/`fs` surface.

## Thinking evidence

`thinking_blocks: 11` and provider-reported `reasoning_tokens: 2380` are
present in the worker report; the provider did report a reasoning-token count.
The 11 thinking blocks track the solve: read the briefing/handbook/task, query
`module:env` and the exact `api:env.*` contracts, reason about the
present-but-empty vs absent semantics and the oracle's `${VAR-default}` rule,
choose `env.get_or` for byte-exact string output plus `env.int("CFG_PORT",
8080)?` for validation, write via `fs.write`, then verify against the oracle
across empty/leading-zero/bad-port fixtures. Thinking was directed and
non-exploratory; there is no evidence of stall or scratch-space work.

## Tool-error findings

None. The worker `report.json` records `tool_errors: 0`, the structured phase
`tool_errors` array is empty, and the manager session JSONL contains no
`isError: true` tool results. Every `xsht api` query in this session resolved
(`module:env`, `api:env.get_or`, `api:env.int`, `api:env.bool`, `api:fs.write`,
`api:env.get`, `language:stream`, `search:parse_bytes`, `search:argv`);
there were no invalid discovery queries.

## Timing evidence

No strict candidate/oracle timing gate for this eval (EVAL.md: both sides finish
in milliseconds; timing is diagnostic). Measured per-case wall (ms):

| case | candidate | oracle |
|------|-----------|--------|
| public | 11.55 | 11.42 |
| hidden_defaults | 12.76 | 13.69 |
| hidden_partial | 12.40 | 12.97 |
| hidden_empty | 11.38 | 12.50 |
| hidden_spaces | 13.42 | 13.48 |
| hidden_zero | 13.35 | 13.11 |
| hidden_utf8 | 13.35 | 11.16 |
| hidden_debug_false | 13.16 | 13.37 |
| hidden_malformed | 11.58 | 12.99 |
| hidden_empty_port | 11.84 | 11.85 |

Candidate and oracle are within noise on every case (all 11–14 ms); there is no
timing signal and no gate concern.

## Observation classification

- Correctness / pass: all ten cases byte-exact (`all_exact: true`, including
  `hidden_malformed` and `hidden_empty_port` failure controls with a nonzero
  exit and no output file). Evidence: `run.json` `correctness` block plus
  per-case `candidate.*`/`oracle.*` stdout captured in the worker dir.
- Restriction compliance (pass): `env_referenced: true`, `forbidden_operations:
  true`; the submitted `envcfg.xsh` reads through `env.get_or` / `env.int` and
  writes through `fs.write`, with no subprocess boundary and no hard-coded
  config. Evidence: raw artifact (382 bytes via `Path.parse_bytes(
  bytes.from_text(argv[0]))`, `env.get_or(...)`, `env.int(...)?`, `fs.write`).
- Protocol (pass): artifact present, review ok.
- Worker friction (none): no failed tool calls, no repeated discovery; the
  agent selected a valid clean solution (`env.int` validation) in 11 turns.
- Candidate-vs-sentinel observation: the agent validated `CFG_PORT` with the
  typed conversion `env.int("CFG_PORT", 8080)?`, not the `fail(...)?` primitive
  this ticket registers and not the old sentinel `parse_int` hack. `env.int`
  rejects the non-numeric (`abc`) and empty port inputs, so it satisfies the
  eval without `fail`. This is a legitimate typed-conversion path and means
  `task-envcfg` passes regardless of `fail` discoverability.
- Harness metric noise: `outputs.candidate_sha256 = e3b0c44298...` in
  `run.json` is the SHA-256 of an empty string. The generic evaluator computes
  it over `/session/candidate.1.stdout` (`eval-legacy` pattern
  `hash.sha256(p"/session/candidate.1.stdout")`), but this eval's deliverable is
  a written file, not stdout, so the candidate stdout is empty. The
  authoritative pass evidence is the per-case byte comparison
  (`all_exact: true`), which fully passed; the `candidate_sha256` field is
  therefore non-informative for this file-deliverable eval, not a correctness
  defect. Classified as ordinary noise, not a product defect, and not strong
  enough to open a ticket.
- Commit-identity note: the phase `report.json` `data.xsh_commit` is `97edb51`
  (the run's baseline/parent merge), while the worker `run.json`
  `xsh_commit = 2d423c`, the candidate commit. `xsh-build.state` confirms the
  image was built from `2d423c`, and the candidate worktree HEAD is `2d423c`.
  The candidate under test is therefore the worktree commit; the phase baseline
  field reflects the merge-base. No conflict; recorded for evidence clarity.

## Handbook decision

Unchanged. The approved snapshot (`sha256 97c5d8...`) already documents the
`env`/`fs` surface, `env.get_or` absent-only-default semantics, `?`
propagation, and the "typed `env.int`/`env.bool` are not strict validators" caveat
sufficiently for this task; the agent solved it in 11 clean turns with no
repeated friction. The write-up already warns that byte-exact decimal contracts
must be checked explicitly — the agent's `env.int` choice is compliant. No
reusable lesson emerged that would remove repeated friction, so no provisional
handbook edit is justified. Per procedure, the approved snapshot is copied
unchanged to `lineage/handbook-candidate.md`.

Candidate re-evaluation decision (pre-merge, not a merge): the executor
evidence SUPPORTS the `task-envcfg-002` fix. The clean worktree commit `2d423c`
contains exactly the requested change — a `fail` entry in
`crates/xsh-registry/src/reference.rs` (`CORE_LANGUAGE_ITEMS` + `core_doc`
describing "Constructs a deliberate validation failure") and a focused test
`crates/xsht/tests/api.rs::api_fail_builtin_is_indexed_with_signature_and_validation_contract`
asserting `xsht api language:core.fail` resolves to `status: exact` with the
purpose and `fail(message: Str) -> Result[Unit, Error]` signature — and the
eval passes all ten cases under that build. Caveat: this cycle's agent did NOT
query `search:fail` or adopt `fail(...)?` (it chose `env.int`), so the
discoverability/adoption acceptance criterion was not directly replayed; that
remains the focus of the post-merge replay. The candidate's source change is
correct and regression-free; the CTO may consider merging on that basis.

## Tickets created

None. No strong reproducible observation warrants a new ticket this cycle. The
`candidate_sha256` empty-hash field is a non-informative generic-evaluator
metric for a file-deliverable eval, not a general XSH ergonomics or correctness
problem, and the agent session had zero friction, so opening a ticket would not
advance a general change.

## Post-merge decisions

None. The reconciler supplied no merged tickets (`merged ticket files: none`).
`task-envcfg-002` is an Approved candidate in pre-merge validation (decision in
the Handbook decision section above), `task-envcfg-001` remains Open, and
`task-tags-003` is Open; none is a post-merge acceptance assignment for this
cycle.

## Next replay

After the CTO merges `task-envcfg-002`, replay `task-envcfg` on the shared
handbook lineage against the merged commit and specifically check that the
agent (a) can resolve `xsht api search:fail` / `language:core.fail` from the
reference alone and (b) adopts `fail("...")?` (or consciously chooses the
`env.int` path) instead of the sentinel `parse_int` hack, with all ten cases
and both failure controls passing. Optionally replay a `task-ecount` /
`task-tags`-style loud-exit boundary to confirm the registered primitive
generalizes beyond `task-envcfg`. This is the falsification check for the
discoverability hypothesis that ticket `task-envcfg-002` is built on.

## North-star impact

This run confirms the `env`/`fs` configuration surface is discoverable and
composable: an agent with the handbook rendered a byte-exact config file from
typed environment reads, preserved empty values, and routed a malformed port to
a loud nonzero exit with no partial file — exactly the "expected failures
visible" and explicit-boundary ethos XSH is built on. The candidate validates a
general ergonomics principle from `task-envcfg-001`/`002`: a newly shipped
language primitive must be findable through the same `xsht api` reference the
handbook directs agents to, or agents silently route around it. That is a
learnability and trust improvement for all future evals and users, not a
task-specific win.
