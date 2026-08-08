# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

`print` emits a space between each command-word argument, so `print "dir=" $value`
produces `dir= /srv/app` rather than `dir=/srv/app`. The natural fix
`print "ext=" + ext` is rejected by check (`bare-print-ident`) even though the
`+` is in expression position, and the handbook's "build concatenated text in
expression position and then print the value" advice can be misread as
permitting this. The reliable pattern is computing the whole line first (an
f-string literal or a `let`), then printing that single value.
