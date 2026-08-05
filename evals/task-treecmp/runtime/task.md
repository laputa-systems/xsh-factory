Create one file named `treecmp.xsh` in the task working directory.

The program accepts a root directory and a manifest file:

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
  - `missing` — the relative path is in the manifest but has no regular file
    in the tree;
  - `changed` — a regular file exists at that relative path but its actual
    byte size differs from the manifest value;
  - `extra` — a discovered regular file whose relative path is not in the
    manifest;
- print exactly one line per deviation:

      missing<TAB>RELATIVE_PATH
      changed<TAB>RELATIVE_PATH<TAB>EXPECTED<TAB>ACTUAL
      extra<TAB>RELATIVE_PATH

- print the deviation lines sorted byte-lexicographically by the **entire
  line** (this places `changed…` before `extra…` before `missing…`), one line
  per deviation;
- print nothing when there are no deviations.

The evaluator supplies several different trees and manifests, so do not
hard-code one result. The program must perform the traversal through XSH
filesystem values and parse the manifest through XSH text values. It must not
start subprocesses, invoke an external command, or add diagnostic text to
stdout.

The filesystem entries from `fs.files` / `fs.walk` expose a `path` (absolute),
`size`, and `kind` field, but no precomputed relative path — derive each
file's path relative to `ROOT` yourself. A manifest failure (missing or
malformed) must be a loud nonzero exit with empty stdout; do not silently
default or emit a partial report.

Use the handbook and the available `xsht` checks as the reference. A normal
development loop is:

    xsht api module:fs
    xsht check treecmp.xsh
    xsht fmt treecmp.xsh
    xsht lint treecmp.xsh
    xsh treecmp.xsh /usr/share /manifest
