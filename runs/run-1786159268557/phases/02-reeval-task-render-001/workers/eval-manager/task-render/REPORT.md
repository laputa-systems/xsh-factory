# Eval-manager report

## Result

pass

## Effort metrics

Trial 1 (candidate re-eval of `task-render-001`, worktree commit `461fe36`):

- assistant_turns: 37
- tool_calls: 43 (bash 31, edit 6, read 4, write 2)
- tool_results: 43
- tool_errors: 6 (all resolved during the session; map construction had zero failed probes)
- thinking_blocks: 28
- session_span_ms: 198173 (~198 s); agent_wall_ms: 199403
- worker friction: six recoverable tool errors, none touching the Map-construction path the ticket targets.

## Usage and cost

Trial 1 (worker `task-render-1`):

- input: 30,532 tokens; output: 14,593; cache_read: 576,832; cache_write: 0; bucket total: 621,957.
- reasoning_tokens: 8,786 (provider-reported; a subset of output).
- cost: $0.015757596 (input $0.00274788, output $0.00262674, cache_read $0.010382976, cache_write $0). budget_usd: 0.5; no budget failures.
- Aggregate across the run (phase `report.json`): assistant_turns 37, tool_errors 6, cost $0.015757596, bucket tokens 621,957, workers 1. No malformed lines or unknown costs.

## Thinking evidence

- 28 thinking blocks; reasoning_tokens 8,786 reported by the provider (a subset of output, not additional).
- The thinking transcript shows the worker planned the program correctly before first write, decided `map.empty()` was the constructor, and only probed list-indexing / loop syntax (turns 25–29). It iterated on the boolean-operator and trailing-newline match rather than on Map construction.
- `thinking.md` is not materialized separately; findings grounded in the canonical `session.jsonl.bz2` assistant thinking blocks.

## Tool-error findings

Six nonzero Pi tool results in the current worker session (`workers/eval-worker/task-render-1/report.json`); none in the manager session:

1. turn: invalid `xsht api language.cli.xsh-SCRIPT` — unquoted query, shell-expanded; `expected KIND:VALUE`. Worker friction; re-run quoted at the next turn and dropped. CLI-discovery query format, not the ticket's target.
2. `Path(argv.get(0))` type mismatch (three receivers) — `argv.get` returns `Result[Str, Error]`, so the direct cast fails. Worker friction / agent error; resolved with the fallback overload then the lint-preferred `fp"${argv.get(i, "")}"`.
3. `lint.path-constructor` warnings for `Path(...)` — lint guidance to prefer `fp` interpolation. Worker friction; compliant fix applied.
4. Missing-TEMPLATE/VALUES runtime traceback plus `ls out_missing*.txt` failure — this is the expected-behavior control (exit nonzero, no OUTPUT created). The nonzero exit is the deliberate success signal; the `ls` failure is the `ls`-on-absent-file false positive, not a defect.
5. `parse.unsupported-boolean-operator '&&'` — `&&` rejected; XSH uses word forms. Worker friction; fixed to `and`.
6. `parse.expected-expression` on `and not ...` — `not` is not a boolean operator (negation is prefix `!`). Worker friction; fixed to `and !`.

Manager session: `None.` (no manager tool errors in this run).

## Timing evidence

- This eval has no strict candidate/oracle timing gate; timing is diagnostic only.
- Worker session span 198 s for 37 turns. `run.json` does not record candidate/oracle wall times; the trailing-newline logic was verified against the awk oracle across public and hidden fixtures with a byte-exact final match.
- Provider telemetry: events file absent, but the worker report records `retry_count 0`, `retry_errors []`, `provider_errors []`. No provider retries or errors; latency attribution is normal/unknown-neutral, and the 198 s span is consistent with the turn/tool count rather than an efficiency regression.

## Observation classification

- **Product/tooling change validated (the ticket's target):** `xsht api method:Map` returns a `method.Map.constructor` reference disclosing `map.empty()`, and the summary appends `Map constructors: module.map.empty`. The worker built the map with `map.empty()` on the first construction attempt with zero failed probes — direct, reusable evidence for the ticket's acceptance criteria (previous baseline required five probes and a `grep summary | map.empty` detour).
- **Worker friction (recoverable, not product defects):** invalid `xsht api` query form, `Path(argv.get(...))` Result cast, `&&`/`not` boolean-operator guesses. These were resolved within the session; they are ordinary short-task iteration, though the boolean-operator rule is a genuinely reusable lesson (see handbook candidate).
- **Expected-behavior confirmation (not an error):** the missing-file runtime traceback corresponds to the required "exit nonzero, create no OUTPUT" control.
- **Noise:** none beyond the above; no evaluator, harness, or image mismatch observed.

## Handbook decision

Provisional candidate staged at
`runs/run-1786159268557/phases/02-reeval-task-render-001/lineage/handbook-candidate.md`
(approved snapshot copied, one concise `## Control flow` addition). General lesson: XSH boolean operators are the word forms `and`/`or`, `&&`/`||` are rejected, and negation is the prefix `!` (the word `not` fails to parse); list/argv indexing is a Result-returning method, so read CLI args with the fallback overload `argv.get(i, "")` and prefer the `fp"${...}"` interpolation for dynamic paths.

This is global (any eval writing a conditional or reading argv), evidence-backed by two of this session's six tool errors and by the worker's own `review.md`, and needs replay (and CTO review) before promotion to `runtime/handbook.md`. The Map-construction lesson itself is intentionally NOT duplicated into the handbook: it is now discoverable through `xsht api method:Map` once the candidate ticket merges, keeping the handbook minimal and avoiding a task-recipe.

## Tickets created

None created this cycle. The staged `handbook-candidate.md` is global guidance pending replay, and the boolean-operator friction is not strong/reproducible enough across evals yet to warrant a product ticket.

## Post-merge decisions

No reconciled merged tickets this cycle (reconciler found none; `task-render-001` is a pre-merge candidate, not a merged ticket).

Candidate re-evaluation decision for `task-render-001` (pre-merge validation, not yet main):
- Ticket: `task-render-001`
- Candidate XSH commit: `461fe36bfd0d1ca5670777e2ea1531f902e88558` ("docs: index map constructor from Map type"), base `ac37f813...`
- Decision: **ACCEPT** — the executor evidence supports the proposed fix.
- Evidence: live `xsht api method:Map` output in the fresh trial discloses `map.empty()` as a `method.Map.constructor` ("This constructor is indexed from the Map type so type-first discovery finds it"); summary appends `Map constructors: module.map.empty`; the worker wrote `var values = map.empty()` on the first construction attempt with zero Map-construction probes, and the final `render.xsh` passed `check`/`fmt`/`lint` and matched the oracle byte-for-byte (evaluator `run.json`: `correctness.exact: true`, `restrictions.passed: true`, `protocol.review_ok: true`).
- Acceptance-criteria check: (1) summary discloses `module.map.empty` — implemented via `append_receiver_references` + test `api_map_summary_discloses_its_constructor`; (2) `method:Map.*` finds `map.empty()` without probing the map module — confirmed live and tested (`api_map_receiver_query_discloses_its_constructor`); (3) map built on first attempt with clean `check`/`fmt`/`lint` — confirmed; (4) behavioral contract unchanged — only `xsh-registry`/`xsht api` docs-plus-tests, no runtime/type semantics changed (test asserts `{}` is an empty Record).
- Revert proposal: none.

## Next replay

After the CTO merges `task-render-001` onto main, replay `task-render` (this same lineage) plus one independent map-building eval (e.g. `task-dupcheck`) and falsification check: the worker must build the Map on the first construction attempt via `xsht api method:Map`/summary with clean `check`/`fmt`/`lint` and a byte-exact oracle match for both evals. Separately, replay the provisional `## Control flow` handbook candidate on another conditional-heavy eval before promoting it to `runtime/handbook.md`.

## North-star impact

This run validates a focused ergonomics/learnability fix for a core systems-glue idiom — folding parsed text into a typed `Map` — by showing that a type-first agent can now discover `map.empty()` from the `Map` type itself and build the map on the first attempt, eliminating the five-probe detour the original session required. That is a concrete step toward making XSH's map boundary explicitly discoverable rather than assumed, in line with the north-star mission of reducing guesses and repeated discovery when writing real XSH. The run also surfaced a concise, generalizable control-flow rule (word-form `and`/`or`, prefix `!`) as a provisional handbook candidate, strengthening learnability without adding task-specific recipes.
