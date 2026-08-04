# Pi session reporting briefing

Read `NORTH-STAR.md` before interpreting a run. Session metrics support the
XSH improvement mission. They are not a reward function.

The session JSONL is canonical.
Do not re-research Pi source or the HTML exporter before interpreting a run.

## Evidence order

Start with the current phase or run `report.json`, worker `report.json`,
`REPORT.md`, and `run.json` when the claim concerns an eval.

Search older runs or implementation source only when current artifacts disagree
or leave a concrete field unexplained. One targeted reproduction usually
separates a defect from noise.

Use exact `KIND:VALUE` queries with `xsht api`.
Examples include `language:stream.group-by` and `module:tui.left_pad`.
Another example is `method:List.join`.
Do not try `api:...`, dotted core queries, or invented method signatures.

## Session evidence

Count assistant turns separately from tool calls and tool results. A `toolResult`
belongs to the preceding tool call. Use the wrapper status and final report for
failed or cancelled workers.

Provider usage reports four buckets: `input`, `output`, `cacheRead`, and
`cacheWrite`.
Provider reasoning is optional and is a subset of `output`. Never add it to
output or total tokens. Missing provider costs remain unknown, not zero.

Pi does not derive exact thinking-token counts from thinking text. Thinking-block
counts and transcript text are qualitative evidence. The worker report records
the count.

The worker session span measures the conversation. Candidate-oracle timing
measures the submitted program. Do not combine those clocks.

## Manager guidance

Classify evidence as agent friction, reusable handbook guidance, product defect,
harness mismatch, evaluator failure, or ordinary noise. Ask whether the
observation advances the north-star objective and generalizes beyond the task.
Open a product ticket only when one strong reproducible observation supports a
general change.

Tool errors, repeated reads, failed API queries, and idle spans are efficiency
evidence. They are not automatically product failures. When the same friction
recurs, name the smallest prompt, handbook, or controller change and the replay
that will test it.
