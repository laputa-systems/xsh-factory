# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

- Stream-stage blocks containing a `let` fail to compile with `indexed IR could
  not encode full_ir_function_blocker` (e.g. `range(0,n) |> all { |i| let b =
  s.byte_at(i,-1); b >= 48 }`). Only single-expression closures are encoded,
  which forced re-evaluating the method call and made tight digit validation
  verbose. Allowing local bindings in stream closures would be cleaner.
- There is no discoverable way to construct a generic `Error` value: the
  `Error(kind: ...)` constructor reports it "was removed", and documented
  variants like `FsError.NotFound(...)` were unresolved in a plain script.
  Combined with the lack of an explicit nonzero-exit builtin, the only reliable
  way to abort was propagating a deliberately forced `parse_int` error.

## xsht friction

- `module.env.int` is more permissive than a strict decimal-integer check: it
  accepts `-1`, `+1`, and a leading space, which do not match the task oracle's
  `*[!0-9]*` rejection. I had to implement my own digit check rather than trust
  the typed integer API for the acceptance boundary.
