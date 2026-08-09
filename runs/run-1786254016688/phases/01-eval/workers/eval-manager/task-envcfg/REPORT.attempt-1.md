# Eval-manager report: task-envcfg

Run: `run-1786254016688` phase `01-eval` (eval mode)
Manager report path: `workers/eval-manager/task-envcfg/REPORT.md`
Handbook snapshot: `lineage/handbook-approved.md` (sha256 `eba997ebd583ac6f2eb0ac48feaf701f64696fcaf72e93626fae238102b46d32`)
XSH commit under test: `e2a609a94d8f624b8dc7cc1efae62a2691d3cbc8`
Trials configured: 1 (trial 1 executed by controller)

## Result

pass

## Effort metrics

Trial 1 (worker `eval-worker/task-envcfg-1`): assistant turns 21, tool calls 26,
tool errors 2, tool results 26, thinking blocks 16, user messages 1. Session span
and candidate/oracle timing fields to be read from the worker `report.json` and
evaluator `run.json`.

## Usage and cost

Trial 1 worker: input 19321, output 7075, cache_read 248384, cache_write 0,
provider_total 274780 (bucket total 274780, consistent). Reasoning tokens 4317
(reported subset of output). Cost: input $0.00173889, output $0.0012735,
cache_read $0.004470912, total cost $0.007483302 against budget $0.5. One worker.

## Thinking evidence

Thinking blocks reported: 16. Provider-reported reasoning tokens: 4317. Full
thinking text is in the canonical session JSONL; the worker report must be read
to confirm this did not interfere with correctness. (Detailed correlation after
reading the worker report.)

## Tool-error findings

Two failed Pi tool results are recorded in the phase `tool_errors` array, both
from worker `task-envcfg-1`:
- turn 5, tool `bash`, `sh: syntax error: unexpected "("` exit 2.
- turn 13, tool `bash`, exit 1: a local comparison harness covering
  invalid/empty/leading-zero/plus/space port cases, with the candidate exiting
  nonzero via `parse-int` and `ls` confirming no output file.

These are worker `bash` probes of the candidate against the oracle during the
agent session, not `xsht` tool failures. Detailed account after reading the
worker report.

## Timing evidence

No strict candidate/oracle timing gate for this eval; both candidate and oracle
finish in milliseconds. Per-case timings in the evaluator `run.json` are
diagnostic until a stable envelope is established. Session wall span and
per-case timing to be read from worker report and `run.json`.

## Observation classification

Pending worker/manifest read. Initial signal: worker passed all cases including
the two failure controls (correctness pass, restrictions pass, protocol pass).

## Handbook decision

No handbook candidate has been justified yet from the structured packet alone.
Re-evaluation after reading worker report and evaluator `run.json`. If no
generalizable friction is found, the approved snapshot is copied unchanged to
`lineage/handbook-candidate.md`.

## Tickets created

None at first draft; to be confirmed after reviewing structured evidence.

## Post-merge decisions

No reconciled merged ticket is listed by the controller (`open_tickets: []`);
no pre-manager ticket is a merged re-evaluation; candidate re-evaluation is
`not-reevaluation`. No post-merge acceptance decision applies this cycle.

## Next replay

The next replay is a second independent manager/worker run of eval
`task-envcfg` on the same `lineage/handbook-approved.md` snapshot and XSH commit
to confirm the pass is reproducible and, if a handbook candidate is staged, to
validate that candidate.

## North-star impact

This eval closes a gap no existing eval covered: reading typed configuration
from the process environment (`env` module) with absence-only defaults, writing
a byte-exact config file, and propagating a malformed-value failure while
creating no partial file. A passing worker demonstrates the environment/config
surface is discoverable and composable, supporting the "connect processes,
files, paths, streams, JSON, and system state" north-star thesis. Detailed
qualitative impact after the worker/manifest read.
