# Eval-manager report

## Result

fail

Pre-merge validation of candidate `task-pathparts-001` (XSH commit
`30fabd4e12181830d146615b978861bef0737f96`) on the clean engineer worktree
`/Users/josh/d/laputa-systems/xsh-factory/../.xsh-factory-worktrees/run-1786146336183/task-pathparts-001`
(HEAD verified = `30fabd4e` "Add POSIX path decomposition methods").

The executor evidence **supports** the proposed fix: on the candidate commit the
agent reproduced the seven-case oracle through the typed `Path` surface
(`p.parent()`, `p.name()`, `p.ext()`) with all seven correctness cases true and
no raw-`Str` reimplementation — exactly acceptance criterion 1 of the ticket.
The trial nevertheless fails (`restriction_failed`) because the eval's `Path(`
restriction gate cannot be satisfied: `xsht lint` hard-fails (`exit 1`,
`warn[lint.path-constructor]`) on the documented `Path(str)` cast and steers the
agent to `fp"${argv[0]}"`, which removes the literal `Path(` token →
`restrictions.path_referenced: false`. That residual failure is the independent,
already-open `task-pathparts-002` lint-versus-restriction conflict, not a defect
in the path-decomposition fix under test. Candidate fix validated; eval cannot
pass until the lint/gate tension is resolved.

## Effort metrics

- Trial 1 worker `task-pathparts-1`: 19 assistant turns, 20 tool calls
  (14 `bash`, 3 `read`, 3 `write`), 2 tool errors, session span 154,709 ms
  (~154.7 s), agent wall 156,052 ms. stop reasons: 1 `stop`, 18 `toolUse`.
- Provider telemetry present: `retry_count: 0`, `provider_errors: []`,
  `retry_errors: []`, so no external-health signal attributable to latency.
- Worker friction: moderate, concentrated in one early print/display-string
  probe (turn 3) and the lint steer (turns 32-34). Protocol `pass`, review
  present with `None.` findings (review.md).
- Trial 1 outcome: `correctness` all 7 true, `restrictions.passed: false`,
  `restrictions.path_referenced: false`, `classification: restriction_failed`,
  `result: fail`, `timing: pass`, `protocol: pass`.

## Usage and cost

- Trial 1 (single worker, aggregate = per-worker): `input` 23,735;
  `output` 6,634; `cacheRead` 188,544; `cacheWrite` 0; provider `totalTokens`
  218,913; bucket total 218,913 (match). `reasoning` 3,994 (provider-reported,
  subset of output). `cost_usd` 0.006724062; cache-read cost 0.003393792;
  budget 0.5 USD, `budget_state: pass`. No unknown/missing cost fields
  (`unknown_costs: 0`).
- No cost-breach or cache-write traffic.

## Thinking evidence

- 14 thinking blocks; provider-reported reasoning tokens 3,994 of 6,634 output.
- Thinking (canonical session) shows the agent reasoning about
  `basename`/`dirname`/shell-extension semantics, mapping `Path.ext() == ""` to
  `none`, discovering display-string interpolation via
  `xsht api language:core.display-strings`, and explicitly choosing
  `fp"${argv[0]}"` over `Path(argv[0])` "to keep `xsht lint` clean" (turns
  32-34). That reasoning correlates directly with the restriction failure:
  the agent followed the visible lint error, believing it must be clean,
  and thereby dropped the `Path(` token the gate requires. Provider did report
  reasoning-token counts for this session.

## Tool-error findings

Two nonzero Pi tool results in the structured `tool_errors` array (worker
`task-pathparts-1`), both accounted for:

1. **Turn 3 (`bash`)** — probe `print "arg=" $argv[0]` →
   `err[check.argv-conversion]: interpolation cannot convert to one command
   word` on all test shapes. Early discovery friction: the agent was probing
   print/display-string syntax before consulting
   `xsht api language:core.display-strings`. Resolved within the session;
   the handbook already documents the print/display-string rule. Classified as
   ordinary worker discovery friction, not a product or handbook defect.
2. **Turn 14 (`bash`)** — `xsht lint pathparts.xsh` → `FMT-OK` then
   `warn[lint.path-constructor]` with `Command exited with code 1`,
   recommending `use path string syntax instead ... fp"${argv[0]}"`. This is
   the hard lint `exit 1` on the documented `Path(str)` cast (reproduced, and
   the agent's subsequent switch to `fp"${argv[0]}"` dropped the `Path(`
   token). Classified as the lint-versus-restriction product/tooling defect
   already tracked by `task-pathparts-002`; reproduced once here, no new
   ticket opened.

No other failed Pi tool results exist in the current evidence packet.

## Timing evidence

Candidate/oracle per-case wall times are all millisecond-scale and comparable
(candidate ~11.6–13.2 ms, oracle ~11.1–13.5 ms across the seven cases);
`timing: pass`. The eval contract has **no** strict candidate/oracle ratio gate
(timing is diagnostic only). The ~155 s agent session span is the Pi coding
conversation, not candidate runtime; the two clocks are distinct.

## Observation classification

- **Correctness signal (reusable):** On the candidate commit the agent
  reproduced the byte-exact seven-case oracle entirely through the typed
  `Path` decomposition methods (`parent`/`name`/`ext`) with no raw `Str`
  reimplementation. This validates the `task-pathparts-001` path-decomposition
  fix and its north-star claim that typed `Path` is an expressible, trusted
  boundary for this contract. Generalizes to any path-decomposition eval.
- **Product/tooling defect (reusable, already ticketed):** `xsht lint` hard
  `exit 1` on the documented `Path(str)` cast while the eval's `path_referenced`
  gate requires the literal `Path(` token — two factory surfaces direct the
  agent opposite ways; the agent deterministically failed the gate by following
  the tool. This is `task-pathparts-002` (Open., deferred). Reproduced exactly
  here; no new ticket (see Tickets created).
- **Ordinary noise:** the turn-3 print/display-string probe error was resolved
  via canonical `xsht api` discovery; no signal.
- **External health:** provider telemetry shows zero retries/errors; latency is
  not a confounder. Not a factor in the failure.

## Handbook decision

Unchanged. The approved snapshot `handbook-approved.md`
(sha256 `3b56a781...`, hash verified) is copied verbatim to
`lineage/handbook-candidate.md` (same hash). No new handbook lesson is
warranted: the handbook already documents `Path(str)` and labels `fp"${...}"`
"the interpolated, lint-preferred form," which is consistent with the tool. The
failure is a lint-vs-restriction gate conflict (a product concern), not a
handbook gap; one-trial plan produced no reusable handbook change.

## Tickets created

None. The one reproducible observation — `xsht lint` hard-failing on the
contract-required `Path(` construction and blocking the `path_referenced` gate —
is already captured by the open ticket `tasks/task-pathparts-002.md` (Open.,
deferred). No new or duplicate ticket opened this cycle.

## Post-merge decisions

None. The reconciler found no merged ticket files for this run (`none`). The
candidate `task-pathparts-001` is a pre-merge validation, not a merged
acceptance assignment; per the assignment it is not marked merged, not
dispatched, and not treated as main. Decision on the candidate is recorded in
`## Result`: fix supported by evidence, but the eval cannot pass until the
`task-pathparts-002` lint/gate conflict is resolved.

## Next replay

After `task-pathparts-002` (lint-/gate-alignment) is delivered and merged,
replay `task-pathparts` against the merged build that also carries the
`task-pathparts-001` typed-`Path` decomposition methods. Acceptance: a fresh
trial passes both `xsht lint` and the `path_referenced` restriction gate
(Build/`Path(`-token) and the seven-case oracle via the typed `Path` surface,
and the agent is no longer misled into dropping the required construction.
Per the ticket post-merge plan, also replay a second path-construction eval to
confirm the guidance generalizes. Handbook lineage under review:
`runs/run-1786146336183/phases/02-reeval-task-pathparts-001/lineage/`.

## North-star impact

This run validates that the `task-pathparts-001` fix restores the typed `Path`
value as an expressible, learnable boundary for the
dirname/basename/extension contract — the north star's "connect ... paths ...
system state" and reduce-friction goal — since the agent now reproduces the
oracle through `Path.parent()/name()/ext()` with zero raw-string parsing. It
simultaneously re-confirms, with a clean one-item reproduction, the
lint-versus-gate trust conflict (two factory surfaces telling the agent
opposite things about typed-`Path` construction), which erodes
trustworthiness and ergonomics. Resolving that conflict (the deferred
`task-pathparts-002`) is the next durable step so that passing this eval no
longer requires guessing which factory surface is authoritative.
