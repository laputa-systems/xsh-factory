# Eval-designer report

## Result

ready-for-review

## Proposal

Proposal: `runs/run-1785726325461/phases/04-eval-design/proposals/proposal-1/`

- `EVAL.md` — task-jsonfilter contract: purpose, north-star hypothesis, task,
  agent boundary, oracle/evaluator, metrics, manager policy, staged dry run.
- `runtime/task.md` — user-facing task prompt with the exact `jq -cS` oracle
  and failure semantics.
- `runtime/artifact.md` — required artifact `jsonfilter.xsh`.
- `executor.xsh` / `evaluate.xsh` — thin selectors for the shared executor and
  evaluator, forwarding `-- task-jsonfilter` (structurally identical to the
  approved task-tags/task-ecount/task-envcfg selectors).
- `Dockerfile` — task image adds pinned `jq=1.8.1-r0` (Alpine 3.24.1) to the
  shared base, mirroring the task-ecount `fd` pattern.
- `dry-run/` — reference solution, `review.md`, per-case evidence
  (`cases/`), verdict transcript, and `DRY-RUN.md`.

Task shape: `jsonfilter.xsh OUT` reads one JSON document from `CFG_DOC`
(`{"records":[{"name":Str,"active":Bool,"count":Int},...]}`), writes the
`active == true` records sorted by `name`, projected to `{name, count}`, as a
byte-exact compact key-sorted newline-terminated JSON file; absent, empty, or
malformed `CFG_DOC` exits nonzero with no output file. Oracle is the
`jq -cS` pipeline in `runtime/task.md`, run with identical `env:`.

## Dry run

Exercised inside the real task image (`task-jsonfilter:dry-run`, built from
`xsh-factory-base:dry-run` packaging the current `evals/.dist/xsh` + `xsht`,
plus `jq=1.8.1-r0`):

- Reference solution passes `xsht check` and `xsht lint` in the container on
  the pinned Linux build.
- All 10 cases (public, empty, all-inactive, single, unicode, spaces, zero,
  large, malformed failure control, missing/empty failure control) passed
  byte-for-byte against the Alpine jq oracle with identical `CFG_DOC`; both
  failure controls exited nonzero with no output file on both sides.
- Negative controls each rejected: no-`json.` hard-coded workaround,
  `process.run`/`jq` subprocess escape, missing review heading, template
  placeholders.

Remaining unproven: the controller-owned `evaluate_common.xsh` dispatch that
produces the `run.json` manifest (wired only after user approval, per the
task-envcfg precedent) and a live Pi agent session. Full evidence:
`dry-run/DRY-RUN.md`, `dry-run/transcript.txt`, `dry-run/cases/`.

## North-star impact

The north star names JSON among the boundaries XSH should connect, and no
approved eval exercises it: task-tags transforms argv text, task-ecount
traverses the filesystem, task-envcfg renders scalar config. task-jsonfilter
probes the smallest practical JSON-glue workflow — decode a document from
system state, require a schema it intends to trust, filter/sort/project typed
records, and serialize a byte-exact JSON file for a downstream consumer —
replacing a `jq` one-liner with typed XSH. A successful run teaches whether
the handbook makes the JSON module discoverable (`xsht api module:json`),
whether the `.require(Type)?` trust lesson transfers from docs to a real
task, and whether matching an exact JSON byte contract (compact, key-sorted,
final newline) is easy. The design resists task-specific hacks because hidden
`CFG_DOC` values are unknown to the worker, the output file is created only
on success, failure controls demand a loud nonzero exit with no file, and the
evaluator rejects sources that omit `json.` or start a subprocess — a
hard-coded file, text workaround, or `jq` escape each fails a distinct gate.

## Known risks

- Key-sorted JSON: the contract relies on `json.encode`/`json.write` sorting
  object keys alphabetically to match `jq -S`; verified on the current pinned
  build, but a serialization change in a future XSH build could silently
  break byte-exactness — mitigated by the per-case oracle comparison being the
  hard judge.
- Trailing-newline detail: `json.write` emits no final newline while `jq -cS`
  does; the task states the requirement explicitly, but an agent could miss it
  and fail only the byte comparison (this is the intended exactness gate, not
  a correctness trap).
- Sorting ties: hidden cases use distinct `name` values so `jq sort_by` and
  XSH `sort-by` tie behavior never decides the verdict; a future case set must
  keep names distinct.
- Oracle presence guard: `jq` exits 0 on empty stdin, so the oracle guards
  with `test -n "${CFG_DOC-}"` before invoking jq; the evaluator must run the
  oracle as stated in `runtime/task.md`, not a bare `jq` pipe, or the
  missing/empty failure control would diverge.
- Environment injection: `CFG_DOC` may contain quotes/UTF-8; the evaluator
  must pass it as one `env:` record (no shell interpolation), which the
  container dry run already does.
- Unproven live-agent and controller-dispatch paths are noted in `## Dry run`;
  a first real trial may still surface worker friction that is classified as
  handbook/ticket material rather than an eval defect.

## Review path

Pending user approval: `runs/run-1785726325461/phases/04-eval-design/proposals/proposal-1/`
(EVAL.md, runtime files, selectors, Dockerfile, dry-run evidence). On
approval the controller stages `evals/task-jsonfilter/` and merges the
`run_task_jsonfilter` dispatch branch into the shared evaluator, then the
normal `run-eval.xsh` cycle can run trials.
