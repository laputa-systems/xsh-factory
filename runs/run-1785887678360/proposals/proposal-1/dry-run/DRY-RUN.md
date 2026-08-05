# Dry run — task-emptyfiles

Reference candidate `evidence/reference-emptyfiles.xsh` and the external
oracle `evidence/oracle.sh` were exercised on the host against the six case
fixtures that the package-owned `evaluator.xsh` stages. Per-case candidate and
oracle stdout are saved under `evidence/`.

## Oracle

```sh
root="$1"
find "$root" -type f -empty -print | LC_ALL=C sort
```

`LC_ALL=C` pins byte-wise (POSIX/C) ordering. Without it, multibyte filename
ordering is locale-dependent (a macOS `en_US.UTF-8` collation ordered a
`日本語/…` path before a `résumé/…` path, while byte order is the reverse);
forcing the C locale makes the byte-exact contract identical in any
environment and matches the XSH `sort-by` value ordering.

## Reference candidate

```xsh
proc main(...argv: List[Str]) [fs, error, io] {
  let root = Path(argv.get(0, "/tmp/efdr/tree"))
  let lines = fs.files(root)
    |> where .kind == "file"
    |> where .size == 0
    |> map { |entry| entry.path.display() }
    |> sort-by { |p| p }
    |> collect()
  for line in lines {
    print $line
  }
}
```

The reference candidate passes `xsht check`.

## Results

| case | candidate | oracle | byte match |
| --- | --- | --- | --- |
| public | MATCH | MATCH | yes |
| hidden_default | MATCH | MATCH | yes |
| hidden_nested | MATCH | MATCH | yes |
| hidden_spaces | MATCH | MATCH | yes |
| hidden_utf8 | MATCH | MATCH | yes |
| hidden_none | MATCH (empty) | MATCH (empty) | yes |

Every case matched byte-for-byte.

## Not exercised this cycle

The container isolation and the package-owned evaluator wiring are inherited
unchanged from the approved scaffold and were not re-run end-to-end in a
container this cycle (the shared `/usr/local/lib/xsh-factory` evaluator path
is a container-only surface). The oracle's `LC_ALL=C sort` behavior in the
Alpine/BusyBox container was reasoned from musl byte comparison and validated
against the XSH value ordering on the host; it is the one behavior that should
be confirmed on first admission.
