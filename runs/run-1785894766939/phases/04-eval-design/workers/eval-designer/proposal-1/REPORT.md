## Result

ready-for-review

## Proposal

`task-histogram` — a binned cumulative distribution report.

Scaffolding under
`runs/run-1785894766939/phases/04-eval-design/proposals/proposal-1/`:
`EVAL.md` (status `Draft.`), `runtime/task.md`, `runtime/artifact.md`
(`histogram.xsh`), `executor.xsh`, `evaluator.xsh`, `evaluate.xsh`, and
`dry-run/DRY-RUN.md` with the exercised oracle and fixture evidence. The
scaffold's source title/ID was replaced with the new `task-*` ID and the status
is `Draft.`.

## Dry run

Exercised: the external oracle (byte-for-byte the `#!/bin/sh` block embedded
in `evaluator.xsh`) against the exact fixture data across the public case, six
hidden passing cases, and two failure controls. All seven passing cases exited
0 with the expected `bin count cumulative` output; `hidden_bad_width` exited 1
with empty stdout and `hidden_bad_value` exited 2 with empty stdout. `xsht
check` passes on `evaluator.xsh`, `executor.xsh`, and `evaluate.xsh`; `xsht
lint` reports only advisory warnings consistent with the approved scaffold
(rc 0). No candidate XSH solution was authored, so candidate/oracle timing is
unmeasured. Remaining unproven: the package-owned evaluator wiring and the
container-only `/usr/local/lib/xsh-factory` evaluator boundary, inherited
unchanged from the approved scaffold and not re-run in a container this cycle.

## North-star impact

Hypothesis: an agent with the handbook can turn raw measurements into a binned,
cumulative distribution report purely in typed XSH values — reading a file,
parsing each value with `parse_int()?`, deriving a bin key by integer division,
aggregating counts in a keyed Map, then `sort-by` + fold to compute the
cumulative column — with a loud nonzero exit on a non-integer value or a
non-positive width, and no subprocess escape. This probes the discoverability
and composability of integer division, keyed aggregation, and a sorted running
fold — the exact glue an operator reaches for instead of an `awk | sort | awk`
pipeline — and validates whether the handbook's Result/`?` and Map idioms
transfer to a real measurement-summary boundary. It is at least ecount-level: it
exceeds traversal + keyed counting by adding an arithmetic bin transformation
on every element and a second independent cumulative reduction over the sorted
bins, giving the CTO a replayable signal for a capability no current eval
covers.

## Known risks

- **Division semantics**: the task relies on integer division of non-negative
  values; `/` (truncation) matches the oracle's `int($1/w)`, and the worker must
  discover that operator via `xsht api`. If the pinned image's integer-division
  behavior differs for any value, the oracle would be the arbiter and a mismatch
  would surface as a candidate failure, not a silent pass. Verified `/` on the
  host build for non-negative integers.
- **Failure-control exit values**: the two failure controls only require both
  sides to exit nonzero with empty stdout; specific exit codes differ (1 vs 2)
  by design and are not compared, so this is robust.
- **Restriction markers**: `read_text`, `parse_int`, `sort-by` were chosen as
  anti-hardcode gates for a natural solution; a valid but unconventional
  alternative that omits one marker would be classified as a restriction
  failure. This matches the precedent set by `task-colsum`/`task-bigfiles`.
- **Timing**: no candidate was built or timed; the candidate/oracle timing
  envelope is unproven until the first worker trial (both sides finish in
  milliseconds, so this is diagnostic only).
- **Container wiring**: the shared evaluator path is container-only and was not
  re-run end-to-end this cycle.

## Review path

Promoted eval path: `evals/task-histogram/` (staged on CTO approval with this
package). Evidence for the CTO decision: `EVAL.md` (including the
`## Difficulty justification` section), `runtime/task.md` and
`runtime/artifact.md` (contract), `evaluator.xsh` (oracle, fixture, hidden
cases, restriction, protocol checks), `executor.xsh`/`evaluate.xsh` (thin
selectors for the shared executor/evaluator protocol), and the saved
`dry-run/DRY-RUN.md` showing the oracle passing all seven passing cases and
both failure controls on the host. Package status is `Draft.`; the CTO review
gate decides promotion and `Approved.` status after the session.
