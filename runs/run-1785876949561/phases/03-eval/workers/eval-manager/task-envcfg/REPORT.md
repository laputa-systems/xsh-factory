# Eval-manager report

## Result

pass

## Effort metrics

One trial (`task-envcfg-1`) against XSH commit `434080dfe330cc3bb705bd8068d57a1015b7b218`.

- Worker `task-envcfg-1`: assistant turns 39, tool calls 40, tool results 40,
  tool errors 3, user messages 1, thinking blocks 28.
- Session span (Pi conversation): `session_span_ms` 328009 ms
  (`agent_wall_ms` 329381 ms).
- Worker friction: the 3 tool errors are all recoverable and self-corrected
  within one turn each; see `## Tool-error findings`. No repeated discovery
  loops beyond the deliberate `language.core.fail` exploration (turns 12-20).

## Usage and cost

Worker `task-envcfg-1` (provider OpenRouter, model deepseek/deepseek-v4-flash-0731):

- input tokens 30,777; output tokens 14,958; cacheRead 642,816; cacheWrite 0;
  bucket total 688,551 (matches provider `totalTokens` 688,551).
- reasoning tokens 9,824 (provider-reported, a subset of output).
- cost: input $0.002769930, output $0.002692440, cacheRead $0.011570688,
  cacheWrite $0, provider total $0.017033058. Budget $0.50; budget_state pass.
- Single trial, so trial and aggregate figures are identical.

## Thinking evidence

The worker reported 28 thinking blocks and 9,824 reasoning tokens. The
transcript shows the thinking tracked a planned, incremental path: read
handbook + `xsht api module:env`, probe `env.get_or`/`env.int`/`parse_int`
behavior against absent/empty/malformed values, search for a deliberate-error
construct, then converge on the final `envcfg.xsh`. Reasoning is qualitative
evidence; the claim that `language.core.fail` is non-callable was confirmed by
tool results (turns 12-20), not by the transcript alone.

## Tool-error findings

All 3 nonzero Pi tool results from the structured `report.json` `tool_errors`
array are accounted for:

1. Turn 26 — `||` boolean operator: `parse.unsupported-boolean-operator`
   (`use 'or' instead of '||'`) plus cascading `expected-token` /
   `expected-expression`. The agent wrote C-style `||`; the XSH checker
   rejected it with a clear, actionable message naming the word form. The
   agent corrected it to `or` in the next edit. **Classified as worker
   friction / reusable handbook guidance** (see `## Handbook decision`), not a
   product defect — the diagnostic is complete and correct.
2. Turn 27 — `let path = Path(argv[0])` triggers
   `check.standard-module-shadow` (name `path` shadows the standard module
   `path`). Clear diagnostic; agent renamed the binding to `out`. One-turn
   recovery. **Classified as worker friction / minor convention note**, not a
   repeated or blocking defect.
3. Turn 35 — `ls: /tmp/o: No such file or directory` (exit 1). This is the
   agent's own negative test verifying that a malformed `CFG_PORT` produces no
   output file. The nonzero exit is the *expected* result of the deliberate
   failure-control check, not an agent error. **Classified as ordinary
   noise / expected negative test.**

No `xsht api` discovery query produced an error in the structured arrays; the
three listed errors are all `bash` tool results (two `xsht check` diagnostics
and one deliberate negative-test `ls`).

## Timing evidence

Evaluator candidate/oracle wall timings per case (nanoseconds): all ten cases
cluster in the 11.0-13.2 ms range for both candidate and oracle
(e.g. public candidate 12,390,442 / oracle 11,233,697; hidden_malformed
candidate 12,870,606 / oracle 11,309,572). Both sides finish in milliseconds;
there is **no strict candidate/oracle timing gate** for this eval, so timing is
purely diagnostic and shows no out-of-contract slowness. Wall-clock
attribution: provider telemetry present with `retry_count 0`,
`provider_errors []`, retry_delay 0, so there was no external-health
confounder; latency attribution is not needed here.

## Observation classification

- **Correctness / result:** pass. All ten cases exact (public + 9 hidden,
  including the two failure controls hidden_malformed and hidden_empty_port),
  restrictions pass (`env_referenced`, no forbidden subprocess), protocol pass
  (artifact present, `review.md` valid).
- **Product/tooling defect (evidence-backed, not new ticket):**
  `api:language.core.fail` returns an exact listing —
  `fail(message: Str) -> Result[Unit, Error]`, contract "postfix `?`
  propagates ... top-level propagation exits nonzero" — yet every invocation
  the worker tried (function call, command form, `return fail(...)`, with
  `[error]` effect) fails `xsht check` with `check.unresolved-call: unresolved
  pure function call` / `check.unresolved-proc-command`. This cost the worker
  ~8 turns (12-20) and forced a non-obvious workaround
  (`port.delete("0123456789").parse_int()?`). This is the same deliberate-error
  gap already captured by open ticket `task-envcfg-001`; notably this trial
  provides **falsifying evidence against that ticket's CTO assumption** that
  current HEAD `434080d` "contains both the runtime fail(message) primitive
  and its canonical xsht api registration (`2d423c1`)" — the primitive is still
  not callable by the agent even though the API registry exposes it. No new
  ticket is opened (see `## Tickets created`).
- **Worker friction / reusable handbook guidance:** the `||` → `or` parse
  error and (secondarily) the standard-module shadow are small, recoverable
  convention frictions. The boolean word-form operator is a general,
  previously-flagged lesson not yet present in the approved snapshot.
- **Ordinary noise:** the turn-35 negative-test `ls` exit 1; the harness
  `candidate_sha256` recorded as the empty-string hash (e3b0c44...) rather than
  the artifact hash (18d95a9...) — infra diagnostic only, does not affect the
  byte-for-byte result which passed all ten cases.

## Handbook decision

Provisional candidate staged at
`runs/run-1785876949561/phases/03-eval/lineage/handbook-candidate.md`
(approved snapshot `97c5d80` + one concise addition). The addition teaches the
general word-form boolean-operator convention:

> Boolean conditions use the word-form operators `and`/`or`/`not`; the C-style
> `&&`, `||`, and `!` are parse errors.

General lesson: XSH operators are word forms, so an agent should write
`x or y` (not `x || y`). This removes a one-turn syntax round-trip and is a
learnability/ergonomics improvement independent of any single task. Replay
scope: task-envcfg (conditions), task-ecount, task-tags — any eval whose
solution branches on a condition. This is a one-trial run, so the candidate is
**not yet validated**; it requires later replay (and CTO review) before
promotion to `runtime/handbook.md`. The boolean-operator lesson was previously
flagged (see `task-envcfg-001` scope note) but is not yet present in the
approved snapshot, so staging it here is consistent with existing intent.

## Tickets created

Zero new tickets. The one strong reproducible product observation — documented
`language.core.fail` primitive that is not callable through `xsht check` at
current HEAD — is already within the scope of the open, Approved ticket
`task-envcfg-001` (the deliberate-error primitive gap). Opening a new ticket
would duplicate that active assignment. This trial's fresh evidence that
`fail(...)` is still unresolved at HEAD `434080d` (despite the API registry
exposing it) is recorded here to feed `task-envcfg-001`'s adoption gate in the
next cycle rather than dispatched as new engineer work.

## Post-merge decisions

None. The reconciler reported merged ticket files: `none`. No merged ticket
requires a post-merge acceptance decision this cycle. (Open ticket
`task-envcfg-001` is Approved-for-implementation and not merged; the trial
evidence above is relevant to its future adoption gate, not a post-merge
accept/reject.)

## Next replay

Replay `task-envcfg` against a follow-up XSH commit to (a) confirm the
staged handbook boolean word-form operator candidate is adopted and harmless,
and (b) re-test whether `language.core.fail` becomes callable once
`task-envcfg-001`'s implementation lands — the acceptance gate should require
`xsht api search:fail` discovery plus adoption of `fail(...)?` and all ten
evaluator cases. Also replay `task-ecount` / `task-tags` over the shared
handbook lineage to falsify or corroborate the general boolean-operator rule.

## North-star impact

This run demonstrates the environment/config surface is discoverable and
composable: an agent with the handbook produced a byte-exact, all-ten-case
correct `envcfg.xsh` using `env.get_or` + explicit validation + `fs.write`,
with stdout clean and the failure controls loud. That confirms the intended
`env`/`fs`/`?` lesson transfers to a real config-validation boundary. The
run also sharpens two durable signals aligned with the north star: (1) a
documented `fail` validation primitive that is not callable undermines the
"make expected failures visible" goal and forces an opaque sentinel
workaround — resolving it (open ticket `task-envcfg-001`) would make deliberate
validation rejection explicit and learnable; (2) a concise word-form
boolean-operator handbook rule removes a trivial but recurring agent
round-trip, a small ergonomics gain for every conditional solution.
