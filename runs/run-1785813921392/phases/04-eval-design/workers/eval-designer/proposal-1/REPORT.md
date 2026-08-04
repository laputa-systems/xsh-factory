# Eval-designer report

## Result

ready-for-review

## Proposal

New eval `task-render` — render a `@KEY@` template from a `KEY=value` file
into a byte-exact output file, entirely through typed XSH file/text values and
without a subprocess.

- Proposal package: `runs/run-1785813921392/phases/04-eval-design/proposals/proposal-1/`
  - `EVAL.md` (Draft., id `task-render`, north-star hypothesis, task, agent
    boundary, oracle, hidden cases, metrics, manager policy)
  - `evaluate.xsh`, `evaluator.xsh`, `executor.xsh` (generic scaffold, id
    switched from `task-tags` to `task-render`)
  - `runtime/task.md`, `runtime/artifact.md` (`render.xsh`)
  - `dry-run/` evidence: `render.xsh` reference, five fixtures + oracle
    outputs, `run-log.txt`, `lint-check.txt`
- Required report: `workers/eval-designer/proposal-1/REPORT.md` (this file)

The `task-tags` title/ID and `Disabled.` status were replaced before any dry
run; the proposal is `Draft.` and untouched by the CTO review gate.

## Dry run

Exercised on the local `xsh`/`xsht` binary (representative, not the
containerized full pipeline):

- `xsht check render.xsh` → exit 0 (recorded in `dry-run/lint-check.txt`;
  lint emits only advisory unused-local warnings from the accumulate-then-substitute
  pattern).
- Byte-for-byte match against the `awk` oracle on five representative cases:
  1. basic two-key substitution; 2. multiple adjacent placeholders; 3. unknown
  placeholder left intact plus an empty-value key; 4. keys defined in reverse
  order (order-independent substitution); 5. values containing `=` and spaces
  and an empty value.
- Negative control: missing TEMPLATE exits nonzero and creates no OUTPUT.

All five oracle comparisons are `MATCH` and the failure control `PASS`
(`dry-run/run-log.txt`).

Remains unproven: a real agent coding session in the pinned container; the
`evaluate_legacy.xsh` per-task oracle wiring (controller-owned, wired by the
CTO at promotion); and lint cleanliness of the agent's own solution (the
reference passes `xsht check`, which is the pass gate).

## North-star impact

Fills a real hole in the current portfolio: every approved eval either reads
files to filter/rank/count text, renders a fixed config from scalar env, or
crosses JSON — none builds a typed data structure from a parsed text file and
uses it to substitute placeholders in a separate template. Templating is the
canonical devops/sysadmin glue shape ("render `app.conf` from values") and
directly tests the typed-value, deterministic-key-iteration, and literal
`Str.replace` ergonomics that distinguish XSH from shell quoting sludge. A
successful run and any generalizable friction feed learnability and ergonomics
evidence; the design's variable hidden cases (key order, empty values, unknown
placeholders, punctuation in values) make hard-coded or one-example solutions
fail, so the signal is about genuine capability rather than memorization.

## Known risks

- **Task-specific hack:** a worker could hard-code a known fixture; the hidden
  cases and fresh-files-per-trial contract make this fail. Unknown placeholders
  left intact and order independence further resist a shortcut.
- **Oracle/awk risk:** the production oracle lives in the controller-owned
  `evaluate_legacy.xsh` (not part of this package) and must be wired to the
  documented `awk` command by the CTO at promotion. The values-may-not-contain
  `@` restriction keeps substitution unambiguous and order-independent; it
  should be enforced in the fixture generator.
- **Timing/difficulty:** no strict candidate/oracle timing gate is set; the
  Map-build plus substitution is close to the ecount ceiling and could expose
  real `Map`/accumulation friction, which would surface as reusable handbook
  guidance rather than a blocking defect.
- **Missing checks:** the dry run does not exercise the containerized
  executor/evaluator path or a full agent session; only the contract and oracle
  were proven.

## Review path

The CTO promotes this package into `evals/task-render/` immediately on review
and decides `Approved.` vs `Draft.` from the evidence. Id `task-render` is not
present under `evals/`, so promotion cannot collide with a retired eval.
Evidence for the approval decision: `EVAL.md` (contract, oracle,
hidden-cases, metrics, manager policy), the staged `executor.xsh`/`evaluator.xsh`
selectors, `runtime/task.md` + `artifact.md`, and `dry-run/run-log.txt` +
`lint-check.txt` (reference passes `xsht check`, matches the `awk` oracle
byte-for-byte on five fixtures, and the missing-file control behaves). The
CTO's remaining work is wiring the documented oracle into `evaluate_legacy.xsh`
and admitting a trial.
