# CTO factory improvement

## Status

pending-validation

`pending-validation` means the CTO has already implemented this change. It is
not awaiting another approval; the next cycle verifies the named metric or
applies the safe inverse.

## Change

The run inspector now snapshots `process.list()` once and reads every
newline-delimited PID in each registry file, so live phase/worker processes
are visible together. The audit machinery now accepts evaluator manifests
whose correctness is represented as a per-case boolean map when the package
terminal result is `pass`; native coverage is in
`tests/tools_test.xsh::test_run_status_inspects_live_and_completed_evidence`
and `test_audit_accepts_per_case_correctness_manifest`.

## Throughput requirement

One reviewable engineer implementation commit was produced (`a652116`), but
zero commits were delivered because the linked replay's audit rejected a
per-case correctness map. This is a throughput failure; the corrective audit
change is pending validation.

## Provider-health attribution

Captured. Worker reports contain provider telemetry; no retry or provider
error signal explains the failure. The failure is infrastructure evidence
aggregation, not provider health.

## Baseline metric

Cycle 3 delivered 1/1 at `$0.157813502`, 162 assistant turns, and six workers
(`runs/run-1786165552479/report.json`).

## Target metric

Validate one engineer delivery with conversion `1.0`, consistent product /
evaluator / infrastructure outcomes, and complete multiline PID visibility.

## Validation

Run `xsht test`, then use
`templates/ORGANIZATION-REQUEST-CYCLE-5.md`. Check
`data.throughput.delivered_tickets == 1`, `delivery_conversion == 1.0`, and
that the phase report agrees with the evaluator manifest's per-case result.

## Revert condition

Revert the audit fallback if a malformed manifest can pass without a terminal
`result: pass`, or if native tests fail. Keep the read-only inspector if it
reports every live registered PID; otherwise repair parsing before admission.

## Next-cycle disposition

Pending validation in the next cycle; link the new run evidence before
promoting this change to `validated`.
