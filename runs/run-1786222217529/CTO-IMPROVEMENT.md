# CTO factory improvement

## Status

pending-validation

The queue-pressure allocation and evidence-ownership changes were validated
in this cycle. The manager ceiling/path-following repair was applied after the
cycle and requires the next paid cycle to validate.

## Change

- `factory/control.xsh` now allocates the optional independent-eval lane from
  Open-ticket pressure while preserving a hard linked replay for every passing
  engineer row.
- `factory/controllers/organization.xsh` and `run.xsh` record and enforce the
  same adaptive decision without adding a throughput schema.
- `templates/EVAL-MANAGER-ASSIGNMENT.md` separates primary native-test evidence
  from replay-owned behavior and tells managers to follow exact manifest paths.
- `factory/control.xsh` lowers the normal eval-manager ceiling from 600 to 300
  seconds; report recovery remains bounded at 180 seconds.
- The linked `task-histogram` evaluator gained a discriminating padded-width
  case before this cycle.

## Throughput requirement

Met. One retained engineer implementation commit was delivered to XSH `HEAD`;
the cycle had no fresh engineer row because the selected approved ticket
already had an implementation branch.

## Provider-health attribution

Provider telemetry was present for the manager and worker reports and recorded
no provider errors or retry events. The first manager's long delay is therefore
classified as a harness/provider-response stall with three guessed-path read
errors, not normal evidence-review effort. The independent eval manager's
successful retry completed in six turns with no tool errors.

## Baseline metric

Cycle 30 delivered 0 of 2 admitted tickets at $0.104614 and 148 turns because
the fresh replay was non-discriminating. Evidence:
`runs/run-1786220380763/report.json` and its task-histogram-010 manager report.

## Target metric

Next cycle: preserve at least one delivered engineer commit when eligible, and
bound normal eval-manager closeout to 300 seconds plus at most one 180-second
recovery attempt.

## Validation

Run `XSH_MODULE_PATH=. xsh run.xsh templates/ORGANIZATION-REQUEST-CYCLE-32.md`
through the normal launcher. Verify the queue event contains
`independent_eval_target`, the linked replay remains mandatory, and the
manager's first attempt is bounded by the 300-second `SESSION-LIMIT`.

## Revert condition

If two consecutive healthy manager packets require more than 300 seconds for
structured closeout, restore the 600-second default only after recording the
evidence and retain the exact-path prompt fix.

## Next-cycle disposition

Replace `pending-validation` with `validated` or `reverted` after the next
cycle records the timing and delivery evidence.
