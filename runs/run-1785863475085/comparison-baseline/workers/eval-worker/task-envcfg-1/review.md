## XSH language proposals

The `language.core.fail` construct documented by `xsht api` is not usable in
this pinned build: `fail("...")?` fails checking with
`check.unresolved-call: unresolved pure function call` and a hard runtime
exit. Because there is no working generic error constructor, a deliberate
validation error that no typed conversion can express (a strict decimal
digits-only check) has to be forced through an incidental
`"".parse_int()?` failure in the invalid branch. A real `fail`/validation
error primitive would make this far cleaner and is presumably the intended
design; either the API docs are ahead of the runtime, or `fail` needs a
different syntax than a plain function call.

## xsht friction

- The strict digit-validation contract (`CFG_PORT` must be nonempty decimal
  digits) is not expressible by `parse_int`/`env.int`, which both accept
  signs, whitespace, leading zeros, and (in `parse_int`'s case) `0x`-pairs.
  The manual `delete("0123456789")` + `byte_len` check is required, and then
  there is no typed conversion that fails exactly on that rejected set.
- The failure exit code from a propagated conversion error is 3, not 1; the
  task requires only "nonzero", so this passes, but an oracle that compares
  exact codes would diverge.
