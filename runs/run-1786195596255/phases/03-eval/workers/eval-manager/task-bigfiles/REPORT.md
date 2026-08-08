# Eval-manager report

## Result

fail

## Effort metrics

- Trials: 1 (controller executed; not re-run by manager).
- Worker `task-bigfiles-1`: assistant_turns 24; tool_calls 26 (bash 22, read 1,
  write 3); tool_results 26; tool_errors 0; session_span_ms 603034 (~10.05 min),
  agent_wall_ms 604234.
- Worker friction: minimal structural friction. The agent discovered the
  filesystem API, sort-by/take, and `Str.parse_int`, and produced a correct
  artifact on the visible-only and non-dot cases. The single correctness
  failure (`hidden_default`, the dot-file case) stems from an undocumented API
  default, not from wasted exploration.
- The worker session ended with one provider-error stop (see `## Provider
  health`) before filling `review.md` findings; `review.md` remained at its
  default `None.` entries and was accepted by the evaluator (`review_ok: true`).
- Manager session: reads/writes only; no tool errors.

## Usage and cost

Worker `task-bigfiles-1` (single trial; aggregate equals the trial):
- bucket input 122,447; output 5,731; cacheRead 118,272; cacheWrite 0;
  provider bucket total 246,450.
- reasoning_tokens 2,883 (provider-reported, a subset of output); thinking
  blocks 18.
- cost: input $0.01102023; output $0.00103158; cacheRead $0.002128896;
  cacheWrite $0; total $0.014180706. budget $0.50; no breach (provider reports
  `provider_total_tokens` equal to the bucket sum; no malformed usage lines).

## Thinking evidence

- 18 thinking blocks; provider-reported reasoning_tokens 2,883.
- Findings grounded in the transcript (`thinking.md` not separately printed;
  thinking blocks are recorded inline in `session.jsonl.bz2`):
  - The agent correctly probed `Str.parse_int` semantics and chose a strict
    "digits only" validation so `0x10`, `-3`, `5.5`, and ` 3` are rejected and
    exit nonzero (hidden_bad_n matched, both nonzero).
  - It experimented with an if/else-as-expression containing `let` bindings,
    hit parse errors, and correctly switched to a `var`/statement-if form.
  - It used `fs.files(root, stat: true)?` without considering hidden entries;
    the only failing case is the forest containing a dot-prefixed file.

## Tool-error findings

The structured `tool_errors` arrays in the phase `report.json` and the worker
`report.json` are both empty (worker tool_errors 0). `None.`

Note (not a Pi tool error): one discovery probe `xsht api language.cli.xsh-SCRIPT`
returned `invalid API query 'language.cli.xsh-SCRIPT'` because it used a
dotted spelling instead of the `KIND:VALUE` form. One-off, corrected
immediately, and classified as ordinary discovery noise below.

## Timing evidence

- No strict candidate/oracle timing gate. Per-case wall times are 12–16 ms
  (candidate) vs 11–15 ms (oracle) across the nine cases; `timing.passed: true`.
  Both sides complete in milliseconds, diagnostic only.
- hidden_bad_n: candidate exit 3, oracle exit 1 — both nonzero, so the failure
  control passed (`exact: true`).
- The deciding failure is `hidden_default` (candidate omitted the dot entry),
  a correctness/observation mismatch, not a timing issue.

## Provider health

- `provider_telemetry.present: true`; `provider_errors` contains one:
  `Upstream error from DigitalOcean: Response payload is not completed:
  <TransferEncodingError: 400 ... Not enough data to satisfy transfer length
  header.>` This terminated the final response with stopReason `error`.
- `retry_count 0`, `retry_delay_ms 0`, `retry_successes 0`, `retry_failures 0`;
  `output_tokens_per_second 0` (derived value unavailable).
- Latency attribution for the ~10-minute wall span is **mixed/unknown**: one
  clear provider error is present, but the referenced
  `session.jsonl.events.jsonl` file is absent, so explicit retry timing is not
  available. Do not attribute the wall clock to an agent regression; the agent
  effort (24 turns, 26 tool calls, 0 tool errors) is modest and the artifact is
  substantively correct. Provider switching/fallback is out of scope this cycle
  (future TODO only).

## Observation classification

- **Reusable handbook guidance (strong):** `fs.files` and `fs.walk` skip
  dot-prefixed entries by default (`hidden` defaults to `false`), and the
  handbook does not state this. The candidate passed every case except the one
  with a dot file (`hidden_default`), a silent omission that is not the
  worker's fault given the reference available. This is the recurring, general
  learnability gap already captured by approved product ticket
  `task-bigfiles-004` (which documents the `hidden: false` default and dot-entry
  omission in the API contract). A provisional handbook candidate teaching
  `hidden: true` for complete recursive discovery is staged in the run lineage.
- **Product/tooling defect (already ticketed):** the `xsht api` contract for
  `fs.files`/`fs.walk` lists a `hidden` option and says "Order and traversal
  behavior are explicit in the options" but never states the default or its
  dot-entry semantics. This is `task-bigfiles-004`, already Approved for a
  later cycle; this run adds fresh evidence but is not a new ticket (no
  duplicate created).
- **Ordinary noise:** the single invalid `language.cli.xsh-SCRIPT` API query
  and the if/else-as-expression syntax stumble were transient, corrected in
  place, and did not affect the final artifact.
- **External-health evidence:** the one DigitalOcean transfer/encoding error is
  provider-side, not agent inefficiency.

## Handbook decision

Provisional candidate staged at
`runs/run-1786195596255/phases/03-eval/lineage/handbook-candidate.md` (approved
snapshot copied unchanged plus a new `## Hidden (dot) entries` section). The
general lesson: recursive discovery through `fs.files`/`fs.walk` omits hidden
dot entries by default, so pass `hidden: true` when a complete listing is
required. Replay scope: re-run `task-bigfiles` (whose `hidden_default` case
makes this observable) and at least one other discovery eval, e.g.
`task-findexec` or `task-histogram`, to confirm agents select `hidden: true`
from the handbook and remain byte-exact. Promotion to `runtime/handbook.md`
requires those replays and CTO approval.

## Tickets created

Zero. The one strong, reproducible observation (undocumented `hidden: false`
default) is already carried by the approved product ticket `task-bigfiles-004`
(next unused focused identity); this run's `hidden_default` failure is
additional evidence for it, not a new ticket.

## Post-merge decisions

None. The reconciler found no merged ticket files for this run (merged list:
`none`). `task-bigfiles-004` remains open/Approved with an unfilled merge record
(not merged), so it is a forward-cycle product assignment, not a post-merge
acceptance. No revert proposal.

## Next replay

Re-run `task-bigfiles` at the same XSH baseline `c77b01a3e2fb676cc57cdeddbb7575be7723aa32`
against `runs/run-1786195596255/phases/03-eval/lineage/handbook-candidate.md` to
verify the worker selects `hidden: true` and passes all nine cases (especially
`hidden_default`). Cross-replay a second discovery eval to confirm the
lesson generalizes before the candidate is promoted to `runtime/handbook.md`.

## North-star impact

This run isolates a silent-behavior trap in recursive filesystem discovery:
dot entries are omitted by default while the contract does not say so, so a
correct-looking program quietly misses files. A short, general handbook rule —
pass `hidden: true` for complete discovery — plus the already-approved product
fix (document the default in `xsht api`) make discovery explicit and
trustworthy, directly serving the learnability and trust goals in the north
star. It advances "practical, learnable, ergonomic, trustworthy XSH" by removing
a fixture-experiment dependency for a canonical `find | sort | head`-style
systems task, rather than rewarding a task-specific workaround.
