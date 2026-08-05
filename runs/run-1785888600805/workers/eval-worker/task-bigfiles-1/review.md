## XSH language proposals

None.

## xsht friction

`Str.parse_int()` is lenient: it accepts hexadecimal (`0x10`), leading/trailing
whitespace, and signs, while the task required a strict decimal integer. There
was no direct way to force a nonzero exit on a rejected value; the working
approach was to validate the string with `delete("0123456789")` and then
deliberately feed a guaranteed-non-integer (`"x" + n`) to `parse_int()?` to
produce the failure. This is a workaround the language could make clearer.

Stream named flags (e.g. `sort-by --desc`) did not accept clear pipeline
syntax; `sort-by { |e| 0 - e.size }` was used to sort descending.
