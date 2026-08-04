# CTO briefing 03-eval

This is the deterministic first-pass briefing for the CTO. The structured
`report.json` files and raw Pi sessions remain the source of truth.

## Result

pass

## Operating context

- Mode: `eval`
- Request: `CYCLE-REQUEST.md`
- Structured report: `report.json`

## Phase outcomes

- `report.json`: result `pass`; report `report.json`
- `workers/eval-manager/task-envcfg/report.json`: result `pass`; report `workers/eval-manager/task-envcfg/report.json`
- `workers/eval-worker/task-envcfg-1/report.json`: result `pass`; report `workers/eval-worker/task-envcfg-1/report.json`
- `workers/eval-worker/task-envcfg-2/report.json`: result `pass`; report `workers/eval-worker/task-envcfg-2/report.json`


## Employee accounting

### Worker metrics

- `eval-manager/task-envcfg` (`eval-manager`): result `pass`; report `workers/eval-manager/task-envcfg/report.json`
  - Execution: `not recorded`; classification: `not recorded`
  - Turns: `16`; bucket tokens: `490260`; thinking blocks: `14`
  - Tool errors: `1`; cost: `0.017334`; budget: `0.150000`
- `eval-worker/task-envcfg-1` (`eval-worker`): result `pass`; report `workers/eval-worker/task-envcfg-1/report.json`
  - Execution: `pass`; classification: `pass`
  - Turns: `21`; bucket tokens: `270545`; thinking blocks: `18`
  - Tool errors: `2`; cost: `0.008018`; budget: `0.500000`
- `eval-worker/task-envcfg-2` (`eval-worker`): result `pass`; report `workers/eval-worker/task-envcfg-2/report.json`
  - Execution: `pass`; classification: `pass`
  - Turns: `38`; bucket tokens: `613476`; thinking blocks: `26`
  - Tool errors: `5`; cost: `0.018464`; budget: `0.500000`


### Nonzero tool results

- `eval-manager/task-envcfg`, turn `15`, tool `bash`: diff --git a/handbook-approved.md b/handbook-candidate.md
index ecbb40d..46c7a57 100644
--- a/handbook-approved.md
+++ b/handbook-candidate.md
@@ -60,6 +60,13 @@ comment marker and causes a parse error, so use `#` for inline notes:
     # CFG_PORT must be a run of decimal digits.
     let digits = port.delete("0123456789")
 
+Boolean conditions compose with the word forms `or` and `and`; the shell-style
+symbols `||` and `&&` are not supported and are rejected with guidance. Agents
+coming from shell glue often reach for `||`/`&&` first, so write conditions with
+words:
+
+    if port.byte_len() == 0 or non_digits.byte_len() > 0 { ... }
+
 Values have explicit types. Common types include Str, Int, Bool, Path,
 List[T], Map[T], and Result[T]. Records have named fields, accessed with dot
 syntax:
62a63,69
> Boolean conditions compose with the word forms `or` and `and`; the shell-style
> symbols `||` and `&&` are not supported and are rejected with guidance. Agents
> coming from shell glue often reach for `||`/`&&` first, so write conditions with
> words:
> 
>     if port.byte_len() == 0 or non_digits.byte_len() > 0 { ... }
> 


Command exited with code 1
  - Structured report: `workers/eval-manager/task-envcfg/report.json`
- `eval-worker/task-envcfg-1`, turn `7`, tool `bash`: xsht api: invalid API query 'language.core.results'; expected KIND:VALUE
===
xsht api: invalid API query 'language.core.fallback'; expected KIND:VALUE


Command exited with code 2
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`
- `eval-worker/task-envcfg-1`, turn `19`, tool `bash`: OK
runtime traceback
executable: /usr/local/bin/xsh
operation: result.propagate
error: parse-int: invalid integer `!`
call path:
  1. proc main at envcfg.xsh:1:1-1:1
minus5 exit:3 (expect nonzero)
ls: /tmp/o.cfg: No such file or directory
runtime traceback
executable: /usr/local/bin/xsh
operation: result.propagate
error: parse-int: invalid integer `!`
call path:
  1. proc main at envcfg.xsh:1:1-1:1
hex exit:3 (expect nonzero)
ls: /tmp/o.cfg: No such file or directory


Command exited with code 1
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`
- `eval-worker/task-envcfg-2`, turn `5`, tool `bash`: (no output)

Command exited with code 1
  - Structured report: `workers/eval-worker/task-envcfg-2/report.json`
- `eval-worker/task-envcfg-2`, turn `15`, tool `bash`: err[check.argv-conversion]: interpolation cannot convert to one command word
  /tmp/t2.xsh:3:17
    print "first" $argv[0]
                  ^^^^^ interpolation cannot convert to one command word
exit=2
--- file ---
cat: can't open '/tmp/out2.cfg': No such file or directory
ls: /tmp/out2.cfg: No such file or directory


Command exited with code 1
  - Structured report: `workers/eval-worker/task-envcfg-2/report.json`
- `eval-worker/task-envcfg-2`, turn `18`, tool `bash`: err[parse.unsupported-boolean-operator]: unsupported operator '||': XSH boolean operators are the word forms 'or'
  envcfg.xsh:8:27
    if port.byte_len() == 0 || non_digits.byte_len() > 0 {
                            ^^ use 'or' instead of '||'

err[parse.expected-token]: expected `{` to start block
  envcfg.xsh:8:27
    if port.byte_len() == 0 || non_digits.byte_len() > 0 {
                            ^ expected `{` to start block

err[parse.expected-expression]: expected expression
  envcfg.xsh:16:1
  }
  ^ expected expression


Command exited with code 2
  - Structured report: `workers/eval-worker/task-envcfg-2/report.json`
- `eval-worker/task-envcfg-2`, turn `18`, tool `bash`: err[parse.unsupported-boolean-operator]: unsupported operator '||': XSH boolean operators are the word forms 'or'
  envcfg.xsh:8:27
    if port.byte_len() == 0 || non_digits.byte_len() > 0 {
                            ^^ use 'or' instead of '||'

err[parse.unsupported-boolean-operator]: unsupported operator '||': XSH boolean operators are the word forms 'or'
  envcfg.xsh:8:27
    if port.byte_len() == 0 || non_digits.byte_len() > 0 {
                            ^^ use 'or' instead of '||'

err[parse.expected-token]: expected `{` to start block
  envcfg.xsh:8:27
    if port.byte_len() == 0 || non_digits.byte_len() > 0 {
                            ^ expected `{` to start block

err[parse.expected-expression]: expected expression
  envcfg.xsh:16:1
  }
  ^ expected expression


Command exited with code 2
  - Structured report: `workers/eval-worker/task-envcfg-2/report.json`
- `eval-worker/task-envcfg-2`, turn `28`, tool `bash`: xsht api: invalid API query 'api:module.applet.exit_code'; expected NAME.MEMBER
===
xsht api: invalid API query 'api:module.applet.exited_with'; expected NAME.MEMBER
===
xsht api: invalid API query 'api:module.applet.exited'; expected NAME.MEMBER


Command exited with code 2
  - Structured report: `workers/eval-worker/task-envcfg-2/report.json`


### Cycle total

- Workers: `3`
- Assistant turns: `75`
- Bucket tokens: `1374281`
- Cost (USD): `0.043816`
- Nonzero tool results: `8`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-manager/task-envcfg

- Role: `eval-manager`
- Result: `pass`
- Report: `workers/eval-manager/task-envcfg/REPORT.md`

#### Efficiency and evidence

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

#### Handbook or proposal decision

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

#### Ticket or product decision

Zero. Every meaningful product observation from this run is already tracked by
an existing ticket (`task-envcfg-001` fail/abort primitive, `task-envcfg-003`
`||`/`&&` parser diagnostics, `task-envcfg-004` `xsht api` query friction), so a
new ticket would duplicate prior work. The one uncaptured item is the boolean-
operator learnability guidance, which is a handbook change (provisional
candidate), not a product ticket. No standardized linked ticket path created this
cycle.

#### Next action

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

#### North-star impact

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



## Eval proposal review

No CTO eval review was recorded.

## Handbook lineage

Checked-in `runtime/handbook.md`: `97c5d804c42c7742c9edfea4480163828d864279391d391df77aa60ee4a40e83`
- approved snapshot: `lineage/handbook-approved.md` sha256 `97c5d804c42c7742c9edfea4480163828d864279391d391df77aa60ee4a40e83` — promoted by CTO ledger; matches checked-in handbook
- candidate: `lineage/handbook-candidate.md` sha256 `36c2f9f168239719b87f05204cd580568d70a30565f557d973f812c7d621b6d3` — DIFFERS; CTO promotion or rejection decision required


## Historical handbook backlog

Historical candidates: 42; differing: 32; ledger-dispositioned: 31; unresolved: 1.
Unresolved candidates requiring one explicit CTO decision:
- `runs/run-1785813921392/phases/03-eval/lineage/handbook-candidate.md` sha256 `36c2f9f168239719b87f05204cd580568d70a30565f557d973f812c7d621b6d3`


## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
