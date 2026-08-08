# Task runtime

## Files

- `pathparts.xsh` — the submitted program (created by the worker)

## Deliverable

Create one file named `pathparts.xsh` in the task working directory.

The program accepts exactly one path argument and prints exactly three lines:

```text
dir=<directory part>
name=<final component>
ext=<extension, or the word none when there is no extension>
```

The directory part and final component match `dirname`/`basename` semantics on
the single argument. The extension is the text after the final dot of the final
component, **without** the leading dot. A filename with no dot, or a hidden
filename whose name is a leading dot with no further dot (`.profile`), reports
`none`; a filename with a real extension reports that extension (`app.yaml` →
`yaml`, `pkg.tar.gz` → `gz`). The evaluator supplies several different path
shapes, so do not hard-code one result.

The behavior is defined by this oracle command, run by the evaluator with the
same path argument:

```sh
sh /tmp/pathparts-oracle.sh PATH
```

where `/tmp/pathparts-oracle.sh` is:

```sh
#!/bin/sh
dir=$(dirname "$1")
name=$(basename "$1")
case "$name" in
  ?*.*) ext="${name##*.}" ;;
  *) ext="none" ;;
esac
printf 'dir=%s\nname=%s\next=%s\n' "$dir" "$name" "$ext"
```

Build the path through the typed `Path` value (for example
`Path(argv[0]).parent()`, `.name()`, `.ext()`, or the lint-preferred
`fp"${argv[0]}"` form). The program must not start
subprocesses, invoke an external command, or add diagnostic text to stdout. Do
not hard-code your own machine's paths.

Use the handbook and `xsht api` as the available XSH reference. A normal
development loop is:

    xsht api method:Path.name
    xsht check pathparts.xsh
    xsht fmt pathparts.xsh
    xsht lint pathparts.xsh
    xsh pathparts.xsh /srv/app/server.cfg
