Create one file named `propsort.xsh` in the task working directory.

The program accepts one argument naming a UTF-8 text file. It reads that file
and prints to stdout, in ascending byte order, each line that is neither blank
nor a comment, with leading and trailing whitespace trimmed and each line
followed by a newline.

- A line is blank if its trimmed value is empty.
- A line is a comment if its trimmed value starts with `#`.
- Trimming removes leading and trailing whitespace only; interior characters
  are preserved.
- The surviving lines are sorted in ascending byte order (a normal ASCII
  lexicographic sort).
- Output is one line per entry, each terminated with a newline. If no lines
  qualify, print nothing and exit 0.

The evaluator supplies several different input files, so do not hard-code one
result.

The behavior is defined by this oracle, run by the evaluator on the same input
file:

```sh
sed 's/^[[:space:]]*//; s/[[:space:]]*$//' "$in" \
  | grep -v '^#' | grep -v '^$' | LC_ALL=C sort
```

The program must read the file through XSH filesystem/text APIs and must not
start subprocesses, invoke an external command, or add diagnostic text to
stdout. Do not hard-code the current input's values.

Use the handbook and the available `xsht` checks as the reference. A normal
development loop is:

    xsht check propsort.xsh
    xsht fmt propsort.xsh
    xsht lint propsort.xsh
    xsh propsort.xsh /path/to/input.txt
