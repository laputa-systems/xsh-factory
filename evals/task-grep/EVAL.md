# Eval task-grep

## Status

Approved.

## Purpose

Measure a practical line-oriented text-search systems workflow: reading a
file's text through XSH APIs, streaming its lines, filtering by a byte-exact
literal substring match, annotating each hit with its 1-based line number, and
producing a byte-exact `N:text` stdout contract. This is the classic
sysadmin/log-diagnosis shape "replace `grep -nF` with a typed XSH program",
distinct from the verbatim field extraction of `task-col2`, the set difference
of `task-setdiff`, and the numeric aggregation of `task-total`.

## North-star hypothesis

An agent that has understood the XSH handbook should read a file, stream its
lines, filter on a literal substring, and emit an exact line-numbered report
with little exploratory friction — ordinary text-glue work XSH is meant to
make humane. The eval exposes whether the explicit line-stream boundaries
(`text.lines`, `enumerate`, `where`/`contains`) compose into a correct, clear
program without falling back to a subprocess or a hard-coded answer.

What a successful result would teach: that XSH's typed, explicit text pipeline
(the modern analogue of `grep`'s implicit regex/line contract) lets an agent
turn a search-and-report task into a small readable program. Resisting
task-specific hacks:

- several hidden patterns, including an empty pattern, a regex-meta character
  treated as a literal, a case-sensitivity check, and leading/trailing-space
  lines, rule out hard-coding one result;
- a no-match empty-output case and a missing-file failure contract force real
  behaviour through XSH values rather than a canned answer;
- the no-subprocess boundary and the byte-exact `N:text` (including the final
  newline and exact line text) require a complete, correct solution.

A general improvement shows up as a short, reusable, tool-shaped program; a
task-specific workaround would be fragile across the hidden patterns and would
violate the no-subprocess or exact-output contract.

## Task

Create `grep.xsh`. It accepts two arguments, a PATTERN and a FILE path, and
prints each line of FILE that contains PATTERN as a byte-for-byte literal
substring, prefixed with its 1-based line number and a colon:

```text
LINE: text of that line
```

Rules:

- PATTERN is a literal substring. It is not a regular expression; regex
  metacharacters such as `.` match themselves.
- Lines are numbered starting at 1, from the first line of the file.
- A blank line is still a line and is numbered and printed if it contains the
  pattern.
- A line that contains the pattern is printed once with its line number.
- Preserve each matched line's text exactly, including leading and trailing
  spaces, and print `N:text` followed by a final newline per match.
- If no line contains the pattern, print nothing and exit successfully.
- If the file cannot be read, exit nonzero and print nothing.
- Output order is file order.

The program must read the file through XSH text APIs, filter and number the
lines through XSH values, and must not start subprocesses or invoke an
external command (including `grep`, `sh`, `awk`, or `sed`). The evaluator
supplies several PATTERN/FILE combinations, so do not hard-code one result.

Use the handbook and the available `xsht` checks as the reference. A normal
development loop is:

    xsht check grep.xsh
    xsht fmt grep.xsh
    xsht lint grep.xsh
    xsh grep.xsh quick data.txt

## Agent boundary

The worker runs as root in a minimal Alpine container with `/work` as its task
workspace. The image provides BusyBox, `xsh`, `xsht`, `curl`, and CA
certificates; there is no compiler, repository checkout, or implementation
source. The submitted `grep.xsh` may not start subprocesses or invoke external
commands (`run`, process APIs, `spawn`, or any shell command) and must keep
diagnostics off stdout. The evaluator runs in a separate read-only container
boundary so the worker cannot inspect the oracle or the hidden fixtures.

## Oracle and evaluator

The evaluator is the package-owned `evaluator.xsh`. For each case it writes a
fixture file (or omits it for the missing-file failure control), runs the
candidate with `xsh grep.xsh PATTERN FILE`, and runs the external `grep -nF`
oracle with `sh` against the same fixture and pattern. The oracle is BusyBox
`grep -nF "$pattern" "$file"`, run with `LC_ALL=C`.

A case passes when:

- for a normal case, the candidate stdout is byte-for-byte equal to the oracle
  stdout and the candidate exits successfully (the oracle may exit 1 with
  empty output for a genuine no-match; both must print nothing);
- for the missing-file control, both the candidate and the oracle exit nonzero
  and both print nothing to stdout.

The evaluator also checks the no-subprocess restriction (self-contained source
scan for `process.`/`spawn `/`run `, mirroring the factory control helper),
that the source reads the file through `read_text`, and that `review.md`
preserves both required headings. Results are written to the session
`run.json`.

## Metrics

Record correctness per case and overall, restriction compliance, protocol
completion (review.md headings), worker turns, thinking blocks and reasoning
tokens, token buckets, provider cost, tool calls and errors, session wall
span, and candidate/oracle timing. This eval has no strict candidate/oracle
timing gate; timing is diagnostic until a stable envelope is established.

## Manager policy

Use one trial by default; the controller-owned `## Trial plan` in the cycle
request may explicitly raise this to two. Classify repeated friction as
handbook guidance or a product issue only when it generalises beyond this
search shape; do not open a ticket for an ordinary short-task miss or
evaluator noise. A handbook change must name the concept it teaches and be
replayed on a nearby text-search case before it is trusted, and must not be
auto-promoted (see the handbook ledger).

## Staged dry run

Run the package-owned evaluator against a correct reference `grep.xsh` for a
representative subset (public, empty pattern, no-match empty output,
case-sensitivity, regex-meta literal, leading/trailing-space lines, unicode,
and the missing-file failure control) plus one deliberately wrong candidate to
prove the evaluator distinguishes pass from fail. Save the evidence and
ephemeral fixture/oracle outputs under the run directory.

## CTO review

- Result: `pending`
- Promotion: `not-promoted`
- Package: `complete`
- Missing package files: `None.`
- Status: `Draft.`
- Source run: `runs/run-1785795835208/phases/02-eval-design`

## CTO review

- Result: `accepted`
- Promotion: `promoted`
- Package: `complete`
- Missing package files: `None.`
- Status: `Approved.`
- Source run: `runs/run-1785795835208/phases/02-eval-design`
