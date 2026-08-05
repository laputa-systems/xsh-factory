# Eval-manager report

## Result

pass

## Effort metrics

Single trial (`task-histogram-1`, `workers/eval-worker/task-histogram-1/`),
controller-run. Worker session: **48 assistant turns**, **62 tool calls**
(55 `bash`, 5 `read`, 2 `write`), **3 tool errors**, **45 thinking blocks**,
session span **503 525 ms** (~8.4 min). 45 of 48 stops were `toolUse`; the
final message stopped normally (`stop`). The agent required 1 user message and
completed `review.md` and `histogram.xsh`. Effort is consistent with the
task's North-star difficulty (two independent aggregations plus discovery), not
excessive exploration. Provider telemetry is present (`provider_telemetry.present
== true`); `retry_count 0`, `retry_errors []`, `provider_errors []`, so no
external-health signal. Latency attribution for the 8.4-min span is
agent-session effort (48 turns, 62 tool calls, 3 tool errors) with normal
provider health; the two 0-valued latency fields (`output_tokens_per_second`,
`response_elapsed_ms`) are not populated, so per-response throughput is
`unknown` but the classification is unaffected.

## Usage and cost

Provider: `openrouter/deepseek/deepseek-v4-flash-0731`; 1 worker.
- input tokens 49 576 (input cost \$0.00446184)
- output tokens 24 009 (output cost \$0.00432162)
- cache read tokens 1 164 352 (cache read cost \$0.020958336)
- cache write tokens 0
- provider-reported reasoning tokens 15 862 (a subset of output, reported this
  run)
- provider total tokens 1 237 937; bucket total equals provider total (no
  mismatch)
- aggregate cost **\$0.029741796**; budget \$0.50, **no budget failure**
- unknown costs 0; malformed lines 0.

Single-trial run; costs are per-trial == aggregate.

## Thinking evidence

45 thinking blocks, 15 862 provider-reported reasoning tokens. The thinking
transcript (session lines 25-109) shows the agent reasoning about how to reject
a parsed-but-domain-invalid input: it probed `xsht api summary` greps for
`assert|fail|panic|expect|require|guard|raise|abort|error`, queried
`language:core.error` (returned `status: missing`), `language:core.results`,
`api:record.require`, and attempted `assert argv.len() == 3`
(returned `unresolved proc command`). It repeatedly considered a
validation/require/assert mechanism and, finding none discoverable, settled on
the deterministic sentinel `("x"+bad).parse_int()?` to force a nonzero exit.
Separately, thinking lines 17-31 worked out that Int division is `/`, not `//`,
and that `matches` lives on the compiled `Regex` value. Thinking is consistent
with the artifacts and resolves the discovered API-surface facts; the provider
did report reasoning-token counts this run.

## Tool-error findings

All three structured tool errors are in `workers/eval-worker/task-histogram-1/report.json`
and are `bash`-tool shell errors from the worker's own command snippets (agent
friction, not XSH product defects):

1. **turn 8 / line 27** — `sh: syntax error: unterminated quoted string`; the
   worker's heredoc test of `parse_int` leniency ended with a missing closing
   quote (`echo "run rc=$?'`). Shell-quoting typo, recovered immediately.
2. **turn 16 / line 48** — `(no output)`, exit 1: `xsht api summary | grep -iE
   "assert|panic|unwrap|guard"` matched nothing. This is an API-discovery
   probe returning no hits (part of the deliberate-validation search); it is
   evidence, not a defect in `xsht`.
3. **turn 40 / line 98** — `stdout bytes for invalid: 0` then `sh: syntax
   error: bad substitution`: the worker used bash-specific `${PIPESTATUS[0]}`
   under the default `sh`, causing a substitution error while measuring
   stdout bytes for the negative-file fixture.

No invalid `xsht api` query appears in the manager session. The candidate
artifact and evaluator containers themselves produced zero tool errors.

## Timing evidence

Candidate vs oracle per case (ms), all byte-exact and nonzero on the two
failure controls (oracle exit 1/2, candidate exit 3):

- public 13.29 vs 12.65; hidden_width 12.44 vs 11.04; hidden_many 14.99 vs
  16.19; hidden_sparse 15.61 vs 11.08; hidden_single 14.03 vs 15.68;
  hidden_ties 12.78 vs 15.74; hidden_empty 15.54 vs 11.48; hidden_bad_width
  15.12 vs 11.74 (candidate 3, oracle 1); hidden_bad_value 10.88 vs 11.57
  (candidate 3, oracle 2).

Both sides finish in 10-16 ms process-launch noise; this eval has **no strict
candidate/oracle ratio gate** (EVAL.md "no strict candidate/oracle timing
gate"), so timing is diagnostic only. `timing.passed == true`.

## Observation classification

- **Correctness: pass** — 9/9 cases byte-exact (`all_exact: true`), including
  both failure controls exiting nonzero and printing nothing. Evaluator
  `run.json` classification `pass`.
- **Restrictions: pass** — `restrictions.passed == true`; source uses
  `fp"...".read_text()?`, `parse_int()` (typed integer parse), and a `sort-by`
  stage; no subprocess boundary; `review.md` preserves both headings with no
  template placeholders.
- **Worker friction (ordinary noise):** the 3 bash tool errors are quoting and
  `sh`-vs-bash substitution slips in the agent's own probes — transient, not a
  product or harness defect.
- **Reusable handbook guidance (this run):** (a) Int truncating division is
  `/`, and `//` is a parse error — the task's `/`-styled math notation and the
  `//` token collided, and the handbook only said `//` is not a comment; (b)
  regex matching lives on the compiled `Regex` value (`Regex.matches(text)`),
  not on Str (`method:Str.matches` led nowhere). Both are small, general,
  learnable facts evidenced in-session and safely teachable.
- **Product/tooling gap (recurring, already-owned):** the worker again resorted
  to a misleading sentinel `("x"+bad).parse_int()?` to raise a deliberate
  validation failure, because no fail/assert/require primitive was discoverable
  (`language:core.error` missing, `assert` unresolved) and `parse_int` is too
  lenient (accepts signs/hex). This is the same ergonomics gap as the
  CTO-closed `task-histogram-001`; the CTO closed it citing a merged
  `error.fail`, but this fresh replay shows a current agent could not discover
  or exercise any such primitive and fell back to the exact hack the handbook
  warns against. Classification: durable signal, not noise; handled as a
  CTO-reconciliation note (below) rather than a new engineer ticket to avoid
  re-raising a surface the CTO already rejected as a duplicate.
- **Protocol/harness/evaluator: pass, no failure.** Evaluator, image, and
  container boundary all behaved as designed. No harness mismatch or evaluator
  failure observed.

## Handbook decision

**Provisional candidate staged.** The review here is over the exact approved
snapshot `lineage/handbook-approved.md` (sha256
`3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b`). A concise
candidate was written to `lineage/handbook-candidate.md` adding two short,
general, learned facts:

1. Int integer/truncating division is `/`; the `//` token is a parse error
   (teach the correct operator so agents do not try `//`).
2. Regex testing is on the compiled `Regex` value via `regex.compile(...)?`
   then `matches(text)`; there is no `Str.matches`.

General lesson: name the Int division operator and the Regex receiver directly
so an agent does not rediscover them by trial and error. This is a one-trial
plan, so the candidate is **provisional only** — it is not promoted and is not
yet trusted. Replay scope: `task-histogram` plus at least one arithmetic/
regex-adjacent eval should re-confirm agents choose `/` and `Regex.matches`
without a check-time detour before CTO-promotion to `runtime/handbook.md`. The
deliberate-validation-failure gap is **not** encoded in the candidate because
the correct resolution (verify whether `error.fail` exists in the pinned image;
teach it if present, or own a product capability gap if absent) belongs to CTO
reconciliation, not to a speculative handbook recipe.

## Tickets created

None. No new engineer ticket this cycle. The recurrence of the
deliberate-validation-failure ergonomics gap is recorded as a CTO-reconciliation
finding (see Observation classification and Next replay) rather than a new
ticket, to respect the CTO's close of `task-histogram-001` (duplicate of merged
`error.fail`) and avoid a redundant checker/runtime/api path. The two handbook
facts above are handled as a handbook candidate, not a product ticket.

## Post-merge decisions

None. The reconciler found no merged tickets (`none`) for this run. Open
tickets `task-findexec-001` (Approved) and `task-histogram-003` (Open,
deferred — fold-with-print opaque diagnostic) are not post-merge acceptances
and were not dispatched.

## Next replay

Replay `task-histogram` on this same lineage
(`runs/run-1785962529677/phases/03-eval/lineage/handbook-candidate.md`)
against XSH commit `1cf4ad3d7ee5fde9b3160b11d8073cbd7ce5e7c4` (or the next
merged HEAD) to (a) confirm the two handbook facts hold and (b) re-check
correctness. Falsification check for the CTO: verify whether `error.fail` (the
capability cited in the `task-histogram-001` close, merged from
`task-colsum-001`) is present in the current pinned image; if it is absent, the
pinned image is behind the merged capability (product/image gap for CTO to
own); if it is present, add a handbook line teaching `error.fail(...)?` and
replay. A second numeric/range-validation eval should adopt the same deliberate-
failure idiom to confirm the lesson generalizes.

## North-star impact

This run passes a canonical ops-composition eval — read, typed-parse, integer-
bin, keyed count, sorted cumulative fold — byte-exact on all nine cases with no
subprocess escape, exercising practical systems-glue capability and composability
in the North-star sense. Two small learnable facts (Int `/` division; the Regex
receiver) were discovered by friction and are staged as a concise handbook
candidate that should make the exact same task cheaper for the next agent. The
recurring inability to express a deliberate validation failure (forcing a
misleading sentinel parse hack) is a real ergonomics gap for trustworthy,
learnable deliberate error handling; surfacing it for CTO reconciliation
advances the trust and learnability axis of the North star even though this
cycle correctly does not spend an engineer row on it.
