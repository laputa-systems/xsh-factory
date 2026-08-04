# Eval task-wordfreq

## Status

Draft.

## Purpose

Measure a practical free-text systems-glue workflow that no approved eval
covers: reading a plain-text file, tokenizing it into lowercase ASCII-letter
words, counting each distinct word, and emitting a byte-exact, word-sorted
`COUNT WORD` report. Existing evals extract and count a *fixed* structured
field (`task-logstat`'s 9th log field, `task-groupsum`'s numeric second
column), enumerate the filesystem (`task-ecount`, `task-manifest`), or count
fixed argv/extension values (`task-tags`, `task-ecount`); none tokenizes
*arbitrary free-form text* by running over non-letter boundaries, lowercases
the tokens, and builds a word-frequency map. `task-wordfreq` fills that gap
with the classic shell shape `tr | sort | uniq -c` — vocabulary and term
frequency for docs, package-change and log analysis, typo-check frequency —
performed entirely through typed XSH values without a subprocess.

## North-star hypothesis

XSH's stated role is practical systems glue; counting word frequencies in
free text is one of the most common text-processing chores (`tr`/`awk`/
`sort`/`uniq`-style). This eval probes whether an agent with the handbook can:

- read a file's text with `fs.read_text` and bring it into typed XSH values;
- tokenize on any non-ASCII-letter boundary and lowercase each token through a
  standard-library method (for example a `regex` replacement of
  `[^A-Za-z]+`, then `Str.lower`/`Str.split`);
- accumulate counts with immutable `Map.set`/`Map.get` updates;
- order the distinct words deterministically with `sort-by` so the report is
  stable and byte-exact against the oracle's `sort | uniq -c`.

The design resists task-specific hacks because hidden cases vary the input
(mixed case, embedded digits and punctuation, unusual whitespace, empty
files, no-letter files, non-ASCII letters), so each case must come from the
file's content and never from a hard-coded list. A hard-coded stdout, a
subprocess escape, or a wrong tokenization rule each fail a distinct gate.

## Task

Create `wordfreq.xsh`. It accepts one argument naming a text file and prints
one line per distinct word present, of the form:

```text
COUNT WORD
```

A **word** is a maximal run of ASCII letters (`A-Z` or `a-z`). Everything
else — digits, punctuation, spaces and newlines, and any non-ASCII letter —
separates words. Count each word case-insensitively: lowercase each token, so
`The` and `the` are the same word. Lines are sorted ascending by `WORD`
(ASCII/lexicographic order). There is exactly one ASCII space between the
count and the word, no alignment or padding, and a final newline on each
line. If the file has no words, print nothing and exit successfully.

The behavior is defined by this oracle, which the evaluator runs against each
input file:

```sh
sh /tmp/wordfreq-oracle.sh INPUT
```

where `/tmp/wordfreq-oracle.sh` contains:

```sh
#!/bin/sh
tr 'A-Z' 'a-z' < "$1" | tr -cs 'a-z' '\n' | sed '/^$/d' | sort | uniq -c | sed 's/^[[:space:]]*//'
```

The evaluator invokes the candidate equivalently to `xsh wordfreq.xsh INPUT`
and compares stdout byte-for-byte with the oracle's stdout. Complete
`review.md` using the supplied headings.

## Agent boundary

The worker runs as root in a minimal Alpine container with `/work` as its task
workspace. The image provides BusyBox, `xsh`, `xsht`, `curl`, and CA
certificates, and no extra packages: the `tr` / `sort` / `uniq` / `sed`
oracle applets are already in the shared base image, and `fs`, `regex`,
`Str`, `List`, and `Map` are part of `xsh` itself. There is no compiler,
repository checkout, or implementation source. The submitted program may not
use `run`, process APIs, `spawn`, shell commands, or any other subprocess
boundary; it must read the file through XSH text APIs, keep diagnostics off
stdout, and must not hard-code one input's current word list or counts.

## Oracle and evaluator

The evaluator runs in a separate read-only container boundary. It writes the
oracle script under the evaluator's writable `/tmp`, writes each input file
under `/tmp`, and runs the candidate and the oracle with the same input path
so both observe identical content. It compares stdout byte-for-byte and writes
the comparison evidence plus timings to the run manifest. Public and hidden
cases:

- `public`: `The quick brown fox. The fox jumps over the lazy dog!`
- `hidden_mixed_digits`: `foo2bar baz-BAT 3qux qux QUX mix9`
- `hidden_whitespace`: `  alpha\t beta \n alpha  beta  gamma\t\n`
- `hidden_case`: `Apple APPLE apple Banana banana`
- `hidden_utf8`: `café münchen NAÏVE`
- `hidden_empty`: empty file
- `hidden_nowords`: `123 !!! --- ###`

The evaluator checks the source does not contain the forbidden subprocess
boundary, requires that the source references the file-text Read API
(`read_text`) so a hard-coded stdout workaround is classified as a
restriction failure, and checks that `review.md` preserves both required
headings and contains no template placeholders.

## Metrics

Record correctness for all seven cases, restriction compliance, worker turns,
thinking blocks and reasoning tokens, token buckets, provider cost, tool
calls and errors, session wall span, candidate/oracle timing per case, and
protocol completion. This eval has no strict candidate/oracle timing gate;
both sides finish in milliseconds, so timing is diagnostic until a stable
envelope is established.

## Manager policy

Use one trial by default; the controller-owned `## Trial plan` in the cycle
request may explicitly raise this to two. Classify repeated friction as
handbook guidance or a product issue only when it is generalizable; do not
create a ticket for an ordinary short-task miss or evaluator noise. A handbook
change must name the concept it teaches and be replayed before it is trusted.
On approval, stage `evals/task-wordfreq/` with this scaffolding, including its
package-owned `evaluator.xsh`. The generic evaluator protocol stages and
mounts that script; do not add a task branch to `evaluate_common.xsh`.

## Staged dry run

The proposal was dry-run in the current cycle: a reference XSH solution
(`wordfreq.xsh` using `fs.read_text`, a `regex` replacement of the non-letter
runs, `Str.lower`/`Str.split`, immutable `Map` counting, and `sort-by`) was
checked with `xsht check` / `fmt` / `lint`, compared byte-for-byte against the
BusyBox `sh` oracle on all seven cases on the host, then the proposal's
evaluator was run in an isolated container against a staged `/work` directory
and produced a passing `run.json` with `classification: pass`. Negative
controls (hard-coded output, no-`read_text` text workaround, subprocess
escape, missing `review.md`) were each rejected with the intended
classification. The agent half (a live Pi worker) was not exercised because it
requires a paid agent session and a Pi auth file; the agent path is inherited
unchanged from the approved base image. See `dry-run/DRY-RUN.md` for evidence.

## CTO review

- Result: `rejected`
- Promotion: `promoted`
- Package: `complete`
- Missing package files: `None.`
- Status: `Draft.`
- Source run: `runs/run-1785881832583/phases/02-eval-design`
