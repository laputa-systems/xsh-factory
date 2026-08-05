Create one file named `colsum.xsh` in the task working directory.

The program accepts a file path and a header name:

    colsum.xsh FILE HEADER

`FILE` is a comma-separated text file whose first line is a header row of
column names. Find the column whose header name exactly equals `HEADER`, sum
the decimal integer values (which may be negative) in that column across all
remaining data rows, and print the total on its own line:

    <sum>

`<sum>` is the signed integer total with no leading zeros and no leading
padding. If `HEADER` is not present in the header row, or if any data-row
value in the target column is not a decimal integer, the program must exit
nonzero and print nothing. If there are no data rows, print `0`. Values in
other columns are arbitrary and are ignored; cells contain no commas or
whitespace, so a comma split is unambiguous. The evaluator supplies several
different tables, so do not hard-code one result.

Read the file through XSH filesystem and text values. The program must not
start subprocesses, invoke an external command, or add diagnostic text to
stdout.

Use the handbook and the available `xsht` checks as the reference. A normal
development loop is:

    xsht api module:fs
    xsht check colsum.xsh
    xsht fmt colsum.xsh
    xsht lint colsum.xsh
    xsh colsum.xsh data.csv age
