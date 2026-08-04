# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

- There is no general way to construct an `Error` value or force a deliberate
  nonzero exit from a validation condition. `Error(...)` was removed and
  variant constructors (e.g. `FsError.NotFound`) are not resolved/documented in
  this image (confirmed via `xsht check` and `xsht api summary`, which lists
  no `FsError`/`EnvError` records). The handbook's suggested route is to
  propagate an expected failure from a host operation, so a guard that rejects
  an invalid `CFG_PORT` had to trigger a forced failure via
  `fs.write(p"", "")?`. A dedicated `assert(condition)` / typed validation
  guard that yields a nonzero exit would be clearer.
- `env.int` is not a strict format validator: it accepts `"+5"`, `"-5"`, and
  `"007"` (converting to 7), so a byte-exact "decimal integer" contract had to
  be re-validated manually with `Str.delete`. `env.bool`/`env.int` docs say
  they are convenience readers, but it would help if the docs explicitly
  warned that they are not strict for oracle-style byte contracts.
