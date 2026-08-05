# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

The `sort-by` named option `--desc` must be written before the projection block (`sort-by --desc { |e| ... }`). Putting it after the block (`sort-by { |e| ... } --desc`) is rejected as an unresolved name, producing a generic `check.unresolved-name` rather than a helpful message about flag placement. The API signature lists it as `sort-by(block, --desc: Bool = false)` without indicating that flags precede the block argument.
