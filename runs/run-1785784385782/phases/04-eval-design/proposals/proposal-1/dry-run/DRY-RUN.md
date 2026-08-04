# task-bigfiles dry run

Reference solution: `bigfiles.xsh` (this directory).
Oracle: `oracle.sh` (a BusyBox-portable `sh` script, reproduced inline in
`EVAL.md` and `runtime/task.md`).

Host surface: the cycle's local `xsh`/`xsht` build (`/Users/josh/usr/bin/xsh`)
with the pinned handbook's API surface (`fs.files`, stream `where`/`sort-by`/
`take`/`collect`, `Str.parse_int`, `Path` interpolation).

## What was exercised

- `xsht check bigfiles.xsh` → passes; `xsht fmt` → clean; `xsht lint` → exit 0.
- Candidate vs oracle, byte-for-byte, on the public case plus every hidden
  case described in `EVAL.md`, and the failure control:

```
PASS  public
PASS  hidden_default
PASS  hidden_n2
PASS  hidden_single
PASS  hidden_deep
PASS  hidden_spaces
PASS  hidden_utf8
PASS  hidden_empty
PASS  hidden_bad_n (failure control: candidate ec=3, oracle ec=1, both empty)
```

Sample (public):
```
50 /tmp/.../t_public/sub/b.log
11 /tmp/.../t_public/d.dat
7  /tmp/.../t_public/a.bin
2  /tmp/.../t_public/c.txt
```
(candidate and oracle identical)

The descending sort uses a negated integer key (`sort-by { |e| (0 - e.size) }`)
because this build has no `reverse`/descending stage and enforces a strict
one-parameter block; `take` honors a runtime `Int` from `argv[1].parse_int()?`.

## What remains unproven this cycle

- The container isolation boundary and the package-owned `evaluator.xsh`
  protocol (paths under `/usr/local/lib/xsh-factory` are container-only).
  These are inherited unchanged from the approved scaffold; the proposal only
  changes the selected task ID in `executor.xsh` / `evaluator.xsh`.
- A live Pi worker session (requires a paid agent session and auth file); the
  agent path is inherited from the approved base image.
- The evaluator's source-level restriction scan (rejects `run`/`process`/
  `spawn`/shell escapes, requires an `fs.files`/`fs.walk` + `sort-by`
  reference) is enforced by the shared evaluator and was not re-run here.
