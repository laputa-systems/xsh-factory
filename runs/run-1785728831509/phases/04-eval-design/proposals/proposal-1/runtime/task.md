Create one file named `col2.xsh` in the task working directory.

The program accepts one input file path argument and prints the second
whitespace-delimited field of each line of that file, one per line. Whitespace
means spaces and tabs: leading whitespace before the first field is skipped,
runs of whitespace between fields count as one separator, and a line with
fewer than two fields (including an empty line) prints an empty line. The
evaluator supplies several different input files, so do not hard-code one
result.

The behavior is defined by this oracle command, run by the evaluator on the
same input:

```sh
awk '{print $2}' INPUT
```

The evaluator invokes the candidate equivalently to `xsh col2.xsh INPUT` and
compares stdout byte-for-byte. When the input file does not exist, the program
must exit nonzero and must not print fabricated output.

The program must read the file through XSH text APIs. It must not start
subprocesses, invoke an external command, add diagnostic text to stdout, or
modify the input file.

Use the handbook and `xsht api` as the available XSH reference. A normal
development loop is:

    xsht api api:fs.read_text
    xsht api method:Str.lines
    xsht api method:Str.fields
    xsht check col2.xsh
    xsht fmt col2.xsh
    xsht lint col2.xsh
    xsh col2.xsh input.txt
