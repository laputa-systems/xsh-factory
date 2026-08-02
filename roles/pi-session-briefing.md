# Pi session reporting briefing

The session JSONL is the canonical record. Do not re-research Pi's source or
HTML exporter before interpreting a run.

Each assistant message may contain text, thinking, and tool-call blocks. A
`toolResult` message belongs to the preceding tool call and may have
`isError: true`. Count assistant turns separately from tool calls and tool
results. A session can finish with a normal stop or with a failed/cancelled
worker; use the wrapper status and final report as well as the transcript.

Usage fields are provider-reported per assistant response:

- `input`, `output`, `cacheRead`, and `cacheWrite` are token buckets;
- `reasoning` is a provider-reported reasoning-token field when available;
- `totalTokens` in a provider response is not a substitute for summing the
  buckets in the report;
- `cost.total` is the authoritative dollar amount when present.

Thinking blocks are qualitative evidence about what the worker considered, not
proof that its explanation is correct. Correlate them with tool errors,
checks, artifacts, evaluator output, and the final result. The worker report
extracts every thinking block into `thinking.md` so a manager can inspect it
without manually decoding the JSONL.

The worker session span measures the Pi conversation. The evaluator's
candidate/oracle timing measures the submitted program. Do not conflate those
two clocks. A short program can have noisy process-launch timing even when the
agent session was long.

The manager should classify evidence as agent friction, reusable handbook
guidance, product/tooling defect, image or harness mismatch, evaluator failure,
or ordinary stochastic noise. Only open a product ticket when one strong
reproducible observation supports a general change.
