# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

- `let mut x = ...` is a parse error; the runtime's true mutable-binding
  keyword is `var x = ...` (reassignment via `x = ...` works). The handbook
  only demonstrates immutable `let`, so mutation syntax had to be discovered
  by trial.
- `Int` has no direct to-string or width-formatted method (`Int.display`,
  `Int.format` are rejected; only `Int.float()` exists). Numeric text relies
  on display-string interpolation `f"${n}"`, and fixed-width padding must be
  hand-built from `range |> map |> collect |> join`.
- There is no `List.sort`; sorting requires moving items into a stream and
  using the `sort`/`sort-by` stream stage. For a plain value list this extra
  round-trip is easy to miss from the summary (only stream sorting is listed).
