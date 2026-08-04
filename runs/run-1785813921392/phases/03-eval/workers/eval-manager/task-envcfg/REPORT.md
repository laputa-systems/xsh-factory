# Eval-manager report

## Result

pass

## Effort metrics

Controller ran two fresh trials (`task-envcfg-1`, `task-envcfg-2`) against the
approved handbook snapshot (`lineage/handbook-approved.md`,
sha256 `97c5d804…4a40e83`) and XSH commit `5e0c679344458c4f39bf3f368a6d63a4c51aa01f`.
Both trials reached `classification: pass` with all ten cases byte-exact,
restrictions pass (`env_referenced`, `forbidden_operations`), and protocol pass
(artifact present, review ok).

- Trial 1: 21 assistant turns, 22 tool calls (17 bash, 3 read, 2 write), 2 tool
  errors, session span 183976 ms (agent wall 185363 ms). Budget pass.
- Trial 2: 38 assistant turns, 43 tool calls (36 bash, 3 edit, 2 read, 2 write),
  5 tool errors, session span 212460 ms (agent wall 213815 ms). Budget pass.
- Aggregate: 59 assistant turns, 65 tool calls, 7 tool errors, both within the
  $0.50 budget (no budget failures).

Worker friction is concentrated in trial 2, which explored scratch scripts
(`/tmp/t2.xsh`) and hit the `||`/`&&` boolean-operator parse rejection before
settling on word forms. Trial 1 reached a clean solution in fewer turns with the
same `and`/`or` word-form conditions. Both produced valid, env-referenced
`solution` programs; no short-task miss or stalled session.

## Usage and cost

Provider: `openrouter/deepseek/deepseek-v4-flash-0731` (thinking: high). Cost in USD.

- Trial 1: input 24,381 / output 8,596 / cacheRead 237,568 / cacheWrite 0
  (bucket total 270,545; provider total 270,545); reasoning 5,951; cost
  $0.008017794.
- Trial 2: input 73,119 / output 13,317 / cacheRead 527,040 / cacheWrite 0
  (bucket total 613,476; provider total 613,476); reasoning 7,540; cost
  $0.018464490.
- Aggregate: bucket/provider total 884,021 tokens; reasoning 13,491 (subset of
  output, not added to totals); cost $0.026482284 ($0.008017794 + $0.018464490),
  matching the phase `data.cost_usd`. No cache writes, no unknown costs.

## Thinking evidence

Provider-reported reasoning tokens were available for both workers: 5,951
(trial 1) and 7,540 (trial 2). Thinking-block counts: 18 (trial 1) and 26
(trial 2). The `||`/`&&` rejection and typed-reader semantic checks correlate
with the higher trial-2 exploration: the agent reasoned over scratch argv tests
and a `delete`/`byte_len` explicit validation strategy before committing to
`or`. Both reviews independently derived the key contract facts (`env.get_or`
absent-only default, `env.int`/`env.bool` not byte-exact validators) without
resorting to subprocess escapes, confirming the thinking mapped to correct typed
behavior. Provider-reported reasoning counts are treated as a subset of output;
no separate thinking token estimate was computed from the transcripts.

## Tool-error findings

All seven structured tool errors from the two current worker sessions are
accounted for (every nonzero Pi tool result is explained here; none unresolved):

Trial 1 (2 errors):
1. Turn 7 — `xsht api: invalid API query 'language.core.results'` and
   `'language.core.fallback'` (KIND:VALUE expected, exit 2). API-discovery
   friction: the agent guessed non-existent `language:core.*` rule ids for
   Result/fallback semantics. One-off; the agent recovered via `xsht api
   search`/source contract. Covered as a general discovery gap by merged ticket
   `task-envcfg-004`.
2. Turn 19 — runtime traceback `operation: result.propagate / parse-int:
   invalid integer '!'`, exit 3 for the malformed cases, followed by
   `ls /tmp/o.cfg: No such file or directory` (exit 1 shell status). This is the
   intended failure-control path: the candidate deliberately propagated a typed
   conversion failure so a bad `CFG_PORT` exits nonzero and writes no output
   file. NOT a defect; classified as expected behavior (the agent's own
   self-verification matched the oracle's failure controls).

Trial 2 (5 errors):
1. Turn 5 — bash `(no output)`, exit 1. Early scratch run before a valid script
   existed; ordinary worker friction / noise.
2. Turn 15 — `err[check.argv-conversion]` in scratch `/tmp/t2.xsh:3` when
   printing `$argv[0]` (interpolation cannot convert to one command word);
   `cat:/tmp/out2.cfg` no such file. Worker friction during argv experimentation.
3 & 4. Turn 18 (two entries) — `err[parse.unsupported-boolean-operator]`:
   unsupported `||` (use `or`), plus consequent `expected-token`/`expected-
   expression` cascades. Clear, self-correcting diagnostics; the agent recovered
   to `or`. This friction underpins the staged handbook learnability candidate
   and is covered as a parser-diagnostics fix by merged ticket `task-envcfg-003`.
5. Turn 28 — three invalid `xsht api` queries `api:module.applet.exit_code`,
   `exited_with`, `exited` (NAME.MEMBER expected, exit 2). API-discovery
   friction while probing for an exit-status surface — related to the
   explicit-failure gap already tracked in `task-envcfg-001`.

No manager-session tool errors were produced in this run (manager analysis only).
Conclusion: no new discovery/probing loop is warranted; every failure is
explained and either expected, one-off, or already tracked.

## Timing evidence

Both trials report per-case candidate/oracle wall times (ns). Both sides land in
the ~11–18 ms band on every case (e.g. trial 1 public candidate 11.05 ms,
oracle 11.38 ms; trial 2 hidden_utf8 candidate 13.28 ms, oracle 17.81 ms). The
eval contract declares no strict candidate/oracle timing gate for this task — it
is diagnostic only — so both `timing: pass`. No process-launch timing anomalies;
the two evaluation containers (candidate and oracle) are acceptably balanced.

## Observation classification

- `||`/`&&` boolean-operator parse friction (trial 2, turn 18; both reviews):
  reusable learnability signal and existing parser-diagnostics defect. Diagnostics
  are already clear and self-correcting. Classified as worker friction plus a
  small global handbook-learnability candidate. The parser side is already merged
  (`task-envcfg-003`); no new ticket.
- Invalid `xsht api` discovery queries (trial 1 turn 7; trial 2 turn 28): API-
  discovery friction / discovery gap. Already covered by merged ticket
  `task-envcfg-004`; not new. One-off probes, not repeated loops.
- Missing explicit `fail`/`abort` primitive carrying a chosen exit status (both
  reviews): reusable product ergonomics signal — validation failures are
  fabricated via `"x".parse_int()?` and always exit code 3, so a shell oracle's
  exact exit code cannot be matched. This is the strongest product observation,
  reproduced independently in both trial reviews, but it is ALREADY tracked by
  `task-envcfg-001` (Closed) and was acknowledged as acceptable in `EVAL.md` (the
  build intentionally has no generic `Error(...)`; typed-conversion propagation is
  the supported path). Not re-opened; no duplicate ticket.
- Typed readers `env.int`/`env.bool` not strict byte-exact validators (both
  reviews): by-design and already documented in the handbook (the reviews
  themselves note "The handbook already documents this"). Classified as ordinary
  expected behavior, not a gap.
- Expected malformed-case traceback (trial 1 turn 19): ordinary expected
  behavior — the failure control correctly exits nonzero and creates no file.
- `argv` scratch friction (trial 2 turns 5, 15): worker experimentation noise.
- All ten cases byte-exact in both trials: correctness signal, no noise.

## Handbook decision

Provisional candidate staged at
`runs/run-1785813921392/phases/03-eval/lineage/handbook-candidate.md`
(copied from the approved snapshot, plus one paragraph). General lesson: XSH
boolean conditions use the word forms `or`/`and`; the shell symbols `||`/`&&`
are unsupported. This is a short, general, learnability rule that applies to
every eval (this is a shell-glue language, so agents naturally reach for
`||`/`&&`), and `xsht check` already gives a self-correcting hint. Replay scope:
the candidate was NOT replayed by the controller — both trials in this
two-trial plan used the same approved snapshot, so no differentiation was
tested. The candidate is provisional and must be replayed on the shared lineage
(see Next replay) before promotion to `runtime/handbook.md`. This is a
documentation/learnability addition only; the compiler diagnostic fix is already
merged as `task-envcfg-003`, so no conflict.

## Tickets created

Zero. Every meaningful product observation from this run is already tracked by
an existing ticket (`task-envcfg-001` fail/abort primitive, `task-envcfg-003`
`||`/`&&` parser diagnostics, `task-envcfg-004` `xsht api` query friction), so a
new ticket would duplicate prior work. The one uncaptured item is the boolean-
operator learnability guidance, which is a handbook change (provisional
candidate), not a product ticket. No standardized linked ticket path created this
cycle.

## Post-merge decisions

None reconciled in this cycle. The reconciler returned no merged-ticket files for
this run (`none`), and the candidate re-evaluation field is `not-reevaluation`;
the controller completed exactly two fresh trials. Existing merged tickets
(`task-envcfg-003`, `task-envcfg-004`, `task-envcfg-007`) are outside this
cycle's staged acceptance set and were not re-dispatched. The two open tickets in
the phase snapshot (`task-ecount-008` Approved, `task-tags-003` Open) carry their
own eval/linkage and are not post-merge acceptance assignments for this eval.

## Next replay

Replay `eval: task-envcfg` against the shared handbook lineage with the
provisional boolean-operator candidate applied (`lineage/handbook-candidate.md`)
to test whether the `or`/`and` learnability note removes the trial-2 `||`/`&&`
friction (target: fewer parse-error turns and/or fewer turns to a correct
solution with unchanged correctness). Also expose the traded XSH commit
(`5e0c6793…`) for a post-merge/falsification check: confirm the merged
`task-envcfg-003` parser diagnostics and `task-envcfg-004` API-query behavior
observe the current commit. If the candidate's only effect is to shorten an
already-passing session without a correctness change, prefer keeping it minimal
and replay once more before promotion.

## North-star impact

This run validates a new practical systems-glue surface — reading typed config
from the process environment with defaults, writing a byte-exact file, and
propagating a malformed-value failure without a partial artifact — the gap this
eval was designed to fill (`env`/`fs` module usage, absent-only fallback, clean
stdout). Both agent trials reached a correct, clear, restriction-compliant
solution, demonstrating that the `env`/`fs` module surface is discoverable and
composable. The staged handbook candidate advances learnability (a concise,
general `or`/`and` rule) and ergonomics (removing the one recurring shell-habit
friction). No new product ticket is warranted because the deeper ergonomics
observations (explicit fail/abort primitive, `xsht api` discovery) are already
tracked and partly merged; this keeps factory effort focused on durable
handbook/product signal rather than duplicating prior work.
