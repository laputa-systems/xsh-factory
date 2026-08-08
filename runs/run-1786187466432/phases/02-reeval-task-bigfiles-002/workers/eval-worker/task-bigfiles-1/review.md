# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

- There is no generic `Error(...)` constructor for deliberate validation
  failure. `Str.parse_int()` accepts non-decimal spellings such as `"+5"`,
  `"-3"`, and `"0x10"`, so rejecting a strict decimal-integer count had to be
  forced through a contrived always-failing parse (`(s + "x").parse_int()?`).
  A first-class error/validation facility would make the intent clear.
- `if`/`else` used as an expression cannot have branches containing
  statements; `let` bindings inside a branch (e.g. `let s = argv[1]`) failed
  to parse as an expression. The temporary had to be hoisted into a separate
  helper proc.

## xsht friction

None.
