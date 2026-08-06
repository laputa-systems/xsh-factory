# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

There is no strict "digits-only" integer conversion, and no generic way to
raise an expected validation failure except through a typed conversion. To
reject inputs that a permissive `parse_int` accepts (`"+5"`, `"-5"`) or to
reject a non-positive width (`width <= 0`), the only available mechanism was
to route the invalid branch through a deliberately-failing parse (e.g.
`let _ = "".parse_int()?`). A small `ensure(predicate)`/`check` primitive that
produces an expected failure, or a `parse_int` variant that accepts only
ASCII digits (no sign), would express this validation directly instead of
abusing an unrelated parse failure.

## xsht friction

`xsht check` rejects binding the name `group` anywhere it is in scope because
it shadows the standard `group` module; even a short-lived lambda parameter
`|group|` in a `sort-by`/`fold` block triggered
`err[check.standard-module-shadow]` and forced a rename to `grp`. The shadow
check is not scoped to the actual shadowing use.

`xsht lint` flags `Path(expr)` (used as the documented `Path(str)` cast) and
insists on `fp"${...}"` interpolation even when the argument is already a
runtime `Str`; this is an opinionated preference promoted to a lint warning.
