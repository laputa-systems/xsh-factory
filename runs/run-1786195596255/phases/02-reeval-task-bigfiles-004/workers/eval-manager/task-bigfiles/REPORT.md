# Eval-manager report

## Result

fail

## Effort metrics

Single-trial candidate-linked replay of `task-bigfiles` (candidate branch
`task-bigfiles-004`, XSH candidate commit `608ab11bcf25cb0f69df4cb352fa40b27c1be2b3`;
under-test baseline `xsh_commit` `c77b01a3e2fb676cc57cdeddbb7575be7723aa32`).

Worker `eval-worker/task-bigfiles-1`:
- assistant turns: 19 (user_messages 1)
- tool calls: 30 (bash 25, read 3, write 2)
- tool errors: 2
- agent wall: 509305 ms; session span: 508112 ms
- worker friction: one bounded API-discovery detour (effect-rule naming and a shell
  quoting error, see Tool-error findings) plus task solution that did not select
  `hidden: true`.

Trial 1 correctness: 8 of 9 cases byte-exact; `hidden_default` failed (dot-prefixed
regular file silently omitted). `hidden_bad_n` failure control passed (candidate exit
3, oracle exit 1; both nonzero, empty stdout). Restrictions passed, protocol passed,
timing passed.

## Usage and cost

Worker `task-bigfiles-1` provider-reported usage (DeepSeek v4 flash, OpenRouter):
- input 106015, output 4934, cacheRead 134400, cacheWrite 0
- provider_total_tokens 245349 (= bucket total 245349)
- reasoning_tokens 2195 (provider-reported; a subset of output, not added to totals)
- thinking_blocks 17
- cost_usd 0.01284867; budget 0.5 (budget_state pass)
- aggregate cost for this cycle: $0.01285 (1 trial)

## Thinking evidence

17 thinking blocks in the worker session; provider reported reasoning_tokens 2195.
The transcript shows the worker correctly read the documented hidden contract
(`api:fs.files` / `api:fs.walk` at turn 2 returns "hidden: false by default omits
dot-prefixed files and directories, while hidden: true includes them"), yet its
final solution used `fs.walk(root)?` with no `hidden: true`. It did not connect the
documented default to the possibility of dot entries in the fixture, did not probe
for hidden files, and did not exercise the ticket's intended surface. Thinking is
qualitative evidence; the decisive evidence is the failing `hidden_default` case.

## Tool-error findings

Two failed Pi tool results in the worker report (both turn 7):
1. `xsht api` invalid query `'language.effect.error'` and `'language.core.postfix-question'`
   (dot-separated instead of `KIND:VALUE` colon form); command exited 2.
2. `sh: syntax error: unexpected "("` from an unquoted `search:Path(` pipeline probe;
   command exited 2.

Both are non-recurring API-discovery friction: the worker corrected the syntax on the
next probe (`language:core.postfix-question`, `method:Path.parse_bytes` succeeded) and
proceeded. No effect-rule, method, or checker failure is implicated in the end-state
failure. These are ordinary short-task discovery noise, not a generalizable product
defect. No manager-session tool errors (manager run produced none).

## Timing evidence

Candidate/oracle wall times (ms) per case: public 11.7/11.6, hidden_default 12.1/14.8,
hidden_n2 15.6/11.6, hidden_single 12.0/15.3, hidden_deep 12.3/12.0, hidden_spaces
14.6/12.3, hidden_utf8 14.8/12.3, hidden_empty 12.3/14.8, hidden_bad_n 11.7/15.0.
`timings.passed` = true; this eval has no strict candidate/oracle timing gate, so
timing is diagnostic and shows no drift.

Worker session wall (~8.5 min) is dominated by bounded API discovery, not provider
latency: `provider_telemetry.present` = true, retry_count 0, provider_errors [],
retry_delay_ms 0, response_elapsed_ms 0. Latency attribution is therefore
agent-efficiency (discovery-heavy), not provider health. `output_tokens_per_second` 0
is client-observed diagnostic and not treated as provider throughput.

## Observation classification

- **Candidate replay failure (correctness / gateway):** `hidden_default` failed because
  the worker used `fs.walk(root)?` without `hidden: true`, silently omitting the
  dot-prefixed regular file. This is the exact defect class ticket `task-bigfiles-004`
  addresses, and it persisted even though the documented contract change was present
  in the under-test environment and was read by the worker. This is the decisive
  observation: the candidate branch did NOT get the worker to select the intended
  hidden behavior, so the ticket's acceptance criterion (replay selects hidden
  behavior from the contract while all nine cases remain exact) is not met.
- **Reusable handbook signal:** recursive discovery silently drops dot entries by
  default; a worker that intends "all regular files" (size-ranked report, disk-hygiene
  listing) must pass `hidden: true`. This generalizes beyond `task-bigfiles` to any
  tree-walk eval. Staged as a concise provisional handbook candidate.
- **Ordinary noise:** the two turn-7 API discovery errors (dot vs colon query form, a
  shell `(` quoting slip) — corrected within one turn, no recurrence.
- **Not product-tooling defect:** the documented contract was present and readable; the
  failure is that passive documentation was insufficient to prompt the action, not that
  the API reference was wrong or missing.
- No harness/evaluator mismatch; evaluator reported per-case byte comparison correctly
  and the failure-control gate passed on both sides.

## Handbook decision

Provisional candidate staged at
`lineage/handbook-candidate.md` (approved snapshot copied plus one added paragraph under
"Paths and filesystem values"): recursive discovery omits dot-prefixed entries by default;
enable `hidden: true` explicitly when the workflow intends to cover every regular file
(e.g. size-ranked or backup reports). General lesson: make the hidden-entry default and
the "cover all files" intent explicit so agents stop silently missing dot entries.
Replay scope: `task-bigfiles`, plus at least one other recursive-discovery eval
(e.g. `task-ecount`/`task-histogram` if the workflow walks trees) to confirm it
generalizes before promotion to `runtime/handbook.md`. Not promoted this cycle.

## Tickets created

None. The observation is already captured by open, Approved. ticket
`task-bigfiles-004`; the new evidence (documentation present but insufficient in
isolation) is handled here as handbook guidance plus a directed replay of that branch,
not a new product ticket.

## Post-merge decisions

The reconciler found no merged tickets for this cycle (`none`). `task-bigfiles-004` is
a candidate-linked pre-merge validation: candidate commit `608ab11b...` (implementation
branch not yet merged). Decision: **needs-replay — rejection for this cycle**. The
candidate's product change (documenting `hidden: false` / dot-entry omission) is present
and readable in the under-test contract, but the linked replay's worker read the
documented contract and still did not select `hidden: true`, so `hidden_default` failed
byte comparison. The ticket's acceptance criterion that the replay "selects the intended
hidden behavior from the contract while all nine cases remain exact" is not satisfied.
The controller should retain the branch for a directed replay; no revert proposal is
needed because the documentation change itself is correct and not yet merged.

## Next replay

Replay `task-bigfiles` on branch `task-bigfiles-004` (candidate commit
`608ab11b...`) combined with the provisional handbook candidate
(`lineage/handbook-candidate.md`): verify the worker now selects `hidden: true` from
the contract/handbook and all nine cases (including `hidden_default`) are byte-exact.
Falsification check: if the worker again omits `hidden: true` despite both the API
contract and handbook guidance, treat the pending ticket's premise as insufficient and
re-scope it. Also replay one additional recursive-discovery eval before promoting the
handbook candidate.

## North-star impact

This replay directly advances trustworthy, learnable XSH: it shows that documenting a
silent default (`hidden: false` omits dot entries) is necessary but not sufficient —
an agent still needs an explicit, general instruction to enable `hidden: true` when a
workflow intends "all regular files." The staged handbook candidate turns that into a
reusable idiom for every tree-walk task, preventing a size-ranked report from silently
dropping hidden files. It keeps the discovery boundary explicit (the North Star's
trust and ergonomics goals) and pins the next replay that will confirm or falsify the
guidance before it is trusted.
