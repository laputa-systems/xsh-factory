# Dry run — task-manifest

This directory preserves the staged dry run performed in cycle
`run-1785800291944` for the `task-manifest` proposal.

## What was exercised

A reference XSH solution (`manifest.xsh`, using `fs.files` → `sort-by .path` →
`Path.relative_to` → `fs.write`) was validated with the **pinned** binaries
(`evals/.dist/xsh` / `xsht`) inside an `alpine:3.24.1` container, and the
package-owned `evaluator.xsh` was run against a staged `/work` directory.

- `xsht check manifest.xsh` → exit 0
- `xsht lint manifest.xsh` → exit 0 (no warnings)
- `xsht fmt` → idempotent (re-running leaves the file unchanged)
- `xsht check evaluator.xsh` → exit 0

### Positive control (reference solution)

`xsh /opt/evaluator.xsh` produced `session/run.json` with:

- result: `pass`
- classification: `pass`
- all 8 cases exact:

| case | exact | candidate_exit | oracle_exit |
| --- | --- | --- | --- |
| public | true | 0 | 0 |
| hidden_nested | true | 0 | 0 |
| hidden_empty_dirs | true | 0 | 0 |
| hidden_single | true | 0 | 0 |
| hidden_spaces | true | 0 | 0 |
| hidden_utf8 | true | 0 | 0 |
| hidden_empty | true | 0 | 0 |
| hidden_missing_root | true | 3 | 1 |

The `hidden_missing_root` failure control confirmed the candidate exits
nonzero (3) and creates no `OUT`, matching the guarded oracle (exit 1). Two
scaffold bugs surfaced and were fixed during the dry run: `List.is_empty`
does not exist (use `len() == 0`) in the reference, and the oracle pipeline
masked `find`'s nonzero exit with `sort`'s exit 0 — the oracle now guards the
root with `[ ! -d ROOT ] && exit 1`.

### Negative controls

Each was staged with a variant artifact and re-run through the same evaluator
to prove each gate rejects its intended hack:

| control | artifact | classification |
| --- | --- | --- |
| hard-coded listing (no `fs.files`/`fs.walk`) | `negative/hard.xsh` | `restriction_failed` |
| subprocess escape (`process.run`) | `negative/subproc.xsh` | `restriction_failed` |
| wrong output despite real traversal | `negative/wrong.xsh` | `candidate_failed` |
| missing/incorrect `review.md` headings | `negative/bad-review.md` | `protocol_failed` |
| missing artifact (`manifest.xsh` absent) | — | `worker_missing_artifact` |

Evidence: `session/run.json` (positive), `negative/` inputs, and the per-control
`run.json` manifests under `s{control}/`.

## What remains unproven

- The **live Pi agent half** was not exercised; it requires a paid agent
  session and a Pi auth file. The agent/worker path is inherited unchanged from
  the approved base image.
- The generic controller dispatcher (`evaluate_common.xsh`) was not modified
  for this eval and was not re-run end-to-end from the host; the package-owned
  `evaluator.xsh` was invoked directly in the container. The first paid trial
  remains the integration check for how the controller stages/mounts this
  script and produces the worker report.
