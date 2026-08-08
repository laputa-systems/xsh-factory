## XSH language proposals

- Integer division in XSH is the `/` operator on Ints (it truncates toward
  zero), but the fraction slash `//` used in task math notation is a parse
  error (`expected statement terminator`), not a comment or division operator.
  A task author writing `v // WIDTH` will mislead a reader reaching for that
  spelling; consider documenting that `/` is truncating Int division or adding
  an explicit `idiv`-style operator so `//` is not confused with the task
  notation.

## xsht friction

None.
