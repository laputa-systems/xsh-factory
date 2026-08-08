# Eval-manager bounded retry

This is the final bounded retry for the eval-manager report. The prior attempt
did not produce a contract-complete narrative. Recover the existing evidence;
do not rerun the executor, broaden discovery, or inspect historical runs.

First read the current structured phase report and the staged report below.
Then use `write` or `edit` to replace every skeleton placeholder in the staged
report. Finish the report before any optional investigation. A valid closeout
has `## Result` set to `pass` or `fail`, all required headings populated, no
`not-ready` result, and no `Fill from` or `Fill every` placeholder text.

- Phase report: `{{PHASE_REPORT}}`
- Staged retry report: `{{REPORT_PATH}}`

For a candidate-linked replay, state one explicit acceptance decision grounded
in whether the worker exercised the proposed candidate surface. If accepted,
include the exact sentence `Candidate acceptance: pass.` If not accepted,
include `Candidate acceptance: fail.` Do not leave that decision implicit.

Keep the report concise and evidence-backed. The retry budget is for completing
the report, not for re-reading raw sessions after the structured evidence is
already sufficient.
