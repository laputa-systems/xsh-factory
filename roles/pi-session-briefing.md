# Pi session reporting briefing

Read `NORTH-STAR.md` before interpreting a run. Session metrics are evidence
for the XSH improvement mission, not a reward function by themselves.

The session JSONL is the canonical record. Do not re-research Pi's source or
HTML exporter before interpreting a run.

Each assistant message may contain text, thinking, and tool-call blocks. A
`toolResult` message belongs to the preceding tool call and may have
`isError: true`. Count assistant turns separately from tool calls and tool
results. A session can finish with a normal stop or with a failed/cancelled
worker; use the wrapper status and final report as well as the transcript.

Usage fields are provider-reported per assistant response:

- `input`, `output`, `cacheRead`, and `cacheWrite` are token buckets;
- `reasoning` is an optional provider-reported thinking-token count. It is a
  subset of `output`, so never add it to output or total tokens;
- `totalTokens` is Pi's provider-reported total for that usage record. The
  report also calculates a bucket total (`input + output + cacheRead +
  cacheWrite`) and exposes both so a mismatch is visible;
- `cost.input`, `cost.output`, `cost.cacheRead`, `cost.cacheWrite`, and
  `cost.total` are provider-reported dollar fields. Missing fields remain
  unknown rather than being presented as zero;
- Pi does not derive exact thinking-token counts from the thinking text. When
  the provider omits `reasoning`, the report must say that reasoning tokens
  are unavailable. Thinking-block count and transcript text are qualitative
  evidence, not a token estimate.

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
or ordinary stochastic noise. Ask whether the observation advances the
north-star objective and whether it generalizes beyond the task. Only open a
product ticket when one strong reproducible observation supports a general
change.
