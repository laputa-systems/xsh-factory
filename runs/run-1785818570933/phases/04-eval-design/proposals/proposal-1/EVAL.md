# Eval task-logstat

## Status

Draft.

## Budget breach

None.

## Purpose

Measure a practical systems-administration workflow: parsing a structured
text log, extracting one whitespace-delimited field, filtering noise, counting
occurrences with a typed map, and emitting an exact, sorted report. This is the
"status-code histogram from an HTTP access log" shape that operators reach for
daily, and it exercises a different boundary than the existing tree-walking
`task-ecount` or the single-transform `task-envcfg`.

## North-star hypothesis

An agent that has internalized the XSH handbook should replace the classic
`awk | grep | sort | uniq -c` histogram pipeline with a short, typed XSH
program: read a file, split each line on a literal separator, take one field,
filter to digit-only codes, count, and sort. The eval probes whether the
handbook makes whitespace-field extraction, the `delete`-based digit test, the
standard-library counting path, and sorted output easy to discover and combine.
A successful result teaches the factory whether log-shaped text processing is a
smooth, AI-efficient XSH workflow rather than a subprocess escape. The design
resists task-specific hacks because every case is a distinct file the evaluator
supplies by path: a hard-coded histogram would fail the variable distributions,
counts, and sort order, and the no-subprocess restriction rules out shelling
out to `awk`/`sort`/`uniq`.

## Task

Create `logstat.xsh`. It accepts one argument naming a log file and prints a
histogram of HTTP status codes from that file.

Each line of the file is in the standard combined HTTP log format with exactly
one ASCII space between top-level fields:

```text
10.0.0.1 - - [10/Oct/2000:13:55:36 -0700] "GET /index.html HTTP/1.0" 200 2326
```

- The HTTP status code is the 9th whitespace-separated field (0-indexed field
  8). Every real line in the supplied files has at least 9 fields.
- Count each status code that consists only of decimal digits. A line whose
  9th field is non-numeric (for example a `4xx` placeholder) is ignored; it
  contributes no count.
- Print exactly one line per distinct numeric status code present:

```text
CODE count
```

  with a single space between the code and its count, codes sorted ascending
  (all real status codes are three digits, so ISO/ASCII ascending order is
  numeric ascending). Do not add leading zero-padding, alignment, or extra
  text.
- If no numeric status code is present, print nothing and exit successfully.

The evaluator supplies several log files by path and compares stdout
byte-for-byte with an external `awk`/`sort` oracle. Do not hard-code any
specific code list, count, or filename.

The program must read the file through XSH text APIs and perform the
splitting, filtering, counting, and sorting with typed XSH values. It must not
start subprocesses or invoke an external command (including `awk`, `grep`,
`sort`, `uniq`, or `sh`) and must keep diagnostics off stdout.

Use the handbook and the available `xsht` checks as the reference. A normal
development loop (create a small sample file in `/work` to try):

    xsht check logstat.xsh
    xsht fmt logstat.xsh
    xsht lint logstat.xsh
    xsh logstat.xsh sample.log

## Agent boundary

The worker runs as root in a minimal Alpine container with `/work` as its task
workspace. The image provides BusyBox, `xsh`, `xsht`, `curl`, and CA
certificates. It has no compiler, repository checkout, or implementation
source. The submitted program may not start subprocesses or invoke external
commands and must keep diagnostics off stdout. The evaluator runs in a
separate read-only container boundary so the worker cannot inspect the oracle
harness.

## Oracle and evaluator

The evaluator runs in a read-only boundary with `/work` mounted read-only
(candidate `logstat.xsh`), `/session` and `/export` write views, and a
writeable `/tmp`. It writes each case's access-log fixture to `/tmp`, then
invokes the candidate `xsh /work/logstat.xsh <fixture>` and the external
oracle on the same fixture and compares stdout byte-for-byte. The oracle is:

```sh
awk '{print $9}' "$1" | grep -E '^[0-9]+$' | sort -n | uniq -c | awk '{printf "%d %d\n", $2, $1}'
```

The evaluator checks that the candidate source neither starts subprocesses nor
uses `process.*`/`run`/`spawn`, that the artifact exists, and that `review.md`
preserves both required headings. It records each case's candidate and oracle
wall time and a per-case exact-match flag.

Hidden cases (beyond the public one):
- distinct code set and ordering (sort proof);
- a single repeated code;
- a file with several codes and uneven duplicate counts;
- many distinct codes to exercise histogram breadth;
- an empty file (must print nothing);
- a file mixing numeric and non-numeric (e.g. `4xx`) 9th fields (noise filter);
- a file with no matching numeric code (must print nothing).

Failure classification separates a missing artifact, a missing/incomplete
`review.md`, a forbidden-subprocess violation, a candidate correctness miss,
and a clean pass.

## Metrics

Record correctness per case (and all-exact), restriction compliance, worker
turns, thinking blocks and reasoning tokens, token buckets, provider cost,
tool calls and errors, session wall span, and candidate/oracle timing per
case. This eval has no strict candidate/oracle timing gate; timing is
diagnostic until a stable envelope is established.

## Manager policy

Use one trial by default; the controller-owned `## Trial plan` in a cycle
request may raise this to two. Classify repeated friction as handbook guidance
or a product issue only when it is generalizable; do not create a ticket for an
ordinary short-task miss or evaluator noise. A handbook change must name the
concept it teaches and be replayed with the same oracle before it is trusted.

## Staged dry run

The proposal was staged under the current eval-design run and dry-run evidence
was preserved there: a representative candidate was run against a public file,
a distinct-order file, a malformed-field file, and an empty file and produced
byte-identical output to the external oracle, and the candidate passed
`xsht check`, `xsht fmt`, and `xsht lint`.
