# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

A nested `if` used as a statement (or as the direct tail-expression of a branch) inside a `fold { |acc, item| ... }` block fails the indexed IR build with `full_ir_function_blocker` (check exit 2), even though the same nested `if` type-checks fine in a normal `proc` body. Workaround: hoist the nested conditional into a `let` binding (e.g. `let popped = if ... { } else { }`) so the block's tail is only a plain value/record; that form compiles cleanly. This is surprising because `if`-as-expression and assignment-form `if` are both valid language constructs but behave differently inside a fold block.
