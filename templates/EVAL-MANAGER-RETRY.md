# Eval-manager bounded retry

This is the final bounded retry for the eval-manager report. The prior attempt
did not produce a contract-complete narrative. Recover the existing evidence;
do not rerun the executor, broaden discovery, or inspect historical runs.

The role and immutable assignment still require exactly five first reads: the
supplied handbook snapshot, `NORTH-STAR.md`, `roles/pi-session-briefing.md`,
the eval's `EVAL.md`, and the current structured phase report below. Complete
that set first. Do not read the original worker report. Do not read the staged report, evaluator manifest, artifact, or raw session before drafting. Your next
tool call after those five reads MUST use `write` or `edit` to replace every
skeleton placeholder at the staged report path below. Finish the report before
any optional investigation, raw session read, or artifact probe. A valid closeout
has `## Result` set to `pass` or `fail`, all required headings populated, no
`not-ready` result, and no `Fill from` or `Fill every` placeholder text.

- Phase report: `{{PHASE_REPORT}}`
- Staged retry report: `{{REPORT_PATH}}`

For a candidate-linked replay, state one explicit acceptance decision grounded
in whether the worker exercised the proposed candidate surface. If accepted,
include the exact sentence `Candidate acceptance: pass.` If not accepted,
include `Candidate acceptance: fail.` Do not leave that decision implicit.

Keep the report concise and evidence-backed. If a value is absent from the
structured packet, write `unknown` or `None.` and continue. The retry budget is
for completing the report, not for re-reading raw sessions after the
structured evidence is already sufficient.
