Create one file named `trim.xsh` in the task working directory.

The program accepts two path arguments IN and OUT. It reads the text file at
IN and writes a cleaned copy to OUT: every ASCII space (`0x20`) or tab
(`0x09`) at the start or the end of each line is removed, exactly as the
evaluator's `sed` oracle does. Internal whitespace, blank lines, and the
one-line-per-line structure are preserved. A line that contains only spaces
and/or tabs becomes an empty line. The input files in every case are
newline-terminated, and the written output keeps one `\n` per input line.

The behavior is defined by this oracle, run by the evaluator on the same input
file:

```sh
sed 's/^[ \t]*//; s/[ \t]*$//' "$IN" > "$OUT"
```

Read the input and write the output through XSH filesystem APIs. The program
must not start subprocesses, invoke an external command, or add diagnostic
text to stdout. Do not hard-code the contents of one input file.

Use the handbook and the available `xsht` checks as the reference. A normal
development loop is:

    xsht check trim.xsh
    xsht fmt trim.xsh
    xsht lint trim.xsh
    xsh trim.xsh /work/in.txt /work/out.txt
