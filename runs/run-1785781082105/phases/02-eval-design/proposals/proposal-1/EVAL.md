# Eval task-setdiff

## Status

Draft.

## Budget breach

None.

## Purpose

Measure a practical systems-administration / config-drift / package-reconcile
workflow that no approved eval covers: reading two line-oriented files through
XSH text APIs, treating each file as a set of unique lines, and emitting the
set difference (`lines in file A that are not in file B`) as a
byte-exact, sorted stdout contract. `task-tags` transforms argv values,
`task-ecount` traverses the filesystem, `task-envcfg` renders a config file
from scalar environment variables, `task-col2` extracts a field per line,
`task-dupcheck` hashes and groups files, and `task-jsonfilter` crosses a JSON
boundary; none builds sets / deduplicates a line stream and none reports a
deterministic set difference. `task-setdiff` fills that gap with the classic
sysadmin shape "replace `comm -23 <(sort -u A) <(sort -u B)` with a typed XSH
program."

## North-star hypothesis

XSH's stated role is practical systems glue; `comm` / `sort` / `sort -u` are
archetypal glue primitives XSH intends to make unnecessary for small idioms.
This eval probes whether an agent with the handbook can:

- discover the file-content surface (`fs.read_text` / `Path.read_text`) and
  the line stream (`Str.lines`) via `xsht api`;
- model an unordered, duplicate-free collection with the `set` module
  (`set.from`, `set.has`, `Map.keys`) instead of ad hoc string tricks;
- compose a pipeline that filters by set membership and sorts deterministically
  (`sort-by`) into one byte-exact result;
- handle the empty-line edge case correctly: a blank line inside a file is a
  real member, while a final trailing newline adds no extra line;
- propagate a missing-file failure with postfix `?` so a bad input path exits
  nonzero instead of fabricating partial output.

A successful run teaches the factory whether the `set` module and the
`Str.lines` edge semantics are discoverable and composable for a real
reconciliation task. The design resists task-specific hacks because hidden
cases vary which lines appear in each file, their order, duplication, blank
and UTF-8 content, and because the failure controls require a loud nonzero
exit — a hard-coded answer, a wrong dedup/sort, or a subprocess escape each
fail a distinct gate.

## Task

Create `setdiff.xsh`. It accepts two file-path arguments, `fileA` and `fileB`,
and prints to stdout every unique line that appears in `fileA` but not in
`fileB`, sorted in byte (lexicographic) order, one per line. The sorted,
deduplicated output must match byte-for-byte the evaluator's oracle, which is
exactly this BusyBox-`sh`-compatible script run with the two input paths
(temp files avoid bash-only process substitution):

```sh
LC_ALL=C sort -u "$1" > /tmp/sa.$$
LC_ALL=C sort -u "$2" > /tmp/sb.$$
comm -23 /tmp/sa.$$ /tmp/sb.$$
rm -f /tmp/sa.$$ /tmp/sb.$$
```

A line is a run of characters ending at a newline; a blank line between two
newlines is a real member, while a final trailing newline does not create an
extra line. When either input file cannot be read, the program must exit
nonzero and must not print fabricated output. Complete `review.md` using the
supplied headings.

The program must read the files through XSH text APIs and produce set
difference through XSH values. It must not start subprocesses, invoke an
external command (including `comm`, `sort`, or `awk`), or add diagnostic text
to stdout. Do not hard-code one pair of input files' contents.

Use the handbook and `xsht api` as the available XSH reference. A normal
development loop is:

    xsht api api:fs.read_text
    xsht api api:set.from
    xsht api language:stream.sort-by
    xsht check setdiff.xsh
    xsht fmt setdiff.xsh
    xsht lint setdiff.xsh
    xsh setdiff.xsh A.txt B.txt

## Agent boundary

The worker runs as root in a minimal Alpine container with `/work` as its task
workspace. The image provides BusyBox, `xsh`, `xsht`, `curl`, and CA
certificates, and no extra packages: the `comm` / `sort` oracle applets are
already in the shared base image, and the `fs`, `set`, `text`, and `stream`
surfaces are part of `xsh` itself. There is no compiler, repository checkout,
or implementation source. The submitted program may not use `run`, process
APIs, `spawn`, shell commands, or any other subprocess boundary; it must keep
diagnostics off stdout and must not hard-code one configuration's lines.

## Oracle and evaluator

The evaluator runs in a separate read-only container boundary. For each
success case it writes the two input files into the evaluator's writable
area, runs the candidate (`xsh setdiff.xsh fileA fileB`) and the portable oracle
described above (two `sort -u` temp files merged by `comm -23`) on identical
inputs, and compares stdout byte-for-byte, writing the comparison evidence
and timings to the run manifest. Cases:

- `public`: `fileA = b,a,c,d`; `fileB = a,c`;
- `hidden_disjoint`: no common lines;
- `hidden_all_in_b`: every line of A also in B (empty output);
- `hidden_b_empty`: only `fileB` has content (all of A emitted);
- `hidden_a_empty`: only `fileA` has content (empty output);
- `hidden_duplicates`: repeated lines in both files (dedup required);
- `hidden_utf8_spaces`: lines with spaces and UTF-8 content;
- `hidden_unsorted`: both files unsorted (deterministic sorted output);
- `hidden_blank_lines`: an interior blank line is a real member.

Failure controls (candidate-only contract, not oracle-matched, because the
`comm` oracle does not propagate a missing-file failure): `missing_a` and
`missing_b` — the candidate must exit nonzero and must not print fabricated
output when one input path does not exist.

The evaluator checks the source does not contain the forbidden subprocess
boundary and that it references the `set` module or `set.from` (so a naive
string/`awk` workaround is classified as a restriction failure), and checks
that `review.md` preserves both required headings and contains no template
placeholders.

## Metrics

Record correctness for all ten success cases, the two failure controls,
restriction compliance, worker turns, thinking blocks and reasoning tokens,
token buckets, provider cost, tool calls and errors, session wall span,
candidate/oracle timing per case, and protocol completion. This eval has no
strict candidate/oracle timing gate; both sides finish in milliseconds, so
timing is diagnostic until a stable envelope is established.

## Manager policy

Use one trial by default; the controller-owned `## Trial plan` in the cycle
request may explicitly raise this to two. Classify repeated friction as
handbook guidance or a product issue only when it is generalizable; do not
create a ticket for an ordinary short-task miss or evaluator noise. A handbook
change must name the concept it teaches (for example the `set` module or
`Str.lines` trailing-newline semantics) and be replayed before it is trusted.
On approval, stage `evals/task-setdiff/` with this scaffolding, including its
package-owned `evaluator.xsh`. The generic evaluator protocol stages and
mounts that script; do not add a task branch to `evaluate_common.xsh`.

## Staged dry run

The proposal was dry-run in the current cycle: a reference XSH solution
(`setdiff.xsh` using `fs.read_text`, `Str.lines`, `set.from` / `set.has`, and
`sort-by`) was checked with `xsht check` / `fmt` / `lint`, then compared
byte-for-byte against the `comm -23 <(sort -u ...)` oracle on all ten success
cases plus the two missing-file failure controls under
`runs/run-1785781082105/phases/02-eval-design/proposals/proposal-1/dry-run/`.
All success cases matched and both failure controls exited nonzero. Negative
controls (hard-coded output, no-`set.` workaround, subprocess escape, missing
`review.md`) are rejected by the evaluator's restriction and heading checks.
The agent half (a live Pi worker) was not exercised because it requires a paid
agent session and a Pi auth file; the agent path is inherited unchanged from
the approved base image. See `dry-run/DRY-RUN.md` for evidence.
