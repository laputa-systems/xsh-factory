# task-pathparts dry-run evidence

Validated on the local host build with `xsht`/`xsh` (macOS arm64) against the
shared handbook's canonical reference.

## Syntax / reference check

`xsht check` passed for all three package scripts (exit 0):

- `executor.xsh`
- `evaluator.xsh`
- `evaluate.xsh`

Two focused scaffold fixes were applied during the check: `Map[...]` takes one
type parameter (`Map[Bool]`, `Map[Int]`), and the effect-free
`forbidden_source` helper is declared `pure`.

## Oracle semantics verification

The typed `Path` decomposition (`Path(path).parent()`, `.name()`, `.ext()`)
was compared byte-for-byte with the independent BusyBox
`sh` / `dirname` / `basename` oracle on the local host build for every planned
case. Each produced identical `dir` / `name` / `ext` lines:

- `/srv/app/server.cfg` → dir=/srv/app, name=server.cfg, ext=cfg
- `/var/log/app/archive/2024-01-01.txt.gz` → ... ext=gz
- `notes` → dir=., name=notes, ext=none
- `conf/nginx.conf` → dir=conf, name=nginx.conf, ext=conf
- `/home/u/.config/app.yaml` → name=app.yaml, ext=yaml
- `/root/.profile` → name=.profile, ext=none
- `report.tar.gz` → dir=., name=report.tar.gz, ext=gz

## Not exercised here

The live Pi agent session and the full isolated Docker evaluator run require a
paid agent session and the `xsh-factory-base` container image; that path is
inherited unchanged from the approved base image and will be exercised at CTO
review/approval. No candidate implementation or negative-control harness was
built for this proposal.
