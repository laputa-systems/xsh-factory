# Eval task-findexec

## Status

Approved.

## Budget breach

None.

## Purpose

Measure a practical systems-administration workflow that no current eval
covers: filtering a filesystem tree by a permission bit and emitting the
matching paths in a stable, byte-exact order. `task-bigfiles` ranks files by
byte size, `task-ecount` groups by extension and counts, `task-manifest` emits
every regular file's path, `task-renamex` moves files by extension, and
`task-dupcheck` hashes content; none reads a file's mode or executable
metadata. `task-findexec` fills that gap with the classic deployment /
entry-point shape "list the executable files in a tree" — the XSH analogue of
`find ROOT -type f -perm -u+x | sort` — and a clean exercise of the typed
permission fields (`owner_executable`, `mode`, `kind`) the fs stream exposes.

## North-star hypothesis

An agent that has understood the XSH handbook and the typed fs stream should
be able to list owner-executable regular files with a short, direct pipeline:
traverse the root including hidden files, filter on the typed
`owner_executable` boolean, sort by path, and print. The eval probes (a)
whether the metadata fields on the fs stream records are discoverable and
trusted rather than guessed, and (b) whether the `hidden` option is found so
the result matches the oracle's dotfile set. A successful run is evidence
about the learnability and ergonomics of the typed metadata boundary. The
external oracle and the evaluator-supplied fixture distinguish a genuine
filtering implementation from a hard-coded listing, and the
owner/group/other distinction prevents a trivial "executable at all" shortcut.

## Task

Create `findexec.xsh`. It accepts one root directory argument and prints, one
per line and sorted in byte (lexicographic) order, the path of every regular
file at or below that root whose owner-execute permission bit is set. The
traversal must include hidden (dot) files, exactly as the oracle does. Print
only the matching paths, nothing else.

The behavior is defined by this oracle command, run by the evaluator on the
same root:

```sh
find "$ROOT" -type f -perm -u+x | sort
```

The evaluator invokes the candidate equivalently to `xsh findexec.xsh "$ROOT"`
and compares stdout byte-for-byte. The evaluator supplies several different
root directories (fixtures), so do not hard-code one result. Do not modify the
tree while computing the result.

The program must traverse the root through XSH filesystem APIs and decide
owner-executability from the metadata the stream exposes. It must not start
subprocesses, invoke an external command (including `find`), or add diagnostic
text to stdout.

Use the handbook and `xsht api` as the available XSH reference. A normal
development loop is:

    xsht api api:fs.files
    xsht api api:fs.metadata
    xsht check findexec.xsh
    xsht fmt findexec.xsh
    xsht lint findexec.xsh
    xsh findexec.xsh /usr/share

## Agent boundary

The worker runs as root in a minimal Alpine container with `/work` as its task
workspace. The image provides BusyBox, `xsh`, `xsht`, `curl`, and CA
certificates. It has no compiler, repository checkout, or implementation
source. The submitted program may not use `run`, process APIs, `spawn`, shell
commands, or any other subprocess boundary, and it must not modify the tree it
inspects.

## Oracle and evaluator

The evaluator runs in a separate read-only container boundary so the worker
cannot inspect the oracle harness. It builds a controlled fixture root, runs
the candidate and the BusyBox `find ... -perm -u+x | sort` oracle on that same
root, and compares stdout byte-for-byte. It also checks that the source does
not contain the forbidden subprocess boundary. The fixture includes: nested
directories plus a top-level regular file; owner-executable, group-executable-
only, other-executable-only, and non-executable regular files; hidden (dot)
regular files that are owner-executable; and a symlink to a regular file and a
symlinked directory, which are not regular files and must be excluded. A
negative-control case with no owner-executable files verifies empty output. The
evaluator verifies `review.md` preserves the supplied headings.

## Metrics

Record correctness for all cases, restriction compliance, worker turns,
thinking blocks and reasoning tokens, token buckets, provider cost, tool calls
and errors, session wall span, candidate/oracle timing, and protocol
completion. This eval has no strict candidate/oracle timing gate; timing is
diagnostic until a stable envelope is established.

## Manager policy

Use one trial by default; the controller-owned `## Trial plan` in the cycle
request may explicitly raise this to two. Classify repeated friction as
handbook guidance or a product issue only when it is generalizable; do not
create a ticket for an ordinary short-task miss or evaluator noise. A handbook
change must name the concept it teaches (for example, "the fs stream exposes
typed permission fields, and `hidden: true` is required to include dotfiles")
and be replayed before it is trusted.

## Staged dry run

Dry-run evidence proves the candidate pipeline matches the oracle byte-for-byte
inside the pinned gym base image across the fixture classes above: hidden
dotfiles, owner-only versus group/other-only executable bits, nested
directories, symlink exclusion, and a no-match negative control. It also proves
the staged executor/evaluator selectors reference the `task-findexec` id. The
evidence is preserved in the run's proposal-1 materialization.

## CTO review

- Result: `accepted`
- Promotion: `promoted`
- Package: `complete`
- Missing package files: `None.`
- Status: `Approved.`
- Source run: `runs/run-1785804030340/phases/04-eval-design`
