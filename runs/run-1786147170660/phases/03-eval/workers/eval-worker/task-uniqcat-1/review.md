# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

Boolean negation is only expressible with the prefix `!` operator; the natural
`not` keyword is a parse error (`expected expression`). The handbook does not
document either form under core language. Consider supporting `not` as an
alias or documenting the `!` operator so negation does not require
trial-and-error (`xsht api search:negation` returns nothing).

## xsht friction

`xsht check` accepts a bare identifier in `print` (e.g. `print ln`) but `xsht
lint` flags it as `check.bare-print-ident`, so a script can satisfy the
checker yet still fail lint until rewritten with `$ln`. The gap between
`check` and `lint` acceptance for print interpolation is easy to miss.
