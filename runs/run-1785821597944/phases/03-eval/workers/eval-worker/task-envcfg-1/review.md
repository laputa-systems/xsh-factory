# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

A general way to raise a deliberate, expected validation failure would be useful. This build has no generic `Error(...)` constructor, and the only sanctioned error source is a typed conversion failure, which forced me to detect an invalid port via manual digit checks and then trigger a guaranteed `"x".parse_int()?` failure to get a nonzero exit without creating the output file.

## xsht friction

The handbook warns that `env.int`/`env.bool` are not strict validators, and this task confirmed it: `env.int` accepts `"+5"` and `" 5"`, and `Str.parse_int` even accepts `"0x10"`, `"-3"`, and `" 5"`, all of which the task oracle rejects. A byte-exact decimal check had to be written manually (`port.delete("0123456789") != ""` plus a non-empty test) rather than relying on any typed conversion.
