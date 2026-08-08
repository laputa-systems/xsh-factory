# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

- `abort` is not treated as a non-returning (bottom) expression: a proc that must return `Int` but `abort(1)`s on the invalid branch hits `check.type-mismatch: expected Int, found Unit`. A proc whose only non-returning paths end in `abort` should satisfy the return-type check.
- There is no boolean `not` operator (`if not cond` is a parse error), which forced inverting the validation logic into else-branches.
- An empty if-branch body cannot be written with a `()` unit literal (`() is` a parse error); a throwaway `let _ = 0` was required as a no-op.

## xsht friction

- An unchecked proc called from an effect-declared proc requires an explicit empty effect list `[]`; forgetting it produces `check.effect-violation`, and `[]` is needed even when the body only uses `abort` (declared effects: none).
- No boolean negation meant conditions like `if not int_re.matches(...)` had to be restructured, making the validation branch awkward instead of a direct guard-then-proceed form.
