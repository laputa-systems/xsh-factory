Create one file named `usagerep.xsh` in the task working directory.

The program accepts one root directory argument:

    usagerep.xsh ROOT

It recursively discovers every regular file under `ROOT` whose name ends with
`.usage`, reads each one, and prints one line per distinct service:

    SERVICE SUM COUNT

- Only files whose name ends with `.usage` are examined; every other file
  under the root is ignored.
- Each line of a `.usage` file has the form `SERVICE UNITS`, two
  whitespace-separated fields. A blank line (zero fields) or a
  whitespace-only line (also zero fields) is ignored.
- Every other (non-blank) line must contain exactly two fields: a SERVICE and
  a UNITS.
- UNITS (the second field) must be a decimal integer, optionally preceded by a
  single `-` sign (for example `42`, `-3`, `0`, `007`).
- SUM is the sum of the integer UNITS values seen for that SERVICE across all
  `.usage` files in the whole tree.
- COUNT is the number of non-blank lines seen for that SERVICE across all
  `.usage` files.
- Print exactly one line per distinct SERVICE that appears, sorted by SUM
  descending, then (when SUMs tie) by SERVICE ascending in byte (ASCII
  lexicographic) order, formatted as `SERVICE SUM COUNT` with a single space
  between fields and each line followed by a newline. Print nothing else.
- If a non-blank line has anything other than exactly two fields, or a UNITS
  that is not such an integer, the program must exit nonzero and print
  nothing.
- If the root cannot be read, the program must exit nonzero and print nothing.
- If the tree contains no `.usage` files, or all `.usage` files are empty or
  blank, print nothing and exit 0.

The program must discover the tree through XSH filesystem values and read each
selected file through an XSH text API, accumulating through XSH values (a Map
is the natural fit). It must not start subprocesses, invoke an external
command (including `awk`, `sh`, `sort`, `find`, or `cat`), or add diagnostic
text to stdout. The evaluator supplies several different trees, so do not
hard-code one summary.

Complete `review.md` using the supplied headings.

Use the handbook and the available `xsht` checks as the reference. A normal
development loop is:

    xsht api module:fs
    xsht check usagerep.xsh
    xsht fmt usagerep.xsh
    xsht lint usagerep.xsh
    xsh usagerep.xsh /path/to/measurements
