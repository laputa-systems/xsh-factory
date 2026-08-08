# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

A `map` block whose tail is a side-effecting `print` fails check with
`map requires a tail value`; the map stage needs a non-Unit (value-producing)
tail. Side-effect loops over a stream must use the dedicated `each` stage
instead. The handbook mentions binding a terminal's result but does not
explicitly call out that `map` rejects `print` as its tail, which cost a
trial-and-error cycle.
