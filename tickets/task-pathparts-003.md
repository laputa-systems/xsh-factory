# Ticket task-pathparts-003

## Status

Open.

## CTO review

- Review cycle: post-cycle-4.
- Decision: Deferred; do not approve or dispatch yet.
- Basis: The lint false positive is strong, reproducible product evidence,
  but the current approved `task-pathparts-002` branch must be replayed and
  delivered first; admit this follow-on only after the corrected aggregation
  boundary is validated and the proposed read-analysis fix has an isolated
  acceptance run.
- Next evidence: Require a focused display-string lint regression and a
  second output-composing replay before approval.

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
- Shared handbook lineage: `runs/run-1786167293099/phases/02-reeval-task-pathparts-002/lineage/handbook-approved.md`
- Manager run: `runs/run-1786167293099/phases/02-reeval-task-pathparts-002/workers/eval-manager/task-pathparts/`
- Executor run: `runs/run-1786167293099/phases/02-reeval-task-pathparts-002/workers/eval-worker/task-pathparts-1/`
- XSH baseline commit: `9bbc473af32e20e7bb3fa9b967a51acd89eb5200`

## Observation

`xsht lint` reports `warn[lint.unused-local]` (and exits with code 1) for a
local variable that IS read inside a display-string (`f"..."`) interpolation.
In `task-pathparts` the worker wrote `print f"dir=$dir"` where `dir` is a
local binding that the f-string interpolates. Lint flags `dir` as an unused
local ("binding is never read") and exits nonzero, even though the variable is
plainly used and the program runs correctly. The handbook explicitly
recommends display strings for composing exact dynamic output, so the tool's
own documented idiom hard-fails its own quality check.

## Evidence

- Session `task-pathparts-1/session.jsonl`, turns 13 and 16: running
  `xsht lint` on `proc main(...argv: List[Str]) { ... print f"dir=$dir"; ... }`
  produced
  `warn[lint.unused-local]: unused local variable dir ... binding is never read`
  and `Command exited with code 1`, for each of `dir`, `name`, and `ext`.
- The same session verified the workaround: rewriting as
  `let ld = "dir=" + dir; print $ld` makes `xsht lint` exit 0. So the
  concatenation form is accepted while the display-string form is not.
- The program's runtime output was correct for every case, confirming the
  f-string interpolation reads the variable and the lint warning is a false
  positive.
- The worker's `review.md` (field `## xsht friction`) records the same finding
  independently.
- No invalid `xsht api` discovery query is implicated; the false positive is a
  lint read-analysis behavior, not agent error.

## Diagnosis or hypothesis

This is a general XSH ergonomics/trust defect, not task-specific confusion.
The handbook's own guidance ("Use a display string `f"host=${host} port=${port}"`
to compose exact dynamic text") leads an agent straight into a lint failure
because the unused-local analysis does not count a read inside an f-string
template as a use of the interpolated binding. Any program that composes output
from a local value through a display string and then reuses that same value
elsewhere (or alone) can be flagged. This is the same class of internally
inconsistent surface as the lint/restriction tension in `task-pathparts-002`:
a documented, correct idiom fails the factory's own visible check, so the agent
must guess a workaround (here, `+` concatenation) that the handbook does not
teach as the preferred form. The `+` workaround is not wrong, but the lint
should not hard-fail the documented display-string idiom on a false positive.

## North-star impact

The north star targets ergonomics ("fewer guesses, workarounds, ... repeated
discoveries") and trustworthy, learnable surfaces. A lint that reports an
unused-local false positive on the handbook-recommended display-string form
forces agents to discover a non-obvious workaround and erodes trust in the
tool's guidance. Fixing the read-analysis so f-string interpolation counts as a
read lets agents follow the documented idiom without a workaround. Evidence of
generalization: a second eval whose solution composes output via display
strings passing `xsht lint` without the concatenation workaround, plus the
replay in `## Post-merge evaluation`.

## Proposed XSH change

Fix `xsht lint`'s unused-local read analysis so that a local binding
interpolated inside a display string (`f"...$name..."`) is counted as a read
(the name is dereferenced in the template). The smallest change is in the
lint's reference collection for the `f"..."` AST node, mirroring how it already
treats `$name` dereferences in print/expression position. Keep the `+`
concatenation spelling as an accepted alternative; do not change the
display-string semantics, the language, or the runtime.

## Acceptance criteria

- `xsht lint` reports no `unused-local` for a local that is read only inside a
  display-string interpolation, and exits 0 on such a program.
- `xsht lint` still reports `unused-local` for a genuinely unused local (no
  false negatives).
- The `task-pathparts` solution can be written with `print f"dir=$dir"` (or
  equivalent display strings) and pass `xsht check`, `fmt`, and `lint` without
  the concatenation workaround.
- Eval contract, fixture cases, and oracle are unchanged.

## Scope and non-goals

- No change to display-string language semantics, `print`, or the runtime.
- No change to the `task-pathparts` task contract, fixture cases, or oracle.
- Does not overlap the `task-pathparts-002` path-constructor lint advisory,
  which is a separate severity/exit-code change; this ticket targets the
  unused-local read-analysis itself.

## Post-merge evaluation

Replay `task-pathparts` against the merged build and record whether the worker
can compose the three output lines with display strings and pass
`xsht check`/`fmt`/`lint` without the `+` workaround, and whether a second
output-composing eval confirms the same. The linked eval-manager records
accept/reject.
