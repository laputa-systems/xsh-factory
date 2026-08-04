# CTO factory improvement

## Status

validated

`pending-validation` means the CTO has already implemented this change. It is
not awaiting another approval; the next cycle verifies the named metric or
applies the safe inverse.

## Change

The factory now runs each passing engineer sibling's linked replay
independently, and the shared forbidden-subprocess scanner ignores `#`
comments while still detecting code tokens. This changes
`run-organization.xsh`, `factory_control.xsh`, and the evaluator scanner
contracts, with native regression coverage in
`tests/factory_control_test.xsh`.

## Baseline metric

The prior cycle had a correct sibling candidate suppressed by another sibling's
failure and classified a correct envcfg candidate as restricted because prose
contained `run `. Evidence: `runs/run-1785784385782/CTO-REPORT.md` and its
linked phase reports.

## Target metric

Every passing engineer row must receive its own replay, and comment prose must
not create a restriction failure. The next-cycle target is zero sibling
suppression and zero comment-only restriction failures.

## Validation

Validated by `XSH_MODULE_PATH=. xsht test` (38 native tests, including
`test_forbidden_subprocess_scan_ignores_comments`), plus the fresh cycle's
per-ticket re-evaluation events and evaluator classification.

## Revert condition

If a passing engineer row lacks its own replay, or a comment-only `run `,
`spawn `, or `process.` occurrence fails restrictions, revert the controller
and scanner changes and restore the prior narrow behavior after preserving the
failing run evidence.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted`
after running the named verification, and link the evidence before admitting
paid work.
