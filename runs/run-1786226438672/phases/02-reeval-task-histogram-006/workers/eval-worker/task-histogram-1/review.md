## XSH language proposals

- Integer division for Ints uses the `/` operator (17 / 5 == 3), while `//`
  is a parse error (reserved, not a comment marker nor a division operator).
  The handbook documents that `//` is not valid but does not state that `/`
  is the integer-division operator. Consider documenting the arithmetic
  operators (int division/remainder, which types they accept) in one place.
- `abort(status)` is the clean way to reject invalid input with a nonzero
  exit and no stdout; it is not covered in the main handbook. Worth a short
  mention alongside the Result-`?` propagation guidance for validation.

## xsht friction

- `xsht api search:parse_uint`, `search:div`, `search:%`, and
  `search:quotient` all return `missing`/unhelpful results, making it hard to
  discover integer division via search; `/` only becomes obvious by trial and
  error. A search for "division" or arithmetic operators would help.
