# Task review

## XSH language proposals

`group-by` is documented as returning a lazy `Stream[{key, items}]`, but the
type checker rejects any further stream stage after it (`stream stages cannot
follow a terminal stage`). A grouping terminal that also returns a usable
stream cannot be composed inline, so the stream had to be `collect()`ed into a
List before applying `sort-by`. Considering whether a terminal `group-by`
should be chainable (or be renamed/document trimmed) would remove a surprising
composability gap.

There is no evident direct `Int -> Str` conversion or `printf`/`%d` formatting
helper in the pinned stdlib; formatting a right-aligned count required
`tui.left_pad(f"${count}", w)`. A small dedicated integer/`%d` formatting
primitive would make exact-padding output tasks less indirect.

## xsht friction

None.
