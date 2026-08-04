# Eval-manager report

## Result

pass

## Effort metrics

Single fresh trial (trial 1), one worker (`eval-worker/task-envcfg-1`), one
eval (`task-envcfg`) at XSH commit `2d423c166b9c06aee44b9f4e720554ebeee1216b`
against approved handbook snapshot `97c5d804c42c7742c9edfea4480163828d864279391d391df77aa60ee4a40e83`.

Worker session: 21 assistant turns, 28 tool calls, 28 tool results, 2 tool
errors. Tools used: bash 21, write 3, read 3, edit 1. Session span 417693 ms
(~6.96 min); agent wall 420312 ms. One user message; stop reasons: 20
toolUse, 1 stop. Model `openrouter/deepseek/deepseek-v4-flash-0731`, thinking
level high. No budget breach (budget allowance $0.50). Zero malformed lines.

The worker produced `/work/envcfg.xsh` (env.get_or + port.delete digit check +
`parse_int()?` sentinel failure + fs.write) and completed `review.md`. The
evaluator reported `classification: pass`; all ten cases pass, restrictions
pass (env referenced, no subprocess), protocol pass (artifact present, review
ok), timing pass (diagnostic). Trial `passed: true`, `valid: true`.

## Usage and cost

Single worker usage (provider-reported):
- input 114971 tokens (cost $0.010347), output 10369 tokens ($0.001866),
  cacheRead 169152 tokens ($0.003045), cacheWrite 0 ($0).
- provider_total_tokens 294492; bucket total (input+output+cacheRead+cacheWrite)
  294492 — the two totals agree, no mismatch.
- reasoning_tokens 6945 (provider-reported, a subset of output and not added
  to any total), thinking_blocks 16.
- cost_usd aggregate 0.015258546; budget 0.5; no budget failure. Per-trial
  dollars = aggregate = $0.0153 for the single trial.

## Thinking evidence

16 thinking blocks; provider reported 6945 reasoning tokens (deepseek-v4-flash
reports reasoning, so the count is available). The transcript (`thinking`
blocks in `session.jsonl.bz2`) shows a deliberate, linear path: read `module:env`
and `env.get_or`/`env.int`/`env.bool` contracts; confirm `get_or` fallback
applies only on absence; attempt the documented `fail(message)` primitive for
the malformed-port gate; hit `check.unresolved-call` twice (full script and a
minimal `/tmp/f.xsh` repro); reason explicitly about oracle byte-exactness
(rejecting `env.int` as lenient and `parse_int`'s `+`/`-` acceptance), then
land on the explicit digit check plus `port.parse_int()?` sentinel so the
failure is both byte-exact against the oracle and exits nonzero without
writing the file. It verified defaults, empty values, invalid/empty port
no-file behavior before finishing. The final submitted program passed `xsht
check`, `fmt`, and `lint`.

## Tool-error findings

Two nonzero Pi tool results in the structured worker `tool_errors` array; the
manager session incurred none.

1. Turn 4, tool `bash`, "sh: syntax error: unterminated quoted string" (exit 2).
   Command: `cd /work && xsht api api:fs.write; ... xsht api search:Path\(" 2>/dev/null ...`
   — an unbalanced quote in the agent's own shell line while composing an
   API-discovery query. Worker exploration friction (a bash quoting slip), not
   a product defect or handbook gap.

2. Turn 16, tool `bash`, returned exit 1 after running the comprehensive
   oracle-vs-xsh comparison harness. The captured output shows the candidate
   passed every real case: cases A/B/C byte-exact; cases D (invalid port) and
   E (empty port) correctly `xsh exit=3` with **no** output file
   (`ls: /tmp/out4.cfg: No such file or directory`). The command exited 1 only
   because the diagnostic harness validates the intended failure-control cases,
   which necessarily return nonzero and produce no file. Ordinary harness noise
   from a test script, not a defect.

No `xsht api` discovery failures remain current; both discovery queries the
worker did fire (`search:fail`, `language:core.fail`) returned `status: exact`.

## Timing evidence

No strict candidate/oracle ratio gate for this eval; timing is diagnostic
(contract: both sides finish in milliseconds). Candidate wall times 11.0–13.9 ms
per case; oracle wall times 11.2–17.0 ms. Every case lands in the same
~10–17 ms process-launch envelope; no anomaly. Candidate/oracle timing is a
diagnostic measurement here, not a gate, and the two failure-control cases
(invalid and empty port) also finish within envelope.

## Observation classification

- Correctness (pass): all ten cases byte-exact, including hidden_empty,
  hidden_spaces, hidden_utf8, hidden_zero, and the two failure controls
  (nonzero exit, no file). Evidence: `run.json` correctness map all `true`.
- Reusable handbook guidance: the existing "Environment and configuration"
  section (`env.get_or` fallback-on-absence, `fs.write`, typed-env-leniency,
  use a typed conversion with `?` for a deliberate validation failure) was
  enough for a correct solution without digging into source. The productive
  signal is already in the approved handbook; no new general lesson was
  surfaced that the handbook does not already state.
- Product/tooling (tracked, not new): the documented `fail(message)`
  primitive in `xsht api language:core.fail` (now discoverable — see
  `search:fail` returning `status: exact`) is still rejected by `xsht check`
  as `check.unresolved-call`, confirmed twice in this run (full script and a
  minimal repro). The agent fell back to the `parse_int()?` sentinel. This is
  the exact gap already tracked by open ticket `task-envcfg-001` (implement the
  deliberate-error primitive) and completed-in-part by merged
  `task-envcfg-002` (register it in the API reference, whose implementation
  commit equals this run's XSH commit). Reproducing it here confirms the
  ticket's premise; it does not constitute new un-tracked work.
- Worker friction (noise): turn 4 bash quoting slip during exploration;
  turn 16 harness-exit-1 caused by validating intended failure controls. Both
  are ordinary, non-generalizable noise.
- Ordinary noise: `xsht fmt` reformatting a display string into a triple-quoted
  literal (noted in `review.md`); byte-identical output, cosmetic only.

## Handbook decision

Unchanged (provisional candidate = copy of the approved snapshot
`97c5d804…`; staged at `lineage/handbook-candidate.md`).

The run's only real friction — the documented-but-unresolved `fail(message)` —
is a tracked product gap (open `task-envcfg-001`, merged `task-envcfg-002`
registration), not a handbook deficiency. The handbook already teaches the
working, durable pattern (validate explicitly; propagate a typed conversion
with `?` for a deliberate failure) and the agent applied it correctly. Encoding
"fail is not callable, use parse_int" in the shared handbook would be a
task-specific, transient workaround that becomes wrong the moment
`task-envcfg-001` merges; the factory favors durable guidance over a stale
recipe. No candidate change is justified in this cycle.

## Tickets created

Zero.

The single strong signalled observation (documented `fail()` rejected by
`xsht check`, forcing a sentinel conversion) is already fully tracked: open
`task-envcfg-001` (implement the deliberate-error primitive) and merged
`task-envcfg-002` (register it in the API reference). This run reproduces and
supports both; opening a duplicate ticket would not advance the factory.

## Post-merge decisions

The reconciler reported merged ticket files: `none` for this dispatch, so
there are no newly-reconciled post-merge acceptance assignments to decide.

Context worth recording: ticket `task-envcfg-002` (Status `Merged.`) lists
implementation commit `2d423c166b9c06aee44b9f4e720554ebeee1216b`, which is the
exact XSH commit under test. Current evidence confirms 002's acceptance
criterion — `xsht api` discovers `fail(message)` (`search:fail` and
`language:core.fail` both return `status: exact`). The residual "call is
rejected by `xsht check`" condition is precisely the unimplemented half owned
by open `task-envcfg-001`; it is not a regression of 002. No revert proposal.

## Next replay

Replay `task-envcfg` (one trial) after `task-envcfg-001` merges a callable
deliberate-error primitive, against the repaired branch's XSH commit, using
the same approved handbook snapshot `97c5d804c42c7742c9edfea4480163828d864279391d391df77aa60ee4a40e83`
(handbook lineage `runs/run-1785830554385/phases/01-eval/lineage/`). Acceptance:
the worker adopts `fail(...)?` for the malformed/empty-port gates (discoverable
via `xsht api search:fail`) or otherwise no longer needs the `parse_int()?`
sentinel, and all ten evaluator cases still pass — and, separately, a
task-ecount/task-tags replay if this is intended to generalize the deliberate-
error idiom.

## North-star impact

The run confirms the environment/config surface (`env.get_or` fallback-on-
absence, byte-exact config writing via `fs.write`, typed conversion as a
loud-deliberate-failure boundary) is discoverable and composable: a fresh agent
reached a byte-exact, restriction-clean solution with the current handbook and
no source digging. That is direct evidence for XSH's practical systems-glue
mission (render a config file from the process environment) and for the
learnability goal (the Result/`?` lesson transferred to a real validation
boundary). The residual friction points squarely at structured-error
ergonomics — an agent sees a documented `fail()` constructor it cannot call and
must smuggle a failure through an unrelated parse error — which is precisely
the general, mission-aligned gap already under active repair in
`task-envcfg-001`/`002`. Making deliberate validation failures first-class would
let programs reject malformed input clearly instead of abusing a correlation-
free conversion error, advancing the trustworthy, explicit-boundary ethos that
has no generic-constructor short-circuit today.
