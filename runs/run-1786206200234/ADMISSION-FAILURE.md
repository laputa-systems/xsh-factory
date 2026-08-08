# Cycle 24 admission failure

This run was created by the canonical organization controller but stopped
before any paid worker dispatch. The selected `task-grep-001` ticket contained
the manager-authored source value:

`task-grep (evals/task-grep/EVAL.md, Approved)`

The ticket parser treated the whole annotated value as an eval ID and rejected
it as unsupported. No engineer, evaluator, manager, or director session ran;
there is no cycle-level product result to count.

The CTO repaired `factory/control.xsh::ticket_eval` to extract the first
canonical token and added an annotated-ticket regression test. The request is
relaunchable after the repair commit.
