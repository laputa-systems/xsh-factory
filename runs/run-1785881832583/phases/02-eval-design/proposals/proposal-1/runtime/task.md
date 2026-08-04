Create one file named `wordfreq.xsh` in the task working directory.

The program accepts one argument naming a text file and prints one line per
distinct word present in that file, of the form:

    COUNT WORD

A **word** is a maximal run of ASCII letters (`A-Z` or `a-z`). Everything
else — digits, punctuation, spaces and newlines, and any non-ASCII letter —
separates words. Count each word case-insensitively: lowercase each token, so
`The` and `the` are the same word. Lines are sorted ascending by `WORD`
(ASCII/lexicographic order). There is exactly one ASCII space between the
count and the word, no alignment or padding, and a final newline on each
line. If the file contains no words, print nothing and exit successfully. The
evaluator supplies several different input files, so do not hard-code one
result.

The behavior is defined by this oracle, which the evaluator runs against each
input file:

```sh
sh /tmp/wordfreq-oracle.sh INPUT
```

where `/tmp/wordfreq-oracle.sh` contains:

```sh
#!/bin/sh
tr 'A-Z' 'a-z' < "$1" | tr -cs 'a-z' '\n' | sed '/^$/d' | sort | uniq -c | sed 's/^[[:space:]]*//'
```

The program must read the file through XSH text APIs and perform the
tokenizing, lowercasing, counting, and sorting with typed XSH values. It must
not start subprocesses, invoke an external command (including `tr`, `sort`,
`uniq`, `sed`, `awk`, or `sh`), or add diagnostic text to stdout. Do not
hard-code the current input's word list or counts.

Use the handbook and `xsht api` as the available XSH reference. A normal
development loop is:

    xsht check wordfreq.xsh
    xsht fmt wordfreq.xsh
    xsht lint wordfreq.xsh
    xsh wordfreq.xsh sample.txt
