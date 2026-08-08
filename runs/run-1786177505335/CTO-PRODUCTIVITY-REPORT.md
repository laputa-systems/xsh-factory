# CTO productivity report

## Result

fail

## Engineer-commit gate

One fresh engineer implementation commit was reviewable (`704b054` for
`task-histogram-004`), and one retained implementation commit was also
reviewable (`f697fa2` for `task-pathparts-003`). Zero were delivered because
both linked replay phases failed their infrastructure gates. This is a
throughput failure: the cycle had eligible product work and delivered no
engineer commit.

## Comparison with prior cycle

The prior cycle delivered one engineer commit at $0.172625 and 144 turns.
This cycle admitted two tickets, produced one fresh engineer row plus one
retained fast path, completed the primary product/eval phases, and spent
$0.187124 across 178 turns and 8 workers. Product and evaluator outcomes were
`pass`; infrastructure was `fail`. Reviewable work increased, but delivered
throughput regressed from one commit to zero.

## Efficiency judgment

Throughput regressed at the delivery boundary. The product work itself was
good: `task-histogram-004` produced commit `704b054`, and the retained
`task-pathparts-003` commit `f697fa2` passed its fresh trial. This was not an
eval-only cycle; replay/merge blocked otherwise acceptable engineer output.

## Assembly-line bottleneck

The constrained stage was replay/merge. The histogram and pathparts manager
sessions were both killed by the 1,200-second wall watcher, and the pathparts
manager also exited without a candidate lineage file despite a valid report.
The next controller revision pre-stages the approved handbook as the candidate,
changes eval-manager thinking to `medium`, lowers its turn ceiling to 24, and
raises its wall ceiling to 1,800 seconds. The next target is at least one
delivered commit with every linked replay reporting `manager_report=true`,
`candidate_handbook=true`, and `handbook_lineage=true`.

## Evidence

See [`report.json`](report.json), the linked replay reports under
`phases/02-reeval-task-*/report.json`, the engineer reports under
`phases/01-ticket/workers/engineer/`, commits `704b054` and `f697fa2`, the
prior run's productivity report, and [`CTO-IMPROVEMENT.md`](CTO-IMPROVEMENT.md).

## Corrective action

The factory change is implemented in `factory/control.xsh`,
`factory/controllers/eval.xsh`, and the eval-manager prompt/role files. Native
coverage now includes a fixture where the manager does not copy the candidate;
the controller's fail-safe staging must still make the phase pass. The next
cycle must deliver at least one commit; otherwise the manager path remains the
active bottleneck and its assignment must be shortened further.

## Next-cycle target

Required next-cycle metric: `delivered_tickets >= 1` with no linked replay
required-output failures. A pass moves the bottleneck back to product queue
pressure; a fail keeps delivery/replay as the repair target.
