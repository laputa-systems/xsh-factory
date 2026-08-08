# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

`Str.parse_int()` is documented as the typed-conversion path for rejecting
invalid input, but it is permissive: it accepts `0x10`, `1_000`, `+7`, and
leading spaces as integers. A task requiring a strict *decimal* integer
(e.g. rejecting `0x10`) cannot rely on `parse_int()` alone to exit nonzero;
it must first validate the digits (e.g. `s.delete("0123456789")`) and use
`abort(1)` for the reject path. The handbook's guidance that a failed typed
conversion always produces the nonzero exit does not hold for non-decimal
numeric strings, so callers should be told how permissive `parse_int` is.
