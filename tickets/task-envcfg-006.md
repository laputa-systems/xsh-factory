# Ticket task-envcfg-006

## Status

Open.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-envcfg` (`evals/task-envcfg/EVAL.md`)
- Shared handbook lineage: `runs/run-1785784385782/phases/03-eval/lineage/handbook-approved.md` (approved `fed89d59…`; candidate `handbook-candidate.md` with one added comment-syntax sentence)
- Manager run: `runs/run-1785784385782/phases/03-eval/workers/eval-manager/task-envcfg/REPORT.md`
- Executor run: `runs/run-1785784385782/phases/03-eval/workers/eval-worker/task-envcfg-1` (trial 1)
- XSH baseline commit: `51b035a705f856d0bd3ead3cddf1557523d1d30e`

## Observation

The task-envcfg evaluator's forbidden-subprocess restriction scanner uses naive
substring matching that flags natural-language comment text as a forbidden
call. The worker produced a fully correct `envcfg.xsh` that passed all ten
oracle cases byte-for-byte (including both failure controls), referenced the
`env.` module, used no subprocess, and left a complete `review.md`. It was
still classified `restriction_failed` and the evaluator printed
`task-envcfg evaluation failed`. Root cause: the source's inline comment

```xsh
# CFG_PORT must be a non-empty run of decimal digits (matches the oracle).
```

contains the token `run `, and the scanner computes

```xsh
forbidden_operations = ! source.contains("process.") and
  ! source.contains("spawn ") and ! source.contains("run ")
```

so `forbidden_operations` came back `false` even though no subprocess exists
anywhere in the program. The failure is entirely an artifact of comment text.

The same naive check (`source.contains("process.")`, `"spawn "`, `"run "`) is
replicated in the factory evaluator for this eval and several others:
`evals/task-envcfg` (via `evaluate_legacy.xsh`), `task-tags` and `task-ecount`
(same `evaluate_legacy.xsh`), `task-col2`, `task-dupcheck`, `task-jsonfilter`.

## Evidence

This run (`run-1785784385782`, phase `03-eval`):

- Candidate source `workers/eval-worker/task-envcfg-1/envcfg.xsh` (sha256
  `c0f8f133…`) — verified `grep -c "run " envcfg.xsh` returns exactly 1 at
  line 8, the comment `# CFG_PORT must be a non-empty run of decimal digits…`;
  `grep -c "process\."` and `grep -c "spawn "` return 0.
- `run.json`: `restrictions.passed: false`, `classification:
  restriction_failed`, while `correctness.all_exact: true` for all ten cases,
  `env_referenced: true`, `forbidden_operations: false`, `protocol.review_ok:
  true`.
- `evaluator.stderr`: `task-envcfg evaluation failed`.
- Worker report `execution.classification: evaluator_failed`,
  `evaluator_state: fail`.
- The session shows the worker also ran `xsht check`, `fmt`, `lint` all
  passing and compared fourteen configurations against the oracle locally with
  all `OK`.

## Diagnosis or hypothesis

This is a general evaluator-harness correctness defect, not task-specific
confusion or a candidate miss. A substring test for a forbidden subprocess is
invalid because (a) it false-positives on prose (here `run ` in a comment) and
(b) it can false-negative on real call sites such as `process.run(` (where
`run` is not followed by a space) — the check is not parse- or
tokenization-aware. Because the identical pattern appears in six separate eval
evaluators, a correct candidate in any of them can be wrongfully rejected. The
candidate itself is correct; the eval outcome is a false negative produced by
this scanner.

## North-star impact

Accurate eval classification is a trust requirement: the factory's evidence
loop depends on a `restriction_failed` label meaning the candidate actually
violated a task restriction. A scanner that rejects a clean, correct candidate
on the word "run" inside a comment erodes that trust, wastes a paid worker
cycle, and can misroute subsequent handbook/ticket decisions. Fixing the
scanner once generalizes to every eval that forbids subprocesses.

## Proposed XSH change

Make the forbidden-operation check parse-aware instead of a raw substring scan:
strip `#` line comments before scanning (e.g., match `process.` plus actually
forbidden operation names such as `process.run(`, `spawn `, `run ` as command
tokens on real source lines, not inside comments). The smallest fix is to
remove comment contents before applying the substring test and to require a
more specific token boundary for each forbidden name.

## CTO implementation pending replay

The CTO applied the smallest shared fix in `factory_control.xsh` and replaced
the repeated evaluator scans in `evaluate_legacy.xsh`, `evals/task-col2`,
`evals/task-dupcheck`, and `evals/task-jsonfilter`. The native regression
`test_forbidden_subprocess_scan_ignores_comments` proves that `run ` in a `#`
comment is ignored while `process.run(...)` and `spawn` remain forbidden.
Leave this ticket Open until the next `task-envcfg` replay verifies the
containerized evaluator classification and its negative control.

## Acceptance criteria

- A correct `task-envcfg` candidate whose only `run `/`spawn ` occurrence is
  inside a `#` comment passes classification `pass` (not `restriction_failed`).
- A candidate that genuinely calls `process.run(...)`, `spawn`, or `run`
  still fails `restrictions`.
- The unit case above reproduces deterministically on the pinned image.
- Existing task-envcfg cases (public, ten hidden, both failure controls) remain
  byte-exact.

## Scope and non-goals

- In scope: the evaluator restriction scanner and any shared copy of it.
- Out of scope: the separate `xsht api` / comment-syntax learnability topics,
  which are handled by the handbook lineage candidate for this run.

## Post-merge evaluation

The linked eval-manager replay `runs/run-<next>/phases/03-eval` will rerun
`task-envcfg` trial 1 against the evaluator with the scanner fix and require
the same (correct) candidate to classify `pass`, while a deliberately
subprocess-using negative control still classifies `restriction_failed`.
