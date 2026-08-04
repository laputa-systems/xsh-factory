# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

`xsht api language:stream.group-by` and the summary entry document only
"Groups stream items by a projected key" without describing the emitted
value's shape, so the returned record's fields (`.key`, `.items`) had to be
discovered empirically by printing `k.keys()`. Documenting the produced record
type (alongside the existing `sort-by`/`fold` contracts) would remove the
guesswork. Relatedly, `xsht api method:Str` (a bare receiver) is rejected as
"expected NAME.MEMBER", so listing all methods of a receiver requires the
`xsht api summary` index instead of a targeted query.
