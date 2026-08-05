# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

`match` is a reserved keyword, so it cannot be used as a value/binding name. Using `let match = ...` produced a cryptic `expected binding name` parse error with several cascading errors pointing at the following pipeline lines rather than at the keyword. A clearer diagnostic ("`match` is a reserved word") or relaxing the reservation for plain identifiers would save debug time.

## xsht friction

A `collect()` terminal cannot be followed by `fold()` in the same `|>` pipeline (`stream stages cannot follow a terminal stage`). I had to split the materialized list into a separate statement (`let vals = ... |> collect()` then `let total = vals |> fold(0) {...}`). The compiler pointed at the fold stage but did not suggest the fix; a hint that the value must be bound first would help.
