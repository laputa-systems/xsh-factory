# Eval task-cutoff

## Status

Draft.

## Purpose

Measure a practical systems-administration / data-glue workflow that no
approved eval covers: filtering the rows of a usage-oriented file by a typed
numeric threshold supplied on the command line, while preserving the original
line text. `task-ecount` groups and counts extensions, `task-bigfiles` ranks
files by a per-file size, `task-total` sums a numeric field, `task-groupsum`
aggregates by key, `task-wordfreq` counts tokens, and `task-logstat` builds a
status histogram; none filters records by comparing a **parsed integer field
against a CLI-supplied threshold** while emitting the original lines unchanged.
`task-cutoff` targets the classic "show me everything above a threshold"
shape that operators reach for when trimming disk usage, port ranges, or size
reports.

## North-star hypothesis

XSH's role is practical, typed systems glue, and threshold filtering over a
tabular text file is a first-class `awk`-style composition. This eval probes
whether an agent with the handbook can:

- read a file through the typed text APIs (`fs.read_text`) and split it into
  lines and whitespace-separated fields;
- parse a `Str` field into an `Int` through the typed conversion boundary and
  propagate a non-integer file value with postfix `?` so the program exits
  nonzero and prints nothing (a strict validation gate);
- parse the CLI `THRESHOLD` argument the same way and compare it against each
  field value;
- filter the rows with a clear value-based stage while preserving each
  original line byte-for-byte (leading whitespace and extra fields intact);
- keep the whole transformation in XSH values with no subprocess escape.

A successful run teaches the factory whether the typed `parse_int` boundary
and a numeric `where`-style filter over line fields are discoverable and
composable, and whether the strict "exit nonzero, print nothing on any invalid
row" contract transfers cleanly to a thresholding report. The design resists
task-specific hacks because hidden cases vary the field layout, ordering,
leading whitespace, value magnitude, emptiness, and the failure control
(an invalid row and a non-integer threshold must each fail loudly).

## Task

Create `cutoff.xsh`. It accepts two arguments:

    cutoff.xsh INPUT THRESHOLD

It reads the UTF-8 text file `INPUT` and prints, in original order, each line
whose second whitespace-delimited field is a non-negative decimal integer that
is greater than or equal to `THRESHOLD`. Each printed line is the **original
line exactly as written** (leading whitespace and any extra trailing fields
preserved), followed by a newline.

Rules:

- Whitespace means spaces and tabs: leading whitespace before the first field
  is skipped, and runs of whitespace between fields count as one separator.
- A blank line (no fields) is ignored and is not printed.
- Every other (non-blank) line must contain at least two fields, and its
  second field must be a non-negative decimal integer (a run of digits, for
  example `0`, `7`, `100`, `042`). If any non-blank line has fewer than two
  fields, or its second field is not a run of digits, the program must exit
  nonzero and print nothing.
- `THRESHOLD` must be a non-negative decimal integer. If it is not, the
  program must exit nonzero and print nothing.
- If `INPUT` cannot be read, the program must exit nonzero and print nothing.
- The program must read the file through XSH text APIs and perform the
  splitting and comparison through XSH values. It must not start subprocesses,
  invoke an external command, add diagnostic text to stdout, or modify the
  input file. The evaluator supplies several different input files, so do not
  hard-code one result.

The behavior is defined by this oracle, run by the evaluator with the same
`INPUT` and `THRESHOLD`:

```sh
in="$1"; t="$2"
# THRESHOLD must be a non-negative decimal integer.
case "$t" in ''|*[!0-9]*) exit 1 ;; esac
# Validation pass: any non-blank, non-<2-field, non-digit-second-field line is fatal.
awk -v t="$t" 'NF==0 {next} NF<2 || $2 !~ /^[0-9]+$/ {exit 1}' "$in" || exit 1
# Emit pass: print each line whose second field integer is >= THRESHOLD.
awk -v t="$t" 'NF>=2 && $2+0 >= t {print}' "$in"
```

The evaluator invokes the candidate equivalently to `xsh cutoff.xsh INPUT
THRESHOLD` and compares stdout byte-for-byte, and requires both processes to
agree on the exit status (both succeed on valid rows; both exit nonzero and
print nothing on the failure controls).

## Agent boundary

The worker runs as root in a minimal Alpine container with `/work` as its task
workspace. The image provides BusyBox utilities (including `awk` and `sh` for
the oracle), `xsh`, `xsht`, `curl`, and CA certificates, and no extra
packages: the `fs`, text, and stream modules are part of `xsh` itself. There
is no compiler, repository checkout, or implementation source. The submitted
program may not use `run`, process APIs, `spawn`, shell commands, or any other
subprocess boundary; it must keep diagnostics off stdout and must not hard-code
one input's rows.

## Oracle and evaluator

The evaluator runs in a separate read-only container boundary. It stages a
distinct fixture file in a writable `/tmp` for each case, runs the candidate
and the oracle with identical `INPUT` and `THRESHOLD`, compares stdout
byte-for-byte, checks that both exit statuses agree, and writes the comparison
evidence plus timings to the run manifest. Public and hidden cases:

- `public`: a small 4-row file, `THRESHOLD=5` — mix of passing and failing
  values, plus leading whitespace on a passing row;
- `hidden_default`: a 7-row file with `THRESHOLD=3` — several rows pass;
- `hidden_zero`: a file with `THRESHOLD=0` — every valid row passes;
- `hidden_high`: a file with a large threshold — no rows pass, empty output;
- `hidden_leading`: rows with varying leading whitespace/run of spaces preserved
  on the printed lines;
- `hidden_extra`: rows that carry a third trailing field, which must be
  preserved on the printed line;
- `hidden_leading_zero`: values written like `007` that must compare
  numerically as `7`;
- `hidden_empty`: a file with only blank lines — prints nothing, exit 0;
- `hidden_invalid_row` (failure control): a non-blank row with fewer than two
  fields, or a second field that is not digits — candidate and oracle both
  exit nonzero and print nothing;
- `hidden_bad_threshold` (failure control): `THRESHOLD=abc` — both exit
  nonzero and print nothing;
- `hidden_missing` (failure control): `INPUT` does not exist — both exit
  nonzero and print nothing.

The evaluator checks the source does not contain the forbidden subprocess
boundary, requires that the source references the text/file read module and an
integer parse path (so a hard-coded answer is classified as a restriction
failure), and checks that `review.md` preserves both required headings and
contains no template placeholders.

## Metrics

Record correctness for all eleven cases (including the three failure
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
On approval, stage `evals/task-cutoff/` with this scaffolding, including its
package-owned `evaluator.xsh`. The generic evaluator protocol stages and
mounts that script; do not add a task branch to `evaluate_common.xsh` or
`evaluate_legacy.xsh`.

## Staged dry run

See `dry-run/DRY-RUN.md` in this proposal. A reference `cutoff.xsh` and the
external `awk` oracle were exercised on the host across the public case, the
hidden cases, and the three failure controls; the reference byte-matched the
oracle on every passing case, both exited nonzero with empty stdout on every
failure control, and the oracle's TMPDIR fixture layout was checked to make
sure no artifact was written into the input tree. The reference program also
passes `xsht check`, `fmt`, and `lint`. The container isolation and the
package-owned evaluator wiring are inherited unchanged from the approved
scaffold and were not re-run end-to-end in a container this cycle (the shared
`/usr/local/lib/xsh-factory` evaluator path is a container-only surface).

## CTO review

- Result: `pending`
- Promotion: `pending`
- Package: `complete`
- Missing package files: `None.`
- Status: `Draft.`
