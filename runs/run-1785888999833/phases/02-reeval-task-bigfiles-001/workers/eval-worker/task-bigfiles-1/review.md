# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

- There is no strict decimal-integer conversion and no generic `Error`
  constructor. `Str.parse_int()` is lenient: it silently accepts `0x10`,
  `+5`, `1_000`, surrounding whitespace, and a leading sign, while rejecting
  `abc`/`5.5`. A rigid "must be a decimal integer" contract therefore needs a
  `regex.compile("^[0-9]+$")` match plus forcing a genuine typed-conversion
  failure (`"".parse_int()?`) for the invalid branch. A `Str.to_decimal_int`
  that validates digits-only would make this contract primitive.

## xsht friction

- The `language:stream.sort-by` signature renders as `sort-by(--desc: Bool =
  false, block)`, but the parenthesized call form `sort-by(--desc: true) { ... }`
  is a parse error. Only the command-word form `sort-by --desc=true { ... }`
  works. Flag-option syntax for stream stages should be documented with a
  working example rather than a misleading signature.
- Boolean negation in a condition must be written `if !expr`; `if not expr`
  is a parse error. `not` is not documented as a keyword, and the handbook's
  boolean examples don't cover negation.
