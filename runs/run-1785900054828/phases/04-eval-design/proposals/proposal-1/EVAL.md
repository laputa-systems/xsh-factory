# Eval task-treecmp

## Status

Draft.

## Budget breach

None.

## Purpose

Measure a practical systems-administration / deployment capability that no
approved eval covers: reconciling a **live filesystem tree against a declared
size manifest** and emitting a deterministic deviation report (missing,
changed, extra). Existing evals read and rewrite a single file
(`task-propsort`, `task-total`), aggregate one file or a tree into a keyed
summary (`task-groupsum`, `task-svcstat`, `task-usagerep`), merge two
plain-text keyed files (`task-keyjoin`), or rank files by one numeric field
(`task-bigfiles`). None **parses a declarative manifest into a keyed lookup
and then cross-checks a live tree against it with per-key attribute
comparison** — the classic drift/immutability check used by config
deployment, image verification, and inventory reconciliation ("verify this
tree is exactly what the manifest says"). `task-treecmp` targets that shape:
the modern XSH analogue of a `find | sort` plus `join` plus size-comparison
pipeline.

## North-star hypothesis

XSH's stated role is practical systems glue, and reconciling declared state
against observed state is first-class typed stream work. This eval probes
whether an agent with the handbook can:

- read the manifest through the typed text surface and parse each
  `path<TAB>size` line into a keyed lookup, with a strict validation that a
  malformed line makes the program exit nonzero with empty stdout;
- traverse a root with the typed filesystem stream (`fs.files` / `fs.walk`),
  derive each file's **relative path** from the absolute entry path, and read
  its **actual byte size** from the structured `size` field — two independent
  transforms over two different input sources (a text file and a directory
  tree);
- merge the two keyed sets (a stateful set/union reconciliation) and classify
  each path as `missing` (in manifest, absent on disk), `changed` (size
  differs), or `extra` (on disk, not declared);
- impose a strict failure control: an absent/unreadable manifest or any
  malformed manifest line must exit nonzero with empty stdout, so a lenient,
  partial-report solution is loudly rejected;
- emit a byte-exact, deterministically sorted deviation report with no
  subprocess escape.

A successful run teaches the factory whether a declared-state-vs-observed
reconciliation — parsing a lookup, walking a tree, computing a relative path,
and folding two keyed sets into a deviation classification — is discoverable
and composable, and whether the handbook's Result / `?` failure idiom transfers
to a dual-source cross-boundary check.

## Difficulty justification

This task meets or exceeds the ecount composition bar because it requires
**two independent XSH data transformations over two different input sources**
plus **stateful aggregation**:

1. **Manifest → keyed lookup transform.** Read the manifest text, split each
   line on the single tab, reject malformed lines (wrong field count, empty
   path, non-decimal size), and fold valid entries into a `path → size` map.
   This is a stateful parse that can fail midway.
2. **Filesystem traversal transform.** `fs.files`/`fs.walk` over a recursive
   root, derive each regular file's **relative path** from the absolute path,
   and project its actual `size` — a structured stream transformation.
3. **Stateful merge/classification.** Join the two keyed sets and reduce to a
   deterministic deviation classification (`missing` / `changed` / `extra`)
   with a full-line byte sort, then emit a byte-exact report.

The **meaningful failure control** is a reigning gate: an absent/unreadable
manifest or any malformed manifest line must exit nonzero with empty stdout,
forcing the agent to propagate a typed/validation failure loudly rather than
silently defaulting or emitting a partial report.

The **hidden cases defeat a one-liner or hard-coded answer**: the public case
shows every deviation class, but hidden cases vary which paths are
missing/changed/extra, the tree shape and file count, empty trees, empty
manifests, directory structure, file names containing spaces, and UTF-8 file
names. No single tree or line set can be hard-coded, and the two failure
controls (missing manifest, malformed manifest) independently punish both a
silent-default and a subprocess escape. This is at least ecount-level: ecount
traverses a root and counts extensions; treecmp adds a second independent
typed source, a strict dual-source validation, and a three-way keyed merge.

## Task

Create `treecmp.xsh`. It accepts a root directory and a manifest file:

    treecmp.xsh ROOT MANIFEST

The manifest is a plain-text file, one expected regular file per line:

    RELATIVE_PATH<TAB>BYTE_SIZE

`RELATIVE_PATH` is the file's path relative to `ROOT`, using `/` separators,
with no leading `./`, no trailing slash, and no tab or newline characters.
`BYTE_SIZE` is the expected size in bytes as an unsigned decimal integer (at
least one digit).

The program must:

- exit nonzero and print nothing to stdout if `MANIFEST` does not exist, is
  not a regular readable file, or if any manifest line is malformed (a line
  without exactly one tab, an empty relative path, or a size that is not a
  run of decimal digits);
- recursively discover every regular file under `ROOT`, computing its
  relative path (relative to `ROOT`) and its actual byte size;
- classify every manifest entry and every discovered file:
  - `missing` — the relative path is in the manifest but has no corresponding
    regular file in the tree;
  - `changed` — a regular file exists at that relative path but its actual
    byte size differs from the manifest value;
  - `extra` — a discovered regular file whose relative path is not in the
    manifest;
- print exactly one line per deviation with no leading/trailing padding:

      missing<TAB>RELATIVE_PATH
      changed<TAB>RELATIVE_PATH<TAB>EXPECTED<TAB>ACTUAL
      extra<TAB>RELATIVE_PATH

- print the deviation lines sorted byte-lexicographically by the **entire
  line** (which places `changed…` before `extra…` before `missing…` and
  orders paths within each class), one line per deviation;
- print nothing when there are no deviations.

The evaluator supplies several different trees and manifests, so do not
hard-code one result. The program must perform the traversal through XSH
filesystem values and parse the manifest through XSH text values; it must not
start subprocesses, invoke an external command, or add diagnostic text to
stdout. Complete `review.md` using the supplied headings.

The behavior is defined by this oracle, run by the evaluator with the same
`ROOT` and `MANIFEST` against a fixture it stages in `/tmp`:

```sh
root="$1"; manifest="$2"
if [ ! -f "$manifest" ]; then exit 1; fi
tmp=$(mktemp -d) || exit 1
awk -F '\t' '
  NF != 2 || $1 == "" || $2 !~ /^[0-9]+$/ { exit 1 }
  { print }
' "$manifest" > "$tmp/exp" || { rm -rf "$tmp"; exit 1; }
( cd "$root" && find . -type f ) | while IFS= read -r f; do
  rel=${f#./}
  size=$(wc -c < "$root/$rel") || exit 1
  printf '%s\t%s\n' "$rel" "$size"
done | sort -t$'\t' -k1,1 > "$tmp/live"
sort -t$'\t' -k1,1 "$tmp/exp" > "$tmp/exps"
awk -F '\t' -v f1="$tmp/exps" -v f2="$tmp/live" '
  BEGIN {
    while ((getline line < f1) > 0) { split(line, a, "\t"); want[a[1]] = a[2] }
    while ((getline line < f2) > 0) { split(line, a, "\t"); got[a[1]] = a[2] }
    for (p in want) {
      if (!(p in got)) print "missing\t" p
      else if (got[p] != want[p]) print "changed\t" p "\t" want[p] "\t" got[p]
    }
    for (p in got) if (!(p in want)) print "extra\t" p
  }
' | sort
rm -rf "$tmp"
```

The evaluator invokes the candidate equivalently to `xsh treecmp.xsh ROOT
MANIFEST` and compares its stdout byte-for-byte with the oracle's stdout.

## Agent boundary

The worker runs as root in a minimal Alpine container with `/work` as its task
workspace. The image provides BusyBox, `xsh`, `xsht`, `curl`, and CA
certificates, and no extra packages: the `find` / `wc` / `awk` / `sort` /
`printf` oracle applets are already in the shared base image, and the `fs`,
text, map, and stream modules are part of `xsh` itself. There is no compiler,
repository checkout, or implementation source. The submitted program may not
use `run`, process APIs, `spawn`, shell commands, or any other subprocess
boundary; it must keep diagnostics off stdout, must not hard-code one tree's
results, and must derive the relative path itself (there is no relative-path
field on the filesystem entries in this image).

## Oracle and evaluator

The evaluator runs in a separate read-only container boundary. It writes the
oracle shell script under the evaluator's writable `/tmp`, stages a distinct
fixture tree and manifest for each case, and runs the candidate and the oracle
with identical `ROOT` and `MANIFEST` so both observe the same tree. It compares
byte-for-byte and writes the comparison evidence plus timings to the run
manifest. Public and hidden cases:

- `public`: a tree with one matching, one changed, one extra file and one
  missing manifest entry — every deviation class appears;
- `hidden_all_ok`: a 4-file tree whose manifest matches exactly — no output;
- `hidden_missing`: one manifest entry with no file on disk — one `missing`;
- `hidden_changed`: one file whose actual size differs from the manifest —
  one `changed` with both sizes;
- `hidden_extra`: one file on disk that the manifest does not declare —
  one `extra`;
- `hidden_combined`: a nested tree with several missing, changed, and extra
  entries — a sorted multi-line report;
- `hidden_empty_tree`: an empty root with a non-empty manifest — all `missing`;
- `hidden_empty_manifest`: an empty (0-byte) manifest with a populated tree —
  all `extra`;
- `hidden_spaces`: file and directory names containing spaces;
- `hidden_utf8`: file names containing UTF-8 characters;
- `hidden_missing_manifest` (failure control): `MANIFEST` does not exist —
  candidate and oracle must both exit nonzero and print nothing;
- `hidden_bad_manifest` (failure control): a malformed manifest line —
  candidate and oracle must both exit nonzero and print nothing.

The evaluator checks the source does not contain the forbidden subprocess
boundary, requires that the source references the filesystem stream module
(`fs.files` or `fs.walk`) and reads the manifest text (`read_text` or `read`),
so a hard-coded answer is classified as a restriction failure, and checks that
`review.md` preserves both required headings and contains no template
placeholders.

## Metrics

Record correctness for all twelve cases (including both failure controls),
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
On approval, stage `evals/task-treecmp/` with this scaffolding, including its
package-owned `evaluator.xsh`. The generic evaluator protocol stages and
mounts that script; do not add a task branch to `evaluate_common.xsh`.

## Staged dry run

No candidate/oracle dry run was executed for this proposal because the
designer does not build a candidate implementation or a custom oracle runner.
The package was validated by the smallest available reference checks:
`xsht check` passes on `evaluator.xsh` and `executor.xsh`, and the two exact
`xsht api` queries confirmed the `fs.files` / `fs.walk` entry contract (which
has no relative-path field, confirming the agent must derive it). The oracle,
fixture, candidate invocation, and evaluator wiring are staged under this
proposal for the CTO's end-to-end review and promotion; the container-isolated
worker/evaluator protocol is inherited unchanged from the approved scaffold and
was not re-run in a container this cycle. No dry-run comparison evidence is
claimed.

## CTO review

This section is populated by the CTO after review. Status is `Draft.` and the
package is not admitted to paid work until the CTO promotes it into
`evals/task-treecmp/` and sets it `Approved.`.
