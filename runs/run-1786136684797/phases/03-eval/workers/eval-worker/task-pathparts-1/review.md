# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

`Path.ext()` cannot distinguish "no extension" from an empty trailing-dot
extension: it returns `""` for `.profile` (oracle: `none`), `plain` (oracle:
`none`), and `file.` (oracle: empty ext) alike. Likewise `Path.name()` returns
`""` for `.`, `..`, and `/` while the shell `basename` yields `.`, `..`, and
`/`, and `Path.parent()` normalizes `a/.` to `.` where `dirname` yields `a`.
A useful proposal is for `Path` to offer exact `dirname`/`basename` semantics
and a tri-state/Result extension (none vs. empty vs. value), so callers do not
have to reimplement this shell logic over the raw string.

## xsht friction

Naming a binding `path` shadows the standard `path` module, and `xsht check`
reported `unknown module API` on `path.name()` / `path.parent()` with no hint
that this was the shadowing; only a separate `standard-module-shadow` error
revealed the cause. Also, `print $ident` requires the `$` dereference because
bare identifiers in print are rejected as ambiguous — the error message points
to the fix, so this is minor.
