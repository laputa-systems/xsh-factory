# Eval-manager report

## Result

pass

## Effort metrics

Trial 1 (`workers/eval-worker/task-envcfg-1/`):
- Assistant turns: 48 (47 `toolUse` stops, 1 final `stop`).
- Tool calls: 48; tool results: 48; tool errors: 6.
- Tool mix: bash 43, write 2, read 2, edit 1.
- Session span: 553,120 ms (~9.2 min); agent wall 554,405 ms; budget pass (0.5 USD cap).
- Worker friction: moderate — the worker iterated several compile/check cycles (turns 29/31/33) to nail the `error` effect declaration and a byte-exact validation idiom, then a long self-check harness run (turn 42) and a final verification (turn 47). All friction was resolved within budget; the artifact `envcfg.xsh` (489 B) was placed on the first correct attempt after those iterations.

Manager session: no tool calls, no tool errors.

## Usage and cost

Trial 1 provider-reported (`usage`):
- Input tokens 185,147; output 27,124; cacheRead 1,214,720; cacheWrite 0; bucket total 1,426,991 (= provider `totalTokens` 1,426,991, no mismatch).
- Reasoning tokens 21,538 (provider-reported subset of output 27,124).
- Cost: input $0.01666323 + output $0.00488232 + cacheRead $0.02186496 + cacheWrite $0 = $0.04341051 total (matches `cost_usd`). Unknown costs 0.
- Aggregate: 1 worker, total $0.0434, 0 budget failures.

Provider-reported reasoning-token count was available, so the thinking-evidence section also uses block count plus qualitative reading of `thinking.md`/session thinking blocks.

## Thinking evidence

- Thinking blocks: 37 (report `thinking_blocks`), thinking mode `high`, reasoning tokens 21,538.
- Findings grounded in the session: the worker's reasoning on turns 29/31 (see session lines 62, 67) explicitly weighed the `Err("...")` limitation (builds `Result[_, Str]`, cannot propagate through the `error` effect which carries `Error`) and considered a division-by-zero "hack" as a deliberate failure before settling on the sentinel `parse_int` idiom. This is qualitative evidence that the deliberate-error gap is a real agent burden, not task confusion.

## Tool-error findings

All 6 recorded `tool_errors` come from `workers/eval-worker/task-encfg-1` (all `isError:true` bash results). None reflect a defect in the final candidate; each classified:

1. Turn 6 — `xsht api language:effect.error` and `language:core.postfix-question` both returned `status: exact`; the shell exited 1 only because the trailing `xsht api summary | grep -E "method:Str"` matched no lines (grep exits 1 on no match). **Ordinary noise** (benign pipeline exit status; both API queries succeeded).
2. Turn 29 — `xsht check` rejected `Ok(())` ("expected expression"). Worker learned `Ok(())` is not a parseable expression and that a `Result`-returning proc needs a concrete payload. **Worker friction** (narrow parser/expression quirk; agent adapted).
3. Turn 31 — `let h = env.get_or(...)?` inside a `Str`-returning proc: "cannot propagate Error from function returning Str"; `Ok(1)` type mismatch. **Worker friction** (learning the `Result`/`Err` type family; already covered by handbook error-effect guidance and ticket task-envcfg-001 scope).
4. Turn 33 — `fs.write(...)?` flagged "`?` requires the `error` effect". **Worker friction** (effect-declaration lesson already documented in the approved handbook).
5. Turn 42 — the worker's own side-by-side shell harness hit BusyBox `printf` lacking the `%q` specifier and printed `sh: %q\n: invalid format`; the loop still confirmed candidate/oracle parity on the validity cases and nonzero/exit on malformed cases. **Ordinary noise / environment limitation** (harness only; final candidate passed the evaluator).
6. Turn 47 — final verification deliberately asserted nonzero exit (exit=3) and no output file (`ls: /tmp/oc: No such file or directory`); the nonzero exits from the failure-control check cause the bash wrapper to exit 1, so it is flagged as an error. This is the expected success check for the failure controls. **Ordinary noise** (false-positive error flag on an intentional nonzero-exit verification).

Manager session: no tool errors. The invalid `xsht api` discovery query (`language.effect.error`, turn 5, `isError:false`) is not in the `tool_errors` array because it did not fail the shell; it is nonetheless an API-discovery miss that the worker self-corrected on the next turn. No unresolved API question remains open.

## Timing evidence

20 timed runs (10 cases × candidate/oracle), all candidate and oracle wall times between ~11.1 ms and ~13.5 ms on linux/arm64. No strict candidate/oracle ratio gate exists for this eval (`EVAL.md` explicitly: timing is diagnostic until a stable envelope is established). The failure controls (`hidden_malformed`, `hidden_empty_port`) exit nonzero in ~11–13 ms on both sides. No timing anomaly.

## Observation classification

- **Correctness (pass, not noise):** evaluator `run.json` reports `all_exact:true` across all 10 cases including both failure controls; `restrictions.passed:true` (`env.` referenced, no forbidden subprocess); `protocol.pass` (artifact + `review.md` present and clean). This is a durable, reproducible correctness result.
- **Harness note (ordinary noise):** `outputs.candidate_sha256` equals `e3b0c442...` (SHA-256 of empty input). All 10 `candidate.N.stdout` files are 0 bytes, so the evaluator hashed the candidate's stdout (empty) rather than the written file; byte-for-byte correctness is established by the file-vs-oracle comparison (`all_exact`). Expected for a file-deliverable eval; not a product defect.
- **Worker friction (learning loop):** turns 29/31/33 — `Ok(())` non-parse, `Result[_,Str]` vs `error`-effect mismatch, and `?`-requires-`error`-effect. The first two stem from the missing deliberate-error/`Err` primitive (already scoped in approved ticket task-envcfg-001); the effect-declaration one is already covered by the handbook. Reusable at most as handbook reinforcement, not a new finding.
- **Worker friction (validation idiom):** the worker used the sentinel `port.delete("0123456789").parse_int()?` idiom to force the malformed-port nonzero exit — the exact workaround independently reproduced by the two prior `task-envcfg` workers that motivated ticket task-envcfg-001. Confirms the ticket's diagnosis; no new ticket is warranted.
- **Ordinary noise:** turns 6, 42, 47 (pipeline exit status / BusyBox `%q` / intentional-nonzero verification) as detailed above. Not reusable signal.

Reusable signal is therefore limited to confirmation of an already-approved product ticket; everything else is noise or already documented.

## Handbook decision

Unchanged. The approved handbook snapshot already contains the `Environment and configuration` section (`module:env`, `env.get_or` absence-not-empty semantics, "typed `env.int`/`env.bool` are convenience readers, not strict format validators"), the `?`/`error`-effect rule, and the "deliberate validation failure via typed conversion" guidance — all of which the worker needed and used successfully. The one genuine re-usable gap (missing deliberate-error primitive) is a product-language issue already owned by approved ticket task-envcfg-001; a handbook rule here would only restate the contradictory workaround the handbook already warns against. No new provisional handbook lesson meets the "short general rule, removes repeated friction" bar from a single passing trial. Lineage candidate copied from `handbook-approved.md` unchanged.

## Tickets created

Zero. The strong reproducible observation (missing deliberate-error/`Error` primitive that propagates through `?`) is already materialized as approved ticket `tickets/task-envcfg-001.md` (status `Approved.`, from the prior two-worker run); this trial independently reproduces its diagnosis but opening a duplicate would be noise. All other observations are noise or already-documented friction.

## Post-merge decisions

None. The reconciler reported merged ticket files: `none`. `tickets/task-envcfg-001.md` is `Approved.` but not yet implemented/merged at XSH commit `97edb51c621260d61a00034ea7ed0742adacbb80`, so there is no post-merge acceptance assignment for this cycle. Candidate re-evaluation is `not-reevaluation`; nothing to validate pre-merge. No revert proposed.

## Next replay

No handbook candidate was staged, so there is no pending handbook replay for `task-envcfg`. The next replay is the post-merge acceptance of ticket `task-envcfg-001`: once the deliberate-error primitive lands and is merged, replay `evals/task-envcfg` (and, per the ticket, `task-ecount`/`task-tags`) against the merged XSH commit, reapplying this run's `handbook-approved.md` lineage (sha `97c5d804...`), to confirm the sentinel idiom is replaced by the primitive and all cases still pass.

## North-star impact

The trial passes cleanly on the existing handbook, demonstrating that the env/config surface is discoverable and composable on the approved snapshot — the config-from-variables, byte-exact write, and loud-nonzero-failure pattern all transferred from the handbook plus `xsht api`. It independently re-confirms the single most important ergonomics gap: there is no first-class deliberate-error primitive that propagates through `?`, so agents must abuse an unrelated `parse_int` on a sentinel to reject malformed input — exactly the kind of opaque, contradiction-ridden workaround the north star says structured, learnable errors should eliminate. That finding is already owned by an approved ticket, so the correct next step is to implement and then re-accept it, which will make XSH's error story more trustworthy and more learnable for any config/argument validation boundary.
