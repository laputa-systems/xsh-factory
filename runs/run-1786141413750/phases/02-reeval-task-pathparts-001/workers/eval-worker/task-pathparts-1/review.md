# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

- `print` joins multiple command arguments with a space, so emitting an
  exact-layout line (`dir=/srv/app`) requires pre-concatenating the text into
  one string (e.g. `let d = "dir=" + p.dirname().display()`) rather than
  passing `"dir="` and the value as separate arguments. This was only
  discoverable by testing; the handbook shows `print "count" $count` without
  clarifying the separator.
- A `let path = ...` binding is rejected by `xsht check` because it shadows
  the standard `path` module; the error message was clear but the fix (using a
  different identifier) is easy to miss without reading the lint output.
