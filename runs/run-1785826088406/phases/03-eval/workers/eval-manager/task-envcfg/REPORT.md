# Eval-manager report

## Result

pass

## Effort metrics

Single trial (`task-envcfg-1`) as configured. Per worker report:
- assistant turns: 45
- tool calls: 52 (bash 42, edit 3, read 4, write 3)
- tool results: 52
- tool errors: 1 (edit at turn 37, stale file state)
- user messages: 1
- stop reasons: 44 `toolUse`, 1 `stop`
- session span: 275372 ms
- worker friction: minimal; the one failed edit was recovered on the very next
  turn with a smaller targeted edit (see Tool-error findings). Discovery friction
  was modest (see Tool-error findings for malformed `xsht api` probes).

## Usage and cost

Per provider-reported usage (single worker):
- input: 79651, output: 18216, cacheRead: 822144, cacheWrite: 0
- provider_total_tokens: 920011; bucket total: 920011 (consistent)
- cost: input $0.00716859, output $0.00327888, cacheRead $0.014798592,
  cacheWrite $0, total $0.025246062 (budget $0.50, no breach)
- reasoning_tokens: 11783 (provider-reported subset of output)
- thinking_blocks: 38
- Aggregate equals the single trial: $0.025246062 / 920011 tokens.

## Thinking evidence

38 thinking blocks recorded; provider-reported reasoning tokens = 11783 (a
subset of output; never added to totals). Thinking is qualitative: the worker
checked the `env` module contract, verified `env.get_or` fallback-on-absence
semantics, confirmed `env.int`/`parse_int` are non-strict validators, searched
for a deliberate-failure primitive (see Tool-error findings), and settled on an
explicit digit check with a derived `parse_int` sentinel to force the malformed
failure. The eval contract accepted a nonzero exit regardless of code, so the
reasoning was goal-directed and efficient.

## Tool-error findings

Structured `tool_errors` arrays (phase `report.json` and worker
`report.json`) contain exactly one entry, fully accounted for:

1. `edit` at turn 37 (worker `task-envcfg-1`): "Could not find the exact text in
   /work/envcfg.xsh..." The model proposed a large restructure whose `oldText`
   no longer matched the file (it had already edited that region), so the edit
   was rejected. The model recovered on turn 38 with a single-line edit renaming
   `_bad` to `_` (replacing the lint-unclean binding). Classification: ordinary
   transient worker friction, self-correcting, not reproducible, no durable
   signal.

Additionally, three malformed `xsht api` queries ran inside successful `bash`
calls and returned "invalid API query" text rather than structured Pi errors
(`api:Path`, `api:str`, `language.effect.error`). They are not entries in the
structured `tool_errors` arrays because the `bash` tool itself succeeded. This
is minor discovery friction: the worker then corrected to `method:Path`,
`method:Str`, and `language:effect.error` on later turns. No standalone `xsht
api` tool produced a structured error in any current session.

No `None.` applies because all current structured failures are the single edit
above.

## Timing evidence

Candidate/oracle wall times per case (~11–14 ms each side; no strict ratio
gate in this eval contract):
- public 13.32 / 11.80 ms
- hidden_defaults 12.01 / 13.21 ms
- hidden_partial 12.84 / 13.57 ms
- hidden_empty 13.45 / 12.61 ms
- hidden_spaces 13.31 / 13.53 ms
- hidden_zero 12.61 / 13.61 ms
- hidden_utf8 11.84 / 11.19 ms
- hidden_debug_false 13.59 / 13.01 ms
- hidden_malformed 12.19 / 11.80 ms (candidate exit nonzero, no output file)
- hidden_empty_port 12.22 / 11.96 ms (candidate exit nonzero, no output file)

All within the same millisecond envelope; timing is diagnostic only. Both
failure controls produced a nonzero exit (runtime `result.propagate`
tracebacks on stderr, exit code 3) with empty stdout and no file written.
Correctness: all ten cases `exact: true`; `classification: pass`.

## Observation classification

- Worker friction (transient): the turn-37 edit mismatch. Self-corrected next
  turn. Ordinary noise, not reusable.
- Worker friction (minor discovery): malformed api query forms (`api:Path`,
  `api:str`, `language.effect.error`) rejected and corrected. Partly covered by
  the handbook's "bare receiver query is rejected" note; harmless noise here.
- Product/tooling defect (reproducible, already ticketed): the worker again
  could not discover any deliberate-failure primitive. A live `task-envcfg`
  worker at commit `97edb51c` searched `assert`/`fail`/`Error`/`Err`/`panic`/
  `require`/`validate` and found nothing, then fell back to
  `port.delete("0123456789").parse_int()?` sentinel and wrote in
  `review.md`: "no generic `Error(...)` constructor ... forces an awkward
  workaround." This is a second independent reproduction of the exact defect in
  Approved ticket `task-envcfg-002` (the `fail(message)` primitive exists in the
  runtime but is absent from the `xsht api` registry, so agents cannot discover
  it and route around it). Generalizable: any eval needing a loud deliberate
  error boundary (task-tags, task-ecount) hits the same discoverability wall.
- Reusable handbook guidance: none newly warranted. The handbook's "no generic
  Error(...) constructor; let a typed conversion express rejection" line
  correctly described the current (still-unregistered-`fail`) build, and the
  worker succeeded using it. The defect is a product/registry fix, not a
  handbook fix.
- Evaluator/harness: none; all gates (correctness, restrictions with `env.`
  reference, review headings, forbidden subprocess) passed.

## Handbook decision

Unchanged. The approved snapshot is accurate for the build under test
(`env.int`/`parse_int` non-strict; no generic `Error(...)`; explicit digit
checking required). No candidate is staged. The persistent friction is not a
handbook gap — it is the unmerged registry defect in ticket `task-envcfg-002`.
Wrote `lineage/handbook-candidate.md` = approved snapshot unchanged (copy).

## Tickets created

None. The one strong reproducible observation (indiscoverable `fail`
primitive) is already captured and Approved as `tickets/task-envcfg-002.md`;
this run is a second independent live reproduction confirming it. A duplicate
ticket would add noise, not signal. The observation should proceed through
ticket 002's existing acceptance flow.

## Post-merge decisions

The reconciler reported zero merged tickets (`none`), and the candidate ticket
is `not-reevaluation`, so there are no post-merge acceptance assignments this
cycle. Noted: `task-envcfg-002` remains Approved (not yet implemented at the
under-test commit `97edb51c`); this run independently reconfirms its defect and
does not require manager dispatch.

## Next replay

Re-run `evals/task-envcfg` against the merged implementation of ticket
`task-envcfg-002` (once `fail(message)` is registered in the `xsht api`
registry). Acceptance: the eval agent discovers `fail` from the reference alone
and writes `fail(...)?` on the malformed/empty-port branches (no sentinel
`parse_int`) with all ten cases and both failure controls still passing.
Optionally replay `task-ecount`/`task-tags` loud-exit boundaries to confirm the
discoverable primitive generalizes. That replay is the falsification check for
this report's classification.

## North-star impact

This run demonstrates the environment/config surface is discoverable and
composable: with the approved handbook alone the worker produced a
byte-exact config renderer passing all ten cases, kept stdout clean, and made
expected failures visible (nonzero exit, no partial file) — core "glue that
speaks to system state" behavior. It also sharpens a durable trust lesson:
a language feature is not learnable if it is invisible to the reference the
handbook directs agents to. Confirming ticket `task-envcfg-002` drives the
north-star outcome that deliberate validation failures are both structured and
discoverable, so future agents replace an opaque sentinel with a first-class,
documented `fail`, reducing turns and sludge without a task-specific hack.
