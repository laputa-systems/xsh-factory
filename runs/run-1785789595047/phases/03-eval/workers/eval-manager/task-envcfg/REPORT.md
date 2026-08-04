# Eval-manager report

## Result

pass

## Effort metrics

Trial 1 (task-envcfg-1), the only configured trial:
- assistant turns: 44
- tool calls: 57 (bash 49, read 4, write 2, edit 2); tool results 57
- tool errors: 4 (all non-blocking; see `## Tool-error findings`)
- session span: 362,036 ms (~6 min); agent wall 363,804 ms
- worker friction: all 4 tool errors were exploratory; three were already
  covered by the approved handbook, one was self-validation. The entry-signature
  mismatch (task-envcfg-007) cost the most idle exploration (turns ~36–58) but
  did not block completion. No budget breach ($0.024 vs $0.50).

## Usage and cost

Trial 1, provider `openrouter`, model `deepseek/deepseek-v4-flash-0731`:
- input tokens: 50,051; output tokens: 16,894; cache read: 906,816; cache
  write: 0; bucket total: 973,761; provider total: 973,761 (buckets reconcile).
- reasoning tokens: 9,218 (provider-reported; a subset of output, not added to
  totals).
- cost: input $0.00450, output $0.00304, cache read $0.01632, cache write $0,
  total $0.02387.
- Aggregate across the 1 trial: $0.02387, 973,761 bucket tokens.

## Thinking evidence

- thinking blocks: 35 across 44 assistant turns (high-thinking mode).
- Provider did report reasoning-token counts (9,218 tokens) for this model.
- Thinking transcript shows deliberate problem decomposition: reading the
  oracle semantics for `${VAR-default}` vs `${VAR-default}` absence behavior;
  verifying `env.get_or` absent-vs-empty contract; discovering the spread-`main`
  requirement only after multiple `runtime.compact-unsupported-main`
  reproductions; testing `parse_int` leniency (+5/-5/leading-space accepted);
  and confirming keep-stdout-clean by redirecting diagnostics to stderr.
- Thinking correlated with tool errors: the `compact-unsupported-main` thought
  chain (turns 36–58) drove the extra tool probes; the `len` on Str error was
  immediately corrected once the check hint listed `byte_len()`.

## Tool-error findings

All 4 nonzero tool results are from the structured `tool_errors` array in
`workers/eval-worker/task-envcfg-1/report.json` (no manager-session tool
errors; manager session not run this cycle):

1. Turn 9 — `err[check.display-conversion]: value cannot be displayed by print`
   while exploring how to display a Result/stream (`print $r`). Ordinary
   exploratory friction; handbook already warns "print rejects an unconsumed
   stream". Not a defect.
2. Turn 32 — `err[check.unknown-method]: unknown method 'len' on Str` on
   `leftover.len()` / `port.len()`. Covered verbatim by the approved handbook
   ("Str exposes byte_len()/count_chars()/count_bytes(); len() is a List
   method"). Ordinary friction; corrected in the next edit.
3. Turn 35 — `sh: bash: not found` (rc 127). The worker's throwaway `/tmp` test
   script invoked `bash`, which is absent from the BusyBox image. Image /
   environment friction; recovered by using `sh`. Not a product defect.
4. Turn 39 — the worker's own invalid-port self-test: expected nonzero exit
   (rc 3 via `parse-int: invalid integer 'x'`) and `ls /tmp/o.cfg` reporting no
   file. The "Command exited with code 1" is the diagnostic showing the
   required failure behavior (no output file on malformed port). Not a defect.

No `xsht api` discovery-query invalid forms appear in this run's structured
errors (that friction was already covered by prior ticket task-envcfg-004 and
was not re-triggered here).

## Timing evidence

Candidate/oracle wall times per case (all sub-15 ms, no strict ratio gate per
EVAL.md; timing is diagnostic):
- public: candidate 12.6 ms, oracle 11.4 ms.
- hidden_defaults: 11.6 / 11.0 ms; hidden_partial: 11.3 / 11.9 ms;
  hidden_empty: 11.1 / 1.5 ms; hidden_spaces: 11.1 / 13.0 ms;
  hidden_zero: 11.0 / 11.5 ms; hidden_utf8: 13.1 / 15.2 ms;
  hidden_debug_false: 13.5 / 11.9 ms; hidden_malformed: 14.2 / 11.7 ms;
  hidden_empty_port: 11.5 / 12.4 ms.
All same order of magnitude; no gate involved. The single 1.5 ms oracle outlier
(hidden_empty) is process-launch noise, not a contract signal. Both clocks
(candidate/oracle process timing) are separate from the ~6 min agent session.

## Observation classification

- Correctness: pass — all 10 cases byte-exact, including the two failure
  controls (nonzero exit, no output file). Evidence: `run.json`
  `correctness.*exact: true`.
- Restriction: pass — `env.` referenced, no forbidden subprocess boundary.
  Evidence: `run.json` `restrictions.passed: true` (env_referenced true,
  forbidden_operations true).
- Protocol: pass — artifact envcfg.xsh present, review.md complete with both
  required headings, no template placeholders. Evidence: `run.json`
  `protocol.artifact_present/review_ok: true`.
- Worker friction / reusable handbook guidance: the non-spread `main`
  signature passing `xsht check` but failing at runtime with
  `runtime.compact-unsupported-main` is a genuine, reproducible learnability
  gap (3+ reproductions, turns 36/43/55). Classified as both a product/tooling
  defect (see `## Tickets created`, task-envcfg-007) and a provisional handbook
  workaround (main must use the spread form).
- Reusable handbook guidance: boolean logic is spelled `and`/`or`/`not`, not
  `&&`/`&`/`||` (review.md; session turn 78 confirms `&&` is a parse error and
  `and` works). Not a product defect — XSH intentionally uses word operators;
  it is an undersold handbook fact that cost an agent a discovery cycle.
- Ordinary noise: `len` on Str (handbook already covers), print display
  conversion (handbook already covers), `bash: not found` (BusyBox image
  expectation), and the self-test rc=3/ls diagnostics.

## Handbook decision

Provisional candidate staged at
`runs/run-1785789595047/phases/03-eval/lineage/handbook-candidate.md`
(approved snapshot + two concise general additions, chosen so the change is a
short general rule rather than a recipe collection):
1. `Source and entry points` — main must use the spread form `(...argv:
   List[Str])`; the non-spread form passes `xsht check` but fails at runtime
   with `runtime.compact-unsupported-main`.
2. Boolean logic uses `and`/`or`/`not`; `&&`/`&`/`||` are parse errors.

Replay scope: this is a one-trial run, so the candidate is NOT yet trusted.
It must be replayed by task-tags and task-ecount (and a future task-envcfg) on
the shared handbook lineage before promotion to `runtime/handbook.md`. The two
edits are deliberately independent of the envcfg task outcome: the main-spread
and boolean-operator facts apply to any entry-point/conditional XSH program.

## Tickets created

- `tickets/task-envcfg-007.md` — `xsht check` accepts a non-spread `main`
  signature that the runtime rejects with `runtime.compact-unsupported-main`.
  Opened for the NEXT cycle (not dispatched this cycle). General correctness
  defect: checker and runtime disagree on valid entry-point shape. This is the
  single strong reproducible observation; all other observations are covered
  by the handbook or are noise.

## Post-merge decisions

None. The reconciler found no merged ticket files for this run's XSH commit
(`none`), so there are no post-merge acceptance assignments to evaluate. The
open task-envcfg tickets (002, 003, 004, 006) and other-eval open tickets are
pre-existing and outside this cycle's merged set.

## Next replay

Replay `task-envcfg` (and the shared candidates through `task-tags` /
`task-ecount`) against the handbook candidate when promoted, to confirm the
main-spread and `and`-operator notes remove the observed friction and that the
10 correctness cases still pass byte-for-byte. When task-envcfg-007 is merged,
run a post-merge replay asserting `xsht check` gives check-time feedback on the
spread-form requirement with no `runtime.compact-unsupported-main` run-time
round-trip.

## North-star impact

The run confirms the env/config surface (the newest eval) is discoverable and
composable through the handbook + `xsht api`: a fresh agent produced a
byte-exact, restriction-clean solution in ~6 minutes for under $0.03 with no
blocking errors. The durable signal is learnability: two general XSH facts the
handbook did not state (`main` spread form; `and`/`or` word operators) cost the
worker idle discovery cycles, and one checker/runtime disagreement
(task-envcfg-007) is a genuine correctness gap that undermines trust in
`xsht check` as a gate. Teaching those facts and fixing the check/runtime split
reduce repeated agent friction on every future entry-point task, advancing
ergonomics, correctness, and trust — the north-star goals — rather than a
task-specific recipe.
