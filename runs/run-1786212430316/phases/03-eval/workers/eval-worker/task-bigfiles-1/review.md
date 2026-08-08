# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

`Str.parse_int()` is not a purely decimal parser: it also accepts hex (`0x10`), a leading `+`/`-`, surrounding whitespace, and leading zeros. For a contract that requires strict decimal-digit input, there is no decimal-only parse primitive and no generic `Error(...)` constructor, so the program must separately run a digit-only check (the `delete("0123456789") == ""` idiom) and force a failure by feeding a provably-invalid string to `parse_int()?`. A strict `parse_int_decimal()` (or an explicit `radix:` parameter) would make these validations expressible without the force-invalid-string hack.

## xsht friction

A call expression cannot appear directly in `print` arguments: `print $argv[1].parse_int()` fails with `parse.command-call-expr` and requires binding the value to a `let` first. Minor, but easy to trip over when debugging numeric argument parsing.
