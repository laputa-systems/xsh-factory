# Ticket task-bigfiles-004

## Status

Approved.

## CTO review — cycle-12 queue

- Decision: Approved for a later fresh implementation cycle, after the
  retained `task-bigfiles-002` branch is delivered.
- Basis: The linked replay produced one strong, reproducible API-reference
  observation: `fs.files` and `fs.walk` silently omit dot entries by default,
  while the contract does not state the default. The queue has high open-ticket
  pressure and this is the next unused focused product identity with a live
  linked eval, but cycle 12 must first validate the repaired delivery gate.
- Scope: Document `hidden: false` and dot-entry omission for `api:fs.files` and
  `api:fs.walk`; do not change runtime behavior.
- Required acceptance: a fresh engineer reference change passes focused native
  tests, and a linked replay selects the intended hidden behavior from the
  contract without relying on a fixture experiment.

## Change target

- `product`

Factory changes are CTO-owned. Do not create a factory-target ticket for
engineer dispatch; report the infrastructure change to the CTO instead.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `fdeee37e911f820865dc617a14d61ec8e111c603`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-bigfiles`
- Shared handbook lineage: `runs/run-1786185105660/phases/02-reeval-task-bigfiles-002/lineage/handbook-approved.md`
- Manager run: `runs/run-1786185105660/phases/02-reeval-task-bigfiles-002/workers/eval-manager/task-bigfiles/REPORT.md`
- Executor run: `runs/run-1786185105660/phases/02-reeval-task-bigfiles-002/workers/eval-worker/task-bigfiles-1/session.jsonl.bz2`
- XSH baseline commit: `fdeee37e911f820865dc617a14d61ec8e111c603`

## Observation

The eval-worker wrote a recursively discovered regular-file report using
`fs.files(root, stat: true)?` and found that hidden dot entries were silently
omitted. A fixture containing `.hidden.txt`, run with and without
`hidden: true`, showed that the default `hidden=false` excludes dot entries;
only `fs.files(root, stat: true, hidden: true)` included them. The API purpose
and contract text do not state the `hidden` default or its dot-entry semantics.

## Evidence

- The worker session records the fixture probe and the final artifact's use of
  `hidden: true`.
- `xsht api api:fs.files` and `xsht api api:fs.walk` show a hidden option but
  do not state that its default is false or that dot entries are omitted.
- `/work/review.md` records the same reusable API-reference gap.
- All nine evaluator cases passed byte-for-byte after the worker selected
  `hidden: true`.

## Diagnosis or hypothesis

`fs.files` and `fs.walk` silently filter dot entries by default, and that
default is not documented. This is a general XSH learnability problem: a
recursive file-discovery program can look correct on visible-only trees and
quietly miss regular files on trees containing dot entries.

## North-star impact

Documenting the default and its dot-entry semantics makes recursive discovery
explicit and trustworthy, removing a silent behavior trap and the need for a
fixture experiment.

## Proposed XSH change

Add the `hidden` default and dot-entry filtering semantics to the `xsht api`
contracts for `fs.files` and `fs.walk`, with an API-reference regression test.
Do not change runtime behavior.

## API-surface justification

This is a documentation correction for an existing option, not a new builtin,
parser feature, evaluator change, or harness change.

## Acceptance criteria

- Both API entries state `hidden: false` and that dot entries are omitted.
- A reference test keeps that statement present.
- A linked replay reads the contract and selects the intended hidden behavior
  without relying on a fixture experiment, while all nine cases remain exact.

## Scope and non-goals

Out of scope: changing the default, traversal behavior, evaluator, harness, or
provider configuration.

## Post-merge evaluation

Replay `task-bigfiles` at the merged XSH commit and verify that the worker
selects the intended hidden behavior from the contract and remains byte-exact.
