# task-jsonfilter staged dry run

Proposal: `runs/run-1785726325461/phases/04-eval-design/proposals/proposal-1/`.
Status: pending user approval. Not approved, not wired into the shared
evaluator dispatch.

## What was exercised

- **Reference solution** (`reference/jsonfilter.xsh`): reads `CFG_DOC` with
  `env.get`, decodes with `json.decode` and `.require(Doc)?`, filters with
  `where .active`, sorts with `sort-by .name`, projects with `map`, and writes
  the output with `fs.write(out, json.encode(picked)? + "\n")`.
- **Reference review** (`reference/review.md`) carries both required headings
  (`## xsht friction`, `## XSH language proposals`) and no template
  placeholders.
- **Toolchain**: `xsht check` and `xsht lint` both pass inside the task image
  on the pinned Linux `.dist` build (this build differs from the macOS host
  binary, so in-image validation matters).
- **Candidate vs oracle, byte-for-byte, inside the real task image**
  `task-jsonfilter:dry-run` (built from `xsh-factory-base:dry-run`, which
  packages the current `evals/.dist/xsh` + `xsht`, plus pinned `jq=1.8.1-r0`
  from Alpine 3.24.1). Ten cases, identical `CFG_DOC` for both sides:

  | case | outcome |
  | --- | --- |
  | public (mixed active/inactive, names out of order) | PASS |
  | hidden_empty (`records: []`) | PASS |
  | hidden_all_inactive | PASS |
  | hidden_single | PASS |
  | hidden_unicode (`héllo`, `beta`, `äpple`) | PASS |
  | hidden_spaces (`us east 1`) | PASS |
  | hidden_zero (`count: 0`) | PASS |
  | hidden_large (`count: 1048576`) | PASS |
  | hidden_malformed (failure control) | PASS: both exit nonzero, no output file |
  | hidden_missing/empty `CFG_DOC` (failure control) | PASS: both exit nonzero, no output file |

  Per-case stdout/stderr and output files are under `cases/`; the verdict
  transcript is `transcript.txt`.

- **Negative controls** (source-scan and protocol checks the evaluator will
  apply), each rejected as intended:
  - hard-coded output with no `json.` reference -> rejected (restriction);
  - subprocess escape using `process.run`/`jq` -> rejected (restriction);
  - `review.md` missing a required heading -> rejected (protocol);
  - `review.md` containing template placeholders -> rejected (protocol).

## Contract facts learned during the dry run

- `json.write` emits compact, key-sorted JSON **without** a final newline;
  the oracle (`jq -cS`) emits a final newline. The task therefore requires a
  final newline and the reference adds `"\n"` explicitly. This is a real
  byte-contract detail worth stating in `runtime/task.md`.
- `json.encode`/`json.write` sort object keys alphabetically, matching
  `jq -S`; integer counts serialize identically; UTF-8 names serialize raw
  on both sides.
- `sort-by .name` shorthand type-checks after `where .active` on a
  schema-required `List[Pick]`; the block form `sort-by { |r| r.name }` also
  works. The task does not require a specific form.
- `env.get("CFG_DOC")?` fails loudly on a missing variable, and
  `json.decode("")?` fails loudly on an empty value, so the candidate meets
  the failure controls without extra branching.

## What remains unproven

- The full controller evaluator path (`evaluate_common.xsh` producing a
  `run.json` manifest for a `task-jsonfilter` dispatch) is controller-owned
  and is wired only after user approval, as in the task-envcfg precedent. The
  proposal's `evaluate.xsh`/`executor.xsh` selectors are structurally
  identical to the approved task-tags/task-ecount/task-envcfg selectors except
  for the task name and pass `xsht check`.
- A live Pi agent session (worker effort metrics) was not exercised; the agent
  path is inherited unchanged from the shared base image.
- Timing envelope: both sides complete in milliseconds; no strict gate is
  proposed.
