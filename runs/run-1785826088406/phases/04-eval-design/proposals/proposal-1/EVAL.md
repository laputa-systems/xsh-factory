# Eval task-groupsum

## Status

Draft.

## Budget breach

None.

## Purpose

Measure a practical systems-administration aggregation workflow that no
approved eval covers: reading a whitespace-delimited two-field file, parsing a
decimal integer, accumulating a numeric total per distinct key through an XSH
Map, and emitting the per-key totals in sorted key order. Existing evals read
text and extract columns (`task-col2`, `task-propsort`, `task-grep`,
`task-total`), count occurrences of a fixed field (`task-logstat`), or do a
single record lookup (`task-iniget`); none requires building an arbitrary-key
Map of accumulated numbers and then emitting a sorted keyed summary. This is
the classic `awk '{s[$1]+=$2} END{...}'` glue pattern (sum bytes per user,
totals per endpoint, usage per account), expressed as typed XSH values.

## North-star hypothesis

An agent that has read the handbook should be able to turn "sum the second
field per first field and print sorted `KEY SUM` rows" into a short, typed XSH
program that reads the file through fs text APIs, splits each line into
fields, validates the value as an integer, accumulates into a Map with
`Map.set`/`Map.get` fallback, sorts the keys, and formats the rows. The eval
probes whether Map accumulation, integer parsing, and keyed sorting compose
into a real aggregation tool and whether `xsht api` makes the exact split /
parse signatures discoverable. A successful run teaches the factory that the
immutable Map idiom (`sums = sums.set(k, ...)`) and the stream sort idiom are
learnable together; a missed run reveals which of those idioms is still
unclear. The design resists task-specific hacks: the evaluator generates
multiple hidden fixture files at runtime with different keys, accumulation
shapes, and byte-order traps, and requires a clean failure (nonzero exit, no
stdout) on a mis-shaped line, so a hard-coded summary or an eager
throwing-in-the-towel candidate cannot pass.

## Task

Create one file named `groupsum.xsh` in the task working directory.

The program accepts one file-path argument and prints one line per distinct
key:

```text
KEY SUM
```

Rules:

- Each line of the file is split into whitespace-separated fields.
- A blank line (no fields) is ignored.
- Every other (non-blank) line must contain exactly two fields: a KEY and a
  VALUE.
- VALUE (the second field) must be a decimal integer, optionally preceded by a
  single `-` sign (for example `42`, `-3`, `0`, `007`).
- SUM is the sum of the integer VALUEs seen for that KEY across all rows.
- Print exactly one line per distinct KEY that appears, sorted ascending by
  KEY in byte (ASCII lexicographic) order, formatted as `KEY SUM` with a single
  space and each line followed by a newline. Print nothing else.
- If a non-blank line has anything other than exactly two fields, or a VALUE
  that is not such an integer, the program must exit nonzero and print nothing.
- If the file cannot be read, the program must exit nonzero and print nothing.
- If the file has only blank lines or is empty, print nothing and exit 0.

The program must read the file through XSH text APIs and accumulate through
XSH values (a Map is the natural fit). It must not start subprocesses, invoke
an external command (including `awk`, `sh`, `sort`, or `wc`), or add
diagnostic text to stdout. The evaluator supplies several different files, so
do not hard-code one summary.

Complete `review.md` using the supplied headings.

Use the handbook and the available `xsht` checks as the reference. A normal
development loop is:

    xsht check groupsum.xsh
    xsht fmt groupsum.xsh
    xsht lint groupsum.xsh
    xsh groupsum.xsh /path/to/usage.txt

## Agent boundary

The worker runs as root in a minimal Alpine container with `/work` as its task
workspace. The image provides BusyBox, `xsh`, `xsht`, `curl`, CA certificates,
and the XSH standard modules. It has no compiler, repository checkout, or
implementation source. The submitted program may not start subprocesses or
invoke an external command and must keep diagnostics off stdout.

## Oracle and evaluator

The package-owned evaluator runs in a separate read-only container boundary so
the worker cannot inspect fixtures or the oracle harness. It writes a set of
hidden fixture files, invokes the candidate as
`xsh /work/groupsum.xsh <file>` for each case, and compares the candidate's
stdout byte-for-byte with an independent oracle:

- success cases: an external `printf` oracle emits the expected `KEY SUM\n`
  rows (the expected rows are derived from the authored fixture and known
  independently of XSH); the case passes only when the candidate exits 0 and
  its stdout matches the oracle byte-for-byte. The empty-file case expects
  empty stdout with exit 0.
- failure cases (mis-shaped line, invalid integer, unreadable file): an
  external `sh -c 'exit 1'` oracle emits nothing with a nonzero exit; the case
  passes only when the candidate also exits nonzero and prints nothing to
  stdout.

The evaluator then checks that the source reads through an XSH text API
(`read_text`), that it contains no forbidden subprocess boundary, and that
`review.md` preserves the required headings. It writes a JSON run manifest to
`<session>/run.json`.

The hidden cases are:

- `public`: `alpha 1`, `beta 2`, `gamma 3` -> `alpha 1`, `beta 2`, `gamma 3`;
- `hidden_accumulate`: repeated keys sum (`server 10`, `server 5`, `db 3`,
  `db 1` -> `db 4`, `server 15`);
- `hidden_order`: insertion order differs from byte order (`z 1`, `10 5`,
  `2 3`, `a 2` -> `10 5`, `2 3`, `a 2`, `z 1`, verifying that `"10"` sorts
  before `"2"`);
- `hidden_many`: one key repeated many times plus a second key (`build 1..4`,
  `test 7` -> `build 10`, `test 7`);
- `hidden_blank`: blank lines interspersed are ignored (`a 1`, blank, `b 2`,
  blank, `a 3` -> `a 4`, `b 2`);
- `hidden_empty`: empty/blank-only file -> empty stdout, exit 0;
- `hidden_bad_fields`: a line with three fields -> nonzero, empty stdout;
- `hidden_bad_value`: a non-integer value field -> nonzero, empty stdout;
- `hidden_missing`: the file does not exist -> nonzero, empty stdout.

Timing (candidate vs oracle wall ns) is recorded per case but is diagnostic
only; there is no strict runtime envelope.

## Metrics

Record correctness for all cases (success byte-exactness and failure
exit/empty-stdout semantics), restriction compliance (`read_text` reference and
no forbidden subprocess), worker turns, thinking blocks and reasoning tokens,
token buckets, provider cost, tool calls and errors, session wall span,
candidate/oracle timing, and protocol completion (`review.md` rows). This eval
has no strict candidate/oracle timing gate; timing is diagnostic until a stable
envelope is established.

## Manager policy

Use one trial by default; the controller-owned `## Trial plan` in the cycle
request may explicitly raise this to two. Classify repeated friction as
handbook guidance or a product issue only when it generalizes (for example, a
recurring misunderstanding of Map accumulation, integer parsing, or keyed
sorting); do not create a ticket for an ordinary short-task miss or evaluator
noise. A handbook change must name the concept it teaches and be replayed
before it is trusted. The no-subprocess and `read_text` checks keep a workaround
out of the accepted set, so a pass is evidence about typed Map/parse/sort
composition, not about a shell escape.

## Staged dry run

See `REPORT.md` under the run directory. The dry run exercised the reference
candidate across all nine hidden cases plus the failure controls on the local
build, and ran the package-owned evaluator's decision logic against a correct
candidate (pass) and a wrong-sum candidate (fail) to prove the evaluator
contract, isolation checks, and `run.json` manifest. The remaining unproven
surface is a live container trial of the exact `/work`/`/session` paths and a
real agent session.
