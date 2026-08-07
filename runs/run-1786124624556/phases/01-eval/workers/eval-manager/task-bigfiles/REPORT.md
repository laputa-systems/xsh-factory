# Eval-manager report

## Result

pass

## Effort metrics

Trial 1 (`task-bigfiles-1`, single configured trial against approved
handbook):
- assistant turns: 29; user messages: 1
- tool calls: 35 (bash 27, edit 3, read 4, write 1); tool results: 35
- tool errors: 2 (both benign; see Tool-error findings)
- session span: 126742 ms wall (agent_wall_ms 127968)
- outcome: all 9 evaluator cases byte-exact; protocol, restrictions, timing,
  review all pass; agent state pass, budget state pass (budget_failures 0)

No worker inefficiency concern: 29 turns is proportional to the
breadth-first API discovery the task requires, and both tool errors were
self-resolved during exploration without derailing the deliverable.

## Usage and cost

Trial 1 (provider `openrouter/deepseek/deepseek-v4-flash-0731`):
- input tokens 22367, output tokens 6670, cacheRead 375872, cacheWrite 0
- provider total 404909; bucket total 404909 (match)
- reasoning tokens: 2773 (provider-reported; a subset of output, not added)
- cost: input 0.00201303, output 0.0012006, cacheRead 0.006765695999999999,
  cacheWrite 0; provider total 0.009979325999999998
- budget 0.50; no unknown cost fields (unknown_costs 0)
- aggregate for the run: same as the single trial (~$0.010, 404,909 tokens)

## Thinking evidence

23 thinking blocks across 29 turns; provider reported 2773 reasoning tokens.
Thinking text (raw in `session.jsonl.bz2`) shows an ordered discovery path:
query stream stages (`module:fs`, `language:stream`, `language:stream.sort-by`),
then the numeric comparison on `e.size` with `sort-by --desc`, then `take`,
then the `f"${e.size} ${e.path.display()}"` output contract, then the
`parse_int()?` failure control. The compact-runtime error at turn 20 prompted
a correction of the throwaway test rather than of the solution. Reasoning
tokens were reported by this provider, so no estimate was needed.

## Tool-error findings

Structured `tool_errors` for the current worker session (both present, zero
in any manager session — none performed):

1. Turn 5 (bash): `... xsht api api:fs.metadata 2>&1 | head -40; echo ===; xsht api module:fs 2>&1 | grep -i 'args\|main\|argv'`.
   The `api:fs.metadata` query itself returned `status: exact` with the full
   fs.metadata signature. The `Command exited with code 1` came from the
   trailing `grep` finding no `args|main|argv` match in the `module:fs`
   summary, a benign grep-no-match shell artifact.
2. Turn 20 (bash): `xsh th.xsh /tmp/tree2` on a throwaway zero-param
   `proc main()` probe failed with `err[runtime.compact-unsupported-main]`.
   The worker worked around it with `th2.xsh` (invoked without an argument),
   which listed `visible` and `.hidden` correctly, and the fix applied to
   `bigfiles.xsh` (via the 11/4-size tree2 run) confirmed `hidden: true`.

Both are worker-side exploration friction, not product or evaluator defects;
neither affects the passing deliverable.

## Timing evidence

No strict candidate/oracle timing gate for this eval; both sides finish in
milliseconds. Per-case candidate/oracle wall (ns):
- public 12333293 / 11004616 (exact)
- hidden_default 11168201 / 12655044 (exact)
- hidden_n2 16972241 / 11493953 (exact)
- hidden_single 11266702 / 12699920 (exact)
- hidden_deep 12958963 / 12526627 (exact)
- hidden_spaces 13221423 / 13218132 (exact)
- hidden_utf8 13125173 / 11674746 (exact)
- hidden_empty 13216632 / 13131339 (exact)
- hidden_bad_n 13035256 (exit 3) / 13169173 (exit 1), both nonzero, both
  print nothing (exact)

Candidate and oracle agree byte-for-byte on every case; timings are
diagnostic only. Provider telemetry (retry_count 0, provider_errors [],
retry_delay 0) shows no latency confounder; session-span growth is not an
agent-inefficiency signal.

## Observation classification

- Correctness: pass — nine of nine cases byte-exact, including the
  `hidden_bad_n` failure control (candidate exit 3 vs oracle exit 1, both
  nonzero and silent). Not a gate on equal exit codes.
- Restriction: pass — solution uses `fs.files(root, hidden: true)?`,
  `where .kind == "file"`, `sort-by --desc` on `e.size`, `take`, `map` to the
  `<size> <path>` line, `collect`; no subprocess boundary; reference to
  `fs.files` and a `sort-by` stage present, so hard-coding is excluded.
- Tool error 1 (grep exit 1): ordinary noise / worker friction; benign and
  self-resolved.
- Tool error 2 (compact-unsupported-main on a zero-arg throwaway):
  worker friction; one-off, worked around, not a strong reproducible product
  defect this cycle.
- Handbook signal: the worker independently discovered that `fs.files`
  excludes hidden dotfiles by default and that `hidden: true` restores them
  (verified: tree2 listing prints `visible` then `.hidden`). The approved
  handbook's filesystem section does not state this behavior. Real,
  generalizable filesystem behavior; staged as a provisional candidate.
- Evaluator: no failure; output manifests and stdout/stderr all consistent.
- Noise: tree2/tree self-test telemetry and the `hidden true?` probing are
  ordinary exploration, not a defect.

## Handbook decision

Provisional candidate staged at
`runs/run-1786124624556/phases/01-eval/lineage/handbook-candidate.md`
(sha256 not required for the candidate; approved snapshot sha256
3b56a781...e126b). It copies the approved snapshot and adds one general
lesson to "Paths and filesystem values": the walk excludes hidden dotfiles by
default, and `hidden: true` includes them.

Reasoning: this is a short, general rule that removes a repeated-discovery
friction for any future filesystem eval where dotfiles matter, and it
generalizes beyond `task-bigfiles`. It is provisional — validated by one
trial's self-test only, not yet independently replayed — so it must be
replayed by at least one other filesystem/stream eval (e.g. a future
`task-ecount` or `task-bigfiles` re-run against a tree containing dotfiles)
and pass CTO review before promotion to `runtime/handbook.md`. The approved
snapshot and checked-in handbook were not edited.

## Tickets created

None. The two tool errors are benign worker-side exploration, and no strong
reproducible general product or ergonomics defect was established in this
cycle.

## Post-merge decisions

The reconciler found no merged tickets (`none`); there are no post-merge
acceptance assignments. The candidate re-evaluation field is
`not-reevaluation`, so no pre-merge candidate fix was under test.

## Next replay

Replay `evals/task-bigfiles` (same run lineage, XSH commit
1477f472d5b4d57db3584357116ef97c32358ab6) with the provisional
`handbook-candidate.md` snapshot to falsify/confirm the `hidden: true`
lesson; additionally have a distinct filesystem/stream eval (e.g.
`task-ecount` or a future dotfile-inclusive tree) exercise the same claim
before promotion. This is a one-trial run, so the candidate was not replayed
by the controller in this cycle and is not yet trusted.

## North-star impact

The eval validates that XSH's typed filesystem stream (`fs.files`), numeric
`sort-by --desc`, `take` top-N, and `f"${size} ${path}"` output compose into
the canonical disk-hygiene report with byte-exact results and a loud
`parse_int()?` failure control — a genuinely reusable glue idiom rather than
a task-specific hack. The provisional handbook candidate records a general,
learnable filesystem fact (dotfile inclusion) that future agents would
otherwise rediscover, advancing ergonomics and learnability in line with the
XSH rationale.
