# Eval-manager report

## Result

pass

## Effort metrics

Single trial (`task-colsum-1`) executed against candidate commit
`a1cbb632d1ab8673176f6ef9f9d9cf04a7ad5e02` (clean engineer worktree for ticket
`task-colsum-002`, confirmed by `xsh-build.state` build-id
`a1cbb632d1ab8673176f6ef9f9d9cf04a7ad5e02-v1987f51dd994433c` and the worker
`report.json`). Worker session: 24 assistant turns, 33 tool calls (29 bash, 3
read, 1 edit), 33 tool results, 2 tool errors (turns 8 and 9, both on
standalone probe scripts `/tmp/t1.xsh`, `/tmp/t2.xsh`), 1 user message, 22
thinking blocks. Session span 58.1 s (agent wall 59.6 s). Worker friction:
low — the two errors were the worker's initial `?`-context and `print`
display-conversion probes, resolved within two turns without repeated
exploration; the worker then used the previously-failing pipeline shapes
(`where { |e| e.value == header }` over `enumerate()`, `first()?`, plain
receiver `split(",")`) directly and they compiled and ran. Protocol,
restrictions, artifact, and review all pass. No attempt 2; configured count is
1.

## Usage and cost

Provider: `openrouter/deepseek/deepseek-v4-flash-0731`. Worker buckets:
input 19,266; output 7,094; cache-read 264,448; cache-write 0;
provider-total 290,808; bucket total 290,808 (match). Reasoning tokens 3,188
(reported, subset of output; not added). Cost: input $0.00173394, output
$0.00127692, cache-read $0.00476006, total $0.00777092. Budget $0.50; no
budget breach, no unknown costs. Provider telemetry present: retry_count 0,
provider_errors empty, so latency attribution is provider-clean (no external
retry confounder); no provider switching considered.

## Thinking evidence

22 thinking blocks in the worker session; provider reported 3,188 reasoning
tokens. The transcript shows the worker reasoning deliberately: it read the
handbook and agents.md first, discovered exact APIs via `xsht api` (fs.read_text,
Str.split, List.get, language:stream, stream.fold, stream.enumerate, stream.first),
then planned the column-locate + typed-parse + fold solution before writing the
artifact. Thinking correlated with behavior: after the first two `?`-context /
print errors it correctly concluded main must return `Result` and values must
be bound before `print`. The worker used the block-parameter `where { |e| ... }`
over `enumerate()` and `first()?` without any desugar/proc-command error —
the exact shapes the ticket flagged — and did not enter an empirical discovery
loop.

## Tool-error findings

Two structured tool errors, both in the current worker session, both standalone
probe scripts (not the submitted artifact):
1. turn 8 (`/tmp/t1.xsh`): `?` requires a Result-returning context
   (`fs.read_text(...)?`, `lines.get(0)?`) plus `print $cols.get(0)?` display/
   try-result failures — main had not been declared `-> Result[Int]`.
2. turn 9 (`/tmp/t2.xsh`): `print $cols.get(0)?` / `.get(1)?` display-conversion
   and try-result failures on the same unbound-Result probe.

Both are the worker's ordinary onboarding probes for `?`-context and
print-display semantics, resolved by turn 10 by declaring `-> Result[Int]` and
binding values before `print`. No `pipeline sugar was not desugared` and no
`unresolved proc command` appear anywhere in this session (verified by grep),
confirming the candidate desugar fix removed the failure modes the ticket
described. No invalid `xsht api` discovery-query errors occurred; all `xsht
api` queries matched (module:fs, method:Str.lines, method:Path.lines,
method:Str.fields, method:List.get, method:Str.split, language:stream,
language:stream.fold, language:stream.enumerate, language:stream.first,
search/read). Manager session produced no structured tool errors this run.

## Timing evidence

No strict candidate/oracle timing gate; eval contract is byte-exact stdout
comparison with timing diagnostic only. All nine cases passed exact together
with candidate and oracle both finishing in ~11–16 ms wall. Candidate the
marginally slower on most cases (e.g. hidden_extra_cols candidate 11.657 ms vs
oracle 11.110 ms; hidden_many candidate 11.402 ms vs oracle 12.147 ms) with
no consistent direction and no ratio gate, so timing is ordinary noise.
Worker session span and candidate timing are separate clocks and are not
conflated.

## Observation classification

- Correctness: all 9 evaluator cases exact (7 passing cases byte-exact, two
  failure controls both nonzero with no stdout; candidate exit 3 vs oracle 1/2
  on controls, both treated as "exact" because the contract is nonzero/no
  output). Evidence: `run.json`.
- Candidate fix validated (reusable): the previously-failing pipeline desugar
  shapes (`where { |e| e.value == ... }` block param, `first()?` Result tail,
  plain-receiver `split(",")`) now compile and run without a discovery loop.
  This converts the ticket's trial-and-error friction into direct use:
  correct-first-time pipeline authoring. This is the ticket's primary
  acceptance criterion and it is met.
- Worker friction (minor, ordinary): the two `?`-context/print-display probes
  and two `review.md` notes (`match` reserved-word parse error; `collect()`
  terminal cannot be followed by `fold()` in the same pipeline). These are
  single-session onboarding observations, quickly resolved, candidate-agnostic,
  and not strong enough to justify a new ticket this cycle.
- No image/harness mismatch (image `sha256:8d47...`, linux/arm64, restrictions
  pass, no forbidden subprocess boundary in `colsum.xsh`).
- Evaluator behaved correctly; no evaluator failure.

## Handbook decision

Unchanged. The staged candidate (`lineage/handbook-candidate.md`) is a byte
copy of the approved snapshot (sha256 `3b56a781...`, identical to approved).
Rationale: this run's pipeline desugar resolution is a product-fix effect from
the unmerged candidate commit, not an agent-handbook gap — the worker authored
pipelines directly with no handbook friction, so there is no new reusable
handbook lesson this run. The candidate's API-reference/documentation change
(SPEC.md, STREAMS.md) belongs to the product docs and is not yet merged; the
shared handbook should not teach the new desugar contract until the commit is
merged and replayed by another stream eval. Replay scope: a later stream eval
(see Next replay) before any handbook promotion.

## Tickets created

None. The candidate fix is the subject of the pre-merge validation for the
existing open ticket `task-colsum-002`; no new reproducible product defect rose
to the one-strong-observation bar this cycle. The two `review.md` notes are
single-session onboarding observations and are classified as noise, not tickets.

## Post-merge decisions

None. The reconciler found no merged tickets for this run (`none`), and ticket
`task-colsum-002` remains `Approved.`/open as a candidate. This phase is a
pre-merge validation of the clean engineer worktree, not a post-merge
acceptance, so the candidate is not marked merged and no implementation commit
is recorded in the merge record (placeholders untouched).

## Next replay

Replay `task-colsum` (and ideally one additional stream eval such as
`task-groupsum` or `task-tags`) on the merged implementation commit of ticket
`task-colsum-002` to confirm the desugar fix holds after merge, then decide
whether to teach the value-pipeline desugar contract (plain receiver,
Result-returning tail `?`, block-parameter `where`) in the shared handbook
lineage. Before any promotion, confirm the merged commit is an ancestor of the
XSH commit under test and that a fresh trial resolves the same shapes without a
discovery loop.

## North-star impact

This pre-merge validation provides evidence that the ticket's proposed XSH
change serves a core north-star goal: ergonomic, learnable pipelines. The
worker authored the previously-broken shapes directly and correctly on the
first attempt, with no `pipeline sugar was not desugared` / `unresolved proc
command` discovery loop, in only 24 turns and 2 onboarding errors. That is a
concrete reduction in agent exploration and token spend for stream-based
systems glue, and it generalizes across the whole stream-eval family, not just
`task-colsum`. The result is trustworthy: the candidate was built cleanly,
all nine evaluator cases passed byte-exact with no restriction or protocol
violation, and provider telemetry shows no retry confounder.
