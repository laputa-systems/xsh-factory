Create one file named `keyjoin.xsh` in the task working directory.

The program accepts exactly two file path arguments (a left file and a right
file). Each file contains zero or more data lines of the form

    KEY VALUE

where KEY and VALUE are each a single token (no internal whitespace),
separated by one or more spaces or tabs, and any run of leading or trailing
whitespace is ignored. A line is skipped if it is blank or whitespace-only, or
if its first non-whitespace character is `#` (a comment). Within a file a KEY
is unique; if a KEY repeats, the last occurrence wins.

For every KEY that appears in the left file, print exactly one line to stdout:

- if that KEY also appears in the right file:
  `KEY LEFT_VALUE RIGHT_VALUE`
- otherwise:
  `KEY LEFT_VALUE -`

Fields are separated by a single space, lines are sorted in ascending
lexicographic (byte) order by KEY, there are no trailing spaces, right-only
keys are ignored, and the output ends with a final newline. When the left file
has no data keys, print nothing.

The behavior is defined by this oracle command, which the evaluator runs with
the same two paths:

    grep -v '^[[:space:]]*#' "$1" | awk 'NF>=2{print $1"\t"$2}' | sort > /tmp/L
    grep -v '^[[:space:]]*#' "$2" | awk 'NF>=2{print $1"\t"$2}' | sort > /tmp/R
    join -a 1 -e - -o '1.1 1.2 2.2' /tmp/L /tmp/R

Example. A left file:

    alpha 10
    beta 20
    gamma 30

A right file:

    beta X
    epsilon Z

yield, after sorting, exactly:

    alpha 10 -
    beta 20 X
    gamma 30 -

(epsilon is right-only and is ignored). The program must read both files
through XSH file/text APIs (`Path.read_text()` / `fs.read_text`) and combine
them with typed Map values. It must not start subprocesses, invoke an external
command, or add diagnostic text to stdout. Do not hard-code one fixture's
result.

Use the handbook and the available `xsht` checks as the reference. A normal
development loop is:

    xsht check keyjoin.xsh
    xsht fmt keyjoin.xsh
    xsht lint keyjoin.xsh
    xsh keyjoin.xsh left.txt right.txt
