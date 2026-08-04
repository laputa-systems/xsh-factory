# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

The documented `fail(message)` construct (`xsht api language:core.fail`) is
not callable in the installed build, and neither is any generic error
constructor or panic/abort. `env.int` and `Str.parse_int` are convenience
readers, not strict decimal validators: both accept `+5`, `-3`, and `" 5"`
(round-tripping to an Int), so they cannot express rejection of byte-exact
non-decimal ports. For this task I had to validate the raw string characters
with `Str.delete` and then force a guaranteed failure by parsing a sentinel
malformed literal, because a true strict-unsigned-decimal typed reader (e.g.
`parse_uint`) or a working `fail`/`panic` is missing. Propose exposing a real
`fail(message)`/validation construct or a strict unsigned decimal parser.

## xsht friction

`xsht api language:core.fail` advertises a callable `fail(message: Str) ->
Result[Unit, Error]`, but both `xsht check` and `xsh` reject
`fail("boom")?` and the command form `fail "boom"?` with
"unresolved pure function call" / "unresolved proc command". The live
reference and the runtime disagree on whether this construct exists, and there
is no other documented way to raise a deliberate validation failure.
