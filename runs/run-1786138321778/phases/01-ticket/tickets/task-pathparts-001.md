# Ticket task-pathparts-001

## Status

Approved.

## CTO decision — 2026-08-07

- Decision: Approved for implementation in the next organization cycle.
- Evidence: `task-pathparts` passed correctness but failed its typed-`Path`
  restriction after a 45-shape reproduction of the POSIX divergence; the
  mismatch is documented and the acceptance criteria are testable.
- Admission: Dispatch one engineer and require the linked
  `task-pathparts` replay before delivery. The engineer may choose the
  smallest documented/API-compatible fix; no unrelated path redesign is
  admitted.

## Change target

- `product`

Factory changes are CTO-owned. Do not create a factory-target ticket for
engineer dispatch; report the infrastructure change to the CTO instead.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-pathparts`
- Shared handbook lineage: `runs/run-1786136684797/phases/03-eval/lineage/handbook-approved.md`
- Manager run: `runs/run-1786136684797/phases/03-eval/workers/eval-manager/task-pathparts/`
- Executor run: `runs/run-1786136684797/phases/03-eval/workers/eval-worker/task-pathparts-1/`
- XSH baseline commit: `857154dfe505f0d01053c1b5311f44422070eb34`

## Observation

The eval requires the submitted program to decompose one path argument into
its directory, final component, and extension through the typed `Path` value
(the `Path(` construction is a hard restriction gate). The eval-worker
started with the typed `Path` surface (`Path.name()`, `Path.parent()`,
`Path.ext()`) but found those methods do not reproduce the POSIX
`dirname`/`basename`/shell-extension contract the oracle requires, so it
abandoned the typed `Path` and reimplemented `dirname`/`basename`/extension
with raw `Str` byte slicing. The final artifact passes all 45 tested shapes
and all 7 eval cases for correctness, but does not reference `Path(`, so the
evaluator reports `restrictions.path_referenced: false` and the trial fails.

Concrete divergences observed by the worker (documented in its review):

- `Path.name()` returns `""` for `/`, `.`, and `..`, while `basename` yields
  `/`, `.`, and `..`.
- `Path.parent()` normalizes `a/.` to `.`, while `dirname` yields `a`.
- `Path.ext()` conflates "no extension" (`.profile`, `plain` → the oracle's
  `none`) with an empty trailing-dot extension (`file.` → the oracle's empty
  ext), so a caller cannot distinguish the two cases from the returned value.

## Evidence

- Session transcript `task-pathparts-1/session.jsonl.bz2`: turn 12 shows the
  `standard-module-shadow`/`unknown-module-api` probe; turns 15, 37 document
  `Path.ext()`/`Path.name()`/`Path.parent()` divergences from the oracle;
  turn 33 onward shows the manual raw-string `dirname`/`basename`/ext
  reimplementation being iterated against a 45-shape oracle harness until
  `ALL MATCH` (turn 56).
- Final artifact `task-pathparts-1/pathparts.xsh` contains no `Path(`
  construction and reimplements the logic over `Str`.
- Worker review `task-pathparts-1/review.md` records the `Path.ext()` /
  `Path.name()` / `Path.parent()` divergences and proposes tri-state
  extension and exact `dirname`/`basename` semantics.
- Evaluator `task-pathparts-1/run.json`: `correctness` all seven true,
  `restrictions.path_referenced: false`, `classification: restriction_failed`,
  `result: fail`.

## Diagnosis or hypothesis

This is a general XSH ergonomics/correctness surface problem, not
task-specific confusion. The worker produced a correct, well-tested program
and understood the task; it was unable to satisfy a byte-exact POSIX
path-decomposition contract using the typed `Path` value that the north star
and this eval nominate as the trusted boundary. Any future agent that must
reproduce `dirname`/`basename`/shell-extension output on arbitrary path
shapes (`,` `.`, `..`, single-dot components, hidden files, trailing dots)
faces the same wall and is driven back to raw string parsing, defeating the
typed-`Path` ergonomics goal. The divergence between typed `Path`
decomposition and POSIX path semantics is also undocumented in the handbook,
so an agent cannot predict it from the reference and must discover it by
trial and error (the worker burned most of a 36-turn session here).

The eval's `Path(` restriction gate is itself evidence-dependent on this
surface: the intended typed-Path path is not expressible for the whole
contract, so the eval cannot pass its stated north-star hypothesis until the
surface is corrected or the divergence documented.

## North-star impact

The XSH rationale names ergonomics and honest, explicit boundaries as first
priorities, and the north star calls typed `Path` a boundary to strengthen
("connect ... paths ... system state"). A typed path value whose
`parent`/`name`/`ext` decomposition silently diverges from the predictable
POSIX `dirname`/`basename`/extension behavior forces agents to abandon the
typed boundary and reimplement string logic, which is exactly the friction
the factory exists to remove. Resolving it (by adding exact
`dirname`/`basename` semantics or a tri-state extension, or by documenting
the divergence so it is discoverable) restores the typed `Path` surface as a
trustworthy, learnable boundary. Evidence of generalization: an agent using
`Path.name()`/`parent()`/`ext()` in any eval reproduces the oracle and no
longer needs a raw-string reimplementation; confirmed by replay of
`task-pathparts` and a second path-decomposition eval against the merged
change.

## Proposed XSH change

Smallest-surface candidates, in recommended order:

1. Add exact `dirname`/`basename` string semantics to the `Path` value (or a
   module function), matching POSIX behavior on `/`, `.`, `..`, `a/.`,
   repeated slashes, and trailing slashes, so a byte-exact contract is
   expressible without raw string parsing.
2. Make `Path.ext()` tri-state (or otherwise distinguishable) so "no
   extension" is distinct from an empty trailing-dot extension, matching the
   `none`/empty sentinel the shell contract expresses.
3. If the `Path` normalization is a deliberate design (e.g. `parent()` of
   `a/.` intentionally returns `.`), document the divergence in the handbook
   and in `xsht api` contracts so agents can predict it and decide when to
   fall back to raw string logic. This is the minimal admission but leaves
   the raw-string reimplementation in place.

## Acceptance criteria

- A fresh `task-pathparts` trial can satisfy the `Path(` restriction and the
  seven-case oracle using a typed API (no raw `Str` reimplementation of
  `dirname`/`basename` required).
- `Path.ext()` distinguishes "no extension" (`none`) from empty trailing-dot
  extension (`""`), or the divergence is documented in the reference and the
  handbook.
- Existing behavior of the typed `Path` for normal paths is unchanged.

## Scope and non-goals

- No change to the task contract, fixture cases, or evals.
- No provider/fallback change.
- If the intended resolution is documentation-only (Option 3), that is a
  handbook/reference admission and still must be replayed to confirm agents
  no longer spend a long session discovering the divergence by trial.

## Post-merge evaluation

Replay `task-pathparts` and one other path-decomposition eval against the
merged build; the eval-manager records whether the agent can satisfy the
byte-exact contract through the typed `Path` surface without reverting to raw
string parsing.
