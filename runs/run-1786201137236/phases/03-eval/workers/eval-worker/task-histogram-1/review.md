# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

- The task prompt (and the general "integer division" wording) writes the
  truncated-quotient operator as `//`, but XSH treats `//` as a parse error and
  performs integer division with `/`. A shorter integer-division token (or at
  least an error message that points at `/`) would help avoid the trap.

## xsht friction

- `xsht api` requires the `KIND:VALUE` form (e.g. `language:core.abort`); a
  bare dotted query like `language.core.abort` is rejected as
  `expected KIND:VALUE`. The accepted and rejected spellings are easy to
  confuse since the language ids are dotted in the search output.
- In expression position `$name` is rejected ("use `name` directly"), while in
  command position a bare identifier must be written `$name`. Switching between
  the two within one statement (e.g. `let line = entry.bin ... $nr`) trips the
  parser in both directions; the error is precise but the dual syntax is a
  recurring friction.
