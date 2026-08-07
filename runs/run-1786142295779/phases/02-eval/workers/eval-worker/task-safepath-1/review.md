# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

There is no clean way to terminate a program with a nonzero exit status.
Forcing a nonzero exit from `safepath.xsh` requires propagating a deliberately
failing typed conversion (e.g. `"invalid".parse_int()?`), which additionally
dumps a runtime traceback to stderr. A dedicated explicit "exit with code"
primitive (or an `Error(...)` constructor that exits without a traceback)
would be more appropriate for validation-failure exits.

Record values are constructed only with the plain brace literal
`{name: value}`; the typed-constructor form `TypeName{...}` used in the
handbook-style record example is a parse error.

## xsht friction

`xsht lint` reports an "unused type declaration" warning for a `type Acc =
{stack: List[Str], escaped: Bool}` declaration when records are created with
the plain `{...}` literal, even though those literals structurally match the
type. The declaration must be removed (or referenced by name) to get a clean
lint pass.

`List` offers no pop/drop method for removing the last element; removing the
most recently pushed segment requires the slice form `stack[..stack.len() - 1]`,
which is undocumented in the List method summary.
