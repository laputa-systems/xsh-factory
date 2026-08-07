# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

- `sort-by --desc` is not stable: it reverses the order of equal-key items.
  The documented "two-pass idiom" (sort by the secondary key first, then by
  the primary key) does not compose a reliable compound ordering when the
  final pass is descending. Evidence: sorting the records
  [{beta,9},{alpha,9},{delta,9},{gamma,2},{epsilon,0}] by `region` asc then
  `total` desc yields delta,beta,alpha,gamma,epsilon (the equal-total group is
  reversed) instead of alpha,beta,delta. I worked around it by sorting
  ascending once on a `{neg: 0-total, region: region}` record key. Recommend
  making `--desc` stable (equal keys keep prior order) or documenting the
  reversal.
- Boolean conjunction is only available as the word form `and` (`or`, `!`
  also exist). The ASCII `&&` is silently parsed as a command-word separator,
  producing confusing "expected command argument" errors rather than an
  operator diagnostic (unlike `&`/`|`, which get a helpful
  "word forms 'and'/'or'" message). Propose accepting `&&`/`||` or at least
  giving `&&` the same diagnostic as `&`.
- A value-returning `if` whose branch contains statements (a `let`, then a
  tail value) works at top-level statement position but triggers
  "indexed IR could not encode full_ir_function_blocker" when the `if` is the
  value body of a stream lambda (fold/all predicate blocks). Recommend
  supporting multi-statement branch value blocks inside lambdas, matching
  top-level behavior.

## xsht friction

- The compiler error `indexed IR could not encode full_ir_function_blocker`
  is cryptic (shows a file/line but no actionable message) and is triggered by
  common, innocuous patterns: a `fold` that returns a Map followed by calling
  `.keys()` on the result, and a value-`if` with multi-statement branches
  inside a stream lambda. Several valid-looking designs failed with no hint
  about the workaround (use a `var` Map reassigned inside `each` instead of a
  fold, and hoist validation to a top-level `if`).
- The `--desc` option on `sort-by` uses bare flag syntax
  (`sort-by --desc { block }`). The parenthesized `sort-by(--desc, ...)` fails
  with "stream stage does not accept call arguments" and `sort-by(--desc=true)`
  fails with a parse error; the working flag form is not documented in the API
  signature shown by `xsht api`.
