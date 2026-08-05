# Eval-designer report

## Result

ready-for-review

## Proposal

One new eval, `task-emptyfiles`, was materialized under
`runs/run-1785887678360/proposals/proposal-1/`:

- contract: `EVAL.md` (`# Eval task-emptyfiles`, `## Status` = `Draft.`)
- scaffolding: `executor.xsh`, `evaluate.xsh`, and package-owned
  `evaluator.xsh`
- runtime: `runtime/task.md` and `runtime/artifact.md` (`emptyfiles.xsh`)
- dry-run evidence: `dry-run/DRY-RUN.md` with per-case candidate/oracle
  stdout under `dry-run/evidence/`

The package reads the shared `runtime/handbook.md`, sets a new valid
`task-emptyfiles` ID, and is promoted into `evals/task-emptyfiles/` by the
controller while preserving `Draft.` status pending the CTO decision.

## Dry run

A reference `emptyfiles.xsh` and the external oracle
(`find ROOT -type f -empty -print | LC_ALL=C sort`) were exercised on the host
across the six case fixtures the evaluator stages (public, hidden_default,
hidden_nested, hidden_spaces, hidden_utf8, hidden_none). Every case
byte-matched, including the empty-tree case (both print nothing) and the
multibyte-name case once ordering was pinned to C byte order. The reference
candidate passes `xsht check`.

The container isolation and the package-owned evaluator wiring are inherited
unchanged from the approved scaffold and were not re-run end-to-end in a
container this cycle; that is the only remaining unproven surface and is
called out in EVAL.md and `dry-run/DRY-RUN.md`.

## North-star impact

The hypothesis is that a mature handbook lets an agent replace a read-only
`find -type f -empty` inspection with a clear, typed XSH program that walks
the typed filesystem stream, filters on the structured `kind` and `size`
fields, sorts deterministically, and emits a byte-exact path contract — with no
subprocess escape. It is a minimal disk-hygiene shape that is distinct from the
extension census (ecount) and size ranking (bigfiles), and its value is in
probing whether scalar-field filtering plus a deterministic `sort-by` are
discoverable and composable for read-only administration work, which is the
clarity/explicit-boundary ethos NORTH-STAR asks the factory to measure and
compound.

## Known risks

- **Oracle locale sensitivity (task-specific):** GNU/BSD `sort` orders
  multibyte filenames by locale; a macOS `en_US.UTF-8` collation reordered a
  `日本語/…` path relative to `résumé/…`, diverging from byte order. The oracle
  was pinned with `LC_ALL=C` and validates byte-for-byte on the host, but the
  Alpine/BusyBox `LC_ALL=C` byte-order behavior should be confirmed on first
  admission; it is the one inferred container behavior.
- **Path-shape assumption:** the contract assumes the filesystem entry `path`
  is absolute and matches the oracle's `$root`-prefixed output; the fixture
  roots are absolute `/tmp` paths, so this holds, and hidden cases keep the
  ordering unambiguous.
- **No failure control:** like ecount, this pure read-only filtering task has
  no malformed-input control; a wrong-restriction or hard-coded answer is
  caught instead by the `fs.files`/`fs.walk` + `sort-by` source gate and the
  subprocess-prohibition check.
- **Timing:** no strict candidate/oracle timing gate; both sides finish in
  milliseconds, so timing is diagnostic until a stable envelope is
  established.

## Review path

Promote `runs/run-1785887678360/proposals/proposal-1/` to
`evals/task-emptyfiles/` (controller `promote_eval_proposal`). Evidence for the
CTO decision: `EVAL.md` contract and `Draft.` status; package-owned
`evaluator.xsh` passes `xsht check` and references no shared/legacy dispatcher;
`executor.xsh`, `evaluate.xsh`, `runtime/task.md`, and `runtime/artifact.md`
are present; and `dry-run/DRY-RUN.md` plus `dry-run/evidence/` show all six
cases byte-matching the oracle. If the CTO accepts the evaluator and evidence,
the package is set to `Approved.` and admitted to paid work; otherwise it
remains `Draft.` and is not admitted.
