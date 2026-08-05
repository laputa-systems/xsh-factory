# Eval task-col2

## Status

Disabled.

## CTO retirement

- Review cycle: CTO portfolio review following `run-1785888999833`.
- Decision: Retired from paid admission as an intentionally low-difficulty
  sentinel; do not dispatch new trials or create tickets from this eval.
- Basis: the worker reached a correct one-file, one-field projection in 13
  turns with only two recoverable errors, and the independent trial failed at
  evaluator packaging before producing a manifest. The task exercises no
  stateful aggregation, cross-record invariant, or multi-boundary composition,
  so it is a poor source of durable product signal and weak tickets.
- Replacement: prefer the approved `task-colsum`, `task-groupsum`,
  `task-manifest`, or `task-findexec` portfolio members, subject to the new
  difficulty gate in the designer contract.
- Evidence: `runs/run-1785888999833/phases/03-eval/report.json` and
  `runs/run-1785888999833/phases/03-eval/workers/eval-manager/task-col2/REPORT.md`.
- History: retain this contract and its run evidence for audit; `Disabled.`
  makes the package unavailable to paid admission.

## Budget breach

None.

## Purpose

Measure a practical line-oriented text-processing workflow that no current
eval covers: reading a file's text through XSH APIs, splitting each line into
whitespace-delimited fields, selecting the second field with a fallback for
missing fields, and producing a byte-exact stdout contract. Existing evals
cover command-line value transforms (task-tags), filesystem traversal and
counting (task-ecount), and environment-to-file configuration (task-envcfg);
the pending proposals (task-logroll, task-nhead, task-jsonpick) cover rotation,
head-like output, and JSON. None reads a file's text content and transforms it
line by line with a standard text method. The retired `task-col2` package filled that gap with the
classic sysadmin/log-processing shape "replace `awk '{print $2}'` with a
typed XSH program."

## North-star hypothesis

XSH's stated role is practical systems glue; awk is the archetypal glue DSL
that XSH intends to make unnecessary for small idioms. This eval probes
whether an agent with the handbook can:

- discover the file-content surface (`fs.read_text` / `Path.read_text`) and
  the line stream (`Str.lines`) via `xsht api`;
- split each line into whitespace-delimited fields with `Str.fields()` and
  select the second field with an indexed fallback (`List.get(index, fallback)`),
  matching awk's default field semantics without a subprocess;
- keep stdout byte-exact: one line per input line, empty output for blank or
  single-field lines, no diagnostics;
- propagate a missing-file failure with postfix `?` so a bad input path exits
  nonzero instead of producing a partial or fabricated result.

A successful run teaches the factory whether the handbook's "reading and
writing files" promise is discoverable and whether line-oriented text idioms
compose. The design resists task-specific hacks because hidden cases vary
field counts, whitespace layout, blank lines, Unicode values, and the
missing-file failure control, and because the restriction check requires the
source to use a text-reading API — a hard-coded print workaround, a silent
fallback, or a subprocess escape each fails a distinct gate.

## Task

Create `col2.xsh`. It accepts one input file path argument and prints the
second whitespace-delimited field of each line, one per line. Whitespace means
spaces and tabs (the awk default): leading whitespace is skipped, runs of
whitespace between fields count as one separator, and a line with fewer than
two fields (including an empty line) prints an empty line. The behavior is
defined by this oracle command:

```sh
awk '{print $2}' INPUT
```

The evaluator invokes the candidate equivalently to `xsh col2.xsh INPUT` and
compares stdout byte-for-byte with the oracle. When the input file does not
exist, the program must exit nonzero and print no fabricated output. The
program must read the file through XSH text APIs, must not start subprocesses
or invoke an external command, must keep diagnostics off stdout, and must not
modify the input. Do not hard-code one file's current values. Complete
`review.md` using the supplied headings.

## Agent boundary

The worker runs as root in a minimal Alpine container with `/work` as its task
workspace. The image provides BusyBox, `xsh`, `xsht`, `curl`, and CA
certificates, and no extra packages: the `awk` oracle applet is already in the
shared base image, and the `fs` / `Str` / `List` surfaces are part of `xsh`
itself. There is no compiler, repository checkout, or implementation source.
The submitted program may not use `run`, process APIs, `spawn`, shell
commands, or any other subprocess boundary; it must keep diagnostics off
stdout and must not hard-code the current file's values.

## Oracle and evaluator

The evaluator runs in a separate read-only container boundary. It writes the
input files into a writable scratch area, runs the candidate and the `awk`
oracle on identical inputs, compares stdout byte-for-byte, verifies both
processes, and records candidate/oracle wall time per case. Public and hidden
cases:

- `public`: `alpha 1\nbeta 22\n` — second fields `1`, `22`;
- `hidden_single`: lines with exactly one field — each prints an empty line;
- `hidden_blank`: blank lines interleaved with data lines;
- `hidden_leading`: lines with leading spaces and tabs before the first field;
- `hidden_multi_ws`: multiple spaces and tabs between fields;
- `hidden_trailing`: trailing whitespace after the last field;
- `hidden_unicode`: non-ASCII field values such as `héllo wörld 42`;
- `hidden_no_newline`: file without a trailing newline;
- `hidden_empty`: empty input file — no output lines;
- `hidden_missing` (failure control): nonexistent input path — candidate and
  oracle must both exit nonzero.

The evaluator checks that the source does not contain the forbidden subprocess
boundary, requires that the source references a text-reading API (`read_text`)
so a hard-coded output workaround is classified as a restriction failure, and
checks that `review.md` preserves both required headings and contains no
template placeholders.

## Metrics

Record correctness for all ten cases (including the missing-file failure
control), restriction compliance, worker turns, thinking blocks and reasoning
tokens, token buckets, provider cost, tool calls and errors, session wall
span, candidate/oracle timing per case, and protocol completion. This eval has
no strict candidate/oracle timing gate; both sides finish in milliseconds, so
timing is diagnostic until a stable envelope is established.

## Manager policy

Use one trial by default; the controller-owned `## Trial plan` in the cycle
request may explicitly raise this to two. Classify repeated friction as
handbook guidance or a product issue only when it is generalizable; do not
create a ticket for an ordinary short-task miss or evaluator noise. A handbook
change must name the concept it teaches and be replayed before it is trusted.
The proposal is promoted into `evals/task-col2/` with a package-owned
`evaluator.xsh`; the CTO approved it after syntax and reference-artifact checks.

## Staged dry run

The proposal was dry-run in the current cycle: a reference XSH solution
(`col2.xsh` using `fs.read_text` / `Str.lines` / `Str.fields` /
`List.get(index, fallback)` and `print`) was checked with `xsht check` /
`fmt` / `lint`, compared byte-for-byte against the BusyBox `awk` oracle on all
ten cases on the host, and the same comparison was repeated inside the shared
base container image to prove the pinned toolchain and isolation boundary.
Negative controls (hard-coded output, no-`read_text` text workaround,
subprocess escape, missing `review.md`, missing input file) were each rejected
with the intended classification. The agent half (a live Pi worker) was not
exercised because it requires a paid agent session and a Pi auth file; the
agent path is inherited unchanged from the approved base image. The
controller-owned `evaluate_common.xsh` dispatch branch for `task-col2` was not
merged, so the containerized evaluator run remains an integration gap. See
`dry-run/DRY-RUN.md` for evidence.


## CTO review

- Result: `accepted`
- Promotion: `promoted`
- Package: `complete`
- Missing package files: `None.`
- Source run: `runs/run-1785728831509/phases/04-eval-design`
- Approved after the ten-case dry-run evidence and package-owned evaluator
  were checked in and syntax-validated. The first paid trial remains the
  integration check for the evaluator manifest.
