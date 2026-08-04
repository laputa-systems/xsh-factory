## XSH language proposals

- Path literals (`p"..."`) do not interpolate `${expr}`; the braces are treated as literal filename text (writing `p"${argv.get(0)}"` created a file literally named `${argv.get(0)}`). Dynamic paths must go through `Path.parse_bytes(bytes.from_text(s))`.
- There is no clean, documented way to construct a generic `Error` value for an explicit nonzero abort. Generic constructors (`RuntimeError`, `ValueError`, `ThreadError`, etc.) are unresolved names, and plain `Err("...")` does not type-check against `Result[Unit, Error]`. I worked around it by triggering a deterministic runtime failure (`regex.compile("[")?`), which is not semantically meaningful.

## xsht friction

- `env.int` uses a loose parse: it accepts `"-5"` and `" 5"` as valid integers even though a strict decimal-integer check (the task oracle's `*[!0-9]*` pattern) rejects them. It therefore cannot be used for exact port validation; a regex `^[0-9]+$` check on the raw value was required. This gap between `env.int` and a strict integer definition is easy to miss.
