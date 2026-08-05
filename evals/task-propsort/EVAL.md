# Eval task-propsort

## Status

Approved.

## Budget breach

None.

## Purpose

Measure a practical systems-administration workflow that no current eval
covers: reading a plain-text configuration/allowlist file, cleaning it
line-by-line, and writing a byte-exact, sorted result. Approved and active
evals cover CLI value transforms (task-tags), filesystem walks (task-ecount,
task-findexec, task-bigfiles, task-manifest), environment-rendered config
(task-envcfg), and collection/stream transforms (task-setdiff, task-uniqcat,
task-dupcheck, task-total). None reads a multi-line text file as its input and
normalizes it into a sorted stdout contract. `task-propsort` fills that gap
with the classic sysadmin shape "clean and canonicalize an allowlist /
properties file."

## North-star hypothesis

XSH's stated role is practical systems glue; normalizing a text config or
allowlist is one of the most common shell-administration chores. This eval
probes whether an agent with the handbook can:

- discover the `fs` read facade and `text`/`Str` line handling needed to bring
  a multi-line file into typed values without subprocesses;
- apply `Str.trim()` and `starts_with(...)` from the handbook's documented
  method surface;
- filter blank and comment lines with a stream `where` stage;
- sort the surviving lines with `sort-by` and join them back into one exact
  stdout contract, including the empty-result edge (print nothing, exit 0);
- keep stdout free of diagnostics with a file (not argv or env) as the input.

A successful run teaches the factory whether the text/file/stream read->filter
->sort->exact-output pipeline is discoverable and composable, and whether the
handbook's stream and exact-output lessons transfer to a real config-file
normalization boundary. The design resists task-specific hacks because hidden
cases vary blank/comment/whitespace-heavy lines and the empty result, and
because a hard-coded output, a lost final newline, or an added diagnostic each
fails a distinct gate.

## Task

Create `propsort.xsh`. It accepts one argument naming a UTF-8 text file. It
reads that file and prints to stdout, in ascending order, each line that is
neither blank nor a comment, with leading and trailing whitespace trimmed and
each line followed by a newline.

- A line is blank if its trimmed value is empty.
- A line is a comment if its trimmed value starts with `#`.
- Trimming removes leading and trailing whitespace only; interior characters
  are preserved.
- The surviving lines are sorted in ascending byte order (a normal ASCII
  lexicographic sort).
- Output is one line per entry, each terminated with a newline. If no lines
  qualify, print nothing and exit 0.

Do not hard-code the input. The program must perform the work through XSH
values and host modules. It must not start subprocesses, invoke an external
command, or add diagnostic text to stdout.

Use the handbook and the available `xsht` checks as the reference. A normal
development loop is:

    xsht check propsort.xsh
    xsht fmt propsort.xsh
    xsht lint propsort.xsh
    xsh propsort.xsh /path/to/input.txt

The behavior is defined by this oracle, run by the evaluator on the same input
file (via the BusyBox `sh` / `sed` / `grep` / `sort` applets already in the
shared base image):

```sh
sed 's/^[[:space:]]*//; s/[[:space:]]*$//' "$in" \
  | grep -v '^#' | grep -v '^$' | LC_ALL=C sort
```

## Agent boundary

The worker runs as root in a minimal Alpine container with `/work` as its task
workspace. The image provides BusyBox, `xsh`, `xsht`, `curl`, and CA
certificates, and no extra packages: the `sed` / `grep` / `sort` oracle
applets are already in the shared base image, and the `fs` / text handling is
part of `xsh` itself. There is no compiler, repository checkout, or
implementation source. The submitted program may not use `run`, process APIs,
`spawn`, shell commands, or any other subprocess boundary; it must keep
diagnostics off stdout and must not hard-code one input's values.

## Oracle and evaluator

The evaluator runs in a separate read-only container boundary. It writes a
per-case input file under the evaluator's writable directory and runs the
candidate (`xsh propsort.xsh IN`) and the oracle with the same input,
comparing byte-for-byte and writing comparison evidence plus timings to the
run manifest. Public and hidden cases:

- `public`: a mixed file with comments, blank lines, and ASCII entries;
- `hidden_mixed`: a file with leading/trailing whitespace around entries;
- `hidden_comments_only`: only `#`, blank, and whitespace-only lines (empty
  result, exit 0);
- `hidden_empty`: an empty input file (empty result, exit 0);
- `hidden_blank_lines`: many blank lines between entries;
- `hidden_tab_whitespace`: entries indented with tabs and trailing tabs;
- `hidden_duplicates`: duplicate entries that must both be preserved;
- `hidden_unsorted`: a deliberately out-of-order file;
- `hidden_restriction` (negative control): a candidate that shells out or
  adds a diagnostic to stdout must fail.

The evaluator checks the source does not contain the forbidden subprocess
boundary, requires that the source actually reads the input file through the
`fs` facade (a text literal or hard-coded output is classified as a
restriction failure), and checks that `review.md` preserves both required
headings and contains no template placeholders.

## Metrics

Record correctness for all cases (including the empty-result failure controls),
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
On approval, stage `evals/task-propsort/` with this scaffolding, including its
package-owned `evaluator.xsh`. The generic evaluator protocol stages and
mounts that script; do not add a task branch to `the shared evaluator dispatcher`.

## Staged dry run

The proposal was dry-run in the current cycle: a reference XSH solution
(`propsort.xsh` using `fs.read_text` / `Str.trim` / stream `where` / `sort-by`
/ `join`) was checked with `xsht check` / `fmt` / `lint` and compared
byte-for-byte against the BusyBox `sh`/`sed`/`grep`/`sort` oracle on the
representative cases on the host. Negative controls (hard-coded output,
subprocess escape, missing `review.md`) were each rejected with the intended
classification. The agent half (a live Pi worker) was not exercised because it
requires a paid agent session and a Pi auth file; the agent path is inherited
unchanged from the approved base image. See `dry-run/DRY-RUN.md` for evidence.

## CTO review

- Result: `accepted`
- Promotion: `promoted`
- Package: `complete`
- Missing package files: `None.`
- Status: `Approved.`
- Source run: `runs/run-1785805967215/phases/04-eval-design`
