## Result

ready-for-review

## Proposal

- Proposal package: `runs/run-1785873121313/phases/04-eval-design/proposals/proposal-1/`
  - `EVAL.md` — contract, `## Status` = `Draft.`, task `task-intsum`
  - `runtime/task.md` — worker instructions
  - `runtime/artifact.md` — `intsum.xsh`
  - `executor.xsh` — thin `task-intsum` selector into the shared eval-executor
  - `evaluator.xsh` — self-contained evaluator for `task-intsum`
  - `evaluate.xsh` — generic selector (shared dispatch, unchanged)
- Dry-run evidence: `proposals/proposal-1/dryrun/` (`DRYRUN.md`, candidate, oracle)
- No approved eval was edited; the existing `task-tags` seed is preserved.

Selected task: `task-intsum` — sum integer command-line arguments with a typed
loop and fail loudly (nonzero) on any non-integer argument. It is a small,
distinct, practical programming/glue capability (no existing eval is an
argv-arithmetic task), no harder than ecount.

## Dry run

Exercised with the checkout build (`XSH_MODULE_PATH=. xsht check` and `xsh`):

- All three package scripts pass `xsht check`: `evaluator.xsh`, `executor.xsh`,
  `evaluate.xsh`. Two focused scaffold errors were corrected before pass:
  the forbidden-subprocess helper needed the `pure` modifier, and the pure-fn
  spelling is `pure name(...)`, not `proc pure`.
- The reference solution (see `dryrun/intsum-candidate.xsh`) was run end to end:
  `4 9 2` -> 15, no args -> 0, `-3 7 -1` -> 3, `2147483647 1` -> 2147483648,
  `0 10 20` -> 30, and malformed `5 abc 2` -> no stdout with nonzero exit (3).
- The portable `sh` oracle (`dryrun/intsum-oracle.sh`) reproduces every one of
  those results and exits nonzero (1) on the malformed case. Candidate and
  oracle match byte-for-byte on all five numeric cases, and both fail
  (nonzero, silent stdout) on the malformed case — satisfying the evaluator's
  `expect_fail` contract.
- Int64 width was confirmed (`2147483647 1` -> `2147483648`), so the large case
  is a real bound probe, not a wrap.

Remains unproven here: the full isolated container run — an agent producing
`/work/intsum.xsh` + `review.md` inside the eval image, the evaluator container
executing `evaluator.xsh` end to end, and the `run.json` manifest. That gate
belongs to the CTO after promotion into `evals/`.

## North-star impact

Capability hypothesis: an agent that has internalized the handbook's typed
command-line glue should turn an argument vector into a typed integer list,
propagate an expected parsing failure with postfix `?`, accumulate in a `var`,
and print an exact single line — with no subprocess and no silent coercion.
The malformed case is the key discriminator: it rewards explicit, typed failure
(clear nonzero exit) over a shell-like `0`/quirk, which is exactly the
XSH-explicit-boundary ethos in `NORTH-STAR.md`. A clean pass is evidence about
learnability and ergonomics of typed argv + `Result` propagation; a malformed
case miss points at a product or handbook gap in typed failure, which is
generalizable rather than task-specific.

## Known risks

- Oracle/candidate divergence on untested pathological inputs: the `sh` oracle
  and XSH `parse_int` may differ on inputs not in the case table (bare `-`,
  leading `+`, `-0`, `007`, whitespace, empty string). No case exercises these;
  the evaluator's hidden cases stay within the stated decimal-integer contract.
- The `expect_fail` check (malformed) verifies only a nonzero exit and silent
  stdout, not a specific error message; a wrong-but-failing implementation could
  pass the negative case. This is accepted for a small task; the numeric cases
  still carry the real correctness signal.
- Forbidden-subprocess check is a whitespace-aware heuristic over `#`-stripped
  lines (`process.`, `spawn `, `run `); it is the established factory bound and
  matches the shared `factory_control.xsh` logic.
- Timing is collected but diagnostic only (no ratio gate), consistent with the
  task-tags/envcfg envelope.
- Full evaluator execution was only syntax-checked, not run in the container;
  the end-to-end paid run is the CTO's post-promotion decision.

## Review path

- Promoted eval path after CTO decision: `evals/task-intsum` (copy of this
  proposal package; status stays `Draft.` until the CTO accepts a passing
  evaluator and sets `Approved.`).
- Evidence for the CTO approval decision: `EVAL.md` (contract, `Draft.`,
  oracle/hidden-cases/agent-boundary/metrics/manager-policy), `runtime/task.md`,
  `runtime/artifact.md` (`intsum.xsh`), `executor.xsh`/`evaluator.xsh` passing
  `xsht check`, and `dryrun/` showing candidate + oracle byte-for-byte agreement
  on all six cases including the malformed expect-fail.
- The controller's eval-design gate decides `Draft.` vs `Approved.`; this
  proposal does not self-approve.
