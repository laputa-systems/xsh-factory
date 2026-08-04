Create one file named `safepath.xsh` in the task working directory.

The program must accept two command-line arguments: an absolute root directory
and a relative path. It must print the normalized absolute path formed by
joining them while guaranteeing the result stays under root. If the relative
path would escape the root, print exactly one line

    escape: <relative path>

and exit with a nonzero status.

Normalization rules:

- Split the relative path on `/`.
- Ignore empty segments (from `//`, a trailing `/`, or an empty relative
  path) and `.` segments, so `a/./b` and `a//b` both behave like `a/b`.
- `..` removes the most recently added normal segment, so `a/../b` becomes
  `b`. If there is no normal segment left to remove, the relative path
  escapes the root.
- A relative path that starts with `/` is always an escape.
- The final path is `root` if no segments remain, otherwise
  `root/<remaining segments joined with />`, with no trailing slash.

On success print only the normalized path and exit 0. On escape print only
`escape: <relative path>` and exit nonzero. Keep all diagnostics off stdout.
The root is given as an absolute directory without a trailing slash (it is
never just `/`).

Examples with root `/srv/app`:

    a/b/c        -> /srv/app/a/b/c
    a/../b       -> /srv/app/b
    ./x//y       -> /srv/app/x/y
    a/../../etc  -> escape: a/../../etc   (exit nonzero)
    /etc/passwd  -> escape: /etc/passwd   (exit nonzero)

The program must perform the transformation through XSH values. It must not
start subprocesses, invoke an external command, or add diagnostic text to
stdout.

Use the handbook and the available `xsht` checks as the reference. A normal
development loop is:

    xsht check safepath.xsh
    xsht fmt safepath.xsh
    xsht lint safepath.xsh
    xsh safepath.xsh /srv/app 'a/../b'
