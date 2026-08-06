# XSH agent handbook — provisional candidate (run-1785971528057 / 03-eval, task-histogram trial 1)

This is a run-lineage candidate diff against the approved snapshot
`lineage/handbook-approved.md`. It is NOT yet promoted. It becomes trusted only
after replay and CTO review.

## Candidate lesson: number arithmetic and boolean negation

Add a short "Numbers and arithmetic" note (near "Bind values with let" /
"Streams and collections") and extend the boolean guidance:

- Integer division on `Int` is written with `/` and truncates toward zero
  (`40 / 3 == 13`); `%` is modulo. `//` is NOT a valid operator — the parser
  rejects it with an `expected statement terminator` error, and `#` is the
  comment marker. When a task spec writes `v // WIDTH` to mean integer
  division, write `v / width` on `Int` operands.
- There is no `not` keyword. Write a boolean negation as `expr == false`
  (e.g. `if re.matches(t) == false { ... }`).

## Why

In trial 1 the worker read `v // WIDTH` in the task and the `//`-as-comment
warning in the handbook, then spent several probe rounds discovering that the
actual operator is `/`, and separately discovered that `not` is invalid and
`== false` is the usable negation. These are repeated discovery frictions at a
language-surface boundary; naming the two operators up front removes the
probe chain without encouraging a task-specific trick.

## Replay scope

Any future eval that does scalar arithmetic or boolean validation:
`task-histogram`, `task-colsum`, `task-groupsum`, `task-total`, `task-envcfg`
(width/port checks), and similar. Replay should verify the agent reaches a
correct solution without probing `/` vs `//` or `not` vs `== false`.
