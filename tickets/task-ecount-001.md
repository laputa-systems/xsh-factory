# Ticket task-ecount-001

## Status

Merged.

## Change target

- `product`

## CTO review

- Review cycle: `run-1785787490432` (2026-08-03)
- Decision: Approved for the next ticket-implementation cycle.
- Basis: The missing `language:stream.*` signatures and module-function text
  signatures are independently reproduced, affect general API discovery, and
  have concrete acceptance criteria covering API output, compatibility, and a
  task-ecount replay.
- Assignment boundary: repair the API reference payloads and text rendering
  described here; do not broaden into unrelated stream semantics.

## Merge record

- Implementation branch: `factory/task-ecount-001/1785789595996`
- Implementation commit: `c2402341d7f3cf29b504ca8c22b89be2cf7a3eba`
- Detected at XSH commit: `c2402341d7f3cf29b504ca8c22b89be2cf7a3eba`
- Implementation run: `runs/run-1785789595047`
- CTO merge verification: `cargo test -p xsht` passed (164 tests)

## Source eval and manager

- Eval: `task-ecount` (`evals/task-ecount/EVAL.md`)
- Shared handbook lineage: `runs/run-1785654810978/phases/03-eval/lineage/handbook-approved.md` (approved `c7c9dd9a…`; candidate `c7c9dd9a…` unchanged)
- Manager run: `runs/run-1785654810978/phases/03-eval/workers/eval-manager/task-ecount/session.jsonl`
- Executor run: `runs/run-1785654810978/phases/03-eval/workers/eval-worker/task-ecount-1` (trial 1)
- XSH baseline commit: `a66ade8218aacb38a2d1247db192f0c550cbb5cd`

## Observation

`xsht api` is the live reference the handbook names as the source of truth
("Treat the displayed signature and contract as the source of truth for a
task."), but every `language:stream.*` entry carries an empty signature list,
so agents cannot confirm the signature or return shape of the core pipeline
stages. The task-ecount worker needed `group-by`'s record shape and had to
discover by trial and error that the stage yields a record with `key` and
`items` (not a `Map`), and repeatedly re-queried `module:tui.left_pad` because
the text output never showed its signature.

Reproduced on the pinned image (`xsh-factory-task-ecount:latest`, XSH commit
`a66ade82`, image `sha256:824ba48787b92746d28effb9855b02819371147fa7851f452663e0b5618b1956`):

```text
$ xsht api language:stream.group-by --format jsonl
... "signatures":[] ...
$ xsht api language:stream.fold --format jsonl
... "signatures":[] ...
$ xsht api language:stream.map --format jsonl    # and where, collect, sort, each,
... "signatures":[] ...                          # unique-by: all empty
```

By contrast, module functions and methods carry signatures in jsonl:
`module:fs.files` has the full signature and return record, and
`method:Str.lower` has `Str.lower() -> Str`.

Second, related formatter defect: the text formatter omits the signature line
for module functions even though the jsonl payload contains it. `xsht api
module:tui.left_pad` (text) prints only purpose; `--format jsonl` contains
`"signatures":["tui.left_pad(text: Str, width: Int) -> Str"]`. Methods do show
a `signature:` line in text output (`method:Str.lower`), so the behavior is
inconsistent by kind.

## Evidence

- Worker session: `runs/run-1785654810978/phases/03-eval/workers/eval-worker/task-ecount-1/session.jsonl` — multiple `xsht api` probes for stream stages, `tui.left_pad`, display-strings; the worker's thinking (turns ~14–30) shows it did not know `group-by`'s return shape and discovered `key`/`items` by writing and checking candidate code.
- Worker review: `runs/run-1785654810978/phases/03-eval/workers/eval-worker/task-ecount-1/review.md`, section `## xsht friction` — "The actual group field had to be discovered by trial and error (it is a record with `key` and `items`, not a `Map`)." and "The text format (`--format text`) for `module:tui.left_pad` and many module functions showed only the purpose."
- Manager host probe on the pinned image: `language:stream.group-by`, `fold`, `map`, `where`, `collect`, `sort`, `each`, `unique-by` all return `"signatures":[]`; `module:tui.left_pad` and `module:fs.files` return signatures only in jsonl, not text.
- Quantitative metrics: `run.json` protocol `review_ok: true`, restrictions `passed: true`; the run's only failure was the evaluator oracle (separate evaluator-failure observation, not this ticket).

## Diagnosis or hypothesis

The stream-stage reference data was authored without signature/return-shape
payloads, and the text renderer drops module-function signatures that exist in
jsonl. The handbook's promise — "Exact results show the purpose, contract,
effects, signature, tags" — is therefore false for the exact stages the
handbook tells agents to query first ("Common stages include where, map,
sort-by... Query their language references when the stage's block or ordering
semantics matter"). Any agent composing a pipeline must guess return shapes
instead of reading them. This is a general learnability/discoverability defect,
not a task-ecount recipe: it affects every pipeline-oriented script in every
eval, and it is consistent with the task-tags-002 finding that core constructs
are invisible to `xsht api`.

## North-star impact

The north star asks for a concise handbook that teaches reusable concepts and
for agents that "reach a correct, clear solution with less unnecessary
exploration, turns, and thinking." A live reference that omits the signature
and return shape of its own core stream stages forces trial-and-error
discovery — precisely the "repeated discoveries" the factory exists to remove.
Filling `signatures` for `language:stream.*` (at minimum the block signature
and the record shape produced by group-by/fold/each) and rendering the
existing module-function signatures in text output would make the documented
source of truth truthful. Evidence of generalization: any eval worker that
queries a stream stage would see its signature instead of empty output, and a
replay of task-ecount should show `group-by`'s `key`/`items` shape resolved
from `xsht api` rather than by trial and error.

## Proposed XSH change

Smallest candidate, two parts:

1. Populate signature/return-shape data for `language:stream.*` entries so
   `xsht api language:stream.<stage>` shows the block signature and the
   concrete output (e.g. `group-by(block) -> Stream[{key, items}]`,
   `fold(init, block) -> Stream[...]`, `each(block) -> Stream[...]`), in both
   text and jsonl output.
2. Make the text formatter emit the signature line for module functions when
   the jsonl payload contains one (parity with methods, which already render a
   `signature:` line).

No runtime semantics change.

## Acceptance criteria

- `xsht api language:stream.group-by` (text) prints a signature and a return
  shape naming the `key`/`items` record; the same is true for the other
  commonly queried stages (`map`, `where`, `sort-by`, `fold`, `each`,
  `collect`, `unique-by`).
- `xsht api module:tui.left_pad` (text) prints
  `tui.left_pad(text: Str, width: Int) -> Str` or an equivalent signature line.
- `xsht api` continues to resolve module functions and methods exactly as
  before, and `xsht check`/`fmt`/`lint` are unaffected.
- A replay of `task-ecount` on the merged change shows the worker resolving
  `group-by`'s return shape from `xsht api` (no trial-and-error loop), with
  the candidate still byte-for-byte matching the true oracle.

## Scope and non-goals

- No change to stream-stage runtime behavior or ordering semantics;
  documentation/indexing only.
- Not a task-ecount shortcut; the change must make any stream-stage query
  informative.
- No change to the shared handbook inside XSH; the factory lineage owns the
  agent-facing handbook.

## Post-merge evaluation

The `task-ecount` eval-manager will run a controlled replay against the merged
XSH commit using the current approved handbook lineage, check that the worker
resolves `group-by`'s record shape through `xsht api`, verify byte-for-byte
oracle match with the corrected evaluator oracle, and record acceptance or
rejection in that run's manager report.
