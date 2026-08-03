Create one file named `renamex.xsh` in the task working directory.

The program accepts one directory path argument and renames every regular file
in that directory tree whose name ends with `.tmp` so that the `.tmp` suffix
becomes `.bak`. For example, `report.tmp` becomes `report.bak`, and
`a/b/c.tmp` becomes `a/b/c.bak`. Files whose names do not end in `.tmp` are
left unchanged, and directories are never renamed. If the argument directory
does not exist, the program must exit nonzero.

The program must perform each rename through the XSH filesystem API
(`fs.rename`). It must not start subprocesses, invoke an external `mv` or
shell command, or add diagnostic text to stdout.

Use the handbook and the available `xsht` checks as the reference. A normal
development loop is:

    xsht check renamex.xsh
    xsht fmt renamex.xsh
    xsht lint renamex.xsh
    xsh renamex.xsh /tmp/tree
