# Pi session reporting briefing

Read `NORTH-STAR.md` before interpreting a run. Session metrics are evidence
for the XSH improvement mission, not a reward function by themselves.

The session JSONL is the canonical record. Do not re-research Pi's source or
HTML exporter before interpreting a run.

Start with the current controller outputs: the phase or run `report.json`,
the role worker `report.json` and `REPORT.md`, and `run.json` when the claim concerns an
eval. Search older runs or implementation source only when those current
artifacts disagree or leave a concrete field unexplained. One targeted
reproduction is usually enough to distinguish a real defect from noise.

When using `xsht api`, the query syntax is `KIND:VALUE`. Use exact queries such
as `language:stream.group-by`, `module:tui.left_pad`, or `method:List.join`.
Do not spend turns trying `api:...`, dotted `language.core...` guesses, or
invented method signatures; record an API-discovery gap and continue from the
canonical handbook and source contract.

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
checks, artifacts, evaluator output, and the final result. The worker
`report.json` records the thinking-block count; raw thinking remains in the
canonical session JSONL when a manager needs to inspect it.

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

Tool errors, repeated reads, failed API queries, and long idle spans are
efficiency evidence. They are not automatically product failures. Compare them
with the role's required paths and current controller outputs; when the same
friction recurs, the manager should name the smallest prompt, handbook, or
controller change that would remove it and the replay that will test that
hypothesis.

## Provider health and latency attribution

Provider responsiveness is an external confounder, not automatically an agent
efficiency signal. The factory captures Pi provider telemetry separately from
the canonical transcript when available. Use explicit retry events, provider
errors, retry delays, and response timing before attributing wall-clock growth
to an agent or prompt regression.

Classify latency evidence as:

- **provider-latency signal:** explicit retry/429/5xx/overload/timeout evidence
  or elevated provider wait with no corresponding increase in turns, tool
  errors, repeated exploration, or tokens;
- **agent-efficiency signal:** increased turns, tool calls, repeated reads,
  invalid queries, tool errors, or tokens while provider telemetry is normal;
- **mixed signal:** both provider latency and agent effort are elevated;
- **unknown:** provider telemetry is absent or incomplete. Do not call a slow
  session an agent regression from wall time alone.

Pi's `auto_retry_start` and `auto_retry_end` events are the authoritative retry
evidence. Derived output tokens/second is client-observed diagnostic data, not
provider-side throughput, unless the provider explicitly reports generation
timings. Provider switching or fallback based on health is deliberately out of
scope; record it only as a future TODO.
