# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

N/A (see friction for a related gap).

## xsht friction

There is no way to raise a deliberate validation error for an arbitrary predicate. The build has no generic `Error(...)` constructor, so the only documented path is to force a typed-conversion failure. That does not generalize: `Str.parse_int_decimal` is stricter than the task's oracle (it rejects leading zeros such as `09001` that the oracle accepts), so I had to implement the oracle's digit check manually and only call `parse_int_decimal()` inside the already-rejected branch to produce the nonzero exit. A primitive to fail with a message (equivalent to `exit 1`) would make matching custom predicates straightforward.
