Create one file named `total.xsh` in the task working directory.

The program accepts one file argument and prints a two-line summary of the
numeric values found in that file:

    count=<number of valid rows>
    total=<sum of the values>

Rules:

- Each line of the file is split into whitespace-separated fields.
- A blank line (no fields) is ignored.
- Every other (non-blank) line must contain exactly two fields: a NAME and a
  VALUE.
- VALUE (the second field) must be a decimal integer, optionally preceded by a
  single `-` sign (for example `42`, `-3`, `0`, `007`).
- A non-blank line with anything other than exactly two fields, or a VALUE
  that is not such an integer, is invalid: the program must exit nonzero and
  print nothing.
- If the file cannot be read, the program must exit nonzero and print nothing.
- count is the number of valid rows; total is the sum of their numeric values.
- Print exactly two lines (`count=N` then `total=S`), each followed by a
  newline, and nothing else.

The program must read the file through XSH text APIs and split/aggregate it
through XSH values. It must not start subprocesses or invoke an external
command (including `awk`, `sh`, `sort`, or `wc`), and must keep diagnostics off
stdout. The evaluator supplies several different files, so do not hard-code one
summary.

Use the handbook and the available `xsht` checks as the reference. A normal
development loop is:

    xsht check total.xsh
    xsht fmt total.xsh
    xsht lint total.xsh
    xsh total.xsh data.txt
