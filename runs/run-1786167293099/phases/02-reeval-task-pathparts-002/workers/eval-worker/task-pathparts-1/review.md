## XSH language proposals

None.

## xsht friction

`xsht lint` reports `unused-local` for a local variable referenced only inside
a display-string (`f"..."`) interpolation. In this image, reading a binding
through `f"dir=$dir"` is not counted as a use, so every such binding is
flagged unused and lint exits nonzero. The workaround is to build the string
in expression position with `+` (`let ld = "dir=" + dir`) and print the
result, which lint accepts. This makes the lint-preferred display-string form
unusable for output that must reuse a local value.
