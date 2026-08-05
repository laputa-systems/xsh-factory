## Result

ready-for-review

## Proposal

- Proposal path:
  `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785888600805/proposals/proposal-1/`
- Scaffolding (all present, status `Draft.`):
  - `EVAL.md` — task contract, north-star hypothesis, agent boundary, oracle,
    public/hidden cases, metrics, and manager policy.
  - `runtime/task.md` — the worker-facing task text with the `tail -n "$N" "$in"`
    oracle and acceptance rules.
  - `runtime/artifact.md` — `tailn.xsh`.
  - `executor.xsh` — thin selector for the shared `eval-executor.xsh`
    (`-- task-tailn`), modeled on the approved `task-trim` selector.
  - `evaluator.xsh` — thin package selector for the shared
    `evaluate_legacy.xsh` (`-- task-tailn`), modeled on the approved package.
  - `evaluate.xsh` — generic selector for `evaluate_common.xsh`.
- Task ID: `task-tailn` (new, not an existing eval). Difficulty is at or below
  the `task-ecount` upper bound: it reads a newline-terminated text file's
  lines, keeps the last N, and emits a byte-exact line stream. No approved eval
  exercises an end-of-stream slice of a line-oriented file, so this is a novel
  capability.

## Dry run

- Exercised: the smallest available package syntax/reference check. `xsht check`
  was run against the proposal's three XSH scaffold scripts
  (`executor.xsh`, `evaluator.xsh`, `evaluate.xsh`); all exited 0 on the first
  pass, so no scaffold error needed fixing.
- The line-stream idiom the task targets is documented in the shared handbook
  and the XSH SPEC/STREAMS reference (`path.lines()?`,
  `text.lines()`, stream/list `take`/`drop`) and was confirmed present in the
  checkout source before the contract was written.
- Not exercised (unproven): the live eval-agent session, the oracle-container
  byte-for-byte comparison, and the `Path.lines()`/`drop` pipeline executed
  inside the pinned gym image. Per the designer boundary I did not build a
  candidate implementation, a custom oracle runner, a localized evaluator, or a
  negative-control harness, and I did not run an agent. No dry-run evidence is
  claimed that was not saved under the proposal.

## North-star impact

Capability hypothesis: given a mature XSH handbook, an agent should be able to
replace the small `tail -n N file` shell idiom with a clear, typed XSH program
that brings a file in as a typed line stream and slices off the end — the same
"small script that grows into a tool" systems-glue promise the language is
built on. This matters because reading a log/config file and taking its last N
lines is everyday administration glue, and no current eval probes the
end-of-stream slice boundary (approved evals cover whole-file normalizers,
aggregation, CLI transforms, and filesystem walks). The design is generalizable
rather than a trick: variants of N, blank lines, UTF-8 bytes, the empty result,
and the whole-file edge each map to a distinct rejected behavior, so a correct
answer cannot be produced by hard-coding or by shelling out.

## Known risks

- Oracle/timing: relies on the BusyBox `tail -n` applet; the contract pins
  inputs to newline-terminated UTF-8 text so line counting and the final
  newline are unambiguous. `tail -n 0` and an empty file both print nothing and
  exit 0; the hidden cases cover these.
- Slice idiom: the intended solution depends on stream/list `drop`/`take` and
  `List.len()`; if the pinned gym image's API surface for slicing differs from
  the documented `take`/`drop`/`last`, an agent may need extra discovery. This
  is a handbook discoverability risk, not an oracle escape.
- Negative control: the source check (no subprocess, must read through the
  `fs` facade, review.md headings intact) lives in the shared evaluator
  protocol and was not re-run here; it is inherited unchanged from the approved
  base line.
- Unproven halves: the live agent trial and the oracle-container comparison
  were not executed in this session; those remain the CTO's validation points
  before the package can be promoted to `Approved.`.

## Review path

- Promoted eval path (on CTO acceptance):
  `/Users/josh/d/laputa-systems/xsh-factory/evals/task-tailn/` staged with
  `EVAL.md`, `executor.xsh`, `evaluator.xsh`, `evaluate.xsh`, and
  `runtime/{task,artifact}.md`, preserving `Draft.` status until review.
- Evidence for the decision: the complete package tree above; `xsht check`
  succeeded (exit 0) on the three scaffold XSH selectors this session; the
  line-stream / slice idiom is present in the shared handbook and the XSH
  source reference. The CTO approval should additionally confirm the oracle
  `tail -n "$N" "$in"` contract and decide whether to promote to `Approved.`
  before the package is admitted to paid work.
