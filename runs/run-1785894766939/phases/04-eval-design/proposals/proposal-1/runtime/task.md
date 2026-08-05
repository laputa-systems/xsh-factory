Create one file named `histogram.xsh` in the task working directory.

The program accepts a file path and a positive integer width:

    histogram.xsh FILE WIDTH

`FILE` is a text file where each non-blank line holds a single non-negative
decimal integer (optional surrounding whitespace; no sign). For every value
`v`, compute its bin as `v // WIDTH` (integer division; for non-negative
values this is the truncated quotient). Count how many values land in each
bin, then print the occupied bins in ascending bin order, exactly one line per
bin:

    <bin> <count> <cumulative>

`<bin>` is the integer bin value with no leading padding; `<count>` is the
number of values in that bin; `<cumulative>` is the running total of counts
across all bins up to and including this one in ascending bin order. If `FILE`
contains no values (or is empty), print nothing. Blank lines are ignored.

If `WIDTH` is not a positive decimal integer, or if any non-blank line of
`FILE` is not a non-negative decimal integer, the program must exit nonzero
and print nothing. The evaluator supplies several different files and widths,
so do not hard-code a result.

The program must read the file through typed filesystem/text values, build the
per-bin counts with a keyed aggregation, sort the occupied bins, and fold the
cumulative total. It must not start subprocesses, invoke an external command,
or add diagnostic text to stdout.

Use the handbook and the available `xsht` checks as the reference. A normal
development loop is:

    xsht api search:parse_int
    xsht api language:stream.sort-by
    xsht check histogram.xsh
    xsht fmt histogram.xsh
    xsht lint histogram.xsh
    xsh histogram.xsh /usr/share/hist-data.txt 10
