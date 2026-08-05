# Eval task-uniqcat

## Status

Approved.

## Purpose

Measure a practical systems-administration / list-reconciliation workflow that
no approved eval covers: reading several line-oriented input files and emitting
each distinct line of their concatenation exactly once in first-occurrence
(priority) order. `task-tags` transforms argv values, `task-ecount` counts
extensions, `task-envcfg` renders a config from environment scalars,
`task-setdiff` computes a *sorted* set difference of two files, and
`task-total` aggregates numbers; none concatenates
multiple files and deduplicates while preserving canonical input order.
`task-uniqcat` fills that gap with the classic sysadmin shape "merge and
dedup several config / host / package lists, keeping the first (highest
priority) occurrence" — the XSH analogue of `cat "$@" | awk '!seen[$0]++'`
without a subprocess or a sort.

## North-star hypothesis

XSH's stated role is practical systems glue ("connect processes, files, paths,
streams, JSON, and system state"). Merging many small line-oriented files while
dropping duplicates is everyday glue. This eval probes whether an agent with
the handbook can:

- accept a variable number of file arguments and open each through the XSH
  text surface (`fs.read_text` / `Path.read_text`) in argument order, turning
  repeated sysadmin input into an ordinary `for` loop;
- split each file into lines with `Str.lines()` and honor its exact boundary
  semantics — a blank line inside a file is a real member while a final
  trailing newline adds no extra line — so an unterminated last line and an
  empty internal line both line up with `awk`'s record model;
- deduplicate with a membership set (`set.empty` / `set.has` / `set.add`
  returning an updated value) while preserving first-occurrence order, instead
  of sorting or collapsing to a `Map`;
- keep stdout byte-exact (one line per distinct first occurrence, final
  newline) and fail loudly with postfix `?` on a missing file rather than
  fabricating partial output.

A successful run teaches the factory whether multi-file sequential input,
order-preserving membership dedup, and the `Str.lines` edge model compose for a
real "merge these lists" task, and whether that lesson transfers from the
line-stream handbook guidance to a concrete file. The design resists
task-specific hacks because hidden cases vary the number of files, internal
and cross-file duplicates, blank lines, an unterminated final line, UTF-8
content, and preserved leading/trailing spaces, and because the failure
control requires a loud nonzero exit with empty stdout — a hard-coded answer, a
wrong dedup, a silent fallback, or a subprocess escape each fails a distinct
gate.

## Task

Create `uniqcat.xsh`. It accepts one or more file-path arguments and prints
each distinct line of the byte concatenation of those files exactly once, in
first-occurrence order. First-occurrence order is the order a line first
appears when scanning the files in argument order and each file top to
bottom. A line that appears again later (in the same or a later file) is
skipped. The output is one line per distinct first occurrence, each line
followed by a newline, with nothing else on stdout. The behavior exactly
matches the evaluator's BusyBox-awk oracle, run against the same file set:

```sh
awk '!seen[$0]++' file1 file2 ...
```

A line is a run of characters ending at a newline. A blank line between two
newlines is a real member; a final trailing newline does not create an extra
line. Content is compared byte-for-byte, so leading/trailing spaces and UTF-8
bytes are significant and case is preserved. When an input file cannot be
read, the program must exit nonzero and print nothing. In the evaluator's
failure case the unreadable file is the first argument, so a correct program
that reads the files in argument order fails before printing anything.

The program must read the files through XSH text APIs and deduplicate through
XSH values. It must not start subprocesses, invoke an external command
(including `cat`, `awk`, `sort`, or `sh`), or add diagnostic text to stdout.
Complete `review.md` using the supplied headings.

## Agent boundary

The worker runs as root in a minimal Alpine container with `/work` as its task
workspace. The image provides BusyBox, `xsh`, `xsht`, `curl`, and CA
certificates; there is no compiler, repository checkout, or implementation
source, and no extra packages. The submitted `uniqcat.xsh` may not use `run`,
process APIs, `spawn`, shell commands, or any other subprocess boundary, and
must keep diagnostics off stdout. The evaluator runs in a separate read-only
container boundary so the worker cannot inspect the oracle or the hidden
fixtures.

## Oracle and evaluator

The evaluator is the package-owned `evaluator.xsh`. For each case it writes
the fixture files under its own writable `/tmp`, runs the candidate
(`xsh /work/uniqcat.xsh FILE...`) and the oracle
(`awk '!seen[$0]++' FILE...`) with the same absolute file set, and compares
stdout byte-for-byte, recording per-case wall time to the run manifest.
Public and hidden cases:

- `public`: two files with one shared line, `A=[alpha,beta,gamma]`,
  `B=[beta,delta]` → `alpha,beta,gamma,delta`;
- `hidden_single`: one file containing internal duplicates
  `[x,y,x,y]` → `x,y`;
- `hidden_three`: three files with cross-file duplicates each with a unique
  line;
- `hidden_blank`: a file `a\n\nb` (blank line inside, no trailing newline)
  → `a`, blank, `b`;
- `hidden_utf8`: UTF-8 lines with a duplicate later in the list;
- `hidden_space`: lines with leading/trailing spaces and an internal space,
  space content preserved and not duplicated wrongly;
- `hidden_all_empty`: every file is empty → empty stdout;
- `hidden_missing` (failure control): one path does not exist — candidate and
  oracle must both exit nonzero and both emit no stdout.

The evaluator checks the source does not contain the forbidden subprocess
boundary, requires that the source references a text-reading API
(`read_text`) so a hard-coded print workaround is classified as a restriction
failure, and checks that `review.md` preserves both required headings and
contains no template placeholders.

## Metrics

Record correctness for all eight cases (including the failure control),
restriction compliance, worker turns, thinking blocks and reasoning tokens,
token buckets, provider cost, tool calls and errors, session wall span,
candidate/oracle wall timing per case, and protocol completion. This eval has
no strict candidate/oracle timing gate; both sides finish in milliseconds on
the small fixture files, so timing is diagnostic until a stable envelope is
established.

## Manager policy

Use one trial by default; the controller-owned `## Trial plan` in the cycle
request may explicitly raise this to two. Classify repeated friction as
handbook guidance or a product issue only when it is generalizable; do not
create a ticket for an ordinary short-task miss or evaluator noise. A handbook
change must name the concept it teaches and be replayed before it is trusted.
Keep a timing or isolation failure separate from a language-correctness
failure.

## CTO review

- Result: `accepted`
- Promotion: `promoted`
- Package: `complete`
- Missing package files: `None.`
- Status: `Approved.`
- Source run: `runs/run-1785801609594/phases/04-eval-design`
