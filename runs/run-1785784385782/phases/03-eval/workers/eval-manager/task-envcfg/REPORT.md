# Eval-manager report

## Result

fail

## Effort metrics

Single trial (Trial 1, `task-envcfg-1`), no budget breach, no session-limit
breach.

- Assistant turns: 51
- Tool calls: 55; tool results: 55
- Tool errors: 6 (all accounted for below)
- User messages: 1; stop reasons: 1 `stop`, 50 `toolUse`
- Session wall span: 244,605 ms (~4.1 min); agent wall (host posterity):
  246,194 ms
- Worker friction: substantial. The agent spent many turns discovering how to
  force a controlled nonzero exit without a generic `Error` constructor
  (`Result` methods, `parse_int` strictness, `Err(...)` typing, division by
  zero) before settling on a robust strict digit check with
  `(port + "x").parse_int()?`. It also burned several turns and one tool error
  discovering that `//` is not a comment marker and `#` is. See Thinking and
  Tool-error sections.

## Usage and cost

Trial 1 (provider: openrouter, model `deepseek/deepseek-v4-flash-0731`):

- Input tokens: 37,651; output: 17,223; cacheRead: 943,424; cacheWrite: 0
- Provider total tokens: 998,298; bucket total (`input+output+cacheRead+cacheWrite`):
  998,298 (consistent, no mismatch)
- Reasoning tokens (provider-reported): 10,777 (subset of output; not added to
  totals)
- Dollars: input $0.00338859, output $0.00310014, cacheRead $0.016981632,
  cacheWrite $0, total $0.023470362
- Budget: configured $0.50, used $0.02347
- Aggregate for the run equals trial 1 (single trial): $0.023470362, 998,298
  bucket tokens, 0 unknown-cost records (all fields reported).

## Thinking evidence

- Thinking blocks: 28; reasoning tokens 10,777 reported by the provider
  (deepseek-v4-flash did report reasoning-token counts).
- Findings from the thinking transcript: the agent correctly reasoned that
  `env.get_or` applies a default only on absence (keeping present-but-empty),
  that `env.int`/`env.bool` are convenience readers not strict digit
  validators, and that the oracle's `${CFG_PORT-8080}` rejects non-digits and
  empty while preserving the exact string (leading zeros). It then explored
  `Result`/`parse_int`/`Err` mechanics to trigger a nonzero exit without
  writing the file, and chose `Str.delete` for a strict digit check plus a
  guaranteed-failing `parse_int` for the failure branch. The qualitative
  thinking is strong and correct; the eventual source is correct (see
  classification).

## Tool-error findings

All six nonzero Pi tool results from the structured `tool_errors` arrays
(worker `task-envcfg-1`; no manager-session tool errors):

1. Turn 8, `bash`: `xsht api search:parse_int` returned `status: exact` but
   exited code 1. Tooling quirk (an exact `search:` hit still exits nonzero);
   minor noise, no impact on outcome.
2. Turn 27, `bash`: `xsht api summary | grep …` exited code 1 (grep no-match on
   the index dump). Discovery noise; the agent adjusted its query.
3. Turn 29, `bash`: `print x` raised
   `check.bare-print-ident` (must use `$x`), then `sh: syntax error: bad
   substitution` in the same probe; exit 2. Agent-side friction on
   print-dereference, already covered by the handbook's `$ident` rule.
4. Turn 36, `bash`: `envcfg.xsh` parse errors (`expected statement terminator`
   / `expected ')'`) because the agent used `//` comments instead of `#`; exit
   1. This is the root of the comment-syntax discovery gap (see Handbook
   decision).
5. Turn 38, `edit`: "Could not find the exact text in /work/envcfg.xsh" — the
   edit's `oldText` no longer matched because the file had just been rewritten
   with `#` comments. Ordinary edit mismatch; agent recovered by re-reading.
6. Turn 49, `edit`: "No changes made to /work/review.md; replacements produced
   identical content" — the agent submitted a no-op edit to review.md. No
   effect; review.md remained valid.

None of these errors is the cause of the eval failure. The cause is the
evaluator restriction scanner covered in Observation classification / Tickets.

## Timing evidence

No strict candidate/oracle ratio gate for this eval (both sides finish in
milliseconds). Per-case wall times (candidate vs oracle, ns): public 13.30 vs
13.47 ms, hidden_defaults 14.72 vs 12.33, hidden_partial 15.65 vs 12.74,
hidden_empty 15.25 vs 16.05, hidden_spaces 12.82 vs 14.06, hidden_zero 11.06 vs
12.25, hidden_utf8 13.63 vs 11.40, hidden_debug_false 12.48 vs 15.46,
hidden_malformed 11.30 vs 15.39, hidden_empty_port 15.78 vs 13.70. Timing is
diagnostic only; no gate implicated.

## Observation classification

- **Tooling / product defect (reproducible, general):** the eval evaluator's
  forbidden-subprocess restriction scanner uses naive substring checks
  (`source.contains("process.")`, `"spawn "`, `"run "`). The candidate's comment
  `# CFG_PORT must be a non-empty run of decimal digits…` contains `run `, so
  the scanner set `forbidden_operations=false` → `restriction_ok=false` →
  classification `restriction_failed`, even though the candidate is fully
  correct (all ten cases byte-exact, incl. both failure controls), references
  `env.`, uses no subprocess, and has a complete review. The recorded
  `candidate_sha256` (`e3b0c442…`) is the empty-file hash of the program's
  empty stdout (the deliverable is a file, not stdout), so it is not a
  recording error. The same naive check is replicated across six eval
  evaluators (task-envcfg via evaluate_legacy, task-tags, task-ecount,
  task-col2, task-dupcheck, task-jsonfilter). This is a deterministic false
  negative and the single strong reproducible observation → ticket
  `task-envcfg-006`.
- **Reusable handbook guidance (provisional):** comment syntax is
  undocumented; the agent discovered `#` works and `//` is a parse error only
  after a tool error. A short, general rule removes repeated agent friction
  for the whole agent fleet → staged as handbook candidate.
- **Worker friction (ordinary / already covered):** the many turns spent
  hunting for a way to force a nonzero exit (`Err`, `Result` methods,
  `parse_int`, div-by-zero) are largely already addressed by the handbook's
  "propagate an expected failure from a typed conversion … let postfix ?
  produce the nonzero exit" rule. The agent's final
  `(port + "x").parse_int()?` is a legitimate robust encoding; this is
  task-shaped exploration, not a new general signal.
- **Ordinary noise:** `xsht api search:…` exiting 1 on an exact hit; the two
  non-fatal `edit` mismatches; the grep no-match. No durable signal.

## Handbook decision

Provisional candidate staged at
`runs/run-1785784385782/phases/03-eval/lineage/handbook-candidate.md`
(= approved snapshot `fed89d59…` plus one added comment-syntax sentence:
"Comments start with `#` … `//` is not a comment marker and causes a parse
error"). General lesson: document XSH comment syntax so agents stop burning
turns and parse errors on `//`. Replay scope: any future XSH task session; it
is a candidate, not yet trusted — promote to `runtime/handbook.md` only after a
replay on another eval/cycle supports it.

## Tickets created

- `tickets/task-envcfg-006.md` (Open). General evaluator/tooling defect: forbidden-
  subprocess restriction scanner does naive substring matching and false-positives
  on comment text (`run `), wrongfully failing a fully correct candidate. Linked to
  this eval, this manager run, the executor worker evidence (`task-envcfg-1`),
  the handbook lineage, and XSH baseline `51b035a705f856d0bd3ead3cddf1557523d1d30e`.
  Merge-record placeholders left untouched.

## Post-merge decisions

None. The reconciler found no merged ticket files for this cycle; candidate
re-evaluation is `not-reevaluation`.

## Next replay

- Post-merge / falsification check: rerun `task-envcfg` trial 1 on a future
  cycle against the evaluator with the restriction-scanner fix, requiring the
  same correct candidate to classify `pass` and a deliberately subprocess-using
  negative control to still classify `restriction_failed`. Replay the
  comment-syntax handbook candidate on a different eval before promotion to
  `runtime/handbook.md`.

## North-star impact

This run isolated a false-negative evaluator defect: a clean, byte-exact,
restriction-compliant XSH solution was wrongfully rejected because a prose
comment contained the word "run". Accurate eval classification is a trust
requirement of the evidence loop — a wrong `restriction_failed` wastes a paid
worker cycle and can misroute handbook/ticket decisions. Fixing the scanner
once generalizes to all subprocess-forbidding evals. The staged comment-syntax
handbook candidate is a small learnability win that reduces agent parse-error
friction fleet-wide. Both moves advance practical, learnable, ergonomic, and
trustworthy XSH rather than rewarding a task-specific trick.
