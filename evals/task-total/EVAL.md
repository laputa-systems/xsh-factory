# Eval task-total

## Status

Draft.

## Purpose

Measure a practical numeric-aggregation systems workflow: reading a
line-oriented text file through XSH text APIs, splitting it into fields,
parsing signed decimal integers from text, accumulating a count and a sum with
immutable-update discipline, and producing a byte-exact two-line summary while
failing cleanly on malformed input. This is a small reporting/accounting task
(the kind a sysadmin faces when totaling sizes, counts, or amounts) distinct
from simpler verbatim field extraction and the filesystem walk of
`task-ecount`.

## North-star hypothesis

An agent that has internalised the XSH handbook should read a file, split
lines and fields, parse numbers, accumulate a result, and emit an exact
summary with little exploratory friction — the same "small script that grows
into a tool" glue the language is meant to enable. The eval exposes whether
text parsing plus numeric conversion plus accumulation is easy to discover and
combine, and whether an agent reaches a correct, clear solution without
falling back to a subprocess or a hard-coded answer.

What a successful result would teach: that XSH's explicit text/number
boundaries (instead of shell's implicit typing) let an agent turn a row of
`awk`-shaped work into a typed program. Resisting task-specific hacks:

- the file argument and several distinct/negative/blank/unicode hidden inputs
  rule out a hard-coded summary;
- a malformed/missing-file failure contract and a no-subprocess boundary
  force real validation through XSH values rather than shelling out;
- the summary must be byte-exact (`count=…`, `total=…`, final newline), so a
  clear, complete solution is required, not just a plausible one.

A general improvement shows up as a short, idempotent, tool-shaped program; a
task-specific workaround would be fragile across the hidden inputs and would
violate the no-subprocess or exact-output contract.

## Task

Create `total.xsh`. It accepts one file argument and prints a two-line summary
of the numeric values found in that file:

```text
count=<number of valid rows>
total=<sum of the values>
```

Rules:

- Each line of the file is split into whitespace-separated fields.
- A blank line (no fields) is ignored.
- Every other (non-blank) line must contain exactly two fields: a NAME and a
  VALUE.
- VALUE (the second field) must be a decimal integer, optionally preceded by a
  single `-` sign (for example `42`, `-3`, `0`, `007`).
- A non-blank line with anything other than exactly two fields, or a VALUE
  that is not such an integer, is invalid: the program must exit nonzero and
  print nothing.
- If the file cannot be read, the program must exit nonzero and print nothing.
- count is the number of valid rows; total is the sum of their numeric values.
- Print exactly two lines (`count=N`, `total=S`) followed by a final newline.
  Print nothing else.

The program must read the file through XSH text APIs, split and parse it
through XSH values, and must not start subprocesses or invoke an external
command (including `awk`, `sh`, `sort`, or `wc`). The evaluator supplies
several different files, so do not hard-code one summary.

Use the handbook and the available `xsht` checks as the reference. A normal
development loop is:

    xsht check total.xsh
    xsht fmt total.xsh
    xsht lint total.xsh
    xsh total.xsh data.txt

## Agent boundary

The worker runs as root in a minimal Alpine container with `/work` as its task
workspace. The image provides BusyBox, `xsh`, `xsht`, `curl`, and CA
certificates; there is no compiler, repository checkout, or implementation
source. The submitted `total.xsh` may not start subprocesses or invoke
external commands (`run`, process APIs, `spawn`, or any shell command) and must
keep diagnostics off stdout. The evaluator runs in a separate read-only
container boundary so the worker cannot inspect the oracle or the hidden
fixtures.

## Oracle and evaluator

The evaluator is the package-owned `evaluator.xsh`. For each case it creates a
fixture file (or a missing path), runs the candidate with
`xsh total.xsh FILE`, and runs the external oracle against the same fixture.
The oracle is a BusyBox-`sh` script:

```sh
awk 'NF == 0 { next }
NF != 2 { error = 1 }
$2 !~ /^-?[0-9]+$/ { error = 1 }
error == 0 { count++; total += $2 }
END { if (error) exit 1; printf "count=%d\ntotal=%d\n", count, total }' "$1"
```

A case passes only when the candidate stdout is byte-for-byte equal to the
oracle stdout and both exit codes agree. For the invalid/missing cases, both
must exit nonzero and print nothing. The evaluator also checks the no-subprocess
restriction (self-contained source scan for `process.`/`spawn `/`run `,
mirroring the factory control helper), that the source reads the file through
`read_text`, and that `review.md` preserves both required headings. Results are
written to `/session/run.json`.

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
reporting shape; do not open a ticket for an ordinary short-task miss or
evaluator noise. A handbook change must name the concept it teaches and be
replayed on a nearby numeric-aggregation case before it is trusted, and must
not be auto-promoted (see the handbook ledger).

## Staged dry run

Run the package-owned evaluator against a correct reference `total.xsh` for a
representative subset (public, blank, negative, zero, unicode-name, single
row, empty file, and the malformed/missing failure controls) plus one
deliberately wrong candidate to prove the evaluator distinguishes pass from
fail. Save the evidence and ephemeral fixture/oracle outputs under the run
directory.

## CTO review

- Result: `rejected`
- Promotion: `promoted`
- Package: `complete`
- Missing package files: `None.`
- Status: `Draft.`
- Source run: `runs/run-1785787490432/phases/02-eval-design`
