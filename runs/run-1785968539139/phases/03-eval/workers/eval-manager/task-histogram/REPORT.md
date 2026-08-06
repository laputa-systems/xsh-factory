# Eval-manager report

## Result

fail

## Effort metrics

Trial 1 (`task-histogram-1`): 46 assistant turns, 53 tool calls (47 bash,
3 edit, 2 read, 1 write), 53 tool results, 2 tool errors, 32 thinking blocks,
session span 367,296 ms (~6.1 min; agent_wall_ms 368,590). One worker.

Worker friction in this trial was low and concentrated in two places: (1) a
pattern-matching probe used lowercase `ok(v)`/`err(e)` as constructors, which
are `Ok`/`Err` and correctly rejected; the worker pivoted to postfix `?`
propagation for validation; (2) an invalid `xsht api` discovery query
(`language.core.results` -> `expected KIND:VALUE`) that was immediately
corrected to `language:core.results`. Neither was a product or harness defect.
The decisive friction was a task-wording/literal-gate mismatch: the task told
the worker to "read the file through typed filesystem/text values," so the
worker reasonably chose `Path.lines()` (a typed streaming read) instead of the
literal `.read_text()`, which the evaluator's source-token restriction gate
requires. Correctness was unaffected (9/9 byte-exact); only the restriction
gate failed.

## Usage and cost

- input tokens: 61,473 (input cost $0.00553)
- output tokens: 15,816 (output cost $0.00285)
- cacheRead tokens: 852,672 (cacheRead cost $0.01535)
- cacheWrite tokens: 0 (cost $0)
- provider-reported total: 929,961; bucket total (61,473+15,816+852,672+0) =
  929,961 (match).
- reasoning tokens reported: 9,943 (provider-reported; a subset of output,
  not added to totals).
- cost total: $0.023727546 for the single worker; aggregate equals the same.
- budget $0.50, no budget breach, budget_state pass, unknown_costs 0.

## Thinking evidence

The provider reported 9,943 reasoning tokens across 32 thinking blocks. The
transcript (`container.stdout`) shows methodical, correct reasoning: the
worker queried `xsht api` for `parse_int`, `Path.read_text`, `Path.lines`,
`group-by`, `sort-by`, `fold`, `List`/`Map` methods, and path literals; it
built small probes to establish `Str.parse_int` accepts `+7`/`-3` and rejects
`12a`/`4.2`/empty, that `/` on two Ints is truncated integer division (7/2=3),
and that a conditional `"" .parse_int()?` arm is the available way to force a
typed validation failure under `[error]` (no `Error(...)` constructor,
`Err("str")` yields a Str-typed error incompatible with the `error` effect's
`Error`). Thinking then derived the group-by -> sort-by -> fold cumulative
pipeline and validated empty/blank/missing-file/sign cases. The reasoning is
grounded in the artifact that passed all nine cases.

## Tool-error findings

Structured `tool_errors` arrays list two nonzero bash results in worker
`task-histogram-1`:

1. Turn 9 — `err[check.pattern-constructor]: unknown constructor pattern`
   against `/tmp/t.xsh` for lines `ok(v) => v` and `err(e) => -999`. The
   worker guessed lowercase `ok`/`err` match constructors; XSH Result
   constructors are `Ok`/`Err`. Classified as discovery friction; the worker
   immediately abandoned pattern matching in favor of `?` propagation, so it
   caused no downstream loss.

2. Turn 38 — `check OK` followed by `Command exited with code 1`. This was a
   chained shell probe (`xsht check ...; ls -la /usr/share/hist-data.txt
   && ...`) where `ls` failed because `hist-data.txt` is not present in the
   container image; the `&&` chain then exited 1. Classified as ordinary
   probe noise, not a product or harness defect.

Additionally, one invalid `xsht api` discovery query appeared in the
transcript (`language.core.results` -> `expected KIND:VALUE`); it was not
flagged as a tool error in the structured array, but is recorded here for
completeness and was immediately corrected to `language:core.results`.
Current manager session has zero tool errors. All failed Pi tool results are
accounted for above.

## Timing evidence

Candidate and oracle both completed each case in ~11–13 ms (candidate
11.4–13.2 ms, oracle 11.7–13.3 ms) across all nine cases; exit statuses
matched on every case, including both failure controls (`hidden_bad_width`
both nonzero, `hidden_bad_value` both nonzero). This eval has no strict
candidate/oracle timing ratio gate; EVAL.md marks timing as diagnostic. Timing
`passed: true`.

## Observation classification

- **Correctness (pass):** all nine cases byte-exact and status-matched,
  including the two failure controls. Strong evidence that the XSH histogram
  pipeline (typed parse -> bin via Int division -> group-by -> sort-by ->
  fold cumulative) is composable and correct. Reusable signal for the eval's
  north-star hypothesis.
- **Restriction failure / worker friction (leading cause of fail):** the
  artifact used `file_path.lines()` instead of `.read_text()`/`fs.read_text`.
  The task prompt the worker saw ("typed filesystem/text values") is broader
  than the evaluator's literal `read_text` source-token gate. This is a
  generalizable lesson, not a defect: a semantically equivalent typed read
  satisfies the wording but can fail a literal-token gate. → handbook
  candidate (below), not a product ticket.
- **Tool-error noise (reusable? no):** the two structured tool errors were
  one bad constructor guess and one missing-fixture `ls`; both are
  discovery/probe noise, not repeated friction worth a handbook or ticket.
- **Provider health:** telemetry present (`provider_telemetry.events_path`),
  `retry_count 0`, `retry_errors []`, `provider_errors []`; no external
  latency signal. Latency attribution normal; no provider-switch action.
- **Not a product/tooling defect:** `Path.lines()` is valid, typed XSH and
  produced correct output; nothing about the language or checker misbehaved.

## Handbook decision

Provisional candidate staged at
`runs/run-1785968539139/phases/03-eval/lineage/handbook-candidate.md`. The
approved snapshot was used as the base and one general lesson was added:
when a task names a specific typed read API (e.g. `fs.read_text` /
`Path.read_text()`), call that exact method in the source, because an
evaluator's source-level restriction check may match literal API tokens and
reject a semantically equivalent typed read such as `Path.lines()`. This is a
concise, general rule that removes repeated agent friction: it applies to any
eval whose task wording describes a typed read loosely while its restriction
gate is literal. It is global (all evals share the one handbook) and must be
replayed before promotion.

## Tickets created

zero. No product/tooling defect was observed (XSH behaved correctly; the
failure was agent literal-token compliance against a documented gate). No
factory-target ticket (the gate is eval-owned, not factory infrastructure).

## Post-merge decisions

none. The reconciler found no merged tickets for this cycle (`none`), and the
candidate-ticket field is `not-reevaluation`, so there are no post-merge
acceptance assignments to adjudicate.

## Next replay

`task-histogram` at the current lineage (approved snapshot plus the staged
candidate) on the next cycle, requiring the replays to (a) read the file via
`fs.read_text`/`Path.read_text()` so the restriction gate passes, and (b)
remain byte-exact on all nine cases with both failure controls exiting
nonzero. This replay falsifies or confirms the literal-gate handbook lesson
and is the promotion gate for the candidate. Because the lesson is general,
one additional typed-file-read eval should also rerun before the candidate is
promoted to `runtime/handbook.md`.

## North-star impact

The run demonstrates that XSH expresses a canonical measurement-summary
composition (binned cumulative distribution) correctly and learnably: the
agent discovered typed parse, Int division, group-by, sort-by, and a
cumulative fold with the handbook and `xsht api`, and produced byte-exact
output on all nine cases including both failure controls. The remaining gap is
not language capability but agent compliance with a specific typed-read API
under a literal gate. The staged handbook lesson ("call the named read API
exactly; a literal source gate may reject an equivalent typed read") is a
small, durable ergonomics improvement that reduces repeated friction for every
future eval that couples a typed file read with a source-level restriction
check, keeping the factory's focus on learnable, explicit-boundary XSH rather
than task-specific workarounds.
