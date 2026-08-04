# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

On an invalid integer, `env.int(...)?` propagates with exit code 3, whereas a
conventional shell oracle uses exit code 1. Both satisfy a "must exit nonzero"
contract, but a proposal to align propagation's exit code with the common `1`
(or to let a script set an explicit exit status) would make strict exit-code
differencing with shell oracles unnecessary.

## xsht friction

`xsht check` rejects a local variable named `path` because it shadows the
standard `path` module (`standard-module-shadow`). The failure is not a syntax
error and has no self-explanatory hint; rename the variable (`out_path`) and
re-check. Additionally, `xsht api` is strict about the query form `KIND:VALUE` with a
colon: `method.Str.parse_int` (dot) and `language.core.results` (dot) are
rejected while `method:Str.parse_int` / `language:core.results` (colon) are
accepted, and a trailing-dot receiver such as `method:Result.` is rejected with
a generic "expected NAME.MEMBER" message.
