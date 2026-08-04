# Eval task-keyjoin

## Status

Draft.

## Budget breach

None.

## Purpose

Measure a practical systems-administration / data-glue workflow that no
approved eval covers: merging two keyed plain-text files on a shared first
field and emitting a deterministic, byte-exact three-column report with a
left-only sentinel. Existing evals read and rewrite a single file
(`task-propsort`, `task-col2`, `task-total`), aggregate one file into a keyed
summary (`task-groupsum`, `task-logstat`), or do a single typed record lookup
(`task-iniget`). None joins two independent keyed files into one combined
output — the classic `awk`/`join` "map a right table onto a left table" glue
shape (inventory onto hostnames, owners onto packages, labels onto IDs)
expressed as typed XSH values instead of a subprocess pipeline.

## North-star hypothesis

XSH's stated role is practical systems glue; a two-file keyed merge is one of
the most common shell-administration shapes (`join` / `awk`-driven map-onto).
This eval probes whether an agent with the handbook can:

- read two files through the typed text surface (`Path.read_text()` /
  `fs.read_text`), split each line into whitespace fields with `Str.fields()`,
  and skip blank/comment lines with `Str.trim()` / `str.starts_with` — no
  subprocess escape;
- build an immutable keyed Map with `Map.set`, test presence with `Map.has`,
  and read with the `Map.get(key, fallback)` overload;
- iterate the left keys, sort them with the stream `sort-by` stage, and format
  an exact left-outer-join report (`KEY LEFT RIGHT` or `KEY LEFT -`) with a
  final newline and no diagnostics.

A successful run teaches the factory that the read -> split -> Map-build ->
sorted-join -> exact-output pipeline composes cleanly for a real multi-file
workflow, and whether the Map idioms (`.set` immutability, `.has`, sorted
`keys()`) are discoverable together. The design resists task-specific hacks
because hidden cases vary the fixture contents, key order, comment/blank
spacing, tab separators, left-only and right-only presence, and an empty left
file, and because the evaluator requires the source to actually read the two
files and build a typed Map (`Map[`), so a hard-coded answer, a silent empty
result, a subprocess escape, or a solution that never touches the file
contents each fails a distinct gate.

## Task

Create `keyjoin.xsh`. It accepts exactly two file path arguments (a left file
and a right file). Each file contains zero or more data lines of the form

    KEY VALUE

where KEY and VALUE are each a single token (no internal whitespace),
separated by one or more spaces or tabs, and any run of leading/trailing
whitespace is ignored. A line is skipped if it is blank or whitespace-only, or
if its first non-whitespace character is `#` (a comment). Within a file a KEY
is unique; if a KEY repeats, the last occurrence wins.

For every KEY that appears in the left file, print exactly one line:

- if that KEY also appears in the right file:
  `KEY LEFT_VALUE RIGHT_VALUE`
- otherwise:
  `KEY LEFT_VALUE -`

Fields are separated by a single space, lines are sorted in ascending
lexicographic (byte) order by KEY, there are no trailing spaces, the
left-outer-join semantics ignore right-only keys, and the output ends with a
final newline. When the left file has no data keys, print nothing.

The behavior is defined by this oracle command, which the evaluator runs with
the same two paths:

```sh
grep -v '^[[:space:]]*#' "$1" | awk 'NF>=2{print $1"\t"$2}' | sort > /tmp/L
grep -v '^[[:space:]]*#' "$2" | awk 'NF>=2{print $1"\t"$2}' | sort > /tmp/R
join -a 1 -e - -o '1.1 1.2 2.2' /tmp/L /tmp/R
```

Example: a left file

```text
alpha 10
beta 20
gamma 30
```

and a right file

```text
beta X
epsilon Z
```

yield, after sorting, exactly

```text
alpha 10 -
beta 20 X
gamma 30 -
```

(epsilon is right-only and is ignored). The program must read both files
through XSH file/text APIs and combine them with typed Map values; it must not
start subprocesses, invoke an external command, or add diagnostic text to
stdout. Do not hard-code one fixture's result. Complete `review.md` using the
supplied headings.

Use the handbook and `xsht api` as the available XSH reference. A normal
development loop is:

    xsht check keyjoin.xsh
    xsht fmt keyjoin.xsh
    xsht lint keyjoin.xsh
    xsh keyjoin.xsh left.txt right.txt

## Agent boundary

The worker runs as root in a minimal Alpine container with `/work` as its task
workspace. The image provides BusyBox, `xsh`, `xsht`, `curl`, and CA
certificates, and no extra packages: the `sh`/`grep`/`awk`/`sort`/`join`
oracle applets are already in the shared base image, and the file, text, Map,
and stream capabilities are part of `xsh` itself. There is no compiler,
repository checkout, or implementation source. The submitted program may not
use `run`, process APIs, `spawn`, shell commands, or any other subprocess
boundary; it must keep diagnostics off stdout and must not hard-code one
fixture's values.

## Oracle and evaluator

The evaluator runs in a separate read-only container boundary. It writes each
case's left/right fixture files under a writable `/tmp` directory, runs the
candidate (`xsh /work/keyjoin.xsh LEFT RIGHT`) and the oracle
(`sh /tmp/task-keyjoin-oracle.sh LEFT RIGHT`) with the same two paths, and
compares stdout byte-for-byte, recording per-case timing to the run manifest.

Public and hidden cases:

- `public`: a small left/right pair with mixed matches, a left-only key, and a
  right-only key (shown in the task prompt);
- `hidden_comments`: comment and blank lines interspersed, leading/trailing
  whitespace, and multi-space field separators;
- `hidden_tabs`: fields separated by tabs;
- `hidden_left_only`: every left key is missing from the right (all `-`
  sentinels);
- `hidden_right_extra`: the right file has extra keys absent from the left
  (they must be ignored);
- `hidden_single`: a left file with one matching key;
- `hidden_empty_left` (edge): the left file is empty (print nothing).

The evaluator checks that the source does not contain the forbidden subprocess
boundary, requires that the source actually reads file contents (`read_text`)
and builds a typed Map (`Map[`) so a hard-coded or subprocess-hiding
workaround is classified as a restriction failure, and checks that `review.md`
preserves both required headings and contains no template placeholders.

## Metrics

Record correctness for all seven cases, restriction compliance, worker turns,
thinking blocks and reasoning tokens, token buckets, provider cost, tool calls
and errors, session wall span, candidate/oracle timing per case, and protocol
completion. This eval has no strict candidate/oracle timing gate; both sides
finish in milliseconds on the small fixture files, so timing is diagnostic
until a stable envelope is established.

## Manager policy

Use one trial by default; the controller-owned `## Trial plan` in the cycle
request may explicitly raise this to two. Classify repeated friction as
handbook guidance or a product issue only when it is generalizable; do not
create a ticket for an ordinary short-task miss or evaluator noise. A handbook
change must name the concept it teaches and be replayed before it is trusted.
The proposal is promoted into `evals/task-keyjoin/` with a package-owned
`evaluator.xsh`; the CTO approves it after syntax and reference-artifact
checks, and the first paid trial is the integration check for the evaluator's
hidden fixture coverage.

## Staged dry run

The proposal was dry-run in the current cycle: a reference XSH solution
(`keyjoin.xsh` using `Path.read_text()`, `Str.lines()`, `Str.trim()`,
`Str.fields()`, immutable `Map[Str]` with `.set`/`.has`/`.get`, and stream
`sort-by`) was validated with `xsht check` / `fmt` / `lint`, and compared
byte-for-byte against the `sh`/`grep`/`awk`/`sort`/`join` oracle on multiple
fixture pairs (mixed, empty-left, left-only, right-only, tabs, comment
spacing). The proposal's package-owned evaluator was then run in a staged
environment against a simulated `/work` and `/session`: a correct artifact
produced a passing `run.json` with `classification: pass`, and the negative
controls (subprocess escape, missing `Map[` reference, wrong output, missing
`review.md`) were each rejected with the intended classification. The agent
half (a live Pi worker) was not exercised because it requires a paid agent
session and a Pi auth file; the agent path is inherited unchanged from the
approved base image. See `dry-run/` for evidence.

## CTO review

- Result: `rejected`
- Promotion: `promoted`
- Package: `complete`
- Missing package files: `None.`
- Status: `Draft.`
- Source run: `runs/run-1785830554385/phases/02-eval-design`
