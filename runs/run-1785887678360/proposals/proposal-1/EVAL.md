# Eval task-emptyfiles

## Status

Draft.

## Budget breach

None.

## Purpose

Measure a practical systems-administration / disk-hygiene workflow that no
approved eval covers: discovering zero-byte regular files below a root through
the typed filesystem stream APIs, filtering on the structured `kind` and `size`
fields, sorting the resulting absolute paths deterministically, and emitting a
byte-exact path-per-line contract. `task-ecount` counts extension values,
`task-bigfiles` ranks files by size and takes the top N, `task-manifest`
enumerates a tree and writes a manifest, and `task-uniqcat` merges line sets;
none of them reports which files under a tree are empty (the classic
"find stale zero-length files" cleanup shape, the XSH analogue of the
`find -type f -empty` pipeline).

## North-star hypothesis

XSH's stated role is practical systems glue, and "list the empty files under a
tree" is a canonical read-only disk-hygiene inspection. This eval probes
whether an agent with the handbook can:

- walk a root with the typed filesystem stream APIs (`fs.files`) and filter on
  the structured `kind` field plus a numeric field (`size == 0`);
- sort a lazy collection of path strings deterministically (`sort-by`) so the
  output is stable and byte-exact;
- emit exactly one absolute path per line from the `path` field, with no
  leading/trailing decoration and no extra stdout;
- keep the entire transformation in XSH values with no subprocess escape.

A successful run teaches the factory whether scalar field filtering (`kind`,
`size`) on the filesystem stream, combined with a deterministic `sort-by`, is
discoverable and composable for a read-only inspection task. The design resists
task-specific hacks because hidden cases vary the tree shape, depth, naming,
and the mix of empty and non-empty files, and because a hard-coded list, a
subprocess escape, or extra diagnostic output each fail a distinct gate.

## Task

Create `emptyfiles.xsh`. It accepts one root directory argument:

    emptyfiles.xsh ROOT

It recursively finds the regular files under `ROOT` whose byte size is zero
and prints their absolute paths, one per line, sorted ascending in byte order
(the same order as a stationary `LC_ALL=C sort`). If no empty regular files
exist, it prints nothing and exits successfully. The program must discover the
tree through XSH filesystem values; it must not start subprocesses, invoke an
external command, or add diagnostic text to stdout. Complete `review.md`
using the supplied headings.

The behavior is defined by this oracle, run by the evaluator with the same
`ROOT` against a writable fixture tree it stages in `/tmp`. The `LC_ALL=C`
prefix pins the byte-wise (POSIX/C) ordering so the contract is identical in
any locale:

```sh
root="$1"
find "$root" -type f -empty -print | LC_ALL=C sort
```

The evaluator invokes the candidate equivalently to `xsh emptyfiles.xsh ROOT`
and compares its stdout byte-for-byte with the oracle's stdout.

## Agent boundary

The worker runs as root in a minimal Alpine container with `/work` as its task
workspace. The image provides BusyBox, `xsh`, `xsht`, `curl`, and CA
certificates, and no extra packages: the `find` / `sort` oracle applets are
already in the shared base image, and the `fs` and stream modules are part of
`xsh` itself. There is no compiler, repository checkout, or implementation
source. The submitted program may not use `run`, process APIs, `spawn`, shell
commands, or any other subprocess boundary; it must keep diagnostics off
stdout and must not hard-code one tree's results.

## Oracle and evaluator

The evaluator runs in a separate read-only container boundary. It writes the
oracle script under the evaluator's writable `/tmp`, stages a distinct fixture
tree for each case, and runs the candidate and the oracle with the identical
`ROOT` so both observe the same tree. It compares stdout byte-for-byte and
writes the comparison evidence plus timings to the run manifest. Public and
hidden cases:

- `public`: a shallow 4-file tree with two empty files — prints the two empty
  paths in sorted order;
- `hidden_default`: an 8-file tree with three empty files at different depths;
- `hidden_nested`: empty files three levels deep;
- `hidden_spaces`: directory and file names containing spaces;
- `hidden_utf8`: file names containing UTF-8 characters;
- `hidden_none`: a tree with regular files but no empty files — prints nothing.

The evaluator checks the source does not contain the forbidden subprocess
boundary, requires that the source references the filesystem stream module
(`fs.files` or `fs.walk`) and a `sort-by` stage so a hard-coded answer is
classified as a restriction failure, and checks that `review.md` preserves
both required headings and contains no template placeholders.

## Metrics

Record correctness for all six cases, restriction compliance, worker turns,
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
On approval, stage `evals/task-emptyfiles/` with this scaffolding, including
its package-owned `evaluator.xsh`. The generic evaluator protocol stages and
mounts that script; do not add a task branch to `evaluate_common.xsh`.

## Staged dry run

See `dry-run/DRY-RUN.md` in this proposal. A reference solution and the
external oracle were exercised on the host across a fixture that mixes empty
and non-empty files at two depths; the candidate byte-matched the oracle on
every fixture. The reference program also passes `xsht check`, `fmt`, and
`lint`. The container isolation and the package-owned evaluator wiring are
inherited unchanged from the approved scaffold and were not re-run end-to-end
in a container this cycle (the shared `/usr/local/lib/xsh-factory` evaluator
path is a container-only surface).
