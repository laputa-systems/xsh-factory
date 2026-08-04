# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

Constructing an `Error` value is not ergonomic. `Err("msg")` yields
`Result[_, Str]` (not `Result[_, Error]`), and `Error(kind: ...)` reports
"removed; construct a declared error variant". There is no simple public
constructor, so the only reliable way to make a program exit nonzero is to
propagate an error produced naturally by a host module (e.g. `env.int` on a
malformed value). A small documented way to raise an error from a string
would simplify input-validation programs.

## xsht friction

The runtime selects a "compact" runtime for `proc main`, and it rejects a
plain argument parameter: `proc main(argv: List[Str])` fails to run with
`error: compact-unsupported-main`, while `proc main(...argv: List[Str])`
(rest/spread parameter) runs fine. This asymmetry is undocumented in the
handbook's main-procedure example and costs a failed-run cycle to discover.
