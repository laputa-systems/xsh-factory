# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

The stream-stage call syntax was not obvious from the `api` signature. `api
language:stream.sort-by` shows `sort-by(--desc: Bool = false, block)`, which
reads like an ordinary call, but `sort-by(--desc) { |e| e.size }` is rejected
("stream stage does not accept call arguments") and
`sort-by(--desc, { |e| e.size })` fails to parse (the paren-wrapped block is
misparsed). The accepted form is the flag-then-block command spelling
`|> sort-by --desc { |e| e.size }`. A short worked example in the API doc of a
stage with a named flag plus a key block would save the trial-and-error needed
to discover it.
