## XSH language proposals

None.

## xsht friction

- A pure helper procedure that declares no effects (returns a `Result` without
  using `?`) cannot be called from `main` once `main` declares effects; the
  check reports `proc is unrestricted — cannot call from a proc with declared
  effects`. Every helper must carry an effects bracket (here `[error]`) even
  when it only returns a `Result` data value. This is surprising for pure
  value-returning helpers.
- `//` is neither an integer-division operator nor a comment marker (it is a
  parse error); integer division is `/`. Boolean `&&`/`||` are rejected — use
  the word forms `and`.
- `fold` blocks cannot contain a side-effecting `print` ("full_ir_function_blocker");
  cumulative output had to be built with a pure fold into a list and printed
  afterwards via `zip`/`each`.
- `List.get(index)` returns `Result[.., Error]`; the fallback overload
  `List.get(index, fallback)` must be used to read the last element while
  defaulting on an empty list.
