# Eval-designer report

## Result

ready-for-review

## Proposal

`task-col2` — replace the `awk '{print $2}'` idiom with a typed XSH program.
It reads a file's text through XSH APIs, prints the second
whitespace-delimited field of each line (empty line for blank or
single-field lines), matches the oracle byte-for-byte, and exits nonzero with
no fabricated output on a missing input.

Staged under
`runs/run-1785728831509/phases/04-eval-design/proposals/proposal-1/`:

- `EVAL.md` — capability hypothesis, task, agent boundary, oracle/evaluator
  contract, hidden cases, metrics, manager policy, staged dry-run record
- `executor.xsh` / `evaluate.xsh` — controller scaffold with the selector
  switched from `task-tags` to `task-col2`
- `runtime/task.md` — user-facing task prompt (oracle, dev loop)
- `runtime/artifact.md` — `col2.xsh`
- `dry-run/DRY-RUN.md` + `dry-run/evidence/` — reference solution, ten case
  inputs, per-case candidate/oracle outputs, container smoke results

## Dry run

Exercised on the host and inside the pinned `xsh-factory-base:latest` image:

- Reference `col2.xsh` (`fs.read_text` + `Str.lines` + `Str.fields` +
  `List.get(1, "")` + `print`) passes `xsht check` / `lint`; `fmt` is a no-op.
- Byte-for-byte match vs BusyBox `awk '{print $2}'` on all nine content
  cases (public, single-field, blank lines, leading whitespace, multiple
  spaces/tabs, trailing whitespace, Unicode, no trailing newline, empty
  file), both on the host and inside the container.
- Failure control: missing input exits nonzero (candidate 3, oracle 2) with 0
  stdout bytes, on host and in container.
- Negative controls rejected as designed: hard-coded output matches only the
  public case and fails a hidden case; a source without `read_text` fails the
  restriction scan; a source containing `process`/`run`/`spawn` fails the
  restriction scan; a missing `review.md` fails the evaluator's review check.

Remaining unproven: the live Pi worker session (needs a paid agent session and
Pi auth file; the agent path is inherited unchanged from the approved base
image) and the controller-owned `evaluate_common.xsh` dispatch branch for
`task-col2`, which per the approved-eval precedent is merged on approval, not
by the designer.

## North-star impact

Hypothesis: an agent with the handbook can replace the archetypal glue-DSL
one-liner (`awk '{print $2}'`) with a clear, typed XSH program by discovering
the file-content surface (`fs.read_text`), the line stream (`Str.lines`), the
whitespace-field splitter (`Str.fields`), and indexed fallback access
(`List.get(1, "")`), while keeping stdout byte-exact and propagating a
missing-file failure with postfix `?`. No current eval reads file text and
transforms it line by line, so a successful run would teach the factory
whether the handbook's "reading and writing files" promise is discoverable
and whether line-oriented text idioms compose — the exact systems-glue gap the
north star names. The design resists task-specific hacks because hidden cases
vary field counts, whitespace layout, blank lines, Unicode, and the
missing-file failure control, and because a hard-coded print, a silent
fallback, or a subprocess escape each fails a distinct gate.

## Known risks

- Task-specific hack: a worker could hard-code the public file's output; the
  hidden-case byte-match and the `read_text`-reference restriction check close
  this, as the negative controls demonstrate.
- Oracle/whitespace risk: Rust `split_whitespace` and BusyBox `awk` agree on
  space/tab input but differ in principle on exotic Unicode whitespace; the
  case set keeps whitespace ASCII, and the oracle remains the authority for
  any future case addition.
- Timing: no strict candidate/oracle gate; both sides finish in milliseconds,
  so timing is diagnostic only, matching the envcfg precedent.
- Integration risk: the containerized evaluator run is not reproducible by the
  designer because the `task-col2` branch in the controller-owned
  `evaluate_common.xsh` is added on approval; the dry run proves the contract
  and isolation boundary directly instead.
- Missing checks: the live agent path and the evaluator dispatch integration
  are unexercised and should be the first checks of the approval replay.

## Review path

Pending user approval of `runs/run-1785728831509/phases/04-eval-design/proposals/proposal-1/EVAL.md`.
On approval, the controller stages `evals/task-col2/` from this scaffolding and
merges the `run_task_col2` branch into the shared `evaluate_common.xsh`
dispatch so the normal `run-eval.xsh` build stages it into the image.
