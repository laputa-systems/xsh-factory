# Task review

## XSH language proposals

The build has no `Error(...)` constructor, so a deliberate validation failure
must be fabricated by propagating a typed conversion that is guaranteed to
fail (e.g. `"x".parse_int()?`). Rejecting configuration this way reads as
obscured intent and ties the failure to an unrelated parse error. A small
`fail`/`abort` primitive or a real `Error(...)` constructor, ideally one that
can carry a specific exit status, would make explicit rejection cases
(`CFG_PORT` not a decimal integer) clearer and let the program match a shell
oracle's exit code instead of always exiting with the generic propagation
code.

## xsht friction

- Boolean operators are the word forms (`or`, `and`); `||` is rejected with a
  clear hint, which is fine but easy to forget for a shell-oriented task.
- The typed readers are not byte-exact validators, so the contract had to be
  checked manually: `env.int` accepts negative values and silently strips
  leading zeros (`CFG_PORT=000123` yields `8080`-style normalisation while the
  oracle keeps the literal string). The handbook already documents this, and
  manual `delete`/`byte_len` validation was required.
- Propagation of an expected failure via postfix `?` exits with code 3 rather
  than the shell oracle's `exit 1`. The task only requires a nonzero exit, but
  an exact exit-status contract cannot be produced without a custom error
  constructor.
