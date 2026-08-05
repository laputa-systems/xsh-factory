# Eval task-revrank

## Status

Draft.

## Budget breach

None.

## Purpose

Measure a practical systems-administration / operations capability that no
approved eval covers: reading a delimited transaction table, deriving a numeric
value per row from two parsed columns (unit count times unit price), aggregating
that derived revenue into a keyed Map of region totals, and ranking the regions
by the accumulated numeric total with a deterministic tie-break. `task-colsum`
sums one named column, `task-groupsum` totals an already-numeric second field
per key and emits sorted-by-key rows, `task-total` does a flat count+sum, and
`task-histogram` bins values; none computes a second-order numeric field from
two columns, accumulates it per categorical key, and then ranks the aggregates
numerically. `task-revrank` targets the classic ops shape "revenue / spend /
usage leaderboard per region or tenant" — the XSH analogue of the
`awk '{s[$1]+=$3*$4} END{...}' | sort -rn` pipeline.

## North-star hypothesis

XSH's role is practical systems glue, and "compute a derived per-row value,
total it per group, and rank the groups" is a canonical measurement-summary
composition. This eval probes whether an agent with the handbook can:

- read a file's text through typed filesystem APIs (`fs.read_text`) and split
  each non-blank line into exactly four single-space-delimited fields;
- parse the third and fourth fields as typed decimal integers with
  `Str.parse_int()?` and multiply them into a per-row revenue, so a malformed
  or short line yields a loud nonzero exit instead of a silent wrong total;
- accumulate the derived revenue into a keyed Map with immutable update
  discipline (`rev[region] = rev.get(region, 0) + units * price`);
- materialize the Map into records, rank them with a `sort-by` stage using the
  documented two-pass stable idiom (sort by region, then by negated total) so a
  descending numeric rank still breaks ties deterministically in ascending
  region order;
- keep the whole pipeline in XSH values with no subprocess escape;

A successful run teaches whether the two independent transformations (per-row
arithmetic projection and keyed aggregation) plus numeric ranking are
discoverable and composable, and whether the handbook's Result / `?` idiom
transfers to a real leaderboard boundary. The design resists task-specific
hacks because hidden cases vary the region count, row multiplicity, revenue
ties, negative values, row order, and field validity — a hard-coded leaderboard,
a fixed total, a silent default, a single-pass order assumption, or a subprocess
escape each fail a distinct gate.

## Task

Create `revrank.xsh`. It accepts one file-path argument:

    revrank.xsh FILE

`FILE` is a text file whose non-blank lines each hold exactly four
single-space-delimited fields:

    REGION PRODUCT UNITS PRICE

`REGION` and `PRODUCT` are words (no spaces), `UNITS` and `PRICE` are decimal
integers (optionally preceded by a single `-` sign). For each row, the revenue
is `UNITS * PRICE`. Sum the revenue per `REGION` across all rows, then print
exactly one line per distinct region that appears:

    REGION TOTAL

`TOTAL` is the signed integer revenue total with no leading padding. Print the
regions in descending order of `TOTAL`; when two regions have the same `TOTAL`,
order them ascending by `REGION` in byte (ASCII) order. Blank lines are
ignored. If `FILE` contains no data rows (or only blank lines), print nothing
and exit 0.

Rules and failure control:

- Every non-blank line must have exactly four fields. A line with any other
  number of fields is malformed.
- `UNITS` and `PRICE` must be decimal integers; otherwise the line is
  malformed.
- If any non-blank line is malformed, or if `FILE` cannot be read, the program
  must exit nonzero and print nothing.
- The program must read the file through XSH text APIs, derive revenue through
  XSH arithmetic values, accumulate through an XSH Map, and rank with XSH
  stream stages. It must not start subprocesses, invoke an external command
  (including `awk`, `sh`, or `sort`), or add diagnostic text to stdout.

The evaluator supplies several different files, so do not hard-code one
result. Complete `review.md` using the supplied headings.

Use the handbook and the available `xsht` checks as the reference. A normal
development loop is:

    xsht check revrank.xsh
    xsht fmt revrank.xsh
    xsht lint revrank.xsh
    xsh revrank.xsh /path/to/sales.txt

## Agent boundary

The worker runs as root in a minimal Alpine container with `/work` as its task
workspace. The image provides BusyBox, `xsh`, `xsht`, `curl`, CA certificates,
and no extra packages: the `awk` / `sort` oracle applets are already in the
shared base image, and the `fs`, text, stream, and Map modules are part of
`xsh` itself. There is no compiler, repository checkout, or implementation
source. The submitted program may not use `run`, process APIs, `spawn`, shell
commands, or any other subprocess boundary; it must keep diagnostics off
stdout and must not hard-code one file's result.

## Oracle and evaluator

The evaluator runs in a separate read-only container boundary. It writes the
oracle script under the evaluator's writable `/tmp`, stages a distinct fixture
file for each case, and runs the candidate and the oracle with the same `FILE`
so both observe the same table. It compares byte-for-byte and writes the
comparison evidence plus timings to the run manifest. Public and hidden cases:

- `public`: `north gadget 2 10`, `south widget 3 5`, `east tool 1 4` — ranked
  `north 20`, `south 15`, `east 4`;
- `hidden_multiproduct`: one region appears across several product rows that
  must accumulate south;
- `hidden_tie`: three regions with the same `TOTAL` — the tie-break must order
  them ascending by region byte order;
- `hidden_negative`: rows include negative units/price, so totals and ranking
  must still be correct;
- `hidden_order`: rows are inserted in an order that differs from the correct
  ranked output — punishes a pass-through or a non-ranked answer;
- `hidden_many`: a larger dataset spanning several regions with varied totals;
- `hidden_empty`: an empty / blank-only file — prints nothing, exit 0;
- `hidden_bad_fields` (failure control): a line with three fields — candidate
  and oracle both exit nonzero and print nothing;
- `hidden_bad_unit` (failure control): a `UNITS` field that is not an integer —
  candidate and oracle both exit nonzero and print nothing;
- `hidden_missing` (failure control): the file does not exist — candidate and
  oracle both exit nonzero and print nothing.

The evaluator checks the source does not contain the forbidden subprocess
boundary, requires that the source references a typed file read
(`fs.read_text` or `.read_text`), a typed integer parse (`parse_int`), a Map
accumulation, and a `sort-by` stage so a hard-coded answer is classified as a
restriction failure, and checks that `review.md` preserves both required
headings and contains no template placeholders.

## Metrics

Record correctness for all ten cases (including the three failure controls),
restriction compliance, worker turns, thinking blocks and reasoning tokens,
token buckets, provider cost, tool calls and errors, session wall span,
candidate/oracle timing per case, and protocol completion. This eval has no
strict candidate/oracle timing gate; both sides finish in milliseconds, so
timing is diagnostic until a stable envelope is established.

## Manager policy

Use one trial by default; the controller-owned `## Trial plan` in the cycle
request may explicitly raise this to two. Classify repeated friction as
handbook guidance or a product issue only when it is generalizable (for
example, a recurring misunderstanding of per-row arithmetic followed by keyed
Map accumulation, or of the two-pass stable sort for a descending rank with an
ascending tie-break); do not create a ticket for an ordinary short-task miss or
evaluator noise. A handbook change must name the concept it teaches and be
replayed before it is trusted. On approval, stage `evals/task-revrank/` with
this scaffolding, including its package-owned `evaluator.xsh`. The generic
evaluator protocol stages and mounts that script; do not add a task branch to
`evaluate_common.xsh`.

## Difficulty justification

This task is at least ecount-level because it composes two independent XSH data
transformations with a third, independent ranked aggregation:

1. **Per-row derived-value transformation**: each line is split into four
   fields, the third and fourth are each parsed as a typed decimal integer
   with `Str.parse_int()?`, and multiplied into a revenue value. This is a
   first-class arithmetic projection that no input field contains directly, so
   a solution that only copies, extracts, or sums an existing column cannot
   satisfy it.
2. **Keyed stateful aggregation**: the derived revenues are accumulated per
   `REGION` into a `Map[Int]` with immutable update discipline
   (`rev[region] = rev.get(region, 0) + units * price`). This is a separate
   second aggregation over the projected values, independent of the per-row
   arithmetic.
3. **Numeric ranking (third independent order)**: the Map is materialized into
   records and ranked with a `sort-by` stage using the documented two-pass
   stable idiom (region ascending, then negated-total ascending) to produce a
   descending numeric rank with a deterministic ascending tie-break. This is a
   reduction over the whole set of aggregates, not any single row or field.

These three operations are mutually independent: the per-row revenue comes from
two parsed numeric columns alone, the per-region total is a keyed reduction over
those derived values, and the emitted rank is an ordering decision over the
totals. The **meaningful failure control** is explicit and audible: a malformed
row (wrong field count or non-integer units/price) or an unreadable file must
exit nonzero and print nothing, so a silent default or a partial report fails a
distinct gate. The **hidden cases that defeat one-liners and hard-coded
answers** vary the region count and multiplicity (`public`,
`hidden_multiproduct`, `hidden_many`), revenue ties (`hidden_tie`), sign
(`hidden_negative`), input order (`hidden_order`), and emptiness
(`hidden_empty`), so a solution hard-coded to one leaderboard, a pass-through
that ignores ranking, or an order-sensitive single-pass sort cannot pass more
than one case; the three failure controls force real typed parsing and
validation rather than a tolerant filter. This exceeds the ecount floor
(traversal + keyed counting + deterministic sort) by adding per-row arithmetic
projection and a descending numeric rank with an ascending tie-break on top.

## Staged dry run

See `dry-run/DRY-RUN.md` in this proposal. The reference `revrank.xsh` and the
external `awk | sort` oracle were exercised on the host across the public case,
the six hidden passing cases, and the three failure controls; the candidate
byte-matched the oracle on every passing case and both exited nonzero with no
stdout on all three failure controls. The reference also passes `xsht check`
and `xsht lint`. The container isolation and the package-owned evaluator wiring
are inherited unchanged from the approved scaffold and were not re-run
end-to-end in a container this cycle (the shared
`/usr/local/lib/xsh-factory` evaluator path is a container-only surface).

## CTO review

- Result: `pending`
- Promotion: `pending`
- Package: `complete`
- Missing package files: `None.`
- Status: `Draft.`
- Source run: `runs/run-1785896401695/phases/04-eval-design`
