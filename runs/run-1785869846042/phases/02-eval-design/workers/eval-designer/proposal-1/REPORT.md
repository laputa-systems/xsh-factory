## Result

ready-for-review

## Proposal

- Contract: `runs/run-1785869846042/phases/02-eval-design/proposals/proposal-1/EVAL.md`
- Task brief: `.../proposal-1/runtime/task.md`
- Artifact manifest: `.../proposal-1/runtime/artifact.md` (`trim.xsh`)
- Scaffolding: `.../proposal-1/executor.xsh` (task-trim selector), `.../proposal-1/evaluator.xsh` (task-trim package evaluator), `.../proposal-1/evaluate.xsh` (generic, unchanged)
- Package status: `Draft.` (new valid ID `task-trim`; no approved eval was modified)

The proposal is a new small systems-administration eval, `task-trim`: read a
text file with XSH filesystem APIs, strip leading/trailing ASCII space and tab
from each line, and write a byte-exact cleaned file to a second path. It is no
harder than the `task-ecount` upper bound and is distinct from every current
eval (none reads file *content* line-by-line and rewrites it).

## Dry run

Exercised: the minimal package syntax/reference check was run with
`xsht check` on `executor.xsh`, `evaluator.xsh`, and `evaluate.xsh`; all three
passed with no errors. The oracle itself (`sed 's/^[ \t]*//; s/[ \t]*$//'`)
was behavior-verified directly on sample inputs covering leading/trailing
spaces, tabs, blank, and whitespace-only lines to confirm the byte-exact
contract (whitespace-only lines become empty, internal whitespace and one
`\n` per line are preserved).

Remains unproven (not claimed): a full isolated-container evaluator run with a
generated `run.json`, a paid agent session, and negative-control classification
were not exercised in this proposal. Per the designer state machine these
require the shared evaluator infrastructure and a paid session, and building a
localized evaluator / candidate / oracle runner is explicitly out of scope;
those pathways are inherited unchanged from the shared base image. The
proposal's `Dry run` therefore reports only the syntax/reference check plus
oracle-behavior verification.

## North-star impact

Capability hypothesis: an agent with the handbook should be able to replace a
`sed`/`awk`/`tr` text-cleaning step with a clear, typed XSH program that reads
a file, transforms each line, and writes a byte-exact result without a
subprocess — the file-content-transformation gap in the current eval portfolio.
A passing run is evidence that the `fs` stream/read and text-method idioms
compose into a real line-oriented file tool (learnability and ergonomics);
it is not evidence about the whole language. The byte-exact `sed` oracle and
varied hidden line shapes prevent hard-coded or localized answers, honoring the
explicit-boundary and composability ethos.

## Known risks

- Trailing-newline semantics: the contract relies on newline-terminated inputs;
  hidden cases all use newline-terminated files so the candidate and `sed`
  agree on the last line. A candidate that drops or doubles a trailing `\n`
  would fail the hidden cases and be a genuine correctness miss.
- Whitepace edge across ASCII space/tab only: the oracle trims exactly space
  and tab, not other Unicode whitespace; the `hidden_utf8` case keeps internal
  non-ASCII text intact, so UTF-8 byte/char handling is a plausible slip point.
- Emptiness: a whitespace-only line must become a truly empty line (still
  emitted), which a naive "skip blank lines" candidate would get wrong.
- Restriction classification depends on the shared evaluator requiring an
  `fs.` / text-read reference; this gate lives in the shared base evaluator and
  is not re-verified here.
- No negative-control or containerized `run.json` evidence was produced in this
  proposal, so the full evaluator path remains unproven until the shared
  infrastructure is run against a staged workspace.

## Review path

Promoted eval path (if approved): `evals/task-trim/` with `EVAL.md`, `executor.xsh`,
`evaluator.xsh`, `evaluate.xsh`, and `runtime/{task,artifact}.md`. Evidence for
the CTO approval decision: the completed `Draft.` package; `xsht check` passing
on all three scaffolding scripts; and the oracle-behavior verification described
above. Remaining unproven evidence (containerized evaluator `run.json`,
negative controls, paid agent session) is named above and must be exercised by
the shared eval-executor pathway before the CTO considers `Approved.`; until
then the package stays `Draft.`.
