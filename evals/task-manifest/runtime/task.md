Create one file named `manifest.xsh` in the task working directory.

The program accepts two path arguments, a root directory and an output path:

    xsh manifest.xsh ROOT OUT

It recursively finds every regular file under `ROOT` (including files directly
in `ROOT`) and writes to `OUT` one line per file containing the file's path
relative to `ROOT`, in byte-wise ascending sort order, each line terminated by
a newline. Directories and empty directories are not listed. When `ROOT` does
not exist the program must exit nonzero and must not create `OUT`. When there
are no regular files under `ROOT`, `OUT` must be empty (zero bytes). The
evaluator supplies several different trees, so do not hard-code one listing.

The behavior is defined by this oracle, which the evaluator runs with the
same root it passes to the program. For a nonexistent `ROOT` the oracle exits
nonzero, so a valid solution must exit nonzero and create no `OUT`:

    if [ ! -d ROOT ]; then exit 1; fi
    find ROOT -type f | sed "s|^ROOT/||" | LC_ALL=C sort

The program must do the traversal and sorting through XSH filesystem and
stream APIs (referencing `fs.files` or `fs.walk`). It must not start
subprocesses, invoke an external command, or add diagnostic text to stdout.

Use the handbook and the available `xsht` checks as the reference. A normal
development loop is:

    xsht api module:fs
    xsht api api:fs.files
    xsht api method:Path.relative_to
    xsht check manifest.xsh
    xsht fmt manifest.xsh
    xsht lint manifest.xsh
    xsh manifest.xsh /path/to/tree /tmp/out.manifest
