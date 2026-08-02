Create one file named `envcfg.xsh` in the task working directory.

The program accepts one output path argument and writes a small configuration
file to that path. The values come from three environment variables with
defaults:

- `CFG_HOST` (string, default `localhost`)
- `CFG_PORT` (integer, default `8080`)
- `CFG_DEBUG` (boolean, default `false`)

The written file is exactly:

```text
host=<CFG_HOST or "localhost">
port=<CFG_PORT or 8080>
debug=<CFG_DEBUG or "false">
```

A default applies only when the variable is absent. A variable that is
present but empty keeps the empty value. When `CFG_PORT` is present it must be
a decimal integer; if it is present but not a decimal integer, the program
must exit nonzero and must not create the output file. When `CFG_DEBUG` is
present it is `true` or `false`. The evaluator supplies several different
environment configurations, so do not hard-code one result.

The behavior is defined by this oracle, run by the evaluator with the same
environment:

```sh
case "${CFG_PORT-8080}" in
  *[!0-9]*|"") exit 1 ;;
esac
printf 'host=%s\nport=%s\ndebug=%s\n' "${CFG_HOST-localhost}" "${CFG_PORT-8080}" "${CFG_DEBUG-false}"
```

The program must read the variables through XSH environment APIs and write the
file through XSH filesystem APIs. It must not start subprocesses, invoke an
external command, or add diagnostic text to stdout. Do not hard-code the
current environment's values.

Use the handbook and `xsht api` as the available XSH reference. A normal
development loop is:

    xsht api module:env
    xsht api api:env.get_or
    xsht api api:env.int
    xsht api api:env.bool
    xsht check envcfg.xsh
    xsht fmt envcfg.xsh
    xsht lint envcfg.xsh
    CFG_HOST=node-a CFG_PORT=9001 CFG_DEBUG=true xsh envcfg.xsh /tmp/out.cfg
