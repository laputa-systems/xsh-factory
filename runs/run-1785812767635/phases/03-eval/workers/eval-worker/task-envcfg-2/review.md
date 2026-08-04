# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

There is no generic `Error(...)` constructor and no `fail()`/`abort()`
builtin, so the only way to exit nonzero after an explicit manual validation
is to trigger an unrelated typed-conversion failure. In this task I validated
`CFG_PORT` by hand (empty or contains non-digit) and then forced a nonzero
exit with a throwaway `"not-a-port".parse_int()?`. A first-class way to
construct or raise a deliberate error (or an explicit `env`/`Str`
validator with a strict decimal contract) would express the rejected input
directly instead of via a sentinel parse.

## xsht friction

XSH boolean operators are the word forms `or`/`and`; the symbolic `||` (and,
presumably, `&&`/`!`) are parse errors even though both styles appear in
docs/examples. Also `xsht fmt` rewrites an explicit single-line f-string into
a multi-line triple-quoted block layout, which surprised me mid-edit; the
file I intended to write one way was silently reformatted, so I had to check
the output text was still byte-exact.
