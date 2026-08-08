Create one file named `bigfiles.xsh` in the task working directory.

The program accepts a root directory path and an optional count:

    bigfiles.xsh ROOT [N]

It recursively finds every regular file under `ROOT`, including files below
dot-prefixed directories and dot-prefixed regular files, and prints the `N` largest
by byte size (default `N` = 5), from largest to smallest, exactly one line per
file:

    <byte-size> <path>

`<byte-size>` is the file size in bytes with no leading padding; `<path>` is
the absolute file path as reported by the filesystem entry. If fewer than `N`
regular files exist, print all of them. No two files in the supplied trees
share the same byte size, so the size ordering is unambiguous. If `N` is
present but not a decimal integer, the program must exit nonzero and print
nothing. The evaluator supplies several different trees, so do not hard-code
one result.

The program must discover the tree through XSH filesystem values. It must not
start subprocesses, invoke an external command, or add diagnostic text to
stdout.

Use the handbook and the available `xsht` checks as the reference. A normal
development loop is:

    xsht api module:fs
    xsht check bigfiles.xsh
    xsht fmt bigfiles.xsh
    xsht lint bigfiles.xsh
    xsh bigfiles.xsh /usr/share 5
