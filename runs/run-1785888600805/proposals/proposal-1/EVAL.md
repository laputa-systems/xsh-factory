# Eval task-tailn

## Status

Draft.

## CTO review

- Result: `pending`
- Promotion: `pending`
- Package: `complete`
- Missing package files: `None.`
- Status: `Draft.`
- Source run: `runs/run-1785888600805/proposals/proposal-1`

## Purpose

Measure a practical systems-administration workflow that no current approved
eval covers: reading a multi-line text file through XSH APIs and emitting the
last N lines as a byte-exact output. The approved evals cover CLI value
transforms (task-tags), filesystem walks (task-ecount, task-findexec,
task-bigfiles, task-manifest), environment-rendered config (task-envcfg),
aggregation (task-total, task-intsum, task-wordfreq, task-logstat,
task-groupsum), and whole-file normalizers (task-trim, task-propsort,
task-setdiff, task-uniqcat); none takes an *end-of-stream slice* of a
line-oriented file. `task-tailn` fills that gap with the classic sysadmin shape
"read the last N lines of a log or config file" — the analogue of the `tail`
utility that XSH is meant to make unnecessary for small idioms.

## North-star hypothesis

XSH's stated role is practical systems glue; reading a file as a typed line
stream and taking an end-slice is ordinary glue work. This eval probes whether
an agent with the handbook can:

- discover the `path.lines()?` line stream (or the equivalent `text.lines()` /
  `read_text` path) that brings a multi-line file into typed values without a
  subprocess;
- apply a stream stage such as `drop(count)` — or the `List.len()` / `drop` /
  `take` collection path — to keep only the last N lines;
- respect the edge cases (N = 0 prints nothing, N >= line count prints the
  whole file, blank lines are preserved, UTF-8 content is preserved
  byte-for-byte);
- emit one exact line per entry with a trailing newline and keep stdout free of
  diagnostics.

A successful run teaches the factory whether the file-read, stream-slice, and
exact-output lessons compose into a real "tail a log" tool, and whether an
agent reaches a correct, clear solution without falling back to `tail`, a
subprocess, or a hard-coded answer. The design resists task-specific hacks
because hidden cases vary N (0, 1, beyond the file length), blank lines, UTF-8
content, and the whole-vs-part slice, and because a lost final newline, an
extra blank line, a wrong cut, or an added diagnostic each fails a distinct
gate.

## Task

Create `tailn.xsh`. It accepts two arguments: a path to a UTF-8 text file and a
non-negative integer N. Reads the file's lines and prints the last N lines to
stdout, each selected line followed by a single newline, preserving original
order.

- If N is 0, print nothing and exit 0.
- If N is greater than or equal to the number of lines, print all lines.
- A blank line is a line and is preserved as an empty output line.
- Lines are selected by line count only; interior whitespace and UTF-8 bytes
  are preserved exactly.

The behavior is defined by this oracle, run by the evaluator on the same input
file and N (via the BusyBox `tail` applet already in the shared base image):

```sh
tail -n "$N" "$in"
```

Complete `review.md` using the supplied headings.

## Agent boundary

The worker runs as root in a minimal Alpine container with `/work` as its task
workspace. The image provides BusyBox, `xsh`, `xsht`, `curl`, and CA
certificates, and no extra packages: the `tail` oracle applet is already in
the shared base image, and the `fs` / text line handling is part of `xsh`
itself. There is no compiler, repository checkout, or implementation source.
The submitted program may not use `run`, process APIs, `spawn`, shell
commands, or any other subprocess boundary; it must keep diagnostics off
stdout and must not hard-code one input's contents or ignore the N argument.

## Oracle and evaluator

The evaluator runs in a separate read-only container boundary. It writes a
per-case input file under the evaluator's writable directory and runs the
candidate (`xsh tailn.xsh IN N`) and the oracle (`tail -n N IN`) with the same
input and N, comparing stdout byte-for-byte and writing comparison evidence
plus timings to the run manifest. Public and hidden cases:

- `public`: a small mixed file, N = 2;
- `hidden_zero`: N = 0 (print nothing, exit 0);
- `hidden_whole`: N larger than the line count (print the whole file);
- `hidden_single`: a single-line file, N = 1;
- `hidden_tail_blank`: trailing blank lines selected by N that must be
  preserved as empty output lines;
- `hidden_utf8`: a file whose last lines contain non-ASCII UTF-8 content,
  preserved byte-for-byte;
- `hidden_one_of_many`: N = 1 over several lines (last line only);
- `hidden_empty`: an empty input file, N = 5 (print nothing, exit 0);
- `hidden_restriction` (negative control): a candidate that shells out, ignores
  N, or adds a diagnostic to stdout must fail.

The evaluator checks the source does not contain the forbidden subprocess
boundary, requires that the source actually reads the input file through the
`fs` facade (a text literal or hard-coded output is classified as a
restriction failure), and checks that `review.md` preserves both required
headings and contains no template placeholders.

## Metrics

Record correctness for all cases (including the empty-result and negative
controls), restriction compliance, worker turns, thinking blocks and reasoning
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
On approval, stage `evals/task-tailn/` with this scaffolding, including its
package-owned `evaluator.xsh`. The generic evaluator protocol stages and
mounts that script; do not add a task branch to `evaluate_common.xsh`.
