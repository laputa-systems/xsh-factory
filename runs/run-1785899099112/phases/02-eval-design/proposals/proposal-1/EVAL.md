# Eval task-svcstat

## Status

Draft.

## Budget breach

None.

## Purpose

Measure a practical systems-administration workflow that no current eval
covers: aggregating request statistics across many log files into a single
per-service report with both a count and a summed numeric field. `task-bigfiles`
ranks files by a per-file numeric attribute, `task-ecount` groups and counts
extension values, `task-groupsum` sums one numeric column over keyed rows, and
`task-jsonfilter` crosses a JSON boundary; none discovers many files, parses a
line-oriented keyed record, and reduces each key to a **count plus a summed
integer** through XSH stream aggregation before emitting a sorted byte-exact
report. `task-svcstat` targets the canonical "collectd/syslog → per-service
rollup" shape — the modern XSH analogue of a `find | awk '{c[$1]++; s[$1]+=$2} END{...}' | sort`
pipeline.

## North-star hypothesis

XSH's stated role is practical systems glue, and a keyed, accumulating rollup
across a file tree is first-class typed stream work. This eval probes whether
an agent with the handbook can:

- discover every `.log` file under a recursive root with the typed filesystem
  stream (`fs.files`) and keep only regular files whose name ends in `.log`;
- transform each line into a structured `(service, duration)` record, skip
  blank lines, and validate that a non-blank line is exactly two
  space-separated fields with a decimal-digit integer in the second column;
- reduce the record stream by a projected key (`group-by`) and, within each
  group, compute both the item count and a summed integer duration (an
  accumulator `fold`), i.e. stateful aggregation of a stream;
- impose a strict failure control: any malformed non-blank line must make the
  program exit nonzero with empty stdout, rejecting a lenient partial-report
  one-liner;
- emit a byte-exact `<service> <count> <total>` report sorted by service name,
  with no subprocess escape and no hard-coded output.

A successful run teaches the factory whether stream grouping plus an
accumulator fold (count + sum per key) is discoverable and composable, and
whether the strict-validation / Result idiom transfers to an aggregation
boundary where a single bad record must suppress the whole report.

## Difficulty justification

This task combines at least two independent XSH data transformations **and** a
stateful aggregation, exceeding the ecount minimum bar:

1. **Line parsing / validation transformation** — every non-blank line is split
   into exactly two space-separated fields, the duration field is validated as
   a decimal-digit integer, and blank lines are filtered. This is independent
   of the discovery step that surfaces the raw text.
2. **Stateful aggregation** — the stream of `(service, duration)` records is
   grouped by the service key (`group-by`); within each group an accumulator
   `fold` computes the summed duration while the item count is taken from the
   group length. This is a per-key reduction over an unbounded number of
   records across many files, not a per-file one-shot output.
3. **Output transformation** — the aggregated groups are sorted ascending by
   service name and formatted as a byte-exact `<service> <count> <total>`
   report.

Meaningful failure control: a single malformed non-blank line anywhere in the
tree must make the program exit nonzero with empty stdout. This forces the
candidate to validate the full input before emitting and punishes lenient
count-and-print one-liners that ignore format errors or emit partial output.

Hidden cases that defeat one-liners or hard-coded answers: every fixture is a
distinct tree with different service names, request counts, durations, file
counts, and directory depth, so a hard-coded report fails every hidden case;
hidden cases requiring recursive discovery, cross-file aggregation, blank-line
filtering, and a malformed-line strict failure each punish a narrow one-liner
that handles only one aspect. This is at least ecount-level: it requires typed
filesystem traversal plus multi-field parsing, keyed reduction (count + sum),
deterministic sorting, an exact-output oracle, a strict failure control, and a
no-subprocess restriction.

## Task

Create `svcstat.xsh`. It accepts one root directory:

    svcstat.xsh ROOT

It recursively finds every regular file below `ROOT` whose name ends in
`.log`, reads them, and prints a per-service rollup sorted by service name:

    SERVICE COUNT TOTAL

`SERVICE` is a non-empty ASCII token with no spaces; `COUNT` is the number of
request lines for that service; `TOTAL` is the sum of the integer durations
(milliseconds) for that service. Blank (all-whitespace) lines are ignored. Any
non-blank line that is not exactly two space-separated fields with a
decimal-digit integer in the second field is a hard parse failure: the program
must print nothing to stdout and exit nonzero. If no `.log` file exists or no
non-blank lines remain, print nothing and exit zero. The program must discover
the tree and aggregate through XSH filesystem and stream values; it must not
start subprocesses, invoke an external command, or add diagnostic text to
stdout. Complete `review.md` using the supplied headings.

The behavior is defined by this oracle, run by the evaluator with the same `ROOT`
against a writable fixture tree it stages in `/tmp`:

```sh
find "$root" -type f -name '*.log' | sort | while IFS= read -r f; do cat "$f"; done |
awk '
  /^[ \t]*$/ { next }
  { n = split($0, a, " ");
    if (n != 2) { bad = 1; next }
    if (a[1] == "") { bad = 1; next }
    if (a[2] !~ /^[0-9]+$/) { bad = 1; next }
    cnt[a[1]]++; sum[a[1]] += a[2] }
  END { if (bad) exit 1
        for (s in cnt) printf "%s %d %d\n", s, cnt[s], sum[s] }' |
sort -k1,1
```

The evaluator invokes the candidate equivalently to `xsh svcstat.xsh ROOT` and
compares its stdout byte-for-byte with the oracle's stdout.

## Agent boundary

The worker runs as root in a minimal Alpine container with `/work` as its task
workspace. The image provides BusyBox, `xsh`, `xsht`, `curl`, and CA
certificates, and no extra packages: the `find` / `cat` / `awk` / `sort`
oracle applets are already in the shared base image, and the `fs` and stream
modules are part of `xsh` itself. There is no compiler, repository checkout, or
implementation source. The submitted program may not use `run`, process APIs,
`spawn`, shell commands, or any other subprocess boundary; it must keep
diagnostics off stdout and must not hard-code one tree's results.

## Oracle and evaluator

The evaluator runs in a separate read-only container boundary. It writes the
oracle script under the evaluator's writable `/tmp`, stages a distinct fixture
tree for each case, and runs the candidate and the oracle with the identical
`ROOT` so both observe the same tree. It compares byte-for-byte and writes the
comparison evidence plus timings to the run manifest. Public and hidden cases:

- `public`: two services across two log files, unsorted input, `api 1 200`,
  `db 1 55`, `web 2 150`;
- `hidden_single`: one service in one log file, several lines;
- `hidden_many`: many services with varied counts and sums;
- `hidden_nested`: log files staged in nested subdirectories (recursive
  discovery);
- `hidden_idents`: service names containing digits and underscores;
- `hidden_blank`: blank and whitespace-only lines interleaved and ignored;
- `hidden_empty`: a tree with no `.log` file — prints nothing, exit 0;
- `hidden_malformed` (failure control): a non-blank malformed line — candidate
  and oracle must both exit nonzero and print nothing.

The evaluator checks the source does not contain a forbidden subprocess
boundary, requires that the source references the filesystem stream module
(`fs.files` or `fs.walk`), a `group-by` stage, and an accumulator `fold` stage
so a hard-coded or non-aggregating answer is classified as a restriction
failure, and checks that `review.md` preserves both required headings and
contains no template placeholders.

## Metrics

Record correctness for all eight cases (including the failure control),
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
change must name the concept it teaches and be replayed before it is trusted.
On approval, stage `evals/task-svcstat/` with this scaffolding, including its
package-owned `evaluator.xsh`. The generic evaluator protocol stages and
mounts that script; do not add a task branch to `evaluate_common.xsh`.

## Dry run

Package-owned `evaluator.xsh` and `executor.xsh` were syntactically validated
with `xsht check`; the reference oracle was reviewed for byte-exact parity with
the intended aggregation contract. The container isolation, the oracle-vs-
candidate comparison loop, and an end-to-end solution run were not exercised in
a container this cycle (the shared `/usr/local/lib/xsh-factory` evaluator path
and the worker image are container-only surfaces), so the runtime parity of the
oracle with a real candidate remains unproven until admission.
