# Eval task-usagerep

## Status

Draft.

## Budget breach

None.

## Purpose

Measure a practical systems-administration aggregation workflow that no
approved eval covers: consuming a *tree* of per-service measurement files,
reading each file's contents, and accumulating two independent aggregates
(sum of units and count of contributing lines) per distinct service, then
emitting a ranked summary. This is the modern XSH shape behind the shell
metering idiom `cat *.usage | awk '{s[$1]+=$2; c[$1]++} ...'`: total usage
per account, bytes per bucket, calls per endpoint, minutes per job, where the
input facts are scattered across many files under one root.

Existing evals stay below this bar. `task-ecount` counts files by extension
but never reads a file body. `task-groupsum` and `task-colsum` sum a column
from a *single* file. `task-logstat` counts occurrences of one fixed field in
one file, and `task-wordfreq` tokenizes one file. None recursively discovers
many files, reads their contents, and folds two independent accumulators
(sum and count) over an arbitrary key. `task-usagerep` targets exactly that
gap: multi-file aggregation with a ranked, byte-exact report and a meaningful
parse-failure control.

## Difficulty justification

This task is at or above the `task-ecount` minimum bar because it contains
everything ecount has and adds a second transformation, a second independent
accumulator, and a failure control. Concretely:

- Transformation 1 — recursive discovery + content parsing: the program walks
  a root (`fs.files`/`fs.walk`), selects only `*.usage` entries, reads each
  file's body (`read_text`), splits out blank and whitespace-only lines, and
  tokenizes every remaining line into a typed `(SERVICE, UNITS)` record,
  trimming the service token and parsing the units as a decimal integer. This
  is strictly richer than ecount, which never opens a file body.
- Stateful aggregation (two independent accumulators): a fold over the record
  stream builds a `Map` keyed by `SERVICE` that accumulates both a running SUM
  and a running COUNT through `Map.set`/`Map.get` fallback. Two independent
  aggregates are carried per key in one stateful pass, not a single count.
- Transformation 2 — composite ranking + rendering: the per-service records
  are sorted by SUM descending, ties broken by SERVICE ascending in byte
  (ASCII lexicographic) order, then rendered as byte-exact `SERVICE SUM COUNT`
  lines.
- Failure control: a non-blank line that does not split into exactly two
  fields, or whose UNITS is not a decimal integer, forces a nonzero exit with
  empty stdout.
- Hidden cases that defeat a one-liner or hard-coded answer: the evaluator
  seeds a different tree per case at runtime and varies the file count, spread
  of a service across multiple nested files, SUM ties, byte-order traps
  (`"2"` vs `"10"` as service names), blank/whitespace-only lines, an empty
  tree, an empty `.usage` file mixed with real content, directory/file names
  containing spaces, and two distinct malformed-line failures. No literal
  output survives all shapes, and the source-restriction checks (must read
  file contents with `read_text`, must discover with `fs.files`/`fs.walk`, and
  must not spawn a subprocess) block a shell/workaround escape.

## North-star hypothesis

An agent that has read the handbook should be able to turn "read every
`*.usage` file under a root, sum units and count lines per distinct service,
and print a ranked `SERVICE SUM COUNT` report" into a short, typed XSH program
that walks a tree, reads file bodies, parses integers, folds two accumulators
into a Map, sorts by a composite key, and renders byte-exact rows. The eval
probes whether multi-file discovery, content reads, and the two-accumulator
Map idiom (`sums = sums.set(k, sum + v)` with a separate `counts` map, or a
parallel accumulator) compose alongside composite `sort-by`. A successful run
teaches the factory that multi-file aggregation plus composite ranking is
discoverable from the handbook; a miss reveals which idiom (Map accumulation,
integer parsing, tie-break sorting, or content read) is still unclear. The
design resists task-specific hacks because the tree shape, spread, ordering,
and byte-order traps vary at runtime and the source checks block a subprocess
or a literal-output escape.

## Task

Create one file named `usagerep.xsh` in the task working directory.

The program accepts one root directory argument:

    usagerep.xsh ROOT

It recursively discovers every regular file under `ROOT` whose name ends with
`.usage`, reads each one, and prints one line per distinct service:

    SERVICE SUM COUNT

Rules:

- Only files whose name ends with `.usage` are examined; every other file
  under the root is ignored.
- Each line of a `.usage` file has the form `SERVICE UNITS`, two
  whitespace-separated fields. A blank line (zero fields) or a
  whitespace-only line (also zero fields) is ignored.
- Every other (non-blank) line must contain exactly two fields: a SERVICE and
  a UNITS.
- UNITS (the second field) must be a decimal integer, optionally preceded by a
  single `-` sign (for example `42`, `-3`, `0`, `007`).
- SUM is the sum of the integer UNITS values seen for that SERVICE across all
  `.usage` files in the whole tree.
- COUNT is the number of non-blank lines seen for that SERVICE across all
  `.usage` files.
- Print exactly one line per distinct SERVICE that appears, sorted by SUM
  descending, then (when SUMs tie) by SERVICE ascending in byte (ASCII
  lexicographic) order, formatted as `SERVICE SUM COUNT` with a single space
  between fields and each line followed by a newline. Print nothing else.
- If a non-blank line has anything other than exactly two fields, or a UNITS
  that is not such an integer, the program must exit nonzero and print
  nothing.
- If the root cannot be read, the program must exit nonzero and print nothing.
- If the tree contains no `.usage` files, or all `.usage` files are empty or
  blank, print nothing and exit 0.

The program must discover the tree through XSH filesystem values and read each
selected file through an XSH text API, accumulating through XSH values (a Map
is the natural fit). It must not start subprocesses, invoke an external
command (including `awk`, `sh`, `sort`, `find`, or `cat`), or add diagnostic
text to stdout. The evaluator supplies several different trees, so do not
hard-code one summary.

Complete `review.md` using the supplied headings.

Use the handbook and the available `xsht` checks as the reference. A normal
development loop is:

    xsht api module:fs
    xsht check usagerep.xsh
    xsht fmt usagerep.xsh
    xsht lint usagerep.xsh
    xsh usagerep.xsh /path/to/measurements

## Agent boundary

The worker runs as root in a minimal Alpine container with `/work` as its task
workspace. The image provides BusyBox, `xsh`, `xsht`, `curl`, CA certificates,
and the XSH standard modules. It has no compiler, repository checkout, or
implementation source. The submitted program may not start subprocesses or
invoke an external command and must keep diagnostics off stdout. The worker
does not see the evaluator's fixture trees or oracle harness.

## Oracle and evaluator

The package-owned evaluator runs in a separate read-only container boundary so
the worker cannot inspect fixtures or the evaluator. For each case it stages a
fresh fixture tree under the evaluator's writable `/tmp`, invokes the candidate
as `xsh /work/usagerep.xsh <root>`, and compares the candidate's stdout
byte-for-byte with an independent oracle:

- success cases: an external `printf` oracle emits the authored expected
  `SERVICE SUM COUNT` rows (derived from the fixture independent of XSH); the
  case passes only when the candidate exits 0 and its stdout matches the
  oracle byte-for-byte. The empty-tree / empty-file cases expect empty stdout
  with exit 0.
- failure cases (mis-shaped line, invalid integer): an external
  `sh -c 'exit 1'` oracle emits nothing with a nonzero exit; the case passes
  only when the candidate also exits nonzero and prints nothing to stdout.

The evaluator then checks that the source reads file contents through an XSH
text API (`read_text`), discovers the tree with `fs.files` or `fs.walk`,
contains no forbidden subprocess boundary, and that `review.md` preserves the
required headings. It writes a JSON run manifest to `<session>/run.json`.

The hidden cases are:

- `public`: one file `a.usage` with `api 10`, `db 5`, `web 3` -> sorted desc:
  `api 10 1`, `db 5 1`, `web 3 1`;
- `hidden_multi`: files spread across nested directories (`dir1/a.usage`,
  `dir1/sub/x.usage`, `dir2/other.usage`) with `api` appearing in three files
  (`4+6+1 = 11`, count 3), plus `db 2` and `web 1`, plus a non-`.usage`
  `ignore.txt` that must be skipped -> `api 11 3`, `db 2 1`, `web 1 1`;
- `hidden_ties`: `usage.usage` with `alpha 5`, `beta 5`, `gamma 1` ->
  `alpha 5 1`, `beta 5 1`, `gamma 1 1` (SUM tie broken by SERVICE ascending);
- `hidden_order`: `usage.usage` with `z 5`, `10 3`, `2 9`, `a 5` ->
  `2 9 1`, `a 5 1`, `z 5 1`, `10 3 1` (SUM descending primary; byte-order
  trap `"2"` before `"10"`, and `a` before `z` on the SUM tie);
- `hidden_blank`: `usage.usage` with `a 1`, blank, `b 2`, whitespace-only,
  `a 3` -> `a 4 2`, `b 2 1`;
- `hidden_empty`: a tree with only `ignore.txt` and no `.usage` file -> empty
  stdout, exit 0;
- `hidden_empty_file`: `empty.usage` (empty body) plus `main.usage`
  (`api 2`, `db 3`) -> `db 3 1`, `api 2 1`;
- `hidden_spaces`: file and directory names containing spaces
  (`dir with space/usage file.usage` -> `api 2 1`);
- `hidden_bad_value`: a line with a non-integer UNITS (`api 5`, `db xyz`) ->
  nonzero, empty stdout;
- `hidden_bad_fields`: a line with three fields (`api 5`, `db 2 extra`) ->
  nonzero, empty stdout.

Timing (candidate vs oracle wall ns) is recorded per case but is diagnostic
only; there is no strict runtime envelope: both sides complete in
milliseconds.

## Metrics

Record correctness for all ten cases (success byte-exactness and failure
exit/empty-stdout semantics), restriction compliance (`read_text` and
`fs.files`/`fs.walk` references, no forbidden subprocess), worker turns,
thinking blocks and reasoning tokens, token buckets, provider cost, tool calls
and errors, session wall span, candidate/oracle timing, and protocol
completion (`review.md` rows). This eval has no strict candidate/oracle timing
gate; timing is diagnostic until a stable envelope is established.

## Manager policy

Use one trial by default; the controller-owned `## Trial plan` in the cycle
request may explicitly raise this to two. Classify repeated friction as
handbook guidance or a product issue only when it generalizes (for example, a
recurring misunderstanding of multi-file discovery, Map accumulation with two
accumulators, integer parsing, or composite tie-break sorting); do not create
a ticket for an ordinary short-task miss or evaluator noise. A handbook change
must name the concept it teaches and be replayed before it is trusted. The
`read_text` + `fs.files`/`fs.walk` and no-subprocess checks keep a workaround
out of the accepted set, so a pass is evidence about typed multi-file
parse/Map/sort composition, not about a shell escape.

## Staged dry run

See `dry-run/DRY-RUN.md` in this proposal. The package-owned `evaluator.xsh`
and the thin `executor.xsh` selector were syntax-checked with `xsht check` on
the local build and both parse cleanly; the evaluator's staging, oracle, and
restriction logic follow the approved package-owned evaluator pattern from
`task-groupsum`. A live container trial (the exact `/work`, `/session`,
`/export` paths, a real agent session, and candidate-vs-oracle byte matching)
was not run this cycle; that remains the unproven surface for the CTO review.

## CTO review

Pending. Status remains `Draft.` until the CTO review gate decides.

## CTO review

- Result: `rejected`
- Promotion: `promoted`
- Package: `complete`
- Missing package files: `None.`
- Status: `Draft.`
- Source run: `runs/run-1785893827191/phases/02-eval-design`
