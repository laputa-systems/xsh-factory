# Eval-manager report

## Result

pass

## Effort metrics

One fresh trial (`task-bigfiles-1`) against the approved handbook snapshot
(`lineage/handbook-approved.md`, sha256
`4610e8f4e282c52e2fa34eca91ec46f2ef93d6f313b35a88ffb82f5af7e4365a`).

- assistant turns: 22
- tool calls: 28 (22 bash, 1 edit, 3 read, 2 write)
- tool errors: 2 (both warning-severity, see Tool-error findings)
- tool results: 28
- session span: 62,135 ms (~62 s); agent wall 63,256 ms
- stop reasons: 1 `stop`, 21 `toolUse`
- user messages: 1 (the staged task prompt)
- worker friction: low. The worker reached a clean, correct solution with the
  existing handbook; no repeated exploration, no re-read loops, and both tool
  errors were self-correcting single events.

Provider telemetry is present and healthy: `retry_count` 0, `retry_delay_ms` 0,
`provider_errors` [] , `retry_failures` 0. Latency attribution is therefore
**normal / non-confounding**; the ~62 s span is not attributed to external
health and, given 22 turns and 28 tool calls with 2 errors, reflects normal
agent-paced discovery.

## Usage and cost

Per the worker usage record (single worker, single model
`openrouter/deepseek/deepseek-v4-flash-0731`):

- input tokens: 18,219
- output tokens: 4,247
- cache read tokens: 235,840
- cache write tokens: 0
- provider total tokens: 258,306 (bucket total 258,306, consistent)
- reasoning tokens: 1,752 (provider-reported, subset of output, not added to
  totals)
- cost total: $0.00664929 (budget $0.50, no budget breach)
  - input $0.00163971, output $0.00076446, cache read $0.00424512,
    cache write $0, unknown costs 0
- malformed usage lines: 0

Single trial, so the per-trial figure is the aggregate figure. Cost is minimal
and well within budget.

## Thinking evidence

Thinking-block count: 12. Provider reported `reasoning_tokens: 1752`,
so reasoning-token counts **are** available. Transcript reasoning was grounded
and efficient: the worker queried `module:fs`, `api:fs.files`,
`language:stream.sort-by`, `search:take`, `method:Str.parse_int`,
`method:List.get`, and `language:cli.xsh-SCRIPT` before writing the first
draft, then ran `check`/`fmt`/`lint`, applied the two lint corrections, and
verified against a staged local tree incl. the `N=abc` failure control before
submitting. The reasoning blocks track a short, deliberate discovery path with
no churn or backtracking.

## Tool-error findings

Two nonzero Pi tool results in the structured worker `tool_errors` array
(both `bash`, warning severity). The manager session had zero tool errors.

1. Turn 4 — `xsht api: invalid API query 'language.core.main'; expected
   KIND:VALUE` (exit 2). The worker issued a valid `search:main` alongside an
   invalid dotted-rule query `language.core.main`. This is precisely the
   dotted `language.core...` guess the handbook already warns against and
   tells the agent to avoid; it did not recur after the handbook's KIND:VALUE
   guidance, so it is a one-off discovery slip rather than a reusable gap.
   (In the raw transcript two further non-fatal invalid queries —
   `language.core.command-interpolation` and `Path constructor` — also
   appeared inside combined bash commands whose overall exit was 0, so they
   are not flagged in the structured arrays; they are the same dismissible
   discovery noise and were absorbed without cost.)
2. Turn 13 — `xsht lint` exit 1 with three warnings on the first draft:
   `lint.path-constructor` (prefer `fp"${...}"` over `Path(...)`),
   `lint.redundant-command-interpolation`, and
   `lint.redundant-path-display`. These are productive, standard lint
   corrections; the worker applied them (final artifact uses `fp"${...}"`,
   `print $e.size $e.path`) and then `check`/`lint` passed. This is normal
   tooling feedback surfaced as an error only because lint exits 1 on
   warnings, not a defect.

No latent or unexplained tool errors remain.

## Timing evidence

The eval has no strict candidate/oracle timing ratio gate; the EVAL contract
explicitly treats timing as diagnostic until a stable envelope is established.
Measured wall time per case (candidate vs oracle, all in the 11–14 ms band):

- public 11.80 / 12.29 ms
- hidden_default 13.02 / 11.02 ms
- hidden_n2 12.70 / 12.19 ms
- hidden_single 11.83 / 12.37 ms
- hidden_deep 12.89 / 12.17 ms
- hidden_spaces 12.73 / 13.02 ms
- hidden_utf8 11.02 / 11.87 ms
- hidden_empty 11.26 / 13.32 ms
- hidden_bad_n 11.47 / 13.64 ms

Both sides are sub-20 ms per case; timing passes and is noise-neutral. No gate.

## Observation classification

- **Correctness (pass):** all 9 cases byte-exact vs the oracle, including the
  failure control `hidden_bad_n` where both candidate (exit 3) and oracle
  (exit 1) exit nonzero and print nothing. This is the noise-free primary
  signal.
- **Restriction (pass):** source references `fs.files` and a `sort-by` stage,
  uses no subprocess boundary, keeps diagnostics off stdout. Evaluator
  restriction check passed.
- **Protocol (pass):** artifact `bigfiles.xsh` present; `review.md` preserves
  both required headings (`## XSH language proposals`, `## xsht friction`) with
  no template placeholders.
- **Worker friction (low):** 22 turns, 28 tool calls, 2 self-correcting tool
  errors, 62 s span. No repeated exploration or re-read loops. Provider
  telemetry normal, so the span is agent-paced, not health-driven.
- **Ordinary tooling feedback (noise, non-defect):** the two recorded tool
  errors — an invalid dotted `xsht api` guess and productive lint warnings —
  are single-event, already covered by the handbook, and cost one turn each.
  They do not generalize into a defect or a reusable lesson.
- **No reusable handbook gap:** every idiom the agent used (fp-string
  interpolation, `sort-by --desc`, `take`, `parse_int` with `?`) is either
  documented or discoverable through `xsht api` without friction; the agent
  completed with the existing handbook.

## Handbook decision

Unchanged. No strong, reproducible, generalizable lesson emerged; the worker
passed all nine cases and the protocol within the existing approved handbook
with only routine discovery and lint feedback. The only observed frictions are
already addressed by the current handbook (KIND:VALUE rules and the explicit
warn against dotted `language.core...` guesses) and are not worth a recipe.
`lineage/handbook-candidate.md` is staged as a byte-identical copy of the
approved snapshot (sha256
`4610e8f4e282c52e2fa34eca91ec46f2ef93d6f313b35a88ffb82f5af7e4365a`). Replay
scope for promoting any future lesson: none required this cycle. No promotion
to `runtime/handbook.md` is proposed.

## Tickets created

None. No strong reproducible product or tooling defect. The invalid API-query
noise and lint feedback are single-event and already governed by the handbook;
there is no general XSH ergonomics or correctness problem to ticket.

## Post-merge decisions

None. The reconciler reported `none` merged ticket files for this cycle, and
the candidate-re-evaluation slot is `not-reevaluation`. No post-merge
acceptance assignments to evaluate.

## Next replay

Replay `task-bigfiles` against the approved handbook lineage
(`lineage/handbook-approved.md`) on the next XSH cycle commit to confirm the
ranked-stream idiom (`fs.files` + `where .kind` + `sort-by --desc` + `take`)
remains stable and discoverable, and to establish a repeated evidence baseline
before any future handbook claim is considered. Optionally extend replay to
`task-ecount` / `task-histogram` if a future cycle proposes a generic stream
sorting/ranking handbook sentence, since those evals also exercise stream
composition.

## North-star impact

`task-bigfiles` exercises the classic `find | sort -S | head` disk-hygiene
shape in pure XSH values — a compositional, practical systems-glue workflow
that no prior eval covered. This trial shows an agent, guided only by the
handbook and `xsht api`, can walk a rooted tree with the typed filesystem
stream, filter on the structured `kind` field, rank a lazy stream by a numeric
per-file field (`sort-by --desc`), truncate (`take`), and emit a byte-exact
ranked report while propagating a malformed-count failure with `?`. The
clean pass across hidden trees (deep, spaces, UTF-8, empty) and the failure
control strengthens the north-star claim that sorted, truncated, numeric
stream composition is both discoverable and composable — the grammar for glue
remains explicit and learnable, with no subprocess escape and no hidden string
conventions.
