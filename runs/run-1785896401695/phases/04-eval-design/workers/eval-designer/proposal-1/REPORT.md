## Result

ready-for-review

## Proposal

A new draft eval `task-revrank` was designed and staged under
`runs/run-1785896401695/phases/04-eval-design/proposals/proposal-1/`. The task
replaces the scaffolded `task-bigfiles` title and ID, and its status is
`Draft.`

Scaffolding:

- `EVAL.md` — contract, artifact, oracle, hidden cases, agent boundary,
  metrics, manager policy, difficulty justification;
- `runtime/task.md` — the worker-facing task instructions;
- `runtime/artifact.md` — artifact name `revrank.xsh`;
- `executor.xsh` — thin selector dispatching the shared eval-executor for
  `task-revrank`;
- `evaluator.xsh` — package-owned evaluator (fixture, oracle, correctness,
  restriction, protocol checks, `run.json` manifest);
- `evaluate.xsh` — unchanged generic package selector;
- `dry-run/` — `DRY-RUN.md`, `reference/revrank.xsh`,
  `oracle/revrank-oracle.sh`, and `evidence/transcript.txt`.

The task: read a single-space four-field table (`REGION PRODUCT UNITS PRICE`),
derive per-row revenue `UNITS * PRICE`, accumulate it per region into an XSH
`Map[Int]`, and print `REGION TOTAL` rows ranked by total descending with an
ascending byte-order tie-break. Failure controls: a malformed row (wrong field
count or non-integer units/price) or an unreadable file must exit nonzero and
print nothing.

## Dry run

The reference `revrank.xsh` and an independent external oracle were exercised
on the host build across all cases the evaluator will run (transcript saved at
`dry-run/evidence/transcript.txt`):

- `public`, `hidden_multiproduct`, `hidden_tie`, `hidden_negative`,
  `hidden_order`, `hidden_many`, `hidden_empty` — candidate stdout byte-matched
  the oracle in every passing case.
- `hidden_bad_fields`, `hidden_bad_unit`, `hidden_missing` — candidate (exit 3)
  and oracle (exit 2) both exited nonzero with empty stdout, matching the
  failure control.

The reference passes `xsht check` and `xsht lint` (exit 0; lint emits only
non-blocking style warnings). The `executor.xsh`, `evaluator.xsh`, and
`evaluate.xsh` all pass `xsht check` with exit 0. The descending-rank with
ascending tie-break is implemented with the documented two-pass stable sort
(sort by region, then by negated total), which was verified to match the oracle
on the tie case — the single-pass compound-record and `--desc` single-pass
approaches were found to be checker-rejected or tie-order-reversing and were
excluded in favor of the reliable two-pass idiom.

What remains unproven: a live container trial of the exact
`/work`/`/session` mounts and a real agent session, plus the shared
`/usr/local/lib/xsh-factory/evaluate_common.xsh` evaluator plumbing, which is a
container-only surface and was not re-run end-to-end this cycle.

## North-star impact

Probes whether an agent can compose three genuinely independent XSH operations
into one practical report: a per-row arithmetic projection (parsing two typed
integer columns and multiplying), a keyed stateful aggregation into a Map, and
a numeric descending rank with a deterministic ascending tie-break. This is the
canonical "leaderboard / spend / usage per region" glue shape
(`awk '{s[$1]+=$3*$4} END{...}' | sort -rn`) that no approved eval covers. A
clean pass would teach that per-row derived arithmetic plus Map accumulation
plus the two-pass stable descending sort is discoverable from the handbook; a
miss would localize which of those idioms (typed parsing, Map immutable update,
or compound ordering) is still unclear, giving the manager a concrete,
generalizable handbook or product signal rather than a task-specific workaround.

## Known risks

- **Two-pass sort idiom is the brittle part**: the reference relies on the
  stable two-pass `sort-by .region` then `sort-by {-total}`. The compound-record
  and single-pass `--desc` alternatives are checker-rejected or reverse tie
  order in this build; if an agent chooses a one-`sort-by` solution it will fail
  the tie case, which is intended (the tie case is the hidden anti-hard-code
  gate), but it is the most likely source of a false "candidate failed" that is
  really an idiom-knowledge miss.
- **Failure-exit expression**: the reference uses `"bad-count".parse_int()?` to
  force a loud exit on a wrong field count (no generic `Error` constructor in
  the pinned image). This is sanctioned by the handbook's typed-conversion
  rule, but it is slightly unusual and worth confirming the container build
  propagates it the same way.
- **Oracle/exit-status coupling**: the oracle needs `set -o pipefail` so the
  failure controls propagate the awk exit instead of a trailing `0`; this was
  verified on the host and is embedded in `evaluator.xsh`, but a different
  BusyBox `sh`/`awk` in the container could in principle report a different
  nonzero exit — the check only requires nonzero, so it is robust to that.
- **Missing-file case**: the evaluator now skips seeding for `hidden_missing`;
  this is a host-verified extension of the scaffold and remains unproven inside
  the container mount layout.
- **Container surface unproven**: the shared evaluator protocol and real agent
  execution were not run end-to-end; the first live trial is the remaining
  evidence gap.

## Review path

Promoted eval path would be `evals/task-revrank/` (package-owned
`evaluator.xsh`). Evidence for the CTO approval decision:

- `proposals/proposal-1/EVAL.md` with the `## Difficulty justification` naming
  the per-row arithmetic projection, the keyed Map aggregation, and the numeric
  ranking as three independent operations, plus the explicit failure control
  and the hidden cases that defeat one-liners / hard-coded answers.
- `proposals/proposal-1/dry-run/DRY-RUN.md` and
  `dry-run/evidence/transcript.txt` showing the reference byte-matching the
  oracle on all passing cases and both exiting nonzero with empty stdout on all
  three failure controls.
- `xsht check` passing for `executor.xsh`, `evaluator.xsh`, `evaluate.xsh`, and
  the reference `revrank.xsh`.

The package remains `Draft.` pending the CTO review gate.
