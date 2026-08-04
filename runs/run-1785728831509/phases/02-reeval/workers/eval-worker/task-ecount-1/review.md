# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

- Stream stage blocks are restricted to at most one parameter
  ("stream stage blocks accept at most one parameter"), which makes the
  fold/reduce accumulator+item form unusable and forces roundabout
  group-by/count idioms. A two-parameter accumulator block (or a documented
  closed-over accumulator) would make counting/aggregation natural.
- A procedure whose body ends in a pipeline terminal such as `each { ... }`
  fails at runtime with "lowered return type mismatch" because the trailing
  expression value must match the implicit `Unit` return. The result has to be
  discarded with `let _ = <pipeline>`; this is easy to trip on and only fails
  at runtime, not at check time.

## xsht friction

- `xsht api` reports `fold`/`reduce`/`group-by` with empty signatures and a
  null example, so the exact block/argument syntax had to be discovered by
  trial and error (e.g. `fold(init) { |x| ... }` and `|> each { |x| ... }`).
  A small worked example for each stream stage would prevent guesswork.
- The `return type mismatch` from a trailing `each` pipeline is a runtime
  error, not a check-time diagnostic, so a form that will always fail at
  runtime passes `xsht check` cleanly.
