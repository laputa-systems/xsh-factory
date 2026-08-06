# Eval-manager report

## Result

pass

## Effort metrics

Single fresh trial (`task-histogram-1`) against XSH commit
`1cf4ad3d7ee5fde9b3160b11d8073cbd7ce5e7c4`.

- Assistant turns: 38
- Tool calls: 54 (bash 46, read 4, write 2, edit 2); tool results 54
- Tool errors: 0
- Session span: 503,232 ms (~8.4 min); agent wall 504,699 ms
- Stop reasons: 1 `stop`, 37 `toolUse` (terminal staged for an edge validation)
- Worker friction: `xsht check` rejected the lambda parameter/`sort-by`/`fold`
  name `group` twice with `err[check.standard-module-shadow]`, forcing a rename
  to `grp`; the reviewer also noted the `"".parse_int()?` workaround for
  rejecting non-positive width / signed values and `xsht lint` preferring `fp`
  interpolation over the documented `Path(str)` cast.
- Classification per trial: pass (correctness, restrictions, protocol, timing
  all pass; no budget breach).

## Usage and cost

Single worker, provider `openrouter/deepseek/deepseek-v4-flash-0731`.

- Input tokens: 37,575; output tokens: 19,827; cache-read tokens: 748,864;
  cache-write tokens: 0; provider total / bucket total: 806,266 (balanced).
- Reasoning tokens (provider-reported): 13,665.
- Cost: input $0.00338175, output $0.00356886, cache-read $0.013479552,
  cache-write $0, total $0.020430162. Budget $0.50; no budget breach.
- Aggregate equals the single trial (one worker). Unknown-cost fields: 0.

## Thinking evidence

34 thinking blocks; provider-reported reasoning tokens 13,665. No separate
`thinking.md` was emitted; the canonical thinking is in `session.jsonl.bz2.bz2`. The
thinking steered the worker toward the pure `fold` building a `{total, out}`
record followed by an `each { |line| print $line }` stage (this run never
attempted a side-effecting fold body), and toward inlining all typed
validation into `main`. Qualitative evidence is consistent with the correct,
clean final artifact; not treated as a proof of correctness independent of the
evaluator byte-exact result.

## Tool-error findings

None. The structured `tool_errors` arrays are empty in the worker report
(`tool_errors: 0`) and in the manager/phase report; the executor reported no
failed Pi tool results and no invalid `xsht api` discovery queries. The
checker rejections described in Effort metrics are non-error script feedback
inside bash tool results, not failed tool results.

## Timing evidence

No strict candidate/oracle timing gate (eval contract: diagnostic only).
Per-case timing (candidate vs oracle, wall ns):

- public: 13,074,999 / 13,169,415
- hidden_width: 11,136,701 / 11,467,368
- hidden_many: 11,254,368 / 12,929,248
- hidden_sparse: 11,708,619 / 13,217,582
- hidden_single: 11,072,284 / 11,974,078
- hidden_ties: 11,248,159 / 11,300,702
- hidden_empty: 13,439,999 / 13,208,832
- hidden_bad_width: 11,023,201 (exit 3) / 12,862,206 (exit 1)
- hidden_bad_value: 11,986,495 (exit 3) / 11,164,117 (exit 2)

Both sides are sub-20 ms and comparable; candidate is not meaningfully slower.
Provider telemetry shows retry_count 0, provider_errors [] and no retry events;
latency attribution for the ~8.4 min session is not provider-driven
(no elevated latency signal), and the modest turn/token effort is commensurate
with the task.

## Observation classification

- Correctness (pass): all nine cases byte-exact versus the oracle, including
  both failure controls (nonzero exit, empty stdout). Restrictions pass
  (typed `fs.read_text`, `parse_int`, `sort-by` present; no subprocess
  boundary). Reusable signal: the handbook's `group-by` → `sort-by` → pure
  `fold` cumulative idiom transferred cleanly.
- Worker friction / reusable handbook guidance (new, reproducible): the
  `check.standard-module-shadow` rejection of the common word `group` as a
  stream-stage lambda parameter. Confirmed twice in-session (sort-by and fold
  params); the reviewer noted the check is not scoped to an actual shadowing
  call. A short general naming rule removes this for every future eval, so it
  is staged as a handbook candidate rather than a ticket.
- Product/tooling gap (known limitation, not new): no strict digits-only
  parse and no generic expected-failure constructor, forcing the
  `"".parse_int()?` workaround to reject `width <= 0` and signed values. This
  is consistent with the handbook's existing "no generic `Error(...)`
  constructor" note; classified as ordinary noise / documented limitation, no
  new ticket.
- Ordinary noise / expected behavior: `xsht lint` preferring `fp"${...}"`
  over the documented `Path(str)` cast is already the documented
  "lint-preferred" surface; no defect.

## Handbook decision

Provisional candidate staged at
`runs/run-1785966217772/phases/03-eval/lineage/handbook-candidate.md` —
identical to the approved snapshot plus one concise, general rule: do not name
a binding or a stream-stage lambda parameter after a standard module (e.g.
`group`), which `xsht check` rejects with
`err[check.standard-module-shadow]`; choose a non-module identifier such as
`grp` from the start.

Replay scope (global, must generalize): replay `task-histogram` and at least
one other eval whose pipeline uses a stream-block parameter, confirming the
rule avoids the rename friction without changing correctness. The approved
snapshot and checked-in `runtime/handbook.md` were not modified.

## Tickets created

None. The single strong reproducible observation (standard-module shadow
naming) is handled as concise handbook guidance rather than a product ticket;
the eval passed cleanly and the checker behaviour, while conservative, is the
documented shadowing rule. Existing open tickets `task-histogram-003` and
`task-histogram-004` remain open (Open., deferred) and are not touched.

## Post-merge decisions

None. The reconciler reported no merged ticket files for this phase, so there
are no post-merge acceptance assignments to evaluate against
`1cf4ad3d7ee5fde9b3160b11d8073cbd7ce5e7c4`.

## Next replay

Replay `task-histogram` on a future cycle's lineage over the promoted
handbook to confirm the standard-module-shadow naming rule prevents the
`group`-rename friction; extend to one additional eval using a stream-block
lambda parameter to falsify whether the rule generalizes. If it does not, the
observation should be re-attributed to a checker-scoping product ticket for
the CTO.

## North-star impact

This run confirms the handbook's composable measurement-summary idiom
(typed file read, integer division to a derived bin key, keyed
`group-by` count, `sort-by`, and a pure cumulative `fold`) lets an agent
produce a byte-exact binned cumulative distribution with 38 turns and zero
tool errors, advancing XSH as practical, learnable systems glue. The staged
handbook candidate addresses a recurring naming friction so future agents
won't collide with standard modules, and the honest review surfaced (without
re-ticketing) the known lack of a generic expected-failure constructor. No
product or infrastructure defect was found in this cycle.
