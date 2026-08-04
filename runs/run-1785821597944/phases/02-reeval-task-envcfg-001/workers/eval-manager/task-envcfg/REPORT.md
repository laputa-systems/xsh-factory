# Eval-manager report

## Result

fail

## Effort metrics

Single trial (controller executed 1 fresh trial against the candidate build).
Eval-worker `task-envcfg-1`:

- Assistant turns: 51 (1 user message; 1 `stop`, 50 `toolUse`)
- Tool calls: 52; tool results: 52; tool errors: 3
- Session span: 576,994 ms (~9.6 min); agent wall: 578,340 ms
- Thinking blocks: 35
- Model: `openrouter/deepseek/deepseek-v4-flash-0731`, thinking `high`

The phase-level `report.json` data block mirrors this worker (`assistant_turns 51`,
`tool_errors 3`, `cost_usd 0.0276`). No eval-manager session friction was
recorded before this report; the report skeleton was the only missing artifact.
Worker friction concentrated in the error-raising search (turns 53-81), which is
the core observation below.

## Usage and cost

Provider-reported usage (worker `report.json`), per trial:

- Input tokens: 97,286; output tokens: 21,076; cacheRead: 836,544; cacheWrite: 0
- Reasoning tokens: 14,366 (provider-reported; subset of output, not added to total)
- provider totalTokens: 954,906; bucket total (input+output+cacheRead+cacheWrite): 954,906 (match)
- Cost USD: total 0.027607; input 0.008756, output 0.003794, cacheRead 0.015058, cacheWrite 0
- Budget allowance 0.50; budget_state pass

Single-trial run, so aggregate == trial. Reasoning-token count is provider-reported
(this provider exposes it), so the number above is a real figure, not a guess.

## Thinking evidence

35 thinking blocks; 14,366 reported reasoning tokens. The transcript (`thinking`
entries in `session.jsonl.bz2`) shows the worker reasoning carefully about: the
oracle's `-default` vs present-empty semantics (`env.get` returns Err on absence,
Ok("") on present-empty; `??` fallback only on absence), the strict decimal
requirement disallowing `parse_int`/`env.int` permissiveness (leading zeros must
be preserved byte-exact, `-5`/`+5`/`0x1F` must be rejected), and the search for a
deliberate-error primitive. The decisive thinking is turns 47-81: the worker
explicitly wanted `fail`/`Error`/`assert`/`panic` and could not find any, then
reasoned its way to the sentinel `let _ = "".parse_int()?` idiom. This is
qualitative but strongly corroborated by tool results.

## Tool-error findings

The structured `tool_errors` array for `eval-worker/task-envcfg-1` has 3 entries
(all present in the phase `report.json` and worker `report.json`):

1. Turn 3 — `xsht api: invalid API query 'signature:env.get_or'; unknown selector kind 'signature'`. Worker guessed a `signature:` selector kind inside a `bash` call. Worker friction / discovery gap (invalid query, exit 2).
2. Turn 16 — `xsht api: invalid API query 'api:language.core.fallback'` and `'api:language.core.results'; expected NAME.MEMBER`. Worker used the wrong prefix (`api:` instead of `language:`). Worker friction / discovery gap (exit 2). Corrected at turn 40 with `language:...`.
3. Turn 42 — command included `xsht lint` warnings (`lint.needless-annotation` for the `: Int` annotation, `lint.path-constructor` preferring `fp"${out}"`) and a local test harness that left a stale `/tmp/m.cfg`, producing misleading `DIFF` lines for port-invalid cases; the command exited 1. This is a lint+worker-harness artifact, not a product failure; the worker later fixed both (turn 90) and re-verified cleanly.

No other nonzero Pi tool result exists in the current worker session. The
`eval-worker/task-envcfg-1/report.json` and phase `report.json` arrays agree;
there is no separate nonzero tool result in the manager session to report.

## Timing evidence

Candidate/oracle wall times (worker `run.json`) are all millisecond-scale:
candidate 11.0-13.3 ms/case, oracle 10.9-13.6 ms/case across the 10 cases. This
eval has no strict candidate/oracle ratio gate; the task explicitly states timing
is diagnostic. Timing is therefore classified as noise/ordinary signal, not a gate
(no case would trip a ratio bound).

## Observation classification

- Correctness: pass. All 10 cases exact (`all_exact: true`; both failure controls
  exit nonzero with no output file), restrictions pass (`env.` referenced, no
  subprocess), protocol/review pass. The worker build was candidate commit
  `91e0eaa`; the eval remains green with no regression.
- Candidate mechanism: pass in isolation. The `fail(message)` primitive is
  implemented in runtime/sema, documented in `docs/SPEC.md`, covered by a focused
  native test (`tests/xsh/run.xsh::test_fail_constructor_propagates_validation_error`),
  and satisfies check/lint. As a unit it works.
- Product/tooling defect (strong, reproducible): the new `fail` primitive is NOT
  registered in the `xsht api` discovery reference. Evidence: worker turn 54
  `xsht api search:fail` returned only `language.core.fallback`/`results`/`streams`
  (word "failure/failed" matches), and `xsht api summary | grep -iE "Error|Fail|Invalid"`
  (turn 62/64) returned nothing for `fail`. Source-level confirmation: the candidate
  changed `src/runtime/eval{,/indexed,/lowered_run}`, `src/sema/check/call.rs`,
  `docs/SPEC.md`, and `tests/xsh/run.xsh`, but `crates/xsh-registry/src/reference.rs`
  (`CORE_LANGUAGE_ITEMS` and `core_doc`) has no `fail` entry, and `XSHT-API.md` is
  unmodified. Therefore the canonical surface the handbook tells agents to use for
  discovery cannot reveal the new primitive.
- Worker friction (consequence): the agent spent turns 53-81 (a large share of its
  51-turn budget) searching `assert`/`expect`/`panic`/`invalidate`/`fail`/`Error`/
  `Err`/`module:result` and found no deliberate-error primitive, then reverted to
  the sentinel `let _ = "".parse_int()?` — exactly the hack ticket `task-envcfg-001`
  was written to remove. This is durable ergonomic evidence, not task confusion: it
  repeats the independent 2026-cycle finding (two prior workers) and persists after
  the fix because discovery is broken.

## Handbook decision

Unchanged (candidate `lineage/handbook-candidate.md` is a byte-identical copy of
`lineage/handbook-approved.md`). A handbook sentence teaching `fail(message)` is
premature here: this run proves the primitive is not discoverable via `xsht api`,
so a handbook rule would point an agent at an undiscoverable surface, and a
one-trial plan cannot replay a promoted claim anyway. The durable, general lesson
is a product fix (register the primitive in the API reference and keep that
reference in sync with the runtime surface), captured as the ticket below. The
handbook should be revisited for a `fail(message)` sentence only after that
registry fix is merged and an agent actually adopts it in a replay.

## Tickets created

One product ticket for the next cycle:
`/Users/josh/d/laputa-systems/xsh-factory/tickets/task-envcfg-002.md` — "Runtime
keyword/constructor primitives (e.g. `fail`) are not surfaced in the `xsht api`
reference, so agents cannot discover them during an eval."

## Post-merge decisions

None. The reconciler found no merged ticket files for this phase. This is a
pre-merge candidate validation (engineer worktree at
`runs/run-1785821597944/phases/01-ticket/worktrees/task-envcfg-001`, candidate
commit `91e0eaa`). The candidate is not ready to merge as-is: it does not meet
ticket `task-envcfg-001`'s acceptance intent (a discoverable deliberate-error
primitive used via `?`), verified by the linked eval agent's inability to find
`fail` and its reversion to the sentinel workaround. No merge-record fields are
touched, and no merged-ticket decision is recorded.

## Next replay

Re-run `task-envcfg` (and ideally `task-ecount`/`task-tags` where a loud nonzero
exit is required) against the candidate commit after `fail(message)` is registered
in `crates/xsh-registry/src/reference.rs` (an `xsht api search:fail` /
`api:...fail` so it resolves), then confirm the eval agent adopts `fail(...)?`
instead of the sentinel `parse_int` idiom, with all 10 cases and both failure
controls still passing. That is both the falsification check for ticket
`task-envcfg-001` (post-merge) and the validation check for ticket
`task-envcfg-002`.

## North-star impact

The eval's purpose is a practical config-rendering boundary that must reject
malformed input loudly with no partial file — a core XSH "structured errors /
expected failures visible" scenario. The candidate correctly implements the
mechanical `fail` propagation, but XSH's north-star ergonomics/learnability bar
is "fewer guesses, workarounds, tool errors, and repeated discoveries" and "agents
reach a correct solution with less exploration." This run is direct evidence that
the tooling contract broke: an agent spent tens of turns and could not learn of a
newly shipped primitive, so the very workaround the ticket targeted is still the
only reachable path during an eval. Keeping the runtime surface and the `xsht api`
reference in lock-step is a precondition for a learnable language; this report ties
that general principle to concrete, reproducible evidence and names the exact
replay that can falsify it.
