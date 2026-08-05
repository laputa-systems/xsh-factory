# Eval task-colsum

## Status

Approved.

## Budget breach

None.

## Purpose

Measure a practical data-munging systems-glue workflow that no approved eval
covers: reading a comma-separated table, locating a named column through its
header row, and summing the typed decimal integers in that column with a
byte-exact integer report. `task-intsum` sums command-line argument vectors,
`task-total` sums every whitespace field of a line file, `task-groupsum` totals
per distinct key, and `task-jsonfilter` reads structured JSON; none selects a
named column of a delimited table and reduces only that column. `task-colsum`
targets the classic `awk -F,` column-sum shape — the modern XSH analogue of
picking one field out of a table and aggregating it.

## North-star hypothesis

XSH's role is practical systems glue, and "sum the numbers in one named column
of a table" is a canonical structured-data reduction. This eval probes whether
an agent with the handbook can:

- read a file's text through typed filesystem APIs (`read_text`) and split it
  into lines and comma-delimited fields;
- treat the first line as a header and resolve a column name to a numeric
  index with ordinary stream logic rather than an ad hoc convention;
- parse each cell as a typed decimal integer with `Str.parse_int()?` so a
  malformed cell yields a loud nonzero exit instead of a silent wrong total;
- keep the whole reduction in XSH values with no subprocess escape;
- emit a byte-exact single-line `<sum>` contract with no leading padding or
  diagnostic text.

A successful run teaches whether typed parsing (`Result` / postfix `?`)
transfers to a per-cell table boundary and whether splitting + indexing a
delimited header is discoverable and composable. The design resists
task-specific hacks because hidden cases vary header order, column position,
row count, sign, empty tables, a missing header name, and a malformed cell —
a hard-coded total, a silent default, or a subprocess escape each fail a
distinct gate.

## Task

Create `colsum.xsh`. It accepts a file path and a header name:

    colsum.xsh FILE HEADER

`FILE` is a comma-separated text file whose first line is a header row of
column names. Find the column whose header name exactly equals `HEADER`, sum
the decimal integer values (which may be negative) in that column across all
remaining data rows, and print the total on its own line:

    <sum>

`<sum>` is the signed integer total with no leading zeros and no leading
padding. If `HEADER` is not present in the header row, or if any data-row
value in the target column is not a decimal integer, the program must exit
nonzero and print nothing. If there are no data rows, print `0`. Values in
other columns are arbitrary and are ignored; cells contain no commas or
whitespace, so a comma split is unambiguous. The evaluator supplies several
different tables, so do not hard-code a result. Complete `review.md` using the
supplied headings.

The behavior is defined by this oracle, run by the evaluator with the same
`FILE` and `HEADER` against a fixture table it stages in `/tmp`:

```sh
file="$1"; header="$2"
col=$(awk -F, 'NR==1{for(i=1;i<=NF;i++) if($i==h){print i; exit}}' h="$header" "$file")
[ -n "$col" ] || exit 1
awk -F, -v c="$col" 'NR>1{if ($c !~ /^-?[0-9]+$/) {bad=1; exit 2} s+=$c} END{if(!bad) printf "%d\n", s}' "$file"
```

The evaluator invokes the candidate equivalently to `xsh colsum.xsh FILE
HEADER` and compares its stdout byte-for-byte with the oracle's stdout.

## Agent boundary

The worker runs as root in a minimal Alpine container with `/work` as its task
workspace. The image provides BusyBox, `xsh`, `xsht`, `curl`, CA
certificates, and no extra packages: the `awk` oracle applet is already in the
shared base image, and the `fs` and text modules are part of `xsh` itself.
There is no compiler, repository checkout, or implementation source. The
submitted program may not use `run`, process APIs, `spawn`, shell commands, or
any other subprocess boundary; it must keep diagnostics off stdout and must
not hard-code one table's result.

## Oracle and evaluator

The evaluator runs in a separate read-only container boundary. It writes the
oracle script under the evaluator's writable `/tmp`, stages a distinct fixture
table for each case, and runs the candidate and the oracle with identical
`FILE` and `HEADER` so both observe the same table. It compares byte-for-byte
and writes the comparison evidence plus timings to the run manifest. Public
and hidden cases:

- `public`: a 3-row table, `HEADER=age` — prints the age sum;
- `hidden_order`: same kind of data with the header columns in a different
  order and the target column in a different position;
- `hidden_negative`: target column contains negative integers;
- `hidden_many`: a large number of rows with a large total;
- `hidden_single`: header plus exactly one data row;
- `hidden_no_data`: header row only, no data rows — prints `0`;
- `hidden_extra_cols`: target column in the middle with extra columns after;
- `hidden_missing_header` (failure): `HEADER` not present — candidate and
  oracle both exit nonzero and print nothing;
- `hidden_bad_value` (failure): a data-row value in the target column is not a
  decimal integer — candidate and oracle both exit nonzero and print nothing.

The evaluator checks the source does not contain the forbidden subprocess
boundary, requires that the source references a typed file read
(`fs.read_text` or `.read_text`) and a typed integer parse (`parse_int`) so a
hard-coded answer is classified as a restriction failure, and checks that
`review.md` preserves both required headings and contains no template
placeholders.

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
On approval, stage `evals/task-colsum/` with this scaffolding, including its
package-owned `evaluator.xsh`. The generic evaluator protocol stages and
mounts that script; do not add a task branch to `evaluate_common.xsh`.

## Staged dry run

See `dry-run/DRY-RUN.md` in this proposal. The external oracle was exercised
on the host across the public case, the seven hidden cases, and the two
failure controls; the oracle produced the expected sum on every passing case
and exited nonzero with no output on both failure controls. A reference XSH
`colsum.xsh` produced the same sums and passes `xsht check` and `lint`. The
container isolation and the package-owned evaluator wiring are inherited
unchanged from the approved scaffold and were not re-run end-to-end in a
container this cycle (the shared `/usr/local/lib/xsh-factory` evaluator path
is a container-only surface).

## CTO review

- Result: `pending`
- Promotion: `pending`
- Package: `complete`
- Missing package files: `None.`
- Status: `Draft.`
- Source run: `runs/run-1785888999833/phases/04-eval-design`

## CTO review

- Result: `accepted`
- Promotion: `promoted`
- Package: `complete`
- Missing package files: `None.`
- Status: `Approved.`
- Source run: `runs/run-1785888999833/phases/04-eval-design`
