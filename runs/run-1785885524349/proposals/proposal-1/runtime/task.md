Create one file named `cutoff.xsh` in the task working directory.

The program accepts two arguments:

    cutoff.xsh INPUT THRESHOLD

It reads the UTF-8 text file `INPUT` and prints, in original order, each line
whose second whitespace-delimited field is a non-negative decimal integer that
is greater than or equal to `THRESHOLD`. Each printed line is the original
line exactly as written (leading whitespace and any extra trailing fields
preserved), followed by a newline.

Rules:

- Whitespace means spaces and tabs: leading whitespace before the first field
  is skipped, and runs of whitespace between fields count as one separator.
- A blank line (no fields) is ignored and is not printed.
- Every other (non-blank) line must contain at least two fields, and its
  second field must be a non-negative decimal integer (a run of digits, for
  example `0`, `7`, `100`, `042`). If any non-blank line has fewer than two
  fields, or its second field is not a run of digits, the program must exit
  nonzero and print nothing.
- `THRESHOLD` must be a non-negative decimal integer. If it is not, the
  program must exit nonzero and print nothing.
- If `INPUT` cannot be read, the program must exit nonzero and print nothing.
- The evaluator supplies several different input files and thresholds, so do
  not hard-code one result.

The program must read the file through XSH text APIs and perform the splitting
and comparison through XSH values. It must not start subprocesses, invoke an
external command, add diagnostic text to stdout, or modify the input file.

Use the handbook and the available `xsht` checks as the reference. A normal
development loop is:

    xsht api search:parse_int
    xsht api api:fs.read_text
    xsht check cutoff.xsh
    xsht fmt cutoff.xsh
    xsht lint cutoff.xsh
    xsh cutoff.xsh data.txt 5
