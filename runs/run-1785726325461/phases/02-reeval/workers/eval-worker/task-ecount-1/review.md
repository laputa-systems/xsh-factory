# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

- There is no direct `Str -> Path` conversion from runtime data; the only
  route is the awkward `Path.parse_bytes(bytes.from_text(s))?`. A
  `Path.parse(Str)` (or a `Path` constructor accepting a string argument)
  would be a natural, discoverable addition.
- There is also no `Int -> Str` conversion method (only `Int.float`) and no
  `max`/`min`. Formatting a numeric count with leading padding had to be done
  via `f"${n}"` interpolation plus `tui.left_pad` and a hand-rolled `if`
  width clamp. A small `Int` to-string/formatting or `max` helper would
  simplify precise-output tasks.

## xsht friction

- A stream terminal stage left as the final expression of `main` raises a
  confusing runtime error, `lowered return type mismatch`, even though
  `xsht check` passes. Binding the terminal's result with `let _ = xs |>
  each { ... }` makes `main` exit cleanly. The failure mode/exit is not
  hinted at by the checker or the error message.
- The `language:stream.fold` / `group-by` / `reduce` entries expose no
  signatures or examples and blocks accept at most one parameter, so the
  accumulator shape had to be discovered by trial and error (group-by items
  carry `.key`/`.items`). `xsht api` and `xsht check` give no guidance for
  these reduction shapes.
