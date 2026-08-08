# Factory cycle postmortem

## Result

The factory stopped at organization admission before any paid worker ran.

## Budget

- Run: `runs/run-1786200240647`
- Hard cap: `$1.00`
- Observed spend: `$0.00`
- Controller PID: recorded in `processes/controller.pids`

## Shutdown

- Reason: the API-surface gate required the literal `semantic` marker even
  though the approved ticket supplied a concrete `capability` claim and
  evidence.
- Cleanup: no product worktree or worker process was created; inventory and
  budget evidence were preserved.

## Follow-up

The validator now accepts the two equivalent domain terms under the same
existing/evidence guard. A new cycle request is required.
