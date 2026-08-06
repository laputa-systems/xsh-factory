## XSH language proposals

- Integer division is expressed with `/` (`40 / 3 == 13`), while `//` is a
  comment marker and there is no `Int.div`/`div` method in the API index. A
  dedicated integer-division operator or an `Int` divide method with an
  explicit truncation contract would remove the ambiguity I had to probe at
  runtime.
- There is no boolean `not` keyword; negation must be written as
  `expr == false`. A `not` operator would read more naturally for validation
  guards.

## xsht friction

- `method:Int` documents only `.float`; arithmetic operators are not listed in
  the API index, so division semantics (and the fact that `//` is a comment)
  had to be confirmed by running small probe scripts rather than from the
  documented contract.
- The parse error for `not` (`expected expression`) and for `<bin> // <width>`
  (`expected statement terminator`) give no hint about which operator or
  keyword is valid; the correct forms (`== false` and `/`) only surfaced by
  trial and error.
