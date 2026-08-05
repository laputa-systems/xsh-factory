## Result

ready-for-review

## Proposal

A new substantive eval `task-svcstat` is materialized at
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785899099112/phases/02-eval-design/proposals/proposal-1/`
with package status `Draft.`:

- `EVAL.md` — contract, status Draft, difficulty justification, oracle, cases, metrics, manager policy;
- `runtime/task.md` — the `svcstat.xsh` task contract;
- `runtime/artifact.md` — `svcstat.xsh`;
- `executor.xsh` — thin task-svcstat selector into the shared `eval-executor.xsh`;
- `evaluator.xsh` — package-owned evaluator (fixtures, oracle, correctness, restriction, protocol checks);
- `evaluate.xsh` — the shared generic package selector (unchanged, task-agnostic).

The scaffold's source eval (`task-bigfiles`, `Approved.`) was fully replaced in
title, ID, EVAL body, task, and evaluator before any API or dry-run work; the
new ID `task-svcstat` is used throughout and `Status` is `Draft.`.

## Dry run

- `xsht check executor.xsh` and `xsht check evaluator.xsh` both pass (exit 0).
- The authored oracle was shell-syntax checked (`sh -n`) and exercised on the
  host against a public-shaped fixture: it emitted the expected byte-exact
  sorted report (`api 1 200`, `db 1 55`, `web 2 150`, exit 0). During this
  exercise I found and fixed an awk semantic bug (`exit` inside the main block
  still runs `END`, leaking a partial report); the corrected oracle now yields
  `exit 1` with empty stdout on the malformed line and the expected sorted
  output on a valid tree.

Unproven (container-only surfaces not run this cycle): the worker image
isolation, the `evaluate_common.xsh` staging/mount wiring, an end-to-end
oracle-vs-candidate comparison loop, and a real candidate solution. No
candidate implementation was written (forbidden), so oracle/candidate parity at
runtime and `group-by`/`fold` discoverability remain unproven until admission.

## North-star impact

Capability hypothesis: an agent with the shared handbook can write a clean,
typed XSH program that discovers many log files, parses and validates keyed
records, reduces them by service key with a count-plus-sum aggregation
(`group-by` + accumulator `fold`), strictly rejects any malformed record with
empty output and a nonzero exit, and emits a byte-exact sorted rollup — the
modern XSH analogue of a `find | awk '{c[$1]++;s[$1]+=$2}END{...}' | sort`
rollup. Why it matters: keyed cross-file aggregation (count + numeric sum) is
a first-class systems-glue shape and above the ecount minimum; it extends the
factory's evidence beyond ranking, grouping, and single-column summing toward
multi-reducer stream aggregation plus a strict-validation boundary that a
lenient or hard-coded one-liner cannot pass.

## Known risks

- Oracle collation parity: service names are restricted to ASCII
  letters/digits/underscore; `sort -k1,1` (byte order) is assumed to match XSH
  `sort-by` on Str. Not exercised end-to-end.
- awk dialect parity: the oracle was verified with the host awk; BusyBox awk
  (`exit` in `END` semantics, `split`, `[[:space:]]`-free regex) is a
  container-only surface and should be confirmed at admission.
- `group-by` + `fold` restriction check is name-based; if the pinned image
  spells these differently the restriction gate could false-negative (checked
  via `xsht api`: both `language.stream.group-by` and `language.stream.fold`
  exist in the reference build).
- Failure-control parity: the malformed fixture is unambiguous; a candidate
  that prints a partial report or exits 0 fails `hidden_malformed`.
- No end-to-end container or real-candidate evidence this cycle (see Dry run);
  a passing evaluator is not yet demonstrated against a live agent.
- `hidden_idents` relies on `SV3` (upper) sorting before `srv_*` (lower),
  exercising case ordering in both oracle and candidate.

## Review path

Promotion candidate upon approval: `evals/task-svcstat/`, staged with
`Draft.` retained until the evaluator and first-trial evidence pass. Evidence
for the CTO gate: the package's `EVAL.md` including the `## Difficulty
justification` naming the two independent transformations (line parsing /
validation, output formatting) and the stateful aggregation (group-by plus
count+sum fold); the strict failure control; the eight public/hidden cases
punishing one-liners and hard-coded answers; and the two passing scaffold
syntax checks plus the host-verified oracle behavior. Remaining gaps (container
isolation, oracle-vs-candidate parity, live-solution run) are named above and
should be closed at admission before the package is set `Approved.`.
