## XSH language proposals

There is no first-class, statically-typed way to raise/custom-raise an error.
`Err("msg")?` executes correctly at runtime (process exits nonzero), but
`xsht check` rejects it with `incompatible propagated error: cannot propagate
Str from function returning Error`. A language-level error constructor (e.g. a
`fail`/`raise` that yields a proper `Error` value) would let programs express
validation failures without abusing a host operation. In this session the only
check-clean way to exit with a proper Error was to trigger a real host failure
(`regex.compile("(")?`), which is obscure and produces a misleading message.

Path literals do not interpolate: `p"$name"` yields a literal `$name`, unlike
display strings (`f"..."`). There is no obvious Str -> Path conversion exposed;
feeding a `Path`-typed `proc main(out: Path)` argument is the clean route but
is not covered in the handbook.

## xsht friction

Runtime and static checking disagree on the same program: `Err("msg")?`
exits nonzero at runtime yet fails `xsht check`, so a behaviorally correct
program fails the check gate and vice versa. This forces workarounds and makes
`xsht check` an unreliable proxy for runtime behavior.
