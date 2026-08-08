## XSH language proposals

- `Str.parse_int()` is not a decimal-only parser: it accepts hex (`0x10`),
  underscore separators (`1_000`), and explicit signs (`+5`, `-0`) in
  addition to surrounding whitespace. A task requiring a strict decimal
  integer must additionally validate the trimmed text (e.g. with
  `Str.delete("0123456789")`) instead of relying on `parse_int` alone. This
  caught the width and file-line validation in the histogram task.

- Integer division in XSH is `/` (e.g. `10 / 3 == 3`), not `//`. The task
  text spelled it `v // WIDTH`, but `//` is a parse error in this build and
  the handbook notes it is not a comment marker either. The mismatch between
  task prose and the actual operator is worth surfacing.

- `abort(status)` returns `Unit`, so it cannot be used as the tail expression
  of a block that must yield a typed value (e.g. a `map` block returning
  `Int`). Validation with `abort` must be done in statement position (an
  `each` block) before a parsing pass.

- Division by zero is not guarded and crashes the interpreter with a
  `Trace/breakpoint trap` (exit 133) rather than a clean error. Input that can
  produce a zero divisor must be validated explicitly.

## xsht friction

- `xsht api` is picky about query spelling: `api:language.core.abort` and the
  bare `language.core.abort` form are rejected ("invalid API query") while
  `language:core.abort` works. The exact `KIND:VALUE` separator convention is
  easy to get wrong when the id itself contains dots.

- `xsht fmt` reformats confidently but makes no semantic claims; combined with
  `lint` (which has its own warning for `Path(...)` over `fp"..."`) the
  happy-path is check-passing and warning-free, but message terminals like
  `each` must be bound (`let _ = ...`) to avoid a runtime error after output.