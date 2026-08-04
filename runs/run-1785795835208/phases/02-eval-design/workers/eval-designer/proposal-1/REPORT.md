# Eval-designer report

## Result

ready-for-review

## Proposal

New eval **`task-grep`** — a line-oriented literal text-search workflow that
replaces `grep -nF`'s glue with a typed XSH program. A correct run taught the
factory whether an agent can read a file, stream its lines, filter on a
byte-exact literal substring, number the hits from 1, and emit an exact
`N:text` contract without a subprocess.

Staged package (complete, `Draft.`):

- `runs/run-1785795835208/phases/02-eval-design/proposals/proposal-1/EVAL.md`
- `.../evaluator.xsh` (package-owned oracle + cases, writes session `run.json`)
- `.../executor.xsh` (thin selector, `task-grep` id)
- `.../evaluate.xsh` (generic shared-protocol selector, unchanged)
- `.../runtime/task.md`, `.../runtime/artifact.md`

The scaffold's `task-tags` title/ID were retired to `task-grep` and `Disabled.`
flipped to `Draft.` before any dry run; no `task-tags` reference remains in the
package. The proposed eval path for promotion is `evals/task-grep`.

## Dry run

Host-side dry run using env-overridable workspace/session roots
(`FACTORY_WORK`, `FACTORY_SESSION`) with the container defaults `/work` and
`/session` intact. Evidence saved under
`.../proposals/proposal-1/dry-run/` (work/session/export trees and `run.json`
manifests).

Exercised — nine cases through the actual package evaluator: public,
empty-pattern, no-match (empty stdout), case-sensitivity, regex-meta literal
(`a.c` matched literally), leading/trailing-space lines, blank lines, unicode,
and a missing-file failure control.

- **Correct reference** (`dry-run/work-pass/grep.xsh`, the exact stream
  pipeline): `result=pass`, `classification=pass`, `all_exact=true` across all
  9 cases; protocol and restriction checks pass; evaluator exit 0.
- **Deliberately wrong candidate** (`dry-run/work-bad/grep.xsh`, prints
  matches without the `N:` prefix): `result=fail`,
  `classification=candidate_failed`, failing every real-match case while the
  two empty-output cases stay correct — cleanly isolating a correctness
  failure from protocol/restriction noise; evaluator exit 1.

The reference was byte-verified against the live `grep -nF` oracle for every
edge case (blank lines, missing trailing newline, empty pattern, literal
metachars, case, leading/trailing spaces, unicode) before staging. `xsht
check` passes for `evaluator.xsh`, `executor.xsh`, `evaluate.xsh`, and both
reference candidates.

Remaining unproven: the container routing to `/work`/`/session` (standard,
previously proven factory infrastructure) is not re-exercised here; no live
Pi session or token/turn metrics were produced in this design phase. Those are
manager-phase outputs, not design-phase contract requirements.

## North-star impact

Capability hypothesis: XSH's explicit line-stream boundaries — `read_text`,
`text.lines`, `enumerate`, `where`/`contains` — should let an agent compose a
correct, clear search-and-report tool with little exploratory friction,
turning the classic `grep -n` shape into a small typed program. A successful
paid run would strengthen the claim that XSH's text-glue ergonomics and
explicit boundaries (instead of grep's implicit regex/line contract) are
learnable and AI-efficient; it reads a file, which distinctively crosses a
text-file boundary absent from the argv-level `task-tags` and complements the
field-extraction `task-col2`, set-difference `task-setdiff`, and
numeric-aggregation `task-total`.

The design resists task-specific hacks by requiring byte-exact `N:text`
output across hidden empty-pattern, case, regex-meta-literal, whitespace, and
unicode inputs, plus a no-match empty-output case and a missing-file failure
contract, all under a no-subprocess boundary — so a hard-coded answer, a
recognition-only solution, or a shell-out would be fragile and fail the
oracle.

## Known risks

- **Oracle/exit semantics:** `grep` exits 1 on no match while a correct XSH
  program exits 0; the evaluator therefore compares stdout byte-for-byte and
  requires candidate success, without demanding oracle exit equality on the
  no-match case. This is the intended, documented contract but must be
  preserved if cases are edited.
- **Missing-file exit codes differ** (candidate 3 vs oracle 2); the evaluator
  checks both-nonzero + empty stdout, not exact codes. A future rigorous
  exit-code contract would require an oracle that returns the same code.
- **Toolchain drift:** the local `xsh` build is stricter than the factory
  image (`task-total`'s own evaluator fails `xsht check` locally on an
  unrestricted helper). The evaluator was hardened to pass both (pure helper
  declared `[]`, task-total-idiom APIs only: `p`/`fp` literals, `fs.exists`,
  `fs.remove`, `fs.write/copy`, `Path.read_text`, `json.write`, `time.measure`).
  The container `/work`/`/session` routing itself remains unproven by this
  host dry run.
- **Restriction scan** is a substring heuristic mirrored from the factory
  control helper; it is sufficient for the intended no-subprocess check but is
  not a full parse.
- **No live agent data** (turns/tokens) yet; the eval can only give an
  ergonomics signal after a paid or trial worker run.

## Review path

- Proposed promoted eval path: `evals/task-grep/` (EVAL.md, evaluate.xsh,
  evaluator.xsh, executor.xsh, runtime/{task,artifact}.md).
- Evidence for the CTO approval decision: the staged package under
  `.../proposals/proposal-1/` plus the dry-run manifests under
  `.../proposals/proposal-1/dry-run/` — `session-pass/run.json`
  (`pass`, 9/9 exact) and `session-bad/run.json` (`fail`, candidate_failed),
  which together prove the evaluator distinguishes a correct solution from a
  wrong one. All package `.xsh` files pass `xsht check`.
- The CTO may promote the package to `evals/task-grep` and set `Approved.`
  after confirming the container routing; until then it remains `Draft.` and
  is not admitted to paid work.
