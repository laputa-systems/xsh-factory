# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

Catching an `ini` module decode/lookup failure cleanly requires deliberate use: `ini.read` and `Record.get` return `Result`, so propagating with `?` exits nonzero and writes a traceback to **stderr** while keeping stdout empty (exit 3). That satisfies the task but is an implicit contract; there is no way to fail silently/quietly, and `print` rejects a `Record`/`Any` directly (`value cannot be displayed by print`), forcing explicit `Record.get` access. Also, naming a variable `path` is rejected by `check` as shadowing the standard `path` module, and the `Path(...)` cast draws a `lint` warning preferring `fp"..."`; both surfaced in this task's normal loop.
