# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

The handbook directs deliberate validation failures through typed conversions (e.g. `parse_int?`), but the pinned build has no generic `Error(...)` constructor, so a custom rejection that a typed conversion would accept is awkward to signal. `Str.parse_int` accepts non-decimal spellings (`"0x10"` -> 16, `"-3"`, `"007"`), so enforcing a strict decimal contract required an incidental host failure (`[0].get(1)?`, index-out-of-bounds) to exit nonzero. A first-class failure/validation primitive (or a strict decimal parse) would make this cleaner.

## xsht friction

Small grammar gotchas from this session: boolean `&&`/`||` are unsupported (must be `and`/`or`, and check/lint fail hard otherwise); `xsht lint` flags `Path(...)` in favor of `fp"..."`, flags `.display()` on a Path as redundant in command arguments, and warns (exit 1, though check passes) on these style points. `Result` exposes only `.context`, with no `.unwrap`/panic escape hatch. All resolved by following the lint suggestions.
