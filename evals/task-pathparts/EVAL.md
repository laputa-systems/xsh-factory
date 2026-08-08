# Eval task-pathparts

## Status

Approved.

## Budget breach

None.

## Purpose

Measure a practical systems-administration / packaging-glue workflow that no
approved eval covers: decomposing one path argument into its directory, final
component, and extension through the typed `Path` value, and producing a
byte-exact three-line stdout contract. Existing evals transform argv text
(`task-tags`, `task-intsum`), walk a filesystem tree (`task-ecount`,
`task-manifest`, `task-bigfiles`, `task-findexec`, `task-dupcheck`,
`task-renamex`), read environment scalars (`task-envcfg`), or resolve a safe
joined path under a root (`task-safepath`); none reads a *single* path and
reports structural facts about the path itself. `task-pathparts` fills that
gap with the classic sysadmin/installer shape "print where something is, what
it is called, and what kind of file it is" — the XSH analogue of
`dirname` / `basename` / extension extraction, done as typed values instead of
a subprocess pipeline.

## North-star hypothesis

XSH's typed `Path` value is one of the boundaries the north star names
("connect processes, files, paths, streams, JSON, and system state"). The
handbook teaches `Path.parent()`, `Path.name()`, and `Path.ext()` and the
direct `Path(str)` cast for building a path from a runtime string. This eval
probes whether an agent with the handbook can:

- build a typed `Path` from a command-line argument with the direct cast;
- read the structural fields (`parent`, `name`, `ext`) as typed values;
- map the extension's "no extension" case (empty) to the required `none`
  sentinel without guessing;
- keep stdout to exactly the three contract lines.

A successful run teaches whether the typed-Path decomposition surface is
discoverable and whether the handbook's "use `xsht api`" guidance transfers to
a value-construction boundary. The design resists task-specific hacks because
hidden cases vary the path shape (deep absolute paths, multi-dot archives,
relative paths, hidden filename, dot-directory paths, plain filenames), so a
hard-coded answer or a subprocess escape each fail a distinct gate.

## Task

Create `pathparts.xsh`. It accepts exactly one path argument and prints exactly
three lines:

```text
dir=<directory part>
name=<final component>
ext=<extension, or the word none when there is no extension>
```

The directory part and final component follow `dirname` / `basename`
semantics on the one argument. The extension is the text after the final dot
of the final component **without** the leading dot; a filename with no
extension, or a hidden filename whose name consists of a leading dot and no
further dot (`.profile`), reports `none`, while a filename with a real
extension before a dot (`.config/app.yaml` → `yaml`, `pkg.tar.gz` → `gz`)
reports that extension. The behavior is defined by this oracle command
(the path argument is supplied by the evaluator):

```sh
sh /tmp/pathparts-oracle.sh PATH
```

where `/tmp/pathparts-oracle.sh` contains:

```sh
#!/bin/sh
dir=$(dirname "$1")
name=$(basename "$1")
case "$name" in
  ?*.*) ext="${name##*.}" ;;
  *) ext="none" ;;
esac
printf 'dir=%s\nname=%s\next=%s\n' "$dir" "$name" "$ext"
```

The evaluator invokes the candidate equivalently to `xsh pathparts.xsh PATH`
and compares the three stdout lines byte-for-byte with the oracle. Complete
`review.md` using the supplied headings.

## Agent boundary

The worker runs as root in a minimal Alpine container with `/work` as its task
workspace. The image provides BusyBox, `xsh`, `xsht`, `curl`, and CA
certificates, and no extra packages: the `sh` / `basename` / `dirname` oracle
applets are already in the shared base image, and the `Path` value is part of
`xsh` itself. There is no compiler, repository checkout, or implementation
source. The submitted program must build the path with the typed `Path` value
from the argument, must not use `run`, process APIs, `spawn`, shell commands,
or any other subprocess boundary, and must keep all diagnostics off stdout.

## Oracle and evaluator

The evaluator runs in a separate read-only container boundary. It writes the
oracle script under the evaluator's writable `/tmp`, runs the candidate and
the oracle with identical path arguments, and compares the three output lines
byte-for-byte. It writes the comparison evidence plus timings to the run
manifest. Public and hidden cases:

- `public`: `/srv/app/server.cfg`;
- `hidden_deep`: `/var/log/app/archive/2024-01-01.txt.gz`;
- `hidden_plain`: `notes`;
- `hidden_rel`: `conf/nginx.conf`;
- `hidden_dotdir`: `/home/u/.config/app.yaml`;
- `hidden_dotfile`: `/root/.profile` (no extension → `none`);
- `hidden_targz`: `report.tar.gz`.

The evaluator checks the source does not contain the forbidden subprocess
boundary, requires that the source references a documented typed-`Path`
construction (`Path(` or the lint-preferred `fp"${...}"`) so a hard-coded
text workaround is classified as a restriction failure, and checks that
`review.md` preserves both required headings and contains no template
placeholders.

## Metrics

Record correctness for all seven cases, restriction compliance, worker turns,
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
On approval, stage `evals/task-pathparts/` with this scaffolding, including
its package-owned self-contained `evaluator.xsh`. The generic evaluator
protocol stages and mounts that script; do not add a task branch to
`the shared evaluator dispatcher` or `the retired evaluator fallback`.

## Staged dry run

The proposal package scripts (`executor.xsh`, `evaluator.xsh`, `evaluate.xsh`,
and the Markdown contract) were validated in this cycle with `xsht check`
using the shared handbook's canonical reference. The typed `Path` semantics
were verified on every planned hidden case against the independent BusyBox
`sh` oracle on the local host build (each case produced identical
`dir`/`name`/`ext` lines). The live Pi agent session and the full isolated
Docker evaluator run were not exercised here because they require a paid agent
session and an `xsh-factory-base` container; that path is inherited unchanged
from the approved base image and will be exercised at review/approval.

## CTO review

- Result: `accepted`
- Promotion: `promoted`
- Package: `complete`
- Missing package files: `None.`
- Status: `Approved.`
- Source run: `runs/run-1785876949561/phases/04-eval-design`
