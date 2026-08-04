Create one file named `findexec.xsh` in the task working directory.

The program accepts one root directory argument and prints, one per line and
sorted in byte (lexicographic) order, the path of every regular file at or
below that root whose owner-execute permission bit is set. The traversal must
include hidden (dot) files, exactly as the oracle does. Print only the
matching paths, nothing else.

The behavior is defined by this oracle command, run by the evaluator on the
same root:

    find "$ROOT" -type f -perm -u+x | sort

The evaluator invokes the candidate equivalently to:

    xsh findexec.xsh "$ROOT"

Acceptance is a byte-for-byte stdout match with the oracle output. The
evaluator supplies several different root directories, so do not hard-code one
result. Do not modify the tree while computing the result.

The program must therefore:

- traverse the root and all subdirectories through XSH filesystem APIs,
  including hidden (dot) files;
- include a regular file only when its owner-execute bit is set, ignoring
  group- and other-execute bits;
- exclude anything that is not a regular file, including symlinks and the
  directories themselves;
- emit each matching path as its full path string, sorted in byte
  (lexicographic) order, one per line;
- emit only the matching paths and no diagnostic text.

The solution must not use run, process APIs, spawn, shell commands, or any
other subprocess boundary, and it must not modify the tree. Do not hard-code a
fixture's contents.

Use the handbook and `xsht api` as the reference. A normal development loop is:

    xsht api api:fs.files
    xsht check findexec.xsh
    xsht fmt findexec.xsh
    xsht lint findexec.xsh
    xsh findexec.xsh /usr/share
