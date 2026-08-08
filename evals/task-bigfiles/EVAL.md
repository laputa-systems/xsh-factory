# Eval task-bigfiles

## Status

Approved.

## Budget breach

None.

## Purpose

Measure a practical systems-administration workflow that no current eval
covers: ranking discovered files by a numeric attribute (byte size) and
emitting a top-N report. `task-ecount` groups and counts files by extension,
`task-envcfg` renders a config from environment scalars, `task-setdiff` diffs
line sets, and `task-jsonfilter` crosses a JSON boundary; none sorts files by a
per-file numeric field or truncates a ranked stream. `task-bigfiles` targets
the classic disk-hygiene shape "list the largest files in a tree" — the modern
XSH analogue of the `find | xargs ls -S | head` pipeline.

## North-star hypothesis

XSH's stated role is practical systems glue, and a size-ranked file report is
the canonical first-class `du`/`sort`/`head` composition. This eval probes
whether an agent with the handbook can:

- walk a root with the typed filesystem stream APIs (`fs.files`) and filter on
  the structured `kind` field;
- sort a lazy stream by a numeric record field in descending order and take
  only the top N;
- emit a byte-exact `<size> <path>` line contract, with absolute paths taken
  from the `path` field and byte counts with no leading padding;
- keep the transformation in XSH values with no subprocess escape;
- propagate a malformed-count failure with postfix `?` so a non-integer N
  exits nonzero and prints nothing.

A successful run teaches the factory whether numeric stream ordering
(`sort-by` on a per-file size plus `take`) is discoverable and composable, and
whether the handbook's Result / `?` idiom transfers to a real ranked-report
boundary. The design resists task-specific hacks because hidden cases vary the
tree shape, file count, naming, and depth, and because the failure control
requires a loud nonzero exit on a non-integer N — a hard-coded list, a silent
default, or a subprocess escape each fail a distinct gate.

## Task

Create `bigfiles.xsh`. It accepts a root directory path and an optional count:

    bigfiles.xsh ROOT [N]

It recursively finds the regular files under `ROOT` and prints the `N`
largest by byte size (default `N` = 5), from largest to smallest, exactly one
line per file:

    <byte-size> <path>

`<byte-size>` is the file size in bytes with no leading padding; `<path>` is
the absolute file path as reported by the filesystem entry. If fewer than `N`
regular files exist, print all of them. No two files in the supplied trees
share the same byte size, so the size ordering is unambiguous. If `N` is
present but not a decimal integer, the program must exit nonzero and print
nothing. The program must discover the tree through XSH filesystem values; it
must not start subprocesses, invoke an external command, or add diagnostic
text to stdout. Complete `review.md` using the supplied headings.

The behavior is defined by this oracle, run by the evaluator with the same
`ROOT` and `N` against a writable fixture tree it stages in `/tmp`:

```sh
root="$1"; n="${2:-5}"
find "$root" -type f | while read -r f; do
  size=$(($(wc -c < "$f")))
  printf '%d %s\n' "$size" "$f"
done | sort -k1,1rn | head -n "$n"
```

The evaluator invokes the candidate equivalently to `xsh bigfiles.xsh ROOT N`
and compares its stdout byte-for-byte with the oracle's stdout.

## Agent boundary

The worker runs as root in a minimal Alpine container with `/work` as its task
workspace. The image provides BusyBox, `xsh`, `xsht`, `curl`, and CA
certificates, and no extra packages: the `find` / `wc` / `sort` / `head` /
`printf` oracle applets are already in the shared base image, and the `fs` and
stream modules are part of `xsh` itself. There is no compiler, repository
checkout, or implementation source. The submitted program may not use `run`,
process APIs, `spawn`, shell commands, or any other subprocess boundary; it
must keep diagnostics off stdout and must not hard-code one tree's results.

## Oracle and evaluator

The evaluator runs in a separate read-only container boundary. It writes the
oracle script under the evaluator's writable `/tmp`, stages a distinct fixture
tree for each case, and runs the candidate and the oracle with identical
`ROOT` and `N` so both observe the same tree. It compares byte-for-byte and
writes the comparison evidence plus timings to the run manifest. Public and
hidden cases:

- `public`: a 4-file tree, no `N` (default 5) — prints all 4;
- `hidden_default`: an 8-file tree including a dot-prefixed regular file, no
  `N` — top 5; this case makes the documented `hidden: true` selection
  observable rather than allowing the default omission to pass silently;
- `hidden_n2`: a 5-file tree, `N=2` — top 2;
- `hidden_single`: a 1-file tree, `N=5` — prints that one;
- `hidden_deep`: files three levels deep;
- `hidden_spaces`: directory and file names containing spaces;
- `hidden_utf8`: file names containing UTF-8 characters;
- `hidden_empty`: a tree with no regular files — prints nothing;
- `hidden_bad_n` (failure control): `N=abc` — candidate and oracle must both
  exit nonzero and print nothing.

The evaluator checks the source does not contain the forbidden subprocess
boundary, requires that the source references the filesystem stream module
(`fs.files` or `fs.walk`) and a `sort-by` stage so a hard-coded answer is
classified as a restriction failure, and checks that `review.md` preserves
both required headings and contains no template placeholders.

## Metrics

Record correctness for all nine cases (including the failure control),
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
On approval, stage `evals/task-bigfiles/` with this scaffolding, including its
package-owned `evaluator.xsh`. The generic evaluator protocol stages and
mounts that script; do not add a task branch to `the shared evaluator dispatcher`.

## Staged dry run

See `dry-run/DRY-RUN.md` in this proposal. The reference solution and the
external oracle were exercised on the host across the public case, the eight
hidden cases, and the failure control; the candidate byte-matched the oracle
on every passing case and both exited nonzero on the failure control. The
reference program also passes `xsht check`, `fmt`, and `lint`. The container
isolation and the package-owned evaluator wiring are inherited unchanged from
the approved scaffold and were not re-run end-to-end in a container this cycle
(the shared `/usr/local/lib/xsh-factory` evaluator path is a container-only
surface).

## CTO review

- Result: `accepted`
- Promotion: `promoted`
- Package: `complete`
- Missing package files: `None.`
- Status: `Approved.`
- Source run: `runs/run-1785784385782/phases/04-eval-design`
