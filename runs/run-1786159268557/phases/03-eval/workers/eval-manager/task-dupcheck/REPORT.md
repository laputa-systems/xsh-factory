# Eval-manager report

## Result

pass

## Effort metrics

Single fresh trial (`task-dupcheck-1`), controller-executed against the
approved handbook snapshot. Worker: 25 assistant turns (1 user message), 33
tool calls / 33 tool results, 2 tool errors, session span 129,049 ms
(agent_wall 130,803 ms). Stop reasons: 24 toolUse, 1 stop. Tool mix: bash 25,
edit 3, read 3, write 2. Worker friction is low: the agent reached a correct
solution within ~2 minutes and two recovery probes; there is no repeated
exploration or turns-token blowup for a task of this composition bar.

## Usage and cost

Worker `task-dupcheck-1` (only worker; aggregate == per-worker):
- input 22,140; output 6,470; cacheRead 299,584; cacheWrite 0;
- provider total 328,194; bucket total 328,194 (match);
- reasoning tokens 2,687 (subset of output, not added);
- cost: input $0.0019926, output $0.0011646, cacheRead $0.005392512,
  cacheWrite $0, total $0.008549712.
Budget $0.50, budget_state pass, 0 budget failures. Unknown costs 0. No
malformed usage lines.

## Thinking evidence

17 thinking blocks reported; provider reported 2,687 reasoning tokens (included
in output). Thinking is qualitative: the transcript correlates with two
recovery tool calls after API-discovery misses and with the check/fmt/lint
loop that fixed the `print line` -> `print $line` bare-identifier error before
the final run. Evidence supports a deliberate, well-ordered solve rather than
trial-and-error churn.

## Tool-error findings

Two nonzero Pi/bash tool results in the current worker session (both from
`task-dupcheck-1/report.json`; no manager-session tool errors):
1. Turn 3 — `xsht api` discovery: `api:fs.read_bytes` reported `missing`;
   `api:Digest` and `api:hash.sha256.to_hex` reported
   `invalid API query ... expected NAME.MEMBER`. Exit code 2. The worker
   recovered in-session by querying the correct form and using `?.hex()`.
2. Turn 17 — `xsht check/fmt/lint` all rejected `print line` with
   `check.bare-print-ident` ("use `$ident` to dereference"). Exit code 2. The
   worker fixed it to `print $line` and the subsequent run passed all cases.

No other current-session tool errors. Both were recovered within the same
session and did not affect the passing result.

## Timing evidence

This eval has no strict candidate/oracle ratio gate (both sides finish in
milliseconds; timing is diagnostic only). Per-case candidate/oracle wall ns
(candidate->oracle): public 11.4->11.6ms, hidden_empty 11.4->13.2ms,
hidden_nested 13.0->11.5ms, hidden_three 11.0->13.0ms, hidden_spaces
12.5->13.5ms, hidden_many 13.3->11.3ms, hidden_none 12.9->13.4ms,
hidden_missing 11.0->11.1ms. All well within a stable envelope and comparable
to the oracle; no timing concern. `hidden_missing` correctly exits both nonzero
(candidate 3, oracle 1) with no stdout, recorded exact.

## Observation classification

- **API-discovery form friction (2 errors):** the worker probed exact-ish
  names (`api:fs.read_bytes`, `api:Digest`, `api:hash.sha256.to_hex`) that the
  live `xsht api` rejected as missing/invalid. This is ordinary discovery
  noise already governed by the handbook's exact-NAME.MEMBER / `search:` /
  `summary | grep` guidance; it recovered in-session and did not repeat across
  trials (single-trial run). Not strong enough on one trial to warrant a
  handbook edit or a product ticket.
- **Bare-print-ident error:** a normal `check`/`fmt`/`lint` catch, already
  documented in the handbook (`print` arguments are command words, `$var` to
  dereference). Recovered; validates existing guidance rather than revealing a
  gap.
- **Correctness/composition (pass):** the agent discovered
  `hash.sha256(path)?` + `?.hex()`, `fs.files(root, hidden: true)`,
  `group-by .digest`, `where .items.len() > 1`, flatten, and digest-then-path
  sort, matching the eval's intended idiom and matching the oracle byte-exact
  on all eight fixtures including hidden traversal, three-member, spaces, and
  missing-root failure control. This is a strong reusable-signal confirmation
  that the handbook's streams/typed-path lessons transfer to content-level
  hashing work.

## Handbook decision

Unchanged. The provisional candidate (`lineage/handbook-candidate.md`) is a
byte-identical copy of the approved snapshot
(sha256 `4610e8f4e282c52e2fa34eca91ec46f2ef93d6f313b35a88ffb82f5af7e4365a`).
No new general lesson is justified: the only friction (two `xsht api` discovery
misses, one bare-print catch) is already covered by existing handbook guidance
and was recovered within a single passing trial. Per the one-trial plan, no
claim is made that a candidate was replayed. Replay scope: only if exact-name
`xsht api` discovery failures recur across multiple trials/evals should the
handbook be revisited.

## Tickets created

None. The two tool errors are low-severity, recovered, in-session discovery
noise on one passing trial; they do not meet the one-strong-reproducible-
observation bar, and no product ergonomics defect is reproducible from this
evidence. No factory-target ticket (no factory infra change identified).

## Post-merge decisions

None. The reconciler found no merged ticket files for this run; the open-ticket
snapshot lists `task-dupcheck-002` as Open (not merged), so there is no
post-merge acceptance assignment and nothing to dispatch. No revert proposed.

## Next replay

Replay `evals/task-dupcheck` on the next cycle against the next XSH commit,
using this run's handbook lineage, to confirm the hash/group/flatten/sort idiom
and the `hidden: true` traversal semantics remain discoverable and byte-exact.
Falsification check: if discovery friction or a correctness regression reappears
across the replayed content-hashing path, promote a handbook candidate or open
a product ticket.

## North-star impact

Confirms the factory hypothesis for a canonical systems-glue chore: an agent
with the approved handbook can replace `find | sha256sum | sort | awk` with a
typed, subprocess-free XSH program that discovers `hash.sha256`/`?.hex()`,
traverses hidden files, groups by digest, and emits deterministic
`sha256sum`-shaped output byte-exact on all eight fixtures. This advances
practicality (real content-level administration), learnability (streams and
typed-path lessons transfer beyond ecount/tags/envcfg), ergonomics (low
friction, minimal discovery errors), and trust (a crisp oracle plus a
failure-control case). The run also reaffirms the existing `xsht api` and
`print`-dereference handbook rules, so no editorial change is warranted this
cycle.
