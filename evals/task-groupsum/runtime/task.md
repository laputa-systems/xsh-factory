Create one file named `groupsum.xsh` in the task working directory.

The program accepts one file-path argument and prints one line per distinct
key:

    KEY SUM

- Each line of the file is split into whitespace-separated fields.
- A blank line (no fields) is ignored.
- Every other (non-blank) line must contain exactly two fields: a KEY and a
  VALUE.
- VALUE (the second field) must be a decimal integer, optionally preceded by a
  single `-` sign (for example `42`, `-3`, `0`, `007`).
- SUM is the sum of the integer VALUEs seen for that KEY across all rows.
- Print exactly one line per distinct KEY that appears, sorted ascending by
  KEY in byte (ASCII lexicographic) order, formatted as `KEY SUM` with a single
  space and each line followed by a newline. Print nothing else.
- If a non-blank line has anything other than exactly two fields, or a VALUE
  that is not such an integer, the program must exit nonzero and print nothing.
- If the file cannot be read, the program must exit nonzero and print nothing.
- If the file has only blank lines or is empty, print nothing and exit 0.

The program must read the file through XSH text APIs and accumulate through
XSH values (a Map is the natural fit). It must not start subprocesses, invoke
an external command (including `awk`, `sh`, `sort`, or `wc`), or add
diagnostic text to stdout. The evaluator supplies several different files, so
do not hard-code one summary.

Complete `review.md` using the supplied headings.

Use the handbook and the available `xsht` checks as the reference. A normal
development loop is:

    xsht check groupsum.xsh
    xsht fmt groupsum.xsh
    xsht lint groupsum.xsh
    xsh groupsum.xsh /path/to/usage.txt
