# Eval-manager report

## Result

pass

## Effort metrics

Single fresh trial (`task-envcfg-1`), XSH commit `434080dfe330cc3bb705bd8068d57a1015b7b218`.
Worker: 15 assistant turns (1 `stop`, 14 `toolUse`), 19 tool calls (14 bash, 3 read,
1 write, 1 edit), 19 tool results, 1 tool error. Session span 83.47 s (agent wall
84.99 s). Worker friction: low. The single tool error was a lint guidance warning on
turn 7, self-resolved in one subsequent edit; no recurring or blocking friction.

## Usage and cost

Single worker, model `openrouter/deepseek/deepseek-v4-flash-0731` (thinking level high).
Buckets: input 9747, output 5196, cacheRead 147456, cacheWrite 0;
provider total 162399 (bucket sum matches). Reasoning tokens reported: 3081.
Cost per provider: input $0.000877, output $0.000935, cacheRead $0.002654,
cacheWrite $0, total $0.004467. Budget $0.50, no breach. Aggregate = same as the one trial.

## Thinking evidence

11 thinking blocks; provider reported reasoning tokens (3081). The transcript shows
the worker verifying `env.int` semantics experimentally (empty -> error, absent ->
default, `007` -> 7) before choosing the validate-then-write design, then confirming
error output goes to stderr (stdout empty) on the failure controls. These are strong
qualitative signs the worker reasoned rather than guessed; the passing evaluator gate
is the objective confirmation. `thinking.md` is not present as a separate file; the
raw thinking lives in the canonical session JSONL.

## Tool-error findings

One nonzero Pi tool result (from worker report and phase `tool_errors`):
- turn 7, tool `bash`: `xsht lint envcfg.xsh` exited 1 with
  `warn[lint.path-constructor]: prefer p-string interpolation over Path(...)` on
  `let out = Path(argv[0])`. The worker replaced it with `fp"${argv[0]}"` (exactly
  what the handbook already teaches) and subsequent `xsht lint` passed. Not a product
  bug and not an invalid `xsht api` probe. Classified as self-resolving lint guidance.

No other nonzero results. No invalid `xsht api` discovery queries (all `module:`/
`api:`/`method:`/`search:` probes returned valid matches or the expected `missing`).

## Timing evidence

No strict candidate/oracle timing gate (both sides finish in milliseconds). Per-case
candidate/oracle wall times all 10–16 ms (e.g. public 11.3/12.3 ms, hidden_malformed
12.4/15.3 ms, hidden_empty_port 11.5/12.6 ms). Timing is diagnostic only; no envelope
problem. Do not conflate the 83.5 s agent session span with the ms-scale program run.

## Observation classification

- The `Path(...)` vs `fp"..."` lint warning: worker friction / ordinary lint guidance.
  Already documented in the approved handbook ("fp\"${expr}\" is the interpolated,
  lint-preferred form"); the worker resolved it in one turn. Not reusable-new signal,
  not a product defect.
- Use of `env.int` for validation plus `env.get_or` to preserve the raw port string
  (leading zeros): correct, but a routine use of documented APIs rather than a novel
  handbook lesson; not promoted.
- Correct byte-exact output on all ten cases incl. both failure controls (nonzero exit,
  no output file), restrictions (env referenced, no subprocess), protocol complete,
  review present with both headings and no placeholders: ordinary expected outcome.
- No genuine product/tooling defect, harness mismatch, or evaluator failure observed.
  The probe of `method:Bytes.from_text` returning `missing` was correctly re-discovered
  as `module.bytes.from_text`; the worker did not need it, so this is ordinary noise.

## Handbook decision

unchanged. The approved snapshot at `lineage/handbook-approved.md`
(sha256 `97c5d804...a40e83`) fully covered the task: env default-on-absence contract,
typed `env.int` validation with `?` for a loud nonzero exit, write-after-validation to
avoid partial files, `fp"..."` path interpolation. Copied unchanged to
`lineage/handbook-candidate.md` (same hash); no promotion proposed because the run
produced no reusable friction beyond what the handbook already states. Replay scope:
none required for this run.

## Tickets created

zero. The single reproducible observation (lint preferring `fp` over `Path(...)`) is
already in the handbook and caused one self-resolving turn; it does not meet the bar
for a product ticket and is not a general ergonomics/correctness defect.

## Post-merge decisions

None. The reconciler listed no merged ticket files for this cycle, so there are no
post-merge acceptance assignments to adjudicate. Open tickets `task-envcfg-001`
(Approved) and `task-tags-003` (Open) are not merged tickets and require no decision
here.

## Next replay

`task-envcfg` is a first live trial of this eval; the baseline passes on commit
`434080dfe330cc3bb705bd8068d57a1015b7b218` with the unchanged handbook lineage
(`lineage/handbook-approved.md` == `handbook-candidate.md`). Next replay: run
`task-envcfg` again on the same lineage (or a 2-trial plan) to confirm stability of
correctness and of the modest friction profile before trusting the baseline. Invoke
again whenever any future handbook or product change touches the `env`/`fs` surface.

## North-star impact

This eval closes a real capability gap (typed env reads with defaults + byte-exact
config-file write + malformed-value failure propagation) that no prior eval covered.
The agent reached a correct, lint-clean solution in 15 turns with one self-resolving
guidance step, confirming the handbook's env/Result/path lessons transfer to a genuine
config-validation boundary. No product defect or handbook gap surfaced, so the durable
takeaway is the validated baseline: XSH's environment/config surface is discoverable
and composable, which is the north-star outcome this trial was designed to measure.
