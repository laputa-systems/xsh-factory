Create one file named `dupcheck.xsh` in the task working directory.

The program accepts one root directory argument (an absolute path) and prints
one line per regular file below that root whose content is duplicated by at
least one other regular file below the same root. Each line is exactly:

    <sha256-hex>  <path>

The digest is the lowercase hexadecimal SHA-256 of the file contents, followed
by two spaces, followed by the file's full path as produced by traversing the
given root. Lines are sorted first by digest (lexicographic), then by path
(lexicographic), so every member of a duplicate set is consecutive and the
ordering is deterministic. Count regular files only; directories, symlinks,
and other non-regular entries are ignored. Hidden files and hidden
directories are included. When no file has duplicated content, print nothing.

The behavior is defined by this oracle, run by the evaluator with the same
root argument:

```sh
find "$1" -type f -exec sha256sum {} + | sort | awk '
NR == 1 { prev = $1; out = $0; n = 1; next }
$1 == prev { out = out "\n" $0; n++; next }
{ if (n > 1) print out; prev = $1; out = $0; n = 1 }
END { if (n > 1) print out }'
```

Example:

    mkdir -p /tmp/example/sub
    printf 'hello world' > /tmp/example/a.txt
    printf 'hello world' > /tmp/example/sub/b.txt
    printf 'unique' > /tmp/example/c.txt
    xsh dupcheck.xsh /tmp/example

prints exactly:

    b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9  /tmp/example/a.txt
    b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9  /tmp/example/sub/b.txt

The program must compute digests through the XSH hash module and traverse
through XSH filesystem APIs. It must not start subprocesses, invoke an
external command, or add diagnostic text to stdout. Do not hard-code one
fixture's result.

Use the handbook and `xsht api` as the available XSH reference. A normal
development loop is:

    xsht api api:hash.sha256
    xsht api module:fs
    xsht check dupcheck.xsh
    xsht fmt dupcheck.xsh
    xsht lint dupcheck.xsh
    xsh dupcheck.xsh /tmp/example

