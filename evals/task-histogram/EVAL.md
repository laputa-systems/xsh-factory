# Eval task-histogram

## Status

Approved.

## Budget breach

None.

## Purpose

Measure a practical systems-administration / operations workflow that no
approved eval covers: reading a stream of numeric measurements, mapping each
value to an integer bin by a supplied width (integer division), counting the
values that land in each bin, and emitting a sorted cumulative distribution
report. `task-bigfiles` counts files, `task-groupsum` totals a scalar per key,
`task-total` does a flat count+sum, `task-logstat` buckets a fixed field, and
`task-colsum` reduces one named column; none transforms each value into a
derived bucket key and then aggregates two accumulators (per-bin count plus a
running cumulative total across sorted bins). `task-histogram` targets the
classic ops shape "distribution of latencies / sizes / packet counts" — the XSH
analogue of the `awk` histogram pipeline that turns raw measurements into a
binned cumulative report.

## North-star hypothesis

XSH's role is practical systems glue, and a binned cumulative distribution is a
canonical measurement-summary composition. This eval probes whether an agent
with the handbook can:

- read a file's text through typed filesystem APIs (`fs.read_text`) and split
  it into non-blank measurement lines;
- parse each measurement as a typed decimal integer with `Str.parse_int()?`
  and map it to a bin via integer division by a supply width, so a malformed
  value yields a loud nonzero exit instead of a silent wrong count;
- build a keyed Map of bin-to-count (stateful aggregation) with immutable
  update discipline;
- sort the occupied bins with a `sort-by` stage and fold the sorted stream into
  a running cumulative total, emitting a byte-exact, deterministic report;
- keep the whole pipeline in XSH values with no subprocess escape;

A successful run teaches whether integer division plus a keyed count Map plus a
sorted cumulative fold is discoverable and composable, and whether the
handbook's Result / `?` idiom and Map-followed-by-sort pattern transfer to a
real measurement-summary boundary. The design resists task-specific hacks
because hidden cases vary the bin width, dataset size, bin sparsity, and count
ties — a hard-coded list, a fixed binning, a silent default, or a subprocess
escape each fail a distinct gate.

## Task

Create `histogram.xsh`. It accepts a file path and a positive integer width:

    histogram.xsh FILE WIDTH

`FILE` is a text file where each non-blank line holds a single non-negative
decimal integer (optional surrounding whitespace; no sign). For every value
`v`, compute its bin as `v // WIDTH` (integer division; for non-negative values
this is the truncated quotient). Count how many values land in each bin, then
print the occupied bins in ascending bin order, exactly one line per bin:

    <bin> <count> <cumulative>

`<bin>` is the integer bin value with no leading padding, `<count>` is the
number of values in that bin, and `<cumulative>` is the running total of
counts across all bins up to and including this one in ascending bin order. If
`FILE` contains no values (or is empty), print nothing. Blank lines are
ignored.

If `WIDTH` is not a positive decimal integer, or if any non-blank line of
`FILE` is not a non-negative decimal integer, the program must exit nonzero and
print nothing. The evaluator supplies several different files and widths, so do
not hard-code a result. Complete `review.md` using the supplied headings.

The behavior is defined by this oracle, run by the evaluator with the same
`FILE` and `WIDTH` against a fixture it stages in `/tmp`:

```sh
set -o pipefail
file="$1"; width="$2"
case "$width" in ''|*[!0-9]*) exit 1;; esac
[ "$width" -gt 0 ] 2>/dev/null || exit 1
awk -v w="$width" '
  NF==0 { next }
  { if ($1 !~ /^[0-9]+$/) { bad=1; exit 2 }
    b=int($1/w); c[b]++ }
  END { if (bad) exit 2; for (b in c) print b, c[b] }
' "$file" | sort -n -k1,1 | awk '{cum += $2; print $1 " " $2 " " cum}'
```

The evaluator invokes the candidate equivalently to `xsh histogram.xsh FILE
WIDTH` and compares its stdout byte-for-byte with the oracle's stdout.

## Agent boundary

The worker runs as root in a minimal Alpine container with `/work` as its task
workspace. The image provides BusyBox, `xsh`, `xsht`, `curl`, CA
certificates, and no extra packages: the `awk` / `sort` oracle applets are
already in the shared base image, and the `fs`, text, and stream modules are
part of `xsh` itself. There is no compiler, repository checkout, or
implementation source. The submitted program may not use `run`, process APIs,
`spawn`, shell commands, or any other subprocess boundary; it must keep
diagnostics off stdout and must not hard-code one file's result.

## Oracle and evaluator

The evaluator runs in a separate read-only container boundary. It writes the
oracle script under the evaluator's writable `/tmp`, stages a distinct fixture
file for each case, and runs the candidate and the oracle with identical
`FILE` and `WIDTH` so both observe the same data. It compares byte-for-byte
and writes the comparison evidence plus timings to the run manifest. Public
and hidden cases:

- `public`: values `0 1 2 3 4`, `WIDTH=2` — bins `0:2, 1:2, 2:1`;
- `hidden_width`: the same values, `WIDTH=3` — bins `0:3, 1:2` (punishes a
  hard-coded binning for width 2);
- `hidden_many`: a larger dataset (`5 9 10 15 19 20 25 29 30`, `WIDTH=10`)
  spanning four bins;
- `hidden_sparse`: values far apart (`0 1000 100000`, `WIDTH=10`) with empty
  bins in between;
- `hidden_single`: a single value (`7`, `WIDTH=3`);
- `hidden_ties`: two bins with equal counts (`0 1 2 3`, `WIDTH=2`), where the
  cumulative column is the only tie-breaker;
- `hidden_empty`: an empty file — prints nothing;
- `hidden_bad_width` (failure control): `WIDTH=0` — candidate and oracle both
  exit nonzero and print nothing;
- `hidden_bad_value` (failure control): a non-integer line (`12x`) — candidate
  and oracle both exit nonzero and print nothing.

The evaluator checks the source does not contain the forbidden subprocess
boundary, requires that the source references a typed file read
(`fs.read_text` or `.read_text`), a typed integer parse (`parse_int`), and a
`sort-by` stage so a hard-coded answer is classified as a restriction failure,
and checks that `review.md` preserves both required headings and contains no
template placeholders.

## Metrics

Record correctness for all nine cases (including the two failure controls),
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
On approval, stage `evals/task-histogram/` with this scaffolding, including its
package-owned `evaluator.xsh`. The generic evaluator protocol stages and
mounts that script; do not add a task branch to `the shared evaluator dispatcher`.

## Difficulty justification

This task is at least ecount-level because it composes two independent XSH
data transformations with two independent stateful aggregations:

1. **Transform-to-derived-key + keyed aggregation**: each raw measurement is
   parsed as a typed integer and mapped through integer division by a supplied
   width into a derived bin key, then counted into a keyed Map. This mirrors
   `task-ecount`'s traversal + keyed counting but requires an extra arithmetic
   transformation on every element before the key exists, so a source that
   merely counts input fields or copies a value cannot satisfy it.
2. **Sorted cumulation (second independent aggregation)**: the occupied bins
   are ordered with a `sort-by` stage and folded into a running cumulative
   total, producing a second accumulator column that is a deterministic
   function of the whole sorted distribution, not any single bin.

These two aggregations are independent: the per-bin counts come from the input
values alone, while the cumulative column is a reduction over the *ordered*
bins. The **meaningful failure control** is explicit and audible: a non-integer
value or a non-positive width must exit nonzero and print nothing, so a silent
default or a partial histogram fails a distinct gate. The **hidden cases that
defeat one-liners and hard-coded answers** vary the bin width (`hidden_width`),
dataset size (`hidden_many`), bin sparsity (`hidden_sparse`), count ties
(`hidden_ties`), and emptiness (`hidden_empty`), so a solution hard-coded to
one width, one tree, or one total cannot pass more than one case, and the two
failure controls force real typed parsing rather than a tolerant filter. This
exceeds the ecount floor (traversal + keyed counting + deterministic sort) by
adding integer binning and a second cumulative reduction on top.

## Staged dry run

See `dry-run/DRY-RUN.md` in this proposal. The external oracle was exercised
on the host across the public case, the six hidden passing cases, and the two
failure controls; the oracle produced the expected bin/count/cumulative output
on every passing case, printed nothing and exited nonzero on both failure
controls (`WIDTH=0` exits 1, a `12x` line exits 2). The container isolation
and the package-owned evaluator wiring are inherited unchanged from the
approved scaffold and were not re-run end-to-end in a container this cycle
(the shared `/usr/local/lib/xsh-factory` evaluator path is a container-only
surface).

## CTO review

- Result: `pending`
- Promotion: `pending`
- Package: `complete`
- Missing package files: `None.`
- Status: `Draft.`
- Source run: `runs/run-1785894766939/phases/04-eval-design`

## CTO review

- Result: `accepted`
- Promotion: `promoted`
- Package: `complete`
- Missing package files: `None.`
- Status: `Approved.`
- Source run: `runs/run-1785894766939/phases/04-eval-design`
