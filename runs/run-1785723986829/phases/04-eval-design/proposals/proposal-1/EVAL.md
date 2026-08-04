# Eval task-dupcheck

## Status

Draft.

## Budget breach

None.

## Purpose

Measure a practical systems-administration workflow that no approved eval
covers: finding duplicate files by content. An agent must traverse a root with
the typed filesystem stream APIs, hash every regular file with the `hash`
module, group by digest, keep only groups with more than one member, and emit a
byte-exact `sha256sum`-shaped report in deterministic order — replacing the
classic `find | sha256sum | sort | awk` shell pipeline without a single
subprocess. `task-tags` transforms argv values, `task-ecount` counts
extensions, and `task-envcfg` reads environment configuration; none exercises
content hashing, grouping by a computed key, or multi-key deterministic
ordering of a filtered stream.

## North-star hypothesis

XSH's stated role is practical systems glue ("connect processes, files, paths,
streams, JSON, and system state"). Duplicate detection is a canonical
filesystem chore with a crisp external oracle. This eval probes whether an
agent with the handbook can:

- discover `hash.sha256(path)` via `xsht api` and apply `?.hex()` at the
  content boundary;
- combine `fs.files(root, hidden: true)` with `group-by .digest`, filter
  groups by `items.len() > 1`, and flatten members back to a stream;
- produce a deterministic ordering the walk itself does not guarantee, by
  sorting on digest then path so a duplicate set is consecutive and groups are
  stable across runs;
- notice and honor a real traversal semantic (hidden files and hidden
  directories included) rather than guessing a shell default;
- keep stdout to exactly the `<digest>  <path>` contract.

A successful run teaches the factory whether the hash module and the
group/flatten/sort stream idiom are discoverable and composable for a
real-world "replace this pipeline" task, and whether the handbook's streams and
typed-path lessons transfer to content-level work. The design resists
task-specific hacks because hidden cases vary the tree shape, hidden files,
three-way duplicates, spaces in paths, cross-group ordering, empty trees, and
a missing-root failure; a hard-coded answer, a silent empty result, a
subprocess escape, or a solution that never touches the `hash` module each
fails a distinct gate.

## Task

Create `dupcheck.xsh`. It accepts one absolute root directory argument and
prints, for every regular file below that root whose content is duplicated by
at least one other regular file, one line exactly `<sha256-hex>  <path>` (the
`sha256sum` text shape: digest, two spaces, path). Lines sort by digest then
path; hidden files and hidden directories are included; only regular files
count. With no duplicates, print nothing. The evaluator supplies several
fixture roots, so do not hard-code one result. Complete `review.md` using the
supplied headings.

## Agent boundary

The worker runs as root in a minimal Alpine container with `/work` as its task
workspace. The image provides BusyBox, `xsh`, `xsht`, `curl`, and CA
certificates, and no extra packages: the `sh`/`sha256sum`/`find`/`sort`/`awk`
oracle applets are already in the shared base image, and the `fs` / `hash`
modules are part of `xsh` itself. There is no compiler, repository checkout,
or implementation source. The submitted program may not use `run`, process
APIs, `spawn`, shell commands, or any other subprocess boundary; it must keep
diagnostics off stdout and must not hard-code one fixture's values.

## Oracle and evaluator

The evaluator runs in a separate read-only container boundary. It builds each
fixture tree under its own writable `/tmp`, runs the candidate
(`xsh /work/dupcheck.xsh ROOT`) and the oracle
(`sh /tmp/dupcheck-oracle.sh ROOT`) with the same absolute root, and compares
stdout byte-for-byte, recording per-case timing to the run manifest. The
oracle is:

```sh
find "$1" -type f -exec sha256sum {} + | sort | awk '
NR == 1 { prev = $1; out = $0; n = 1; next }
$1 == prev { out = out "\n" $0; n++; next }
{ if (n > 1) print out; prev = $1; out = $0; n = 1 }
END { if (n > 1) print out }'
```

Public and hidden cases:

- `public`: one duplicate pair plus one unique file (shown in the task
  prompt);
- `hidden_empty`: a tree with only unique files (empty output);
- `hidden_nested`: duplicates inside a hidden directory and under a hidden
  file name, plus a three-member set (hidden traversal);
- `hidden_three`: three identical files (runs longer than two);
- `hidden_spaces`: duplicate files whose names contain spaces (exact path
  handling);
- `hidden_many`: several duplicate groups whose digest order differs from
  their path order (global digest-first sort);
- `hidden_none`: an empty directory (empty output);
- `hidden_missing` (failure control): the root does not exist — candidate and
  oracle must both exit nonzero and emit no stdout.

The evaluator checks the source does not contain the forbidden subprocess
boundary, requires that the source references the hash module (`hash.`) so a
hard-coded or text-only workaround is classified as a restriction failure, and
checks that `review.md` preserves both required headings and contains no
template placeholders.

## Metrics

Record correctness for all eight cases (including the failure control),
restriction compliance, worker turns, thinking blocks and reasoning tokens,
token buckets, provider cost, tool calls and errors, session wall span,
candidate/oracle timing per case, and protocol completion. This eval has no
strict candidate/oracle timing gate; both sides finish in milliseconds on the
small fixture trees, so timing is diagnostic until a stable envelope is
established.

## Manager policy

Use one trial by default; the controller-owned `## Trial plan` in the cycle
request may explicitly raise this to two. Classify repeated friction as
handbook guidance or a product issue only when it is generalizable; do not
create a ticket for an ordinary short-task miss or evaluator noise. A handbook
change must name the concept it teaches and be replayed before it is trusted.
On approval, stage `evals/task-dupcheck/` with this scaffolding and merge the
`run_task_dupcheck` branch into the shared `evaluate_common.xsh` dispatch so
the normal `run-eval.xsh` build stages it into the image.

## Staged dry run

The proposal was dry-run in the current cycle: a reference XSH solution
(`dupcheck.xsh` using `fs.files(root, hidden: true)`, `hash.sha256(...)?.hex()`,
`group-by .digest`, `where .items.len() > 1`, `flat-map`, and `sort`) was
checked with `xsht check` / `fmt` / `lint`, compared byte-for-byte against the
BusyBox `sh` oracle on all eight fixture cases on the host, then the
proposal's evaluator was run in an isolated container against a staged `/work`
directory and produced a passing `run.json` with `classification: pass`.
Negative controls (subprocess escape, missing `hash.` reference, wrong output,
missing `review.md`) were each rejected with the intended classification. The
agent half (a live Pi worker) was not exercised because it requires a paid
agent session and a Pi auth file; the agent path is inherited unchanged from
the approved base image. See `dry-run/` for evidence.
