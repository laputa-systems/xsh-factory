# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

Mutable bindings are declared with the `var` keyword (`var x = 0`, then `x = x + 1`); `let` is immutable and `let mut x = 0` is a parse error, yet the `language:core.bindings` doc only says bindings have "declared mutability" without stating the `var` token — it had to be discovered by trial (`let mut`, `mut x`, `let var x` all fail).

An empty `Map[Str, Int]` literal cannot be written as `{}` — the parser treats `{}` as a record, so building a keyed count accumulator with a stream `fold` fails to parse; I worked around it with a `var` + `List.push` run-counting loop over a pre-sorted list. A spelled-out empty-map literal syntax/example would remove the friction.
