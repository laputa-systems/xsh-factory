# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

The typed integer readers are not byte-exact decimal validators. `env.int`
and `Str.parse_int` both accept `+10`, `-5`, `08080`, and surrounding
whitespace, and gain them as valid integers, whereas several task contracts
(e.g. a strict `*[!0-9]*` port check) reject signs, plus signs, and
whitespace. The handbook notes this but it is important enough to restate:
byte-exact digit/boolean checks must be done explicitly (here with
`Str.delete("0123456789")`) rather than trusting `env.int`/`parse_int`.

There is no general-way to raise a deliberate validation failure. `Err("...")`
builds only a `Result[_, Str]`, which cannot be propagated through the `error`
effect (which carries `Error`), so it cannot coexist with `?` over `env`/`fs`
results. A workable idiom is to run a typed conversion on a value derived from
the rejected input (e.g. `port.delete(digits).parse_int()?`), which always
errors exactly for strict-invalid inputs and also handles the strict
edge-cases (negative, `+`, `.`) that the reader itself would accept.

`Ok(())` does not parse as an expression in this build; returning a `Unit`
from a `Result`-returning procedure needs a concrete payload.

## xsht friction

`xsht lint` emits a `lint.path-constructor` warning for `Path(str)` and
recommends `fp"${...}"`; using the interpolated path string is required to get
lint to pass.

`xsht fmt` reflows a single-line `fs.write(path, text)?` call into a
multi-line form with a `f"""..."""` block string. The reflowed output is
semantically identical, but it changes the source layout substantially, so run
`xsht fmt` (and re-`check`) before finalizing.

BusyBox `printf` does not support the `%q` format specifier, which makes
shell-side golden-file comparison awkward in this environment.
