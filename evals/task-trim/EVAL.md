# Eval task-trim

## Status

Approved.

## CTO review

- Result: `accepted`
- Promotion: `promoted`
- Package: `complete`
- Missing package files: `None.`
- Status: `Approved.`
- Source run: `runs/run-1785869846042/phases/02-eval-design`

## Purpose

Measure a practical systems-administration workflow that no current eval
covers: reading a text file, applying a per-line text transform, and writing a
byte-exact cleaned file. The approved evals (task-tags, task-ecount, task-envcfg)
transform command-line values, count extensions, or write an env-derived config;
none reads a file's *content* line-by-line and rewrites it. `task-trim` fills
that gap with the classic sysadmin shape "clean a generated config or log file
by stripping leading and trailing whitespace from every line" — a task a build
or installer script does routinely before it diffs, ships, or parses a file.

## North-star hypothesis

XSH's stated role is practical systems glue ("connect processes, files, paths,
streams, JSON, and system state"); file text transformation is core glue work.
This eval probes whether an agent with the handbook can:

- read a file's lines as XSH values via the `fs` module and stream stages
  (not by shelling out to `sed` / `tr` / `awk`);
- apply a per-line transformation and reassemble the lines with exact
  newline separation;
- write the result to a second path argument with `fs.write`;
- keep stdout clean while the deliverable is a file, and leave the input
  unchanged.

A successful run teaches the factory whether the handbook's filesystem-stream
and text-method lessons compose into a real line-oriented file tool. The design
resists task-specific hacks because hidden cases vary leading/trailing space,
tab, internal, blank, and empty-line shapes, and because the byte-exact oracle
matches the exact `sed` behavior with no ambiguity.

## Task

Create `trim.xsh`. It accepts two path arguments IN and OUT. It reads the text
file at IN and writes a cleaned copy to OUT: every ASCII space (`0x20`) or tab
(`0x09`) at the start or the end of each line is removed. Internal whitespace,
blank lines, and line structure are preserved; a line containing only spaces
and/or tabs becomes an empty line. Input files are newline-terminated, and the
output keeps one `\n` per input line. The behavior is defined by this oracle
command (input is supplied by the evaluator):

```sh
sed 's/^[ \t]*//; s/[ \t]*$//' "$IN" > "$OUT"
```

Complete `review.md` using the supplied headings.

## Agent boundary

The worker runs as root in a minimal Alpine container with `/work` as its task
workspace. The image provides BusyBox, `xsh`, `xsht`, `curl`, and CA
certificates, and no extra packages: the `sed` / `printf` oracle applets are
already in the shared base image, and the `fs` module is part of `xsh` itself.
There is no compiler, repository checkout, or implementation source. The
submitted program may not use `run`, process APIs, `spawn`, shell commands, or
any other subprocess boundary; it must keep diagnostics off stdout and must
not hard-code one input file's current contents.

## Oracle and evaluator

The evaluator runs in a separate read-only container boundary. For each case it
writes an input file in its writable `/tmp`, runs the candidate (invoked
equivalently to `xsh trim.xsh IN OUT`) and the `sed` oracle on the same input,
and compares the written output byte-for-byte. It records the comparison
evidence plus candidate/oracle timings in the run manifest. Public and hidden
cases:

- `public`: several lines mixing leading/trailing spaces, a clean line, and a
  blank line;
- `hidden_tab`: lines mixing leading and trailing tabs with spaces;
- `hidden_blank_lines`: multiple consecutive blank and whitespace-only lines;
- `hidden_internal_only`: lines whose whitespace is entirely internal
  (must be preserved unchanged);
- `hidden_cr`: a line ending inside content with spaces and tabs but no edge
  whitespace (unchanged);
- `hidden_single_line`: one short line with no whitespace edges;
- `hidden_all_ws`: a file whose lines are all spaces/tabs (becomes empty
  lines);
- `hidden_utf8`: a UTF-8 line with spaces on the edges but no space inside
  non-ASCII text.

The evaluator checks the source does not contain the forbidden subprocess
boundary, requires that the source references the filesystem module (`fs.`)
and the text-read path so a hard-coded text workaround is classified as a
restriction failure, verifies the input file is left unchanged, and checks that
`review.md` preserves both required headings and contains no template
placeholders.

## Metrics

Record correctness for all eight cases, restriction compliance, worker turns,
thinking blocks and reasoning tokens, token buckets, provider cost, tool calls
and errors, session wall span, candidate/oracle timing per case, and protocol
completion. This eval has no strict candidate/oracle timing gate; both sides
finish in milliseconds, so timing is diagnostic until a stable envelope is
established.

## Manager policy

Use one trial by default; the controller-owned `## Trial plan` in the cycle
request may explicitly raise this to two. Classify repeated friction as
handbook guidance or a product issue only when it is generalizable; do not
create a ticket for an ordinary short-task miss or evaluator noise. A handbook
change must name the concept it teaches and be replayed before it is trusted.
On approval, stage `evals/task-trim/` with this scaffolding, including its
package-owned `evaluator.xsh`. The generic evaluator protocol stages and mounts
that script; the proposal adds no task branch to any shared evaluator module.

## CTO review

- Result: `accepted`
- Promotion: `promoted`
- Package: `complete`
- Missing package files: `None.`
- Status: `Approved.`
- Source run: `runs/run-1785869846042/phases/02-eval-design`
