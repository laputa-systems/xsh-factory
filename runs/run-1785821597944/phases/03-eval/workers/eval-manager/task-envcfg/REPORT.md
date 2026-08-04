# Eval-manager report — task-envcfg

Cycle run `run-1785821597944`, phase `03-eval`, eval `task-envcfg`.
Approved handbook snapshot under review: `03-eval/lineage/handbook-approved.md`.
XSH commit under test: `97edb51c621260d61a00034ea7ed0742adacbb80`.
Trials configured: 1. Reconcile-merged tickets: none.

## Result

pass

## Effort metrics

One fresh trial (worker `task-envcfg-1`, model `openrouter/deepseek/deepseek-v4-flash-0731`).

- Assistant turns: 26 (25 `toolUse`, 1 final `stop`).
- Tool calls: 32 (bash 18, read 6, write 7, edit 1); tool results 32.
- Tool errors: 4 (all in the initial discovery phase, all recovered in-session).
- Session span: agent wall 219.5 s; session span 218.1 s.
- Worker friction: 4 self-recovered discovery misses (see Tool-error findings). No
  reviewer/manager-writer friction; no blocked paths. Protocol/reporting/review/budget all `pass`.

## Usage and cost

Single trial, provider OpenRouter `deepseek-v4-flash-0731`.

- Buckets (provider-reported): input 50,187; output 9,427; cacheRead 322,688;
  cacheWrite 0; provider total 382,302; bucket total equals provider total (no mismatch).
- Reasoning tokens reported: 5,603 (subset of output; not added to totals).
- Cost: input $0.00451683; output $0.00169686; cacheRead $0.00580838; cacheWrite $0;
  total $0.012022074 of a $0.50 budget.
- Aggregate: 1 trial, total $0.012022074.

## Thinking evidence

- Thinking blocks: 19 (qualitative evidence). Provider reports `reasoning` tokens (5,603), so a
  provider-derived count is available.
- The transcript shows the worker reasoned correctly about the strict-decimal contract: it probed
  `env.int` and `Str.parse_int` behavior (turn 3), found both too permissive (`+5`, ` 5`, `0x10`,
  `-3` accepted), and deliberately chose manual digit-checking plus a forced `"x".parse_int()?`
  failure to satisfy the oracle's `*[!0-9]*|""` gate while keeping the byte-exact string. It also
  correctly applied default-only-on-absence semantics and the `error` effect requirement. Thinking
  correlated with a correct final artifact.

## Tool-error findings

All four failed Pi tool results come from the worker session `task-envcfg-1` (no manager-session
`report.json` tool errors exist in this run; the manager report is authored here).

1. Turn 3, `bash`: `xsh: unknown xsh option '-e'` — the worker tried an inline `xsh -e '...'`
   invocation; XSH has no `-e` flag. The worker recovered by writing a throwaway script. Worker
   discovery friction; the handbook models programs as files with a `main` proc, not `-e`.
2. Turn 7, `bash`: `compact.main-missing-spread: proc main must use the spread form
   (...argv: List[Str])` (12 repetitions in one probe) — worker wrote a fixed-parameter
   `proc main(argv: List[Str])` in a test script. The approved handbook already documents the
   spread form. Self-recovered.
3. Turn 11, `bash`: `check.argv-conversion` + `check.call-target: unsupported call target` —
   worker tried `print "host="(env.get_or(...)?)` with an inline call target and an interpolated
   `$argv[0]`. Self-recovered by binding values with `let` first.
4. Turn 13, `bash`: `check.effect-violation: `?` requires the `error` effect` — worker applied
   `?` without declaring `error`. The handbook covers the `error` effect and postfix `?`. Self-recovered.

No invalid `xsht api` discovery queries appear in the current packets; all `xsht api` calls
(`module:env`, `api:env.get_or`, `api:env.int`, `api:env.bool`, `api:fs.write`,
`method:Str.parse_int`, `search:parse_int`) returned `exact`/`matches` statuses.

## Timing evidence

No strict candidate/oracle timing gate exists; the eval contract declares timing diagnostic until a
stable envelope is established. Per-case candidate vs oracle wall times (ns) were all ~11–13 ms and
comparable (e.g. public 12,708,673 vs 11,296,200; hidden_defaults 10,997,307 vs 11,500,309;
hidden_malformed 12,802,374 vs 12,504,356). Candidate and oracle are both sub-20-ms, so process-launch
noise dominates any difference; run.json records `timing: pass`. No timing conclusion is drawn.

## Observation classification

- Candidate correctness — **reusable signal (pass)**. The submitted `envcfg.xsh` is 564 bytes and
  byte-exact on all ten cases; the two failure controls (hidden_malformed `CFG_PORT=abc`,
  hidden_empty_port `CFG_PORT=`) exit nonzero with a `result.propagate: parse-int: invalid integer`
  traceback and create no output file (candidate.9/.10 stderr), matching the oracle. Restrictions
  pass (`env.` referenced, no subprocess boundary, review.md complete with both headings, no template
  placeholders). This confirms the env/config surface (discoverable via `xsht api module:env`,
  `api:env.get_or`) and the Result/`?` validation-transfer lesson are practically usable — a
  north-star positive.
- 4 tool-error buckets — **ordinary worker friction / noise**. Each was a first-attempt syntax/effect
  miss that the worker corrected in-session; the approved handbook already documents every concept
  (spread `main`, `error` effect, `?` using it, `env.*` semantics). No durable handbook gap.
- `candidate_sha256 = e3b0c4…b855` (empty-string SHA) in `run.json` while the on-disk artifact is
  564 B — **harness mismatch (minor, non-blocking)**. The orchestrator's stdout-derived candidate hash
  is empty because this eval's deliverable is a written file, not stdout. It does not affect
  `correctness.all_exact` (file-vs-oracle comparison) or the pass; it is an informational metric
  field only. Not an XSH product defect; no ticket.
- `review.md` language proposal (a generic `Error(...)` constructor) — **noise**. The worker flagged
  no generic error constructor, but the approved handbook already prescribes propagating a deliberate
  validation failure from a typed conversion (the `"x".parse_int()?` idiom), and the worker used
  exactly that. This is a softer-ergonomics preference, not a reproducible failure.

## Handbook decision

Unchanged. The approved snapshot fully anticipates the friction observed; no reusable rule would
remove repeated agent steps. `03-eval/lineage/handbook-candidate.md` is a byte-identical copy of the
approved snapshot (SHA `97c5d804…`). No replay is required for a change this cycle.

## Tickets created

None. The only candidate product observation (empty `candidate_sha256` for a file-deliverable eval)
is a factory-harness metrics-field quirk, not a general XSH ergonomics or correctness problem, and it
does not affect the result; per policy it does not meet the bar for a standardized ticket.

## Post-merge decisions

The reconciler staged no merged tickets (`none`) for this cycle. The open-ticket snapshot lists
`task-envcfg-001` (Approved for the next org cycle; not merged) and `task-tags-003` (Deferred/Open),
neither of which is a post-merge acceptance assignment. No decision, acceptance, or revert is required.

## Next replay

No provisional handbook candidate was staged, so there is nothing to falsify on replay. Suggested
follow-up: replay `task-envcfg` against `runtime/handbook.md` after any future handbook edit touching
the `environment/configuration` or `effects-and-errors` sections to confirm the env/`?` lesson and the
non-strict-validator note still hold. If a factory-harness fix for the stdout-derived `candidate_sha256`
field on file-deliverable evals is ever implemented, rerun this eval to confirm the metrics field
reflects a real artifact hash.

## North-star impact

This eval directly advances the practical-glue mission: an agent with only the shared handbook and
`xsht api` discovered the `env` module, applied default-only-on-absence semantics, wrote a
byte-exact file with `fs.write`, and propagated a malformed-value failure through `?` to produce a
loud nonzero exit with no partial file — atop a clean stdout. The run demonstrates that the
`environment`/`Result` surface is discoverable and composable and that the Result/`?` lesson transfers
to a real config-validation boundary, reinforcing XSH's clear, explicit-boundary ethos (no silent
defaults, no hidden text conventions). No product change or handbook edit was required; the cycle
confirms the current handbook snapshot enables a correct, learnable, low-friction solution at a
single-trial $0.012 cost.
