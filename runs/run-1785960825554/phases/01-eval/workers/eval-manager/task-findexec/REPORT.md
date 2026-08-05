# Eval-manager report

## Result

pass

## Effort metrics

Single-trial run (`trial 1`, worker `eval-worker/task-findexec-1`). Worker
recorded 34 assistant turns, 40 tool calls (33 `bash`, 3 `read`, 4 `write`),
and 6 tool errors (`warning` severity findings). Session span 257,558 ms
(≈4.3 min); `agent_wall_ms` 258,938 ms. The worker reached a correct,
restriction-clean artifact after a normal discovery loop; the 6 errors were
clustered around two recurring language frictions (boolean symbol operators
and `if` as a bare map tail), not around random exploration. Worker friction
is low-to-moderate overall and is attributed to product ergonomics rather than
provider health (see Usage/Timing).

## Usage and cost

Provider: `openrouter/deepseek/deepseek-v4-flash-0731`, `thinkingLevel: high`,
1 user message. Token buckets (provider-reported): input 30,957; output
13,045; cacheRead 740,096; cacheWrite 0; bucket total 784,098;
provider_total_tokens 784,098 (buckets reconcile exactly). Cost: input
$0.002786; output $0.002348; cacheRead $0.013322; cacheWrite $0; total
$0.018456 (≈3.7% of the $0.50 budget). Budget state: pass. `reasoning` tokens
7,569 (subset of output, not added to totals) and 29 thinking blocks were
reported by the provider.

`provider_telemetry` is present with zero retries, zero provider errors, and
zero retry failures; `response_elapsed_ms` and `output_tokens_per_second` are
0/unpopulated. No external-health signal; latency attribution is `unknown` for
wall-clock purposes and the efficiency judgment below rests on turns, tokens,
tool errors, and artifact quality.

## Thinking evidence

29 thinking blocks recorded (provider reported `reasoning` 7,569 tokens).
Thinking advances were grounded in the API contract: the agent queried
`api:fs.files`/`api:fs.walk` (discovering the typed `owner_executable`,
`kind`, and `path` fields), `language:stream.sort` (byte lexicographic stable
Path ordering), and `search:hidden` (needing `hidden: true`). The reasoning
correctly reasoned about relative-vs-absolute oracle output and verified
empirically with local fixtures against the `find ... | sort` oracle. Two
thinking threads document a genuine product ergonomics investigation:
`if`/`else` as a map tail (turns 55/57, concluding it only works as a `let`
RHS) and the `Path.relative_to` contract/signature mismatch (turn 47). These
match the review.md findings.

## Tool-error findings

All 6 structured tool errors from `eval-worker/task-findexec-1/report.json`
are accounted for:

1. Turn 9 (`bash`, exit 2): `&&` in a `where` predicate rejected —
   `err[parse.unsupported-boolean-operator]: use 'and' instead of '&&'` plus
   cascading expected-token errors. Agent corrected to `and` at turn 27.
   Classified: handbook gap (boolean word forms untaught).
2. Turn 12 (`bash`, exit 1): invalid discovery query `api: module.path.absolute`
   printed "---all Path methods---" with no result. Classified: agent
   API-discovery query-form gap; recovered promptly, low signal.
3. Turn 18 (`bash`, exit 1): `xsht check` failed with
   `err[check.try-result]: '?' can be applied only to Result values` on
   `Path.relative_to`, `err[check.map-tail]: map requires a tail value` on
   `|> map { |e|`, and `err[check.stream-sort]`, plus a diff showing empty
   candidate output. Classified: product/tooling (relative_to contract
   mismatch) + product/tooling (if tail asymmetry).
4. Turn 19 (`bash`, exit 2): `map-tail` and `stream-sort` check errors recurred
   after editing. Classified: product/tooling (if tail asymmetry).
5. Turn 21 (`bash`, exit 2): `map { |n| if ... }` in `/tmp/iftest.xsh` failed
   with `map requires a tail value`. Classified: product/tooling (if tail
   asymmetry); one of several probes establishing the defect.
6. Turn 26 (`bash`, exit 1): `xsht fmt` OK but `xsht lint` exited 1 on two
   warnings (prefer `fp"..."` over `Path(...)`; redundant `.display()`); agent
   resolved both, resulting in the final clean artifact. Classified: ordinary
   tooling behavior, not a defect.

No failed Pi tool result in the manager session; `None.` applies there.

## Timing evidence

This eval has no strict candidate/oracle timing gate (`EVAL.md`: "timing is
diagnostic until a stable envelope is established"). `run.json` records only
correctness/protocol/restrictions and does not publish a candidate vs oracle
timing ratio. The worker ran a `time xsh findexec.xsh /usr/share` comparison
(turn 67) that matched the oracle byte-for-byte; exact elapsed figures are not
in the structured packet, so no ratio is asserted. Timing is diagnostic, not a
gate here.

## Observation classification

- **Correctness/restriction (pass):** `run.json` exact=true, restrictions
  passed, protocol (artifact present, review_ok) passed across the evaluator's
  fixture classes (hidden dotfiles, owner-vs-group/other execute, nested dirs,
  symlink exclusion, empty negative control). The final `findexec.xsh` uses the
  typed `owner_executable` field, `hidden: true`, word-form `and`, and
  `sort` for byte order. This honors the north-star hypothesis: the typed
  metadata boundary and the `hidden` option were discovered and trusted.
- **Handbook gap (reusable):** the `&&`→`and` parse rejection cost one error
  and is a general learnability fact the current handbook omits. Staged as a
  provisional handbook candidate (see Handbook decision).
- **Product/tooling defect (reusable):** `if`/`else` not accepted as a bare map
  tail (errors at turns 18/19/21) is a general ergonomics asymmetry, distinct
  from the boolean-operator lesson. Opened as ticket `task-findexec-001`.
- **Product/tooling (secondary):** `Path.relative_to` contract says it errors
  when the path is not below base, yet its signature returns `Path` (not
  `Result[Path, Error]`), so postfix `?` is rejected. Flagged in review.md;
  recorded here but not opened as a second ticket (one strong reusable ticket
  per guidance). Candidate for a future ticket if confirmed independently.
- **Ordinary noise:** turn 26 lint warnings are correct tool behavior; turn 12
  invalid api query is a low-signal agent discovery miss.
- **No worker-efficiency regression:** 34 turns / 40 tools / 6 errors /
  ≈4.3 min for a correct result is reasonable; the error density traces to the
  two product frictions above, with provider telemetry clean.

## Handbook decision

Provisional candidate staged at
`runs/run-1785960825554/phases/01-eval/lineage/handbook-candidate.md`
(approved snapshot copied + one addition). The lesson: **XSH boolean
combination uses the word forms `and`/`or`; C-style `&&`/`||` are rejected at
parse time.** This is a short, general, reusable rule that removes a parse
error any predicate-writing agent would otherwise hit. It is global (not
eval-specific) and is promoted only after review and replay. Replay scope: a
fresh `task-findexec` run and one predicate-heavy eval (`task-histogram` or
`task-tags`) must both confirm no `&&` parse error before promotion to
`runtime/handbook.md`. The `if`-tail asymmetry is intentionally a ticket, not
a handbook recipe, because it is a language defect to fix rather than a
workaround to teach.

## Tickets created

- `tickets/task-findexec-001.md` (Open., product) — `if`/`else` as a first-class
  expression usable in a stream block tail. Links eval, manager run, executor
  run/session, handbook lineage, and XSH baseline `1cf4ad3d...7e5e7c4`.
  Merge-record placeholders left unchanged.

## Post-merge decisions

The reconciler supplied no merged ticket files (`none`). There are no
post-merge acceptance assignments; no decision required. The candidate
re-evaluation field is `not-reevaluation` (no pre-merge engineer validation).

## Next replay

Replay `task-findexec` on this handbook lineage after CTO review of
`handbook-candidate.md`, and in parallel re-run one predicate-heavy eval
(`task-histogram` or `task-tags`) against the candidate to falsify the
boolean-word-form rule before promotion. Separately, after `task-findexec-001`
is merged, replay `task-findexec` to confirm the conditional pipeline builds
without "map requires a tail value".

## North-star impact

This run is direct evidence for the eval's hypothesis: an agent with the typed
fs stream cleaned up correctly and produced a working owner-executable-file
finder without subprocesses, confirming the typed permission boundary is
learnable and trustworthy. It also produced two learnable/ergonomic signals
for the shared line of work: a concise handbook rule (boolean word forms) that
removes a parse trip for every future predicate, and a real ergonomics defect
(`if` as a block tail) whose fix would streamline pipeline authoring across
all stream-based evals — both consistent with the north-star goals of
learnability, agent efficiency, and an explicit, humane language surface.
