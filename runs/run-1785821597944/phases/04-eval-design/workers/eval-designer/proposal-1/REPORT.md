# Eval-designer report — task-iniget

## Result

ready-for-review

## Proposal

One new eval proposal is staged at:
`runs/run-1785821597944/phases/04-eval-design/proposals/proposal-1/`

- `EVAL.md` — north-star hypothesis, task contract, agent boundary, oracle,
  hidden cases, metrics, manager policy, staged dry run.
- `runtime/task.md` — the user-facing `iniget.xsh` prompt.
- `runtime/artifact.md` — `iniget.xsh`.
- `executor.xsh` — thin selector retargeted to `task-iniget`.
- `evaluate.xsh` — generic package selector (unchanged scaffold convention).
- `evaluator.xsh` — package-owned evaluator (writes hidden INI fixtures, runs
  the candidate per case, compares byte-for-byte with an independent oracle,
  checks `ini.` reference + no-subprocess + review protocol, emits
  `/session/run.json`).
- `dry-run/NOTES.md` and `dry-run/evidence/pass.run.json` — dry-run evidence.

Task ID `task-iniget` is not present under `evals/`, so promotion will not
collide with the retired `task-tags`. Status is `Draft.`.

## Dry run

Validated the materialized proposal on the local build with the exact
package-owned evaluator (sandbox roots relocated via
`INIGET_WORK`/`INIGET_SESSION`/`INIGET_EXPORT` because this host has no
root-level `/work`; the shipped evaluator defaults to the container contract).

- Reference candidate satisfies the contract on the full fixture sweep: five
  success cases byte-exact (public, port, spaced value, trailing-space trim,
  global-key-plus-section) and three failure controls (missing key, missing
  section, malformed duplicate) each exit nonzero with empty stdout.
- The evaluator classifies correctly: a correct candidate yields
  `result=pass, classification=pass, all_exact=true, exit 0`. Negative
  controls: wrong output → `candidate_failed`; `process.` use →
  `restriction_failed`; hand-written parser without `ini.` →
  `restriction_failed (uses_ini=false)`; missing `review.md` →
  `protocol_failed`. All controls exit 1, so the evaluator cannot be gamed by
  a wrong answer, a subprocess, a manual parser, or skipping the protocol.
- `xsht check` passes for `executor.xsh`, `evaluate.xsh`, `evaluator.xsh`, and
  the reference candidate.

Remaining unproven: a live container trial of the exact `/work` `/session`
`/export` paths and the pinned gym image surfacing `ini.decode` (present in
the local build and standard-module source), plus a real agent session.

## North-star impact

Capability hypothesis: an agent with the handbook should turn "read a config
and print one value" into a short typed XSH program using the `ini` module,
dynamic `Record.get` by runtime name, and the `?` failure path — the practical
systems-glue shape of a config lookup tool that no approved eval covers. A
successful run teaches the factory that the typed INI API and record
navigation compose cleanly; a miss reveals a learnability gap in `ini.decode`
discovery, dynamic record access, or propagating "not found". The design
distinguishes a general improvement from a workaround because the evaluator
writes hidden fixtures, passes section/key at runtime, and refuses any
solution that does not reference `ini.` (hand parsers are rejected) or that
opens a subprocess. This honors the explicit-boundary/composability ethos:
typed host API and structured errors instead of string parsing.

## Known risks

- The pinned gym image could surface the `ini` module under a different name
  or pre-date it; verified present in the current build and standard-module
  source, and the evaluator fails closed if the module or candidate is absent.
- The evaluator's `pure source_has_forbidden_subprocess` scans source text
  and could miss an obfuscated subprocess spelling; it is a guideline gate
  like the other evals, not a sandboxing control.
- Nested-record navigation: a candidate could query `doc.get(section).get(key)`
  incorrectly (e.g., lowercase the section or forget key trimming). The
  `hidden_trim` and `hidden_global` cases specifically probe this; if these
  prove noisy, they can be narrowed at review.
- The `INIGET_WORK`/`INIGET_SESSION`/`INIGET_EXPORT` override seam in the
  shipped evaluator is a dry-run convenience; production does not set these,
  but the CTO may prefer them removed to minimize surface.
- Timing is diagnostic (no strict envelope), so a runaway candidate would not
  be caught by a ratio gate; acceptable for a value-lookup task of ecount
  difficulty or below.

## Review path

Promoted eval path (pending CTO): `evals/task-iniget/` containing `EVAL.md`,
`runtime/task.md`, `runtime/artifact.md`, `executor.xsh`, `evaluate.xsh`,
`evaluator.xsh`. Evidence for the CTO decision:

- `proposals/proposal-1/EVAL.md` — contract, boundary, oracle, hidden cases.
- `proposals/proposal-1/dry-run/NOTES.md` — fixture sweep and control matrix.
- `proposals/proposal-1/dry-run/evidence/pass.run.json` — byte-exact pass with
  per-case exits and timing, `uses_ini`, and protocol flags.
- `proposals/proposal-1/evaluator.xsh` — passes `xsht check` and demonstrably
  fails wrong-output, forbidden-subprocess, hand-parser, and missing-review
  candidates.

The CTO may promote the package and set `Approved.` once the evaluator passes
and evidence is accepted; otherwise it stays `Draft.` and is not admitted to
paid work.
