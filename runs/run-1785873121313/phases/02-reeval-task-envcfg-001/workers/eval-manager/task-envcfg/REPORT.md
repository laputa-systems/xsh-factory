# Eval-manager report

## Result

fail

The phase's single purpose — pre-merge validation of the `task-envcfg-001`
implementation (candidate XSH commit `91e0eaa46014ea1dba60a5faebdead98db38cc9f`)
before merge — is **not** met. The executor worker and evaluator both
classified the trial `pass` (all ten evaluator cases byte-exact, restrictions
and protocol clean), but the agent never discovered or adopted the new
`fail(...)` deliberate-error primitive that the ticket was created to provide.
It fell back to the unrelated-host-failure sentinel `fs.write(p"", "")?`, the
same class of workaround the ticket and the CTO replay gate require removing.

Root cause: `91e0eaa` implements the runtime `fail` primitive but does **not**
include `task-envcfg-002`'s API-reference registration (`2d423c16`), which is a
separate merged ticket and is not in this candidate worktree's history. As a
result `xsht api search:fail` exposed no deliberate-error entry and the agent
had no discovery path to `fail`. The ticket is not yet supported for merge; it
needs replay against a build that merges the `fail` API registration into the
candidate.

This is a pre-merge validation; the ticket is not marked merged and engineer is
not dispatched.

## Effort metrics

Trial 1 (only configured trial; `## Trial plan` count = 1):

- Model: `openrouter/deepseek/deepseek-v4-flash-0731`.
- Assistant turns: 45 (stop_reasons: 1 `stop`, 44 `toolUse`).
- Tool calls: 58; tool results: 58; tool errors: 0.
- Thinking blocks: 41; reasoning tokens (provider-reported): 11989.
- Session span: 416,244 ms (agent wall 417,724 ms); user messages: 1.
- Worker friction: the agent spent roughly turns 11–37 searching for a
  deliberate-error primitive (`search:fail`, `search:assert`, `search:check`,
  `Error`, `Err`, `FsError.*`, `EnvError.*`, `module:result`) before settling
  on the `fs.write(p"", "")?` sentinel. One minor `xsht api language:core`
  query returned `invalid API query ... expected KIND:VALUE` (a discovery
  note, not a Pi tool error; correct form is `language:core.*`).

## Usage and cost

Worker trial 1 token buckets (provider-reported):
`input` 109,713, `output` 18,178, `cacheRead` 908,672, `cacheWrite` 0,
`total_bucket` 1,036,563, `provider_total` 1,036,563 (buckets agree).

Cost (provider-reported USD): input 0.00987417, output 0.00327204,
cacheRead 0.016356096, cacheWrite 0, **total 0.029502306**; budget 0.50
(no budget breach). Reasoning tokens 11,989 are a subset of `output`.

Aggregate (one trial): total $0.029502306; unknown costs 0; budget failures 0.

## Thinking evidence

Thinking blocks: 41 (worker). `reasoning_tokens` 11,989 reported by the
provider (`provider` openrouter, `thinking: high`). The worker's thinking —
"fail? I need a function. Let me search xsht api for assert / fail / check" —
directly drove the discovery queries for a deliberate-error primitive. When
`search:fail` returned only `language.core.fallback`/`results`/`streams` word
matches and `search:assert` surfaced only `language.run`/`Bytes.strings`
entries, the agent concluded no deliberate-error primitive exists and adopted
the unrelated `fs.write(p"", "")?` failure. This correlates with the review
claim and confirms the discovery gap, not an incorrect correctness path.

## Tool-error findings

None. The current evidence packet has zero structured tool errors: the worker
`report.json` `tool_errors` is `[]` (usage `tool_errors: 0`) and the manager
session records no `isError` tool results. The `xsht api language:core` query
returned an informational `invalid API query ... expected KIND:VALUE` from
`xsht` inside a successful `bash` tool call (not a Pi tool error) and is
reported as discovery friction above.

## Timing evidence

No strict candidate/oracle timing gate exists for this eval (both finish in
milliseconds). Diagnostic timings per case (wall, ns) were all in the ~11–14 ms
envelope, candidate and oracle comparable:

- public: cand 12,112,694 / oracle 11,318,145
- hidden_defaults: 11,163,769 / 13,817,376
- hidden_partial: 13,619,333 / 13,754,793
- hidden_empty: 13,378,206 / 12,025,943
- hidden_spaces: 12,893,618 / 13,444,123
- hidden_zero: 11,300,062 / 11,125,477
- hidden_utf8: 12,735,033 / 12,096,027
- hidden_debug_false: 13,562,207 / 11,219,936
- hidden_malformed: 13,204,787 / 13,217,204
- hidden_empty_port: 13,271,204 / 12,487,947

No timing concern; not a gate.

## Observation classification

- **Correctness (pass, product signal):** the submitted `envcfg.xsh` passed
  all ten cases byte-exact, including both failure controls (nonzero exit, no
  output file). Downloaded `candidate_sha256 = e3b0c442…` is the hash of the
  empty stdout (the program writes to the file, not stdout) — benign, not a
  defect. This confirms the `fail` primitive, where exercised indirectly, and
  the envcfg solution are mechanically sound.
- **Reusable signal — harness/replay-configuration mismatch:** the candidate
  build `91e0eaa` implements `fail` but omits `task-envcfg-002`'s API
  registration (`2d423c16`, marked Merged, an ancestor of HEAD `434080d`; not
  present in the `91e0eaa` worktree `git log`). The replay therefore could not
  demonstrate the repaired end-state. This is configuration, not a new product
  defect; it is already owned by `task-envcfg-002`.
- **Product/tooling defect (already tracked, not new):** `fail` remains
  invisible on the canonical `xsht api` discovery surface for this candidate
  build, so the agent reverts to the sentinel — exactly why `task-envcfg-002`
  exists. No new ticket warranted.
- **Ordinary noise / minor friction:** `xsht api language:core` invalid-query
  message (handbook teaches `language:core.*`); the `env.int` leniency note in
  `review.md` restates an out-of-scope contract decision the ticket explicitly
  excluded.
- **Cross-check note:** the reviewer's second point (env.int accepts `+5`,
  `-5`, `007`) is consistent with the approved handbook's own "not strict
  format validators" sentence; not a discrepancy.

## Handbook decision

Unchanged. Staged `lineage/handbook-candidate.md` as an exact copy of the
approved snapshot (`97c5d804c42c7742c9edfea4480163828d864279391d391df77aa60ee4a40e83`,
verified equal by hash). No new validated handbook lesson exists yet: the
approved handbook already tells agents to propagate an expected failure with
postfix `?` and not to use an unrelated host failure, and — on the tested
surface — there is still no discoverable deliberate-error primitive, so the
agent's `fs.write(p"", "")?` fallback is exactly the undeveloped boundary the
ticket targets. The handbook's "this build has no generic `Error(...)`
constructor" sentence must be revised only after a replay demonstrates
`fail(...)` is discoverable and adopted; that is a post-replay step, not this
run.

## Tickets created

Zero. The single strong reproducible observation (deliberate-error primitive
present but undiscoverable on `xsht api`) is already owned by the merged
`task-envcfg-002` ticket. No new general XSH defect justified a ticket.

## Post-merge decisions

None. This run's reconciler found no merged ticket files to re-accept (the
structured `## Merge record` reconciliation returned `none`). `task-envcfg-002`
(register `fail` in the API reference, commit `2d423c16`) and `task-envcfg-003`
are merged tickets from prior cycles, but they were not assigned for
acceptance in this run, so no explicit accept/needs-replay decision is recorded
here.

## Next replay

- Eval: `task-envcfg` (trial count 1).
- Handbook lineage: this run's `lineage/handbook-approved.md` (snapshot
  `97c5d804…`); candidate unchanged.
- Post-merge/falsification check: rebuild the candidate with the `fail` API
  registration merged in — i.e. test a HEAD that contains both `91e0eaa`
  (primitive) and `2d423c16` (registration) — then require all of:
  (1) `xsht api search:fail` surfaces the deliberate-error primitive;
  (2) the submitted solution adopts `fail(...)?` (no unrelated typed
  conversion or `fs.write` sentinel); (3) all ten evaluator cases pass.
  Meeting these falsifies the current "still needs the sentinel" finding and
  supports the `task-envcfg-001` fix for merge.

## North-star impact

The run confirms the `fail` primitive and the envcfg solution are correct on
every correctness gate, but north-star trust requires expected failures be
*loud and visible through a discoverable, first-class surface*. Here the
primitive exists yet is invisible to the canonical discovery route, so the
agent still reaches for an unrelated host failure — the very sludge the ticket
and the handbook guidance oppose. A correct next replay (primitive merged with
task-envcfg-002's API registration) should let an agent reject malformed input
with `fail(...)?`, a clean nonzero exit, no partial file, and no fabricated
failure — turning a reusable validation idiom into an ergonomic, learnable,
trustworthy XSH behavior.
