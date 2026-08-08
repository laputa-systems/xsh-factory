## XSH language proposals

- `Path.name()` and the `basename` oracle diverge for root-like paths:
  `Path.name()` of `/`, `.`, and `..` returns the empty string, while POSIX
  `basename` returns `/`, `.`, and `..` respectively (verified via
  `Path.name()`). A `Path.name_or`-style or a documented "return the spelling
  for root-like inputs" method would remove the need for a special case.
- `Path.ext()` returns empty both for a no-dot name and for a trailing-dot
  name (`file.`), so an "empty means no extension" mapping cannot distinguish
  the oracle's `ext=` (trailing dot) from `ext=none` (no dot). The Str API has
  no `rfind`/`substring`, so extracting text after the *final* dot requires
  awkward split/leading-dot tests.

## xsht friction

- Naming a local `path` triggers `check.standard-module-shadow` plus
  confusing follow-on "unknown module API" errors on the method calls, with no
  clear pointer that the shadow is the root cause. A single clear message or a
  rename hint would help.
