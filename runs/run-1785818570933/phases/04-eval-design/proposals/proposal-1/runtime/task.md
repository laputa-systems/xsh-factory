Create one file named `logstat.xsh` in the task working directory.

The program accepts one argument naming a log file and prints a histogram of
the HTTP status codes in that file.

Each line of the file is in the standard combined HTTP log format with exactly
one ASCII space between top-level fields:

    10.0.0.1 - - [10/Oct/2000:13:55:36 -0700] "GET /index.html HTTP/1.0" 200 2326

- The HTTP status code is the 9th whitespace-separated field (0-indexed field
  8). Every real line in the supplied files has at least 9 fields.
- Count each status code that consists only of decimal digits. A line whose
  9th field is non-numeric (for example a `4xx` placeholder) is ignored.
- Print exactly one line per distinct numeric status code present, of the form
  `CODE count` with a single space between the code and its count, codes
  sorted ascending (all real status codes are three digits, so ASCII ascending
  order is numeric ascending). No leading zero-padding, alignment, or extra
  text.
- If no numeric status code is present, print nothing and exit successfully.

The evaluator supplies several log files by path and compares stdout
byte-for-byte with an external oracle. Do not hard-code any specific code
list, count, or filename.

The program must read the file through XSH text APIs and perform the
splitting, filtering, counting, and sorting with typed XSH values. It must not
start subprocesses or invoke an external command (including `awk`, `grep`,
`sort`, `uniq`, or `sh`) and must keep diagnostics off stdout.

Use the handbook and the available `xsht` checks as the reference. To try it,
create a small sample log in `/work` first. A normal development loop is:

    xsht check logstat.xsh
    xsht fmt logstat.xsh
    xsht lint logstat.xsh
    xsh logstat.xsh sample.log
