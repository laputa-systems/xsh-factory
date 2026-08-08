# Ticket task-bigfiles-003

## Status

Approved.

## CTO decision — pre-cycle-6

- Decision: Approved for one engineer row.
- Basis: The fresh `task-bigfiles` worker in
  `runs/run-1786168895521/phases/03-eval/workers/eval-worker/task-bigfiles-1/`
  directly reproduced `stat=false` yielding zero metadata and then passed the
  matched nine-case size-reporting replay. The independent manager narrative
  was blocked by the controller ticket-snapshot race, not by missing product
  evidence; that race is repaired and covered by native tests.
- Scope: Implement the smallest diagnostic or distinguishable-metadata fix,
  with the required runtime/checker/docs regression coverage. Do not add
  named-argument syntax unless the engineer proves it is necessary for the
  acceptance contract.

## CTO review

- Review cycle: post-cycle-4.
- Decision: Deferred; do not approve or dispatch yet.
- Basis: The silent metadata-zero observation is useful and reproducible, but
  it proposes a broader runtime/API contract change than the retained
  pathparts delivery and has only one fresh eval signal.
- Next evidence: Require a focused `stat=false` metadata check and a matched
  size-reporting replay before approval; keep `task-bigfiles-002` separate.

## Change target

- `product`

Factory changes are CTO-owned. Do not create a factory-target ticket for
engineer dispatch; report the infrastructure change to the CTO instead.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `9bbc473af32e20e7bb3fa9b967a51acd89eb5200`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-bigfiles`
- Shared handbook lineage: `runs/run-1786167293099/phases/03-eval/lineage/handbook-approved.md`
- Manager run: `runs/run-1786167293099/phases/03-eval/workers/eval-manager/task-bigfiles/REPORT.md`
- Executor run: `runs/run-1786167293099/phases/03-eval/workers/eval-worker/task-bigfiles-1/session.jsonl.bz2`
- XSH baseline commit: `9bbc473af32e20e7bb3fa9b967a51acd89eb5200`

## Observation

`fs.files` (and `fs.walk` / `fs.children`) accept only positional arguments,
with `stat` defaulting to true and `hidden` defaulting to false. To include
hidden files an agent must supply every preceding positional value, e.g.
`fs.files(root, false, true, [], true)`. A slip that sets `stat=false`
(second positional) silently produces a stream whose `size` field is `0` for
every entry, with no diagnostic, no warning, and no check failure. In this
session the eval-worker's first working program
(`fs.files(root, false, false, [], true)`) output a size of `0` for every
file; the wrong (all-zero) ranking was detected only by comparing against a
separate `stat` probe, costing several extra turns.

## Evidence

- Worker session `session.jsonl.bz2`: the probe at message `089afa02`
  (`fs.files(root)` vs `fs.files(root, false, true, [], true)` vs
  `fs.files(root, false, false, [], true)`) reports
  `default 451 statTrue 451 statFalse 0`, directly reproducing the silent
  zero-size result.
- The intermediate artifact wrote `fs.files(root, false, false, [], true)`
  and emitted a top-5 list where every size was `0` (`message` `6c915dc9`),
  before the worker corrected it to `stat=true` at message `1f092ee6`.
- `review.md` (xsht friction) records: "Sizes are only populated when `stat`
  is true (which is the default), but a stray explicit `stat=false` produces
  all-zero sizes silently; no check catches this."
- Final artifact `/work/bigfiles.xsh` uses `fs.files(root, false, true, [],
  true)` and passes all nine evaluator cases byte-for-byte; the restored
  `stat=true` was the difference between the wrong all-zero output and the
  correct ranking.

## Diagnosis or hypothesis

This is a general XSH correctness/ergonomics problem, not a task-specific
miss. A non-empty numeric attribute (`size`) that is silently reported as `0`
when the entry was not statted is a quiet data-correctness trap: no error, no
warning, and no `xsht check` signal, so a program that depends on `size`
(beyond this eval, any disk-usage, ranking, or metadata report) produces a
plausible-but-wrong answer. The positional-only call surface compounds it:
changing the far-right default (`hidden`) forces the caller to restate every
earlier positional (including `stat`), which is exactly where the slip
happened. The same trap applies to `fs.walk` and `fs.children`, all of which
carry a `stat` default.

## North-star impact

Resolving this advances the north-star goal of trustworthy, explicit
boundaries. The minimal fix is a diagnostic: when a caller requests an
attribute that a non-statted entry does not carry (or when `stat=false` and
size-dependent fields are read), emit a warning or make the populated fields
distinguishable from real zeros rather than returning silent `0` unknowns. A
stronger ergonomic option is supporting named arguments for these parameter
lists so callers can set `hidden=true` without restating `stat`. Evidence of
generalization: any later eval or user program that ranks or reports file
metadata by size (du/sort/head analogues) reaches correct sizes without the
all-zero silent failure and the extra probe turns.

## Proposed XSH change

Emit a diagnostic when a field that requires stat information (e.g. `size`,
`mode`, `uid`) is read from an entry produced without `stat=true`, instead of
silently returning a zero placeholder; and/or document (and ideally support)
named-argument spelling for `fs.files`/`fs.walk`/`fs.children` so a caller can
set `hidden=true` without restating `stat`. The smallest, lowest-risk first
step is a runtime warning (or typed marker) on reads of unpopulated metadata,
paired with regression tests that exercise the all-zero-size case.

## API-surface justification

The existing `stat=false` surface already returns `0` for every metadata
field, so the capability to read unpopulated fields exists but is silent. This
proposal makes the already-available boundary explicit rather than adding a
new builtin or syntax. The closest existing spelling (`stat` default true)
is sufficient when unchanged, but the positional call surface gives no safe
way to (a) set `hidden=true` and (b) guarantee `stat` stays populated, which is
why a named-argument option or a clear diagnostic is warranted. Cost is
bounded to the checker/runtime diagnostic path (or parser named-arg support)
plus doc/example and regression tests; no new data model is required.

## Acceptance criteria

- Reading a metadata field (e.g. `size`) from an entry whose `stat` is false
  produces a warning or a distinguishable non-zero-ambiguity signal, rather
  than a silent `0`.
- A regression test covers the `fs.files(root, false, false, [], true)`
  all-zero case and asserts the diagnostic fires.
- A replay of `task-bigfiles` (or another size/metadata-reporting eval) shows
  the agent reaching the correct `stat=true`/hidden configuration without the
  silent all-zero ranking and the extra probe turns.

## Scope and non-goals

Out of scope: changing the task, evaluator, or harness; recommending provider
changes; altering the meaning of a real zero-byte file size. The `sort-by`
signature rendering is tracked separately in `task-bigfiles-002`.

## Post-merge evaluation

A `task-bigfiles` replay at the merged XSH commit, checking that the worker
emits correct non-zero sizes on the first or second attempt (no all-zero
silent phase) and that all nine cases still pass byte-for-byte.
