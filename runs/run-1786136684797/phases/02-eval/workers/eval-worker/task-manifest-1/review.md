# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

`Path.relative_to` is unsafe as a general "strip prefix" primitive: when the
base path is relative (e.g. `Path("t")`) while the receiver is an absolute
resolved path (the form `fs.files`/`fs.walk` yield), it silently returned the
receiver unchanged instead of returning an error as its contract describes.
Discovering this required first calling `Path.resolve` on the base so both
sides share a canonical prefix. A proposal would be to make relative_to reject
or clearly normalize mismatched base forms.

## xsht friction

`xsht fmt -w SCRIPT` is rejected with `unknown 'xsht fmt' option '-w'`; there
is no in-place flag and `xsht fmt` appears to edit the file while also
printing the result. Invoking it with a non-`-w` argument to format is
therefore implied but undocumented, which is surprising. A clear
`--write`/`--check` contract would help.
