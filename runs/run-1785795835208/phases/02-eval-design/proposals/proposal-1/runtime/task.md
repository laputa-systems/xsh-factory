Create one file named `grep.xsh` in the task working directory.

The program accepts two arguments: a PATTERN and a FILE path. It reads FILE
line by line and prints each line that contains PATTERN as a byte-for-byte
literal substring, prefixed with its 1-based line number and a colon:

```text
LINE: text of that line
```

Rules:

- PATTERN is a literal substring, not a regular expression. Metacharacters
  such as `.` match themselves.
- Lines are numbered starting at 1 from the first line of the file.
- A blank line is still a line and is numbered and printed if it contains the
  pattern.
- A matching line is printed once with its number. Preserve its text exactly,
  including leading and trailing spaces.
- Print `N:text` followed by a final newline for each match, in file order.
- If no line contains the pattern, print nothing and exit successfully.
- If the file cannot be read, exit nonzero and print nothing.

The program must read the file through XSH text APIs, and filter and number
the lines through XSH values. It must not start subprocesses or invoke an
external command (including `grep`, `sh`, `awk`, or `sed`), and must not add
diagnostic text to stdout. The evaluator supplies several PATTERN/FILE
combinations, so do not hard-code one result.

Use the handbook and the available `xsht` checks as the reference. A normal
development loop is:

    xsht check grep.xsh
    xsht fmt grep.xsh
    xsht lint grep.xsh
    xsh grep.xsh quick data.txt
