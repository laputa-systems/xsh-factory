# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

`fs.files`/`fs.walk` are documented with a `Result[Stream[...], Error]` signature, but calling them yields a live Stream (the `Result` is already unwrapped). Applying `?` to the call and then piping the result into a stream stage (`fs.files(root)? |> collect()`) crashes the IR builder with the cryptic `compact.indexed-build: indexed IR could not encode full_ir_function_blocker` at check time; dropping the `?` compiles and runs fine. The signature/behavior mismatch plus the opaque error cost several iterations to isolate.
