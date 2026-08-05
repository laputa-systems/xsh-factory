# Eval task-renamex

## Status

Approved.

## Budget breach

None.

## Purpose

Measure a practical systems-administration workflow that no current eval
covers: a bulk batch rename of files by extension, performed entirely through
the typed filesystem API. The approved evals traverse the filesystem to read
(`task-ecount`), rank by metadata (`task-bigfiles`), hash content
(`task-dupcheck`), or filter text (`task-grep`, `task-total`),
and `task-envcfg` writes a single config file; none moves or renames a set of
files. `task-renamex` fills the write/mutation side of filesystem glue with
the classic housekeeping shape "rename every `*.tmp` file to `*.bak`" — the
XSH analogue of a `find ... -exec mv` pipeline, without a subprocess.

## North-star hypothesis

XSH's stated role is to make the cheap host operations visible as typed host
APIs while rejecting shell sludge ("the expensive work should be visible as a
process, a file operation, or a typed host API"). This eval probes whether an
agent with the handbook can:

- discover the recursive filesystem stream (`fs.files`) and the `kind`/`name`/
  `path` entry fields it exposes;
- filter entries by a Str suffix predicate (`Str.ends_with`);
- build a new path by transforming the displayed path string and casting it
  back with `Path(...)`;
- perform the host rename boundary through `fs.rename(source, dest,
  overwrite)`;
- do all of it without a subprocess `mv` — the no-subprocess restriction makes
  a shell-escape hack a distinct, loud failure.

A successful run teaches the factory whether the filesystem *write* surface
(rename with an explicit overwrite policy) is discoverable and composable, and
whether the handbook's path-cast guidance transfers to a mutation workflow.
The design resists task-specific hacks because hidden cases vary where
`.tmp` files sit (flat, nested, dot-names, none), and because the negative
controls — a hard-coded no-op, a subprocess escape, a rename to the wrong
extension, or a missing `review.md` — each fail a distinct gate.

## Task

Create `renamex.xsh`. It accepts one directory path argument. It renames every
regular file in that directory tree whose name ends with `.tmp`, replacing the
`.tmp` suffix with `.bak` (for example `report.tmp` becomes `report.bak`, and
`a/b/c.tmp` becomes `a/b/c.bak`). Files whose names do not end in `.tmp` are
left unchanged; directories are never renamed. The program must perform the
rename through the XSH filesystem API (`fs.rename`): it must not start
subprocesses, invoke an external `mv`, or add diagnostic text to stdout. When
the argument directory does not exist, the program must exit nonzero.

The behavior is defined by this oracle command, which the evaluator runs
against a fresh copy of the same fixture tree:

```sh
sh /tmp/task-renamex-oracle.sh DIR
```

where `/tmp/task-renamex-oracle.sh` contains:

```sh
#!/bin/sh
if [ ! -d "$1" ]; then exit 1; fi
for f in $(find "$1" -type f -name '*.tmp'); do
  mv "$f" "${f%.tmp}.bak"
done
exit 0
```

The evaluator compares the resulting set of relative file paths (sorted) of
the candidate's tree with the oracle's tree. Complete `review.md` using the
supplied headings.

## Agent boundary

The worker runs as root in a minimal Alpine container with `/work` as its task
workspace. The image provides BusyBox, `xsh`, `xsht`, `curl`, and CA
certificates, and no extra packages: the `sh` / `find` / `mv` oracle applets
are already in the shared base image, and the `fs` module is part of `xsh`
itself. There is no compiler, repository checkout, or implementation source.
The submitted program may not use `run`, process APIs, `spawn`, shell
commands, or any other subprocess boundary; it must keep diagnostics off
stdout and must not hard-code one fixture's file list.

## Oracle and evaluator

The evaluator is package-owned and self-contained (no task branch is added to
the shared evaluator module). It runs in a separate read-only container
boundary. For each case it seeds two identical fixture trees (one for the
candidate, one for the oracle) under `/tmp`, runs the candidate with
`xsh /work/renamex.xsh CAND_DIR` and the oracle with `sh /tmp/task-renamex-
oracle.sh ORAC_DIR`, then compares the sorted relative file-path listings of
the two resulting trees byte-for-byte and records per-case timings. Public and
hidden cases:

- `public`: `a.tmp`, `b.tmp`, `keep.txt`;
- `hidden_nested`: `top.tmp`, `sub/deep.tmp`, `sub/note.txt`;
- `hidden_dotname`: `proj/x.tmp`, `.hidden.tmp`, `proj/doc.md`;
- `hidden_no_suffix`: `tmp`, `note.txt`, `data.log` (nothing renames);
- `hidden_empty`: an empty directory (no renames, exit 0);
- `hidden_missing` (failure control): the argument is a nonexistent path —
  candidate and oracle must both exit nonzero.

The evaluator checks the source does not contain the forbidden subprocess
boundary, requires that the source references the filesystem rename API
(`fs.rename`) and a filesystem discovery API (`fs.files` or `fs.walk`) so a
printed or hard-coded workaround is classified as a restriction failure, and
checks that `review.md` preserves both required headings and contains no
template placeholders.

## Metrics

Record correctness for all six cases (including the failure control),
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
On approval, stage `evals/task-renamex/` with this scaffolding, including its
package-owned `evaluator.xsh`. The generic evaluator protocol stages and
mounts that script; do not add a task branch to the shared evaluator module.

## Staged dry run

The proposal was dry-run in the current cycle. The reference XSH solution
(`renamex.xsh` using `fs.files`, a `Str.ends_with` filter, `Path(...)` on the
displayed path, and `fs.rename`) was checked with `xsht check` / `fmt` / `lint`
and matched the BusyBox `sh` oracle on all six cases by comparing resulting
file trees. The package-owned evaluator was run on the host (via
`WORK_DIR`/`SESSION_DIR`/`EXPORT_DIR` overrides) and produced a passing
`run.json` with `classification: pass`. Negative controls were each rejected
with the intended classification: a subprocess escape → `restriction_failed`;
a solution without `fs.rename` → `restriction_failed`; a rename to the wrong
extension → `candidate_failed`; and a missing `review.md` → `protocol_failed`.
The agent half (a live Pi worker) was not exercised because it requires a paid
agent session and a Pi auth file; the agent path is inherited unchanged from
the approved base image. See `dry-run/DRY-RUN.md` for evidence.

## CTO review

- Result: `accepted`
- Promotion: `promoted`
- Package: `complete`
- Missing package files: `None.`
- Status: `Approved.`
- Source run: `runs/run-1785797449435/phases/04-eval-design`
