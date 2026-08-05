tailn.xsh

The program accepts two arguments: a path to a UTF-8 text file and a
non-negative integer N. The input file is newline-terminated. It reads the
file's lines and prints the last N lines to stdout, each selected line followed
by a single newline, preserving their original order.

- If N is 0, print nothing and exit 0.
- If N is greater than or equal to the number of lines in the file, print all
  lines.
- A blank line in the file is a line and is preserved as an empty output line.
- Lines are selected by line count only; leading/trailing spaces inside a line
  are not trimmed and non-ASCII (UTF-8) content is preserved byte-for-byte.

The evaluator supplies several different `(file, N)` pairs, so do not hard-code
one result and do not ignore the N argument.

The behavior is defined by this oracle, run by the evaluator on the same input
file with the same N (via the BusyBox `tail` applet already in the shared base
image):

```sh
tail -n "$N" "$in"
```

The program must read the file through XSH filesystem/text APIs and must not
start subprocesses, invoke an external command, or add diagnostic text to
stdout. Do not hard-code the current input's contents.

Use the handbook and the available `xsht` checks as the reference. A normal
development loop is:

    xsht check tailn.xsh
    xsht fmt tailn.xsh
    xsht lint tailn.xsh
    xsh tailn.xsh /path/to/input.txt 3
