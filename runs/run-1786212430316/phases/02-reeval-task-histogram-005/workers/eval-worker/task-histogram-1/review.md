# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

There is no generic way to fail on a boolean predicate. To reject a non-positive
width (which `Str.parse_uint` accepts as `0`) there is no `fail()`/`Error(...)`
construct and no checked positive-integer conversion, so the only runtime
failure available is forced integer division by zero, which aborts via SIGFPE
(exit 133) rather than a clean typed error. A deliberate validation helper
(such as `Str.parse_uint_positive()` or an explicit `fail(message)`) would make
the positive-width rejection deterministic and idiomatic instead of relying on
a divide-by-zero side effect.

## xsht friction

Binding a variable named `path` is rejected at check time with
`check.standard-module-shadow` because it shadows the standard `path` module;
the diagnostic is clear but the naming collision is easy to trip over when
storing a filesystem Path value.
