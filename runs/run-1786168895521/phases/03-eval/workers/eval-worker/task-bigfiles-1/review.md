# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

- `method:Str.parse_int` accepts more than strict decimal input: it returns Ok
  for hex (`0x1A`) and for leading-whitespace (`" 7"`) forms. When a task
  contract demands an exact "decimal integer", `parse_int` alone is
  insufficient; I validated with a manual digit check
  (`s.delete("+-").delete("0123456789") == ""`). A strict,
  radix-constrained integer parser (or an explicit option) would be a clearer
  primitive.

## xsht friction

- There is no `not` boolean keyword in this build; negating a Bool required
  `... == false`. A `not`/`!` operator would be more readable.
