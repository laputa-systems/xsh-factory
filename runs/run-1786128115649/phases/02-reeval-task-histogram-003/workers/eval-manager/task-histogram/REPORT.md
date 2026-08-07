# Eval-manager report

## Result

pass

## Effort metrics

Trial 1 (single fresh trial): assistant turns 81, tool calls 81, tool
results 81, tool errors 2, session span 610,645 ms (~610 s). Tool mix: 78
bash, 2 read, 1 write. Provider telemetry present with retry_count 0,
provider_errors [] (no external-health events). Latency attribution therefore
`unknown` (no retry/latency signal); the high turn count is an
agent-efficiency signal driven by extensive bash probing (parse_int
leniency, match-syntax on Result, division operator) rather than provider
health. Phase report records `xsh_commit` 1477f47 but the xsh-build state
shows `build-id=857154dfe505f0d01053c1b5311f44422070eb34` built from the
candidate worktree; the binary under test was the candidate build (see
Timing evidence for detail).

## Usage and cost

Trial 1, one eval-worker: provider openrouter/deepseek/deepseek-v4-flash-0731.
Buckets: input 242,061, output 31,446, cacheRead 2,040,256, cacheWrite 0;
total_bucket_tokens and provider_total_tokens both 2,313,763.
reasoning token count reported = 23,160 (subset of output; provider reported
it). Dollars: cost_usd 0.064170378 total; budget 0.50, budget_state pass.
No budget breach, 0 malformed lines.

## Thinking evidence

71 thinking blocks recorded; the provider reported reasoning-token count
23,160 in the usage records. Thinking text (e.g. session lines 46, 162/164)
shows deliberate probing of parse_int acceptance, Result/match construction,
and final verification—qualitative evidence of an exploratory first pass
rather than a sign that the final solution was reached blindly.

## Tool-error findings

Two nonzero Pi tool results in the single current worker session (none in the
manager session):

1. `turn 13` (session line 31), tool bash: the agent wrote a /tmp/t.xsh probe
   using `match { Result.Ok(raw) => ... / Result.Err(e) => ... }` and got a
   cascade of `err[parse.expected-token] expected => in match arm` /
   `expected-terminator` / `expected-pattern` parse errors (exit 2). The agent
   recovered by abandoning the match-on-Result probe; this is a discovery
   friction on Result/match construction and overlaps the already-open
   ticket task-histogram-004 (Error/value construction), so it is classified
   reusable-but-dup, not a new ticket.
2. `turn 79` (session line 163), tool bash: final `ls -la histogram.xsh
   review.md tasks.md` listed a nonexistent `tasks.md`, producing exit 1 after
   CHECK/LINT/FMT all printed OK. Both required files exist. Ordinary noise
   (a one-character ls typo by the agent); no action.

There are no invalid `xsht api` discovery queries in this session's structured
tool errors.

## Timing evidence

Candidate/oracle timing per case (ms): public 13.04/11.26, hidden_width
11.30/11.23, hidden_many 11.21/11.62, hidden_sparse 12.94/11.41, hidden_single
13.30/12.31, hidden_ties 12.78/11.80, hidden_empty 12.82/11.76, hidden_bad_width
13.30/13.32, hidden_bad_value 13.20/11.45. All nine matches byte-exact; exit
codes match the oracle contract (bad_width candidate 3 vs oracle 1;
bad_value candidate 3 vs oracle 2 — both nonzero/nothing, as specified).
Timing is diagnostic only (EVAL: no strict ratio gate); timing_state pass.
No candidate/timing regression attributable to the candidate fix.

## Observation classification

- Correctness: pass — 9/9 byte-exact including both failure controls (reusable
  signal; the eval still reproduces the histogram composition on the candidate
  build).
- Restriction: pass — solution uses typed `fs.read_text`, `parse_int`,
  `group-by`/`sort-by`/`fold`; no subprocess boundary; review.md headings
  preserved (protocol `review_ok: true`). No restriction regression from the
  candidate.
- Worker friction (moderate): 81 turns / 610 s with heavy bash probing. Root
  cause is recoverable parse_int leniency and Result/match discovery pressure,
  already covered by open tickets task-histogram-005 (strict-decimal) and
  task-histogram-004 (Error construction) from the prior eval cycle; not a new
  signal.
- Tool errors: one Result/match discovery detour (dup of 004) and one `ls`
  typo (noise), as above.
- Harness/meta discrepancy: phase `report.json` `xsh_commit` field records the
  candidate base 1477f47 while the actual image this trial ran was built from
  the candidate commit 857154d (xsh-build.state build-id). This is a
  controller metadata field, not an eval or code failure; it does not change
  the outcome. Flagged for factory/CTO awareness, not an engineer ticket.
- Product/tooling: the candidate (task-histogram-003) is the topic of this
  re-eval; see Handbook/Tickets. The eval itself did not trigger the new
  fold-effect diagnostic because the agent used the safe pure-fold + each
  idiom, so criterion 1 is evidenced by the commit's native test, not by this
  replay (expected).

## Handbook decision

Unchanged — `lineage/handbook-candidate.md` is a byte-identical copy of the
approved snapshot. The run produced no new reusable handbook lesson beyond
observations already tracked by open tickets (strict-decimal parse, Error
construction, `//` division, record literals). The protected fold-then-each
idiom that the candidate fix defends is already consistent with the handbook's
stream guidance ("accumulator-style two-parameter fold/reduce blocks are not
the counting path"; bind terminals). No provisional candidate staged this run.

## Tickets created

Zero. All meaningful friction surfaced this run (parse_int leniency, Error
construction, Result/match) is already represented by open tickets
task-histogram-004/005/007/008 from prior cycles; no strong new reproducible
observation warrants a new ticket. The single product item under test is the
candidate task-histogram-003, handled below.

## Post-merge decisions

Reconciler reported merged tickets: `none`; no post-merge acceptance items.

Candidate (pre-merge validation, not reconciled): ticket task-histogram-003,
implementation commit 857154dfe505f0d01053c1b5311f44422070eb34
("diagnose effects in fold blocks"), engineer worktree
`~/.xsh-factory-worktrees/run-1786128115649/task-histogram-003`, base commit
1477f47. The fresh trial ran against the candidate build (build-id 857154d)
and passes 9/9 byte-exact with the pure fold-into-record + `each`-print idiom,
which `xsht check`/`lint`/`fmt` accept (criterion 2) and which keeps the eval
byte-exact on all nine cases (criterion 3). Criterion 1 (the actionable
`check.fold-effect` diagnostic naming the `each` alternative in place of
`full_ir_function_blocker`) is implemented in `src/sema/check/command.rs` and
`stream.rs` and covered by the added native test `checker_rejects_fold_output_with_actionable_diagnostic`
in `tests/sema.rs`; this replay cannot exercise it because the histogram task
does not call for printing inside a fold and the agent correctly used the safe
idiom. Decision: SUPPORT the candidate fix — no regression observed; the
protected idiom and eval contract remain byte-exact. Do not mark merged; this
remains a pre-merge recommendation for the reconciliation/CTO step.

## Next replay

Replay `task-histogram` on the merged lineage at the XSH commit that merges
857154d to (a) confirm the fold-with-print probe now yields the readable
`check.fold-effect` message instead of `full_ir_function_blocker`, and (b)
re-confirm the list-then-print solution stays 9/9 byte-exact. That falsifies
or supports the diagnostic change post-merge.

## North-star impact

This re-eval advances the trust and ergonomics axes. It confirms that the
candidate diagnostic change does not regress a canonical measurement-summary
composition: the binned cumulative distribution eval remains byte-exact at the
candidate build while the pure-fold + `each`-print idiom (the documented,
learnable alternative to a side-effecting fold) keeps passing check/lint. It
turns an opaque indexer-internal `full_ir_function_blocker` failure into an
actionable `check.fold-effect` message that names the `each` alternative—a
clear boundary, exactly the explicit-error ethos XSH defends—and adds a
regression test that will keep the diagnostic honest on later merges. No
product defect was introduced, and no new task-specific trick was rewarded;
the win is a clearer stream-reduction diagnostic, not a faster path to one
fixture.
