Create one file named `intsum.xsh` in the task working directory.

The program must accept zero or more command-line arguments and print exactly
one line: the integer sum of every argument. With no arguments it must print
`0`. Each argument must be a decimal integer (an optional leading `-` followed
by one or more decimal digits). If any argument is not a valid integer, the
program must exit nonzero on that failure and print no numeric result to
stdout. Do not hard-code a result; the evaluator supplies several argument
lists.

The program must compute the sum through XSH values and typed parsing. It must
not start subprocesses, invoke an external command, or add diagnostic text to
stdout.

Use the handbook and the available `xsht` checks as the reference. A normal
development loop is:

    xsht check intsum.xsh
    xsht fmt intsum.xsh
    xsht lint intsum.xsh
    xsh intsum.xsh 4 9 2
