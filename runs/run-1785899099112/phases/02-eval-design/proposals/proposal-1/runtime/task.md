Create one file named `svcstat.xsh` in the task working directory.

The program accepts one root directory:

    svcstat.xsh ROOT

It recursively finds every regular file below `ROOT` whose name ends in
`.log`, reads them all, and prints a per-service rollup sorted ascending by
service name, exactly one line per service:

    SERVICE COUNT TOTAL

`SERVICE` is the per-line service token, a non-empty sequence of ASCII
letters, digits, and underscores with no spaces. `COUNT` is the number of
request lines recorded for that service. `TOTAL` is the sum of the integer
durations (milliseconds) recorded for that service. Fields are separated by a
single space each, in the exact order `SERVICE COUNT TOTAL`.

A line is blank if it contains only spaces or tabs; blank lines are ignored.
Any non-blank line that is not exactly two space-separated fields with a
non-empty service token and a second field that is a run of one or more
decimal digits is a hard parse failure. On a parse failure the program must
print nothing to stdout and exit nonzero.

If no `.log` file exists below `ROOT`, or all lines are blank, print nothing
and exit zero.

The program must discover the tree through XSH filesystem values and reduce
the records by service key with XSH stream aggregation. It must not start
subprocesses, invoke an external command, or add diagnostic text to stdout.
The evaluator supplies several different trees, so do not hard-code one
result.

Use the handbook and the available `xsht` checks as the reference. A normal
development loop is:

    xsht api module:fs
    xsht api language:stream.group-by
    xsht api language:stream.fold
    xsht check svcstat.xsh
    xsht fmt svcstat.xsh
    xsht lint svcstat.xsh
    xsh svcstat.xsh /work/logs
