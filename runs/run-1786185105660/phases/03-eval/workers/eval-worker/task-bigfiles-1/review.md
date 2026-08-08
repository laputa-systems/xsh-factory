# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

`Str.parse_int()` auto-detects non-decimal prefixes (observed: `0x10` parses
to 16) and accepts no radix argument, so there is no strict-decimal parse.
A task that rejects any non-decimal integer (e.g. `0x10`) cannot express this
with a single typed conversion and must hand-roll digit validation. A
radix/decimal-strict parameter on `parse_int` would cover this cleanly.

There is no generic `Error(...)` constructor, which forced a deliberate
validation failure to be simulated by appending a junk character
(`(tok + "x").parse_int()?`) so the typed `?` could produce the nonzero exit.
A first-class error/abort would be less error-prone.

## xsht friction

`xsht api summary | grep method:Str` returned nothing because method receivers
are aggregated (e.g. `Str (28 items)`), so enumerating the member list of a
type required guessing exact method names. A `type:Str` or
`module:type.Str` selector would make method discovery faster. (Worked around
by probing candidate names with `xsht api method:Str.<name>`.)
