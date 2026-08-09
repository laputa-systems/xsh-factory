## XSH language proposals

None.

## xsht friction

- `env.get_or` is documented with `effects: env` only, but applying postfix `?`
  to its `Result[Str, Error]` return requires adding the `error` effect to the
  procedure. The module signature alone does not advertise this, so a first
  `xsht check` failed with `?` requires the `error` effect on every read. The
  general postfix-? rule is in the handbook, but the env API signature is
  under-specified about it.
