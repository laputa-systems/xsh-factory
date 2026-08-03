Create one file named `probe.xsh` in the task working directory.

The program accepts a command name followed by optional arguments and prints
exactly one line reporting how that command finished:

- `ok` when the command exits with status 0;
- `fail:<code>` when the command exits nonzero, where `<code>` is the decimal
  exit status;
- `missing` when the command name cannot be found as an executable.

The evaluator always supplies a command name as the first argument. The
behavior is defined by this oracle, run by the evaluator with the same
arguments:

```sh
#!/bin/sh
if command -v "$1" >/dev/null 2>&1; then
  "$@"
  code=$?
  if [ "$code" -eq 0 ]; then
    echo ok
  else
    echo "fail:$code"
  fi
else
  echo missing
fi
```

The evaluator invokes the candidate equivalently to `xsh probe.xsh CMD ARG...`
and compares stdout byte-for-byte with the oracle output. The program itself
exits 0 after printing its report and must print no other text to stdout. The
command's own stdout and stderr flow through unchanged, exactly as they do in
the oracle; do not capture, redirect, or suppress them.

The program must launch the command through the XSH process boundary, for
example `process.which`, `process.command_argv`, and `process.run` (or the
`run` / `spawn` forms). A missing executable is an expected failure: handle it
as a value and print `missing`, do not let the program abort. Preserve each
argument as its own argv element; do not join or re-split the argument list.
Do not hard-code one outcome.

Use the handbook and `xsht api` as the available XSH reference. A normal
development loop is:

    xsht api api:process.which
    xsht api api:process.run
    xsht api api:process.command_argv
    xsht check probe.xsh
    xsht fmt probe.xsh
    xsht lint probe.xsh
    xsh probe.xsh true
    xsh probe.xsh false
    xsh probe.xsh sh -c "exit 42"
    xsh probe.xsh definitely-not-a-real-command-xyz

