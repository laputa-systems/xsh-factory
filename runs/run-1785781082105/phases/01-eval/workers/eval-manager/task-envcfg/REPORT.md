# Eval-manager report

## Result

pass

## Effort metrics

Trial 1 (only trial; controller configured `1`). Worker `task-envcfg-1`:
95 assistant turns, 96 tool calls (87 bash, 3 edit, 3 read, 3 write), 9 tool
errors, 74 thinking blocks, 1 user message, session span 557,181 ms (~9.3 min).
All 10 cases (public + 6 hidden value cases + `hidden_malformed` +
`hidden_empty_port` failure controls) passed byte-for-byte; classification,
protocol, restrictions, and agent state all `pass`. The candidate produced no
stdout (deliverable is a file) and exited nonzero with no file on the two
failure controls, matching the oracle. Worker friction was concentrated in
(1) discovering the `env` module and `fs.write`, (2) a strict decimal check
that `env.int`'s permissive reader could not satisfy, (3) repeatedly hitting
the compact-IR `full_ir_function_blocker` on `let`-containing stream closures
before switching to single-expression closures, and (4) a barred
error-construction path that forced a fabricated `parse_int` failure to exit
nonzero.

## Usage and cost

Provider `openrouter`, model `deepseek/deepseek-v4-flash-0731`, thinking `high`.
Trial 1: input 294,301, output 32,383, cacheRead 2,441,088, cacheWrite 0,
bucket total 2,767,772; provider-reported total 2,767,772 (match). Reasoning
tokens 19,152 (subset of output). Cost input $0.02649, output $0.00583,
cacheRead $0.04394, total $0.076256 within the $0.50 budget (no breach).
No malformed usage lines; 1 worker; aggregate cost $0.076256.

## Thinking evidence

74 thinking blocks in the worker session; provider reported 19,152 reasoning
tokens. Thinking correlates tightly with the decisive corrections: blocks
~24–33 isolate that `env.int`/`parse_int` are permissive (accept `007`, `-1`,
`+1`, leading space) and must not gate a strict decimal contract; blocks ~48–64
bisect the `full_ir_function_blocker` to multi-statement closures with a `let`
bisecting to the single-expression workaround; blocks ~84–105 hunt for an
error constructor after `Error(kind:...)` was reported removed and
`FsError.NotFound` was unresolved, settling on a deliberately failing
`parse_int`. The reasoning is present and mostly correct; the worker's only
misstep was the repeated closure-with-`let` attempts until the exact trigger
was found.

## Tool-error findings

All 9 structured tool errors are in worker `task-envcfg-1/report.json`
(session `session.jsonl.bz2`). They account for every failed Pi tool result; the
manager session has zero tool errors.

1. turn 12 — `parse.expected-pattern` on a `match`/`Ok(i)` probe (match-pattern
   syntax discovery).
2. turn 29 — bash command exited 1 with no output (probe of env read).
3. turn 38 — `check.standard-module-shadow` (`path` param shadows module) plus
   `?`-requires-`error`-effect; worker's first `fs.write` probe.
4. turn 67 — `parse.expected-terminator`/`expected-expression` on `b >= 48
   && b <= 57` in a closure.
5. turn 68 — `check.unknown-method`: `is_digits` is not defined on `Str`
   (guessed method name).
6. turn 69 — `compact.indexed-build`: `full_ir_function_blocker` on a stream
   closure containing a `let` (dig3).
7. turn 70 — `compact.indexed-build`: `full_ir_function_blocker` on the same
   pattern inside `proc main` (dig4) — same trigger as #6.
8. turn 82 — `bash: not found` (BusyBox image has no bash; only `sh`).
9. turn 85 — `sh: syntax error: unexpected "("` (worker's own POSIX-shell test
   harness typo).

Items #6 and #7 are the new reproducible defect (ticket `task-envcfg-005`);
#5 is an API-discovery miss; #8 and #9 are ordinary image/worker noise; the
rest are normal development-loop checks.

## Timing evidence

Candidate and oracle each run in milliseconds; there is no strict
candidate/oracle ratio gate (EVAL.md and run.json both treat timing as
diagnostic). Per-case candidate wall ns range 12.2–16.2 ms and oracle 12.1–15.7
ms with no consistent winner; the failure-control exits match the oracle.
Timing is not a gate for this eval.

## Observation classification

- Product/tooling defect (new): stream-stage closures containing a `let`
  binding fail in the compact runtime with the opaque
  `full_ir_function_blocker`, while the single-expression form compiles.
  Reproduced twice in one session and confirmed reproducible; the fix belongs
  in the same compact-IR area as `task-ecount-002` but is a distinct trigger
  (closure-body statements, not positional optional args). Opened
  `task-envcfg-005`.
- Product/tooling defect (already tracked): no discoverable way to construct a
  generic `Error` or force a controlled nonzero exit; worker again resorted to
  a fabricated `parse_int` failure. Reproduced in this run → re-confirms open
  `task-envcfg-001`, no new ticket.
- Product/tooling defect (already tracked): `xsht api` has no per-type index;
  bare receiver queries rejected (task-envcfg-004). Also the `path` module
  shadowing (task-ecount/task-envcfg-002 area) is a normal-name collision the
  worker avoided by renaming the parameter.
- Reusable handbook guidance: the approved handbook has no `env` module
  coverage and no note that `env.int`/`env.bool` are convenience readers, not
  strict format validators. This cost the worker many discovery turns and a
  manual digit check. General and non-defect-dependent → staged as the
  handbook candidate.
- Ordinary noise: `bash: not found` (BusyBox-only image; worker recovered with
  `sh`) and the own-harness `sh` syntax typo. No ticket, no handbook change.
- Evaluator/harness: `candidate_sha256 = e3b0c442…` is the SHA-256 of the
  empty `candidate.1.stdout` (the deliverable is a file, so stdout is empty) —
  expected for a file-deliverable eval, not a defect. Correctness/all-exact
  gates passed against the written file.

## Handbook decision

Provisional candidate staged at
`runs/run-1785781082105/phases/01-eval/lineage/handbook-candidate.md`
(sha256 `002ebd6d…`, approved `c7c9dd9a…`). One concise "Environment and
configuration" section teaches that the environment is a host surface read via
`env.get_or(NAME, default)` (absence-only defaults), writes via
`fs.write(path, text)` with the `env`/`fs` effects declared, and that the typed
`env.int`/`env.bool` readers are convenience readers rather than strict format
validators, so a byte-exact decimal/boolean contract must be validated
explicitly. This is a short general rule that removes repeated exploration and
is not wired to this eval's specific values. Not yet promoted.

## Tickets created

- `tickets/task-envcfg-005.md` — compact-IR blocker on multi-statement
  (`let`) stream closures; merge placeholders left untouched for the CTO. New
  ticket for the next cycle. Links this eval, this manager run, worker
  `task-envcfg-1` session/reports, the handbook lineage, and XSH commit
  `51b035a7`.

Existing open tickets re-confirmed but not re-opened: `task-envcfg-001`
(error construction), `task-envcfg-003` (boolean-operator diagnostics),
`task-envcfg-004` (api type-index). `task-ecount-002` is the related
compact-IR ticket; `task-envcfg-005` is scoped to the distinct closure trigger.

## Post-merge decisions

Controller supplied merged-ticket snapshot `none`; the candidate ticket is
`not-reevaluation`. There are no merged tickets to accept/reject in this run,
so no post-merge decision or revert proposal applies. `task-envcfg-005` is a
new open ticket, not a merged acceptance.

## Next replay

Replay `task-envcfg` against the merged implementation of `task-envcfg-005`
(whichever XSH commit the CTO lands) using this run's approved handbook
lineage `handbook-approved.md` (`c7c9dd9a…`), to confirm a `let`-containing
stream closure either compiles or yields a readable diagnostic instead of
`full_ir_function_blocker`. Separately, promote the staged `Environment and
configuration` handbook candidate to `runtime/handbook.md` only after a second,
independent eval (e.g. a future config-from-env or file-render task) replays it
and the promotion is CTO-approved. Falsification check: an eval that needs a
strict typed read should not regress toward relying on `env.int` as a format
gate.

## North-star impact

This run improves the practical, learnable, ergonomic XSH surface in three
ways: (1) it surfaces a genuine compact-runtime ergonomics defect — multi-
statement stream closures fail opaquely, forcing verbose re-evaluated
single-expression closures — as a general product ticket rather than an envcfg
recipe; (2) it re-confirms the open error-construction gap (no clean nonzero
exit) with fresh evidence, keeping that trust-critical issue visible; and (3)
it stages a concise, general handbook lesson on the `env`/`fs` configuration
surface so future agents read environment-backed config with defaults and
validate strict contracts explicitly instead of re-discovering the module and
its permissiveness. The empty-stdout candidate hash was correctly read as a
file-deliverable artifact, not a correctness failure, keeping the evidence
faithful to the eval contract.
