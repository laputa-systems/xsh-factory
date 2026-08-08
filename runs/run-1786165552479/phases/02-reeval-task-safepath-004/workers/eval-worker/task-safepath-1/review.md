# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

`List` has no pop/sublist/slice operation in this image (only contains, extend, get, join, len, push), so implementing a stack-style "remove most recently added segment" for path normalization required a string accumulator and a reverse/find/byte_slice trick. A `List.pop()` (or a slice of all-but-last) would simplify this kind of navigation.
