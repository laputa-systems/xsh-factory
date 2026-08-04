Create one file named `uniqcat.xsh` in the task working directory.

The program accepts one or more file-path arguments and prints each distinct
line of the byte concatenation of those files exactly once, in first-occurrence
order. First-occurrence order is the order a line first appears when scanning
the files in argument order and each file top to bottom. A line that appears
again later (in the same file or a later file) is skipped. Print one line per
distinct first occurrence, each followed by a newline, and nothing else on
stdout.

The behavior is defined by this oracle, run by the evaluator with the same
file set:

```sh
awk '!seen[$0]++' file1 file2 ...
```

A line is a run of characters ending at a newline. A blank line between two
newlines is a real member; a final trailing newline does not create an extra
line. Content is compared byte-for-byte, so leading and trailing spaces and
UTF-8 bytes are significant and case is preserved. When an input file cannot be
read, the program must exit nonzero and print nothing. In the evaluator's
failure case the unreadable file is the first argument, so a correct program
that reads the files in argument order fails before printing anything.

The evaluator supplies several different file sets, so do not hard-code one
result. The program must read the files through XSH text APIs and deduplicate
through XSH values. It must not start subprocesses, invoke an external command
(including `cat`, `awk`, `sort`, or `sh`), or add diagnostic text to stdout.

Use the handbook and `xsht api` as the available XSH reference. A normal
development loop is:

    xsht api api:fs.read_text
    xsht api module:set
    xsht api method:Str.lines
    xsht check uniqcat.xsh
    xsht fmt uniqcat.xsh
    xsht lint uniqcat.xsh
    xsh uniqcat.xsh A.txt B.txt
