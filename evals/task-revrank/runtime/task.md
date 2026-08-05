Create one file named `revrank.xsh` in the task working directory.

The program accepts one file-path argument:

    revrank.xsh FILE

`FILE` is a text file whose non-blank lines each hold exactly four
single-space-delimited fields:

    REGION PRODUCT UNITS PRICE

- `REGION` and `PRODUCT` are words (no spaces).
- `UNITS` and `PRICE` are decimal integers, optionally preceded by a single `-`
  sign (for example `42`, `-3`, `0`).
- The revenue for a row is `UNITS * PRICE`.
- Sum the revenue per `REGION` across all rows, then print exactly one line per
  distinct region that appears:

        REGION TOTAL

- `TOTAL` is the signed integer revenue total with no leading padding.
- Print the regions in descending order of `TOTAL`; when two regions have the
  same `TOTAL`, order them ascending by `REGION` in byte (ASCII) order.
- Blank lines are ignored. If `FILE` has no data rows (or only blank lines),
  print nothing and exit 0.
- Every non-blank line must have exactly four fields. If a line has any other
  number of fields, or a `UNITS`/`PRICE` field that is not a decimal integer,
  or the file cannot be read, the program must exit nonzero and print nothing.

The evaluator supplies several different files, so do not hard-code one result.

The program must read the file through XSH text APIs, derive revenue through
XSH arithmetic values, accumulate through an XSH Map, and rank with XSH stream
stages. It must not start subprocesses, invoke an external command (including
`awk`, `sh`, or `sort`), or add diagnostic text to stdout.

Use the handbook and the available `xsht` checks as the reference. A normal
development loop is:

    xsht check revrank.xsh
    xsht fmt revrank.xsh
    xsht lint revrank.xsh
    xsh revrank.xsh /path/to/sales.txt
