# Eval task-manifest

## Status

Draft.

## Budget breach

None.

## Purpose

Measure a practical systems-administration / packaging workflow that no current
eval covers: recursively enumerating a directory tree with the typed
filesystem stream APIs, computing each regular file's path relative to a root,
sorting the resulting list into a deterministic byte-exact order, and writing
the manifest to a file. `task-ecount` traverses and aggregates extension
counts, `task-bigfiles` ranks by byte size, `task-renamex` moves files, and
`task-envcfg` renders a config from environment scalars; none emits a sorted,
relative-path manifest as the deliverable. `task-manifest` fills that gap with
the classic shape "generate a sorted file manifest/index of a tree" — the XSH
analogue of `find ROOT -type f | sort` written to an output file, without a
subprocess.

## North-star hypothesis

XSH's stated role is practical systems glue; a sorted manifest of a tree is
how packages, backups, and release tooling name the set of files they ship.
This eval probes whether an agent with the handbook can:

- discover `fs.files` / `fs.walk` and the filesystem entry stream via
  `xsht api module:fs` / `api:fs.files`;
- compute a relative path from the entry with the typed `Path.relative_to`
  (or `strip_prefix`) API instead of fragile string prefix work;
- impose deterministic ordering with the stream `sort-by` stage and produce a
  byte-exact, newline-terminated manifest written with `fs.write`;
- keep the output clean (only the manifest) and fail a missing root loudly
  with postfix `?` so a bad root never leaves a partial output file.

A successful run teaches the factory whether the path-relative and
sort-by-stream surface is discoverable and composable, and whether the
handbook's traversal lesson transfers to a packaging-style deliverable. The
design resists task-specific hacks because hidden cases vary tree shape
(nested dirs, empty dirs, single file), names (spaces, UTF-8), and the
missing-root failure control, and because the restriction check requires the
source to reference a real file-discovery API — a hard-coded manifest, a
subprocess escape, or a silent fallback each fails a distinct gate.

## Task

Create `manifest.xsh`. It accepts two path arguments, a root directory and an
output path:

```text
xsh manifest.xsh ROOT OUT
```

Recursively find every regular file under `ROOT` (including files directly in
`ROOT`), and write to `OUT` one line per file containing the file's path
relative to `ROOT`, in byte-wise ascending sort order, each line terminated by
a newline. Do not include directories or empty directories. When `ROOT` does
not exist, exit nonzero and do not create `OUT`. When there are no regular
files under `ROOT`, write an empty `OUT` (zero bytes). The evaluator supplies
several different trees, so do not hard-code one listing. Complete `review.md`
using the supplied headings.

The behavior is defined by this oracle command (the evaluator supplies the
tree and calls the oracle with the same root; for a nonexistent `ROOT` the
oracle exits nonzero):

```sh
if [ ! -d ROOT ]; then exit 1; fi
find ROOT -type f | sed "s|^ROOT/||" | LC_ALL=C sort
```

## Agent boundary

The worker runs as root in a minimal Alpine container with `/work` as its task
workspace. The image provides BusyBox, `xsh`, `xsht`, `curl`, and CA
certificates, and no extra packages: `find`, `sed`, and `sort` (the oracle
applets) are already in the shared base image, and the `fs` / `Path` / `Str`
stream surfaces are part of `xsh` itself. There is no compiler, repository
checkout, or implementation source. The submitted program may not use `run`,
process APIs, `spawn`, shell commands, or any other subprocess boundary; it
must keep diagnostics off stdout and must not hard-code one tree's values.

## Oracle and evaluator

The evaluator runs in a separate read-only container boundary. It provisions a
writable scratch area, builds each per-case tree with `fs.mkdir` / `fs.write`,
runs the candidate (`xsh /work/manifest.xsh ROOT OUT`) and the `find`/`sort`
oracle on the same root, compares the manifest byte-for-byte with the oracle
stdout, verifies both processes, and records candidate/oracle wall time per
case. Public and hidden cases:

- `public`: a mixed root with files at the top level and in two nested
  directories;
- `hidden_nested`: deeper nesting;
- `hidden_empty_dirs`: subdirectories containing no regular files (excluded);
- `hidden_single`: exactly one file at the root — its relative path is just
  the file name;
- `hidden_spaces`: file and directory names containing spaces;
- `hidden_utf8`: Unicode names such as `café.txt`;
- `hidden_empty` (edge): root exists but has no regular files — empty `OUT`;
- `hidden_missing_root` (failure control): nonexistent root — candidate and
  oracle must both exit nonzero and the candidate must create no `OUT`.

The evaluator checks that the source does not contain the forbidden subprocess
boundary, requires that the source references a file-discovery API (`fs.files`
or `fs.walk`) so a hard-coded listing is classified as a restriction failure,
and checks that `review.md` preserves both required headings and contains no
template placeholders.

## Metrics

Record correctness for all eight cases (including the missing-root failure
control), restriction compliance, worker turns, thinking blocks and reasoning
tokens, token buckets, provider cost, tool calls and errors, session wall
span, candidate/oracle timing per case, and protocol completion. This eval has
no strict candidate/oracle timing gate; both sides finish in milliseconds, so
timing is diagnostic until a stable envelope is established.

## Manager policy

Use one trial by default; the controller-owned `## Trial plan` in the cycle
request may explicitly raise this to two. Classify repeated friction as
handbook guidance or a product issue only when it is generalizable; do not
create a ticket for an ordinary short-task miss or evaluator noise. A handbook
change must name the concept it teaches and be replayed before it is trusted.
The proposal is promoted into `evals/task-manifest/` with a package-owned
`evaluator.xsh`; new evals do not add a task branch to `evaluate_common.xsh`.

## Staged dry run

See `dry-run/DRY-RUN.md` in this proposal. A reference XSH solution
(`manifest.xsh` using `fs.files`, `sort-by .path`, `Path.relative_to`, and
`fs.write`) was checked with `xsht check` / `fmt` / `lint` inside the pinned
Alpine container, compared byte-for-byte against the BusyBox
`find`/`sed`/`sort` oracle on all eight cases, and the package-owned
evaluator's logic was exercised against a staged `/work` directory. Negative
controls (hard-coded listing, no file-discovery API, subprocess escape,
missing `review.md`, missing root) were each rejected with the intended
classification. The agent half (a live Pi worker) was not exercised because it
requires a paid agent session and a Pi auth file; the agent path is inherited
unchanged from the approved base image. The first paid trial remains the
integration check for the evaluator manifest (the controller-owned
`evaluate_common.xsh` dispatcher is not modified for this eval).
