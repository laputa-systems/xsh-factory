# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

There is no documented, working way to construct or raise a generic builtin
`Error` in a value-returning proc. `Error(...)` is removed ("construct a
declared error variant such as FsError.NotFound(...)"), but the suggested
stdlib variants either fail the indexed-IR builder (`fs.FsError.NotFound("x")`
→ "indexed IR could not encode `full_ir_function_blocker`") or run as a
dynamic-call runtime error (`env.EnvError.Conversion("oops")` → "dynamic call
expected Pure or Proc, found Result"). To exit nonzero on validation failure I
had to propagate an unrelated `"x".parse_int()` error, which works but is an
indirect hack. A first-class `raise`/error-construction mechanism (or
documented stdlib error constructor) would make this straightforward. Result
has no `.map`/`.chain`, so coercing `Result[Int, Error]` to `Result[Str,
Error]` requires re-fabricating an `Err` from a bound error via an extra proc.

## xsht friction

- A meaningful parser/`fmt` inconsistency: `if/else` used inside a `match` arm
  is only parsed as an expression when wrapped in parentheses, but `xsht fmt`
  canonicalizes by removing those parentheses, producing a file that no longer
  type-checks. Formatting should not invalidate a valid program.
- Statement/expression ambiguity: an `if/else` at the end of a proc body, and
  one in a `match` arm, is treated as a statement (branches reported as
  "ignored Result", plus "missing-return"), so `return if ...` and extra
  helper procs are required. This is easy to trip over and the handbook does
  not document the rule.
