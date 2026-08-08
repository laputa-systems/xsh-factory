# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

The integer-division operator `//` is rejected (`unsupported-integer-division`);
`/` on Int operands truncates the quotient. Supporting `//` (or documenting the
truncating `/`) would make the binning idiom explicit.

## xsht friction

A block/local variable named `group` is rejected by `xsht check` with
`name shadows the standard module 'group'`; a different identifier is required
even though the name is intuitive for `group-by` output. Also, the `Path(...)`
cast triggers a `lint` warning that prefers `fp"${...}"` interpolation.
