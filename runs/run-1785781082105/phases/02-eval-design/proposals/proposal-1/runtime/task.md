Create one file named `setdiff.xsh` in the task working directory.

The program accepts two file-path arguments, `fileA` and `fileB`, and prints
to stdout every unique line that appears in `fileA` but not in `fileB`,
sorted in byte (lexicographic) order, one per line. Print nothing else. The
sorted, deduplicated output must match byte-for-byte the evaluator's oracle,
which is exactly this BusyBox-`sh`-compatible script run with the two input
paths (temp files avoid bash-only process substitution):

```sh
LC_ALL=C sort -u "$1" > /tmp/sa.$$
LC_ALL=C sort -u "$2" > /tmp/sb.$$
comm -23 /tmp/sa.$$ /tmp/sb.$$
rm -f /tmp/sa.$$ /tmp/sb.$$
```

A line is a run of characters ending at a newline. A blank line between two
newlines is a real member, while a final trailing newline does not create an
extra line. When either input file cannot be read, the program must exit
nonzero and must not print fabricated output. The evaluator supplies several
different input pairs, so do not hard-code one result.

The program must read the files through XSH text APIs and compute the set
difference through XSH values. It must not start subprocesses, invoke an
external command (including `comm`, `sort`, or `awk`), or add diagnostic text
to stdout.

Use the handbook and `xsht api` as the reference. A normal development loop
is:

    xsht api api:fs.read_text
    xsht api api:set.from
    xsht api language:stream.sort-by
    xsht check setdiff.xsh
    xsht fmt setdiff.xsh
    xsht lint setdiff.xsh
    xsh setdiff.xsh A.txt B.txt
