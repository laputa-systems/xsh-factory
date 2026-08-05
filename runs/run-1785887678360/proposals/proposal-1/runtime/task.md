Create one file named `emptyfiles.xsh` in the task working directory.

The program accepts one root directory argument:

    emptyfiles.xsh ROOT

It recursively finds the regular files under `ROOT` whose byte size is zero and
prints their absolute paths, one per line, sorted ascending in byte order (the
same order as a stationary `LC_ALL=C sort`). If
no empty regular files exist, it prints nothing. The evaluator supplies several
different trees, so do not hard-code one result.

The behavior is defined by this oracle command:

    find ROOT -type f -empty -print | LC_ALL=C sort

Acceptance is a byte-for-byte stdout match with the oracle output, including
the per-line absolute paths and the final newline. The candidate must therefore:

- visit the same regular-file set as the oracle;
- keep only regular files whose byte size is zero;
- emit each such file's absolute path (as reported by the filesystem entry),
  one per line;
- order the result lines ascending by byte value, matching the oracle's sorted
  output;
- print nothing else and leave the root unchanged.

The program must discover the tree through XSH filesystem values. It must not
start subprocesses, invoke an external command, or add diagnostic text to
stdout. Do not hard-code the current list of empty files or paths.

Use the handbook and the available `xsht` checks as the reference. A normal
development loop is:

    xsht check emptyfiles.xsh
    xsht fmt emptyfiles.xsh
    xsht lint emptyfiles.xsh
    xsh emptyfiles.xsh /usr/share
