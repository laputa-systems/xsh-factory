# Eval-manager report

## Result

pass

## Effort metrics

One controller-executed fresh trial (`task-envcfg-1`) against the approved
handbook snapshot `lineage/handbook-approved.md` (sha256 `97c5d804...`) and XSH
commit `c2402341d7f3cf29b504ca8c22b89be2cf7a3eba`.

Worker `task-envcfg-1`:
- assistant turns: 52
- tool calls: 52 (42 bash, 4 edit, 4 read, 2 write)
- tool results: 52
- tool errors: 4 (all worker-side; see Tool-error findings)
- user messages: 1
- stop reasons: 51 toolUse, 1 stop
- session span: 243,763 ms (~4.1 min); agent wall 245,352 ms
- worker friction: moderate. The worker explored the strict-decimal
  validation problem heavily (parse_int/env.int leniency, no generic
  Error constructor, no require/assert guard); this drove a large share of
  the 52 turns and 4 tool errors. No restart, budget breach, or agent-state
  issue (agent_state pass, budget_state pass).

## Usage and cost

Provider: openrouter; model `openrouter/deepseek/deepseek-v4-flash-0731`.
Budget per worker: $0.50.

Worker `task-envcfg-1` token buckets (provider-reported):
- input: 41,229
- output: 19,508
- cacheRead: 985,920
- cacheWrite: 0
- provider totalTokens: 1,046,657; bucket total also 1,046,657 (no mismatch)
- reasoning tokens: 11,974 (provider-reported; a subset of output)

Cost (provider-reported):
- input $0.00371061, output $0.00351144, cacheRead $0.01774656,
  cacheWrite $0, total $0.02496861
- unknown costs: 0

Aggregate (1 trial): $0.02496861, 1,046,657 bucket tokens, budget failures 0.

## Thinking evidence

43 thinking blocks recorded in the worker report; provider reported 11,974
reasoning tokens. Thinking text in the canonical session JSONL shows the worker
spent a large fraction of its deliberation on strict decimal validation:
discovering that `Str.parse_int()` is lenient (signs, whitespace, hex, leading
zeros), that `env.int` rejects out-of-range but still accepts `-5`/`+5`/` 5`,
and that there is no strict `[0-9]+` validator and no generic `Error`
constructor or `require`/`assert` guard. It converged on the sentinel
`"".parse_int()?` failure trigger after those probes. The reasoning-token count
is provider-reported and therefore a lower bound for deliberation; thinking
text is qualitative evidence, not an exact token fraction.

## Tool-error findings

Four nonzero Pi tool results; all four are worker-side friction, none is an
XSH product defect, and none prevented a passing result:

1. turn 3 (bash): `xsht api api:env.get ... && xsht api api:fs.write ...`
   printed exact matches for both queries but the compound command exited 1.
   The final `grep -i example` upstream (per raw session, turn 3 at line 8)
   found no `example` line in `env.get_or`, making grep exit 1 after the
   successful api queries. Classification: worker friction / ordinary
   noise, not a discovery failure — the `env.get` and `fs.write` results were
   exact and correct.
2. turn 39 (edit): "Could not find the exact text in /work/envcfg.xsh" — the
   targeted edit did not match the current file (reformatted). Worker friction;
   resolved by reading the file and editing again. No product signal.
3. turn 44 (bash): a self-authored `/tmp/harness.sh` had a shell syntax error
   (`eval: line 4: syntax error: unexpected ";"`) and the first harness run
   mis-simulated the oracle; the harness was rewritten and succeeding attempts
   (later block at turn 45) matched the oracle across many cases. Worker
   friction / prototype noise.
4. turn 48 (bash): final verification command reported exit 1 only because the
   closing `ls /tmp/out3.cfg` correctly found no file (the intended failure
   control) — the tool exited nonzero on the expected-absent file. Worker
   friction; the underlying behavior (no file, nonzero exit) is exactly what
   the task and evaluator require.

No tool error reflects an invalid `xsht api` discovery query; the only
nonzero discovery-adjacent event (turn 3) returned exact results.

## Timing evidence

This eval has no strict candidate/oracle ratio gate (EVAL.md: "timing is
diagnostic"). All cases run in milliseconds:
- candidate wall ns: 10,951,494 – 14,149,093
- oracle wall ns: 11,074,410 – 14,298,409
- per-case candidate/oracle spread is small and within the same millisecond
  band; no case crosses a meaningful ratio. Candidate and oracle both finish
  in ~11–14 ms, so timing is ordinary noise here and is not a product signal.

## Observation classification

- Correctness: pass. All ten cases exact, including both failure controls
  (hidden_malformed, hidden_empty_port) where candidate and oracle both exit
  nonzero and the candidate writes no file. `evaluator.stdout` =
  "task-envcfg evaluation passed".
- Restrictions: pass. `env_referenced: true`, `forbidden_operations: true`,
  no subprocess escape, stdout empty.
- Protocol/reporting: pass. Artifact present, `review.md` present with both
  required headings and no template placeholders.
- Worker friction (reusable signal): the strict-decimal validation gap
  (`parse_int`/`env.int` leniency, no strict `[0-9]+` validator, no
  `Error(...)` constructor, no `require`/`assert` guard) consumed a large
  share of turns and thinking. This is a genuine, repeatable discoverability
  friction that generalizes beyond task-envcfg (any eval needing a
  byte-exact numeric/config contract). It is a handbook-guidance signal more
  than a product defect — the handbook already says typed helpers are "not
  strict format validators, so byte-exact decimal ... contracts must be
  checked explicitly," but it does not teach the concrete idiom (regex
  `^[0-9]+$` match + sentinel `?` failure trigger) that the worker only
  reached after trial and error.
- Worker friction (noise): the four tool errors above were self-inflicted
  harness/edit/verification issues, ordinary prototyping noise.
- Product/tooling note (not a ticket here): the review.md proposes a strict
  unsigned decimal parser and a `require(cond, msg)` guard. This is a
  plausible ergonomics proposal but is already mitigated by expressible regex
  + `?`; it is surfaced for the next cycle and does not warrant a same-cycle
  ticket from a single passing trial.
- Harness metadata quirk (not a failure): `run.json` reports
  `candidate_sha256` as the empty-string hash `e3b0c442...` while the actual
  artifact `envcfg.xsh` is 638 bytes (`c9519645...`). The evaluator records a
  hash of candidate stdout (empty), not of the artifact file — cosmetic and
  consistent with the deliverable being the written file, not stdout.
  Candidate/oracle output comparison is byte-exact and authoritative, so this
  field is not used for correctness.

## Handbook decision

Provisional candidate staged at
`lineage/handbook-candidate.md` (approved snapshot copied forward with two
concise additions). General lessons:
1. Strict byte-exact decimal contracts are not served by `parse_int`/`env.int`
   (leniency: signs, whitespace, hex, leading zeros); validate the raw string
   with `regex.compile("^[0-9]+$")?` and, on match failure, propagate an
   expected error via a deliberately-rejected typed conversion (e.g.
   `"".parse_int()?`).
2. `not` is not a negation keyword (`== false` instead); Result match arms use
   parenthesized patterns; Error values cannot be interpolated into display
   strings.

Replay scope: this is a one-trial plan; the candidate is provisional and is
NOT claimed as validated by replay (the controller executed one trial). It
must be replayed across the shared handbook lineage — primarily task-envcfg and
any future eval with a byte-exact config/numeric contract — before promotion to
`runtime/handbook.md`. The environment/config section already carried the
general "typed readers are not strict validators" rule and that part is
confirmed; the concrete regex+`?` idiom is the new guidance to replay.

## Tickets created

None. All four tool errors were worker-side noise, the run passed all gates,
and the strict-decimal/require-guard observations are a handbook-guidance
signal already addressed in the provisional candidate rather than a
reproducible XSH product defect warranting a same-cycle ticket.

## Post-merge decisions

None. The reconciler staged no merged tickets, so no post-merge acceptance
assignment applies to this cycle's XSH commit.

## Next replay

Replay `task-envcfg` (one trial, same XSH commit `c2402341...`) against the
provisional `lineage/handbook-candidate.md` on the shared handbook lineage to
confirm the strict-decimal idiom removes the `parse_int`/guard exploration
friction and still passes all ten cases. A second, independent eval that
requires a byte-exact numeric/config contract would strengthen the candidate's
generality before promotion; if a later replay shows the sentinel `?` idiom is
task-specific or harmful, falsify and revert the candidate.

## North-star impact

task-envcfg probes the environment/config surface that no prior approved eval
covered (typed env reads, byte-exact file delivery, loud malformed-value
failure). A handbook-and-agent-only run passed all ten cases including the two
failure controls, confirming that the `env`/`fs` modules, `get_or` absence-only
defaulting, and Result/`?` propagation are discoverable and composable from the
handbook. The one durable, reusable signal — that byte-exact decimal contracts
require an explicit regex + `?` sentinel rather than the lenient typed readers
— becomes concise handbook guidance that removes repeated agent trial-and-error
for any future config-validation or exact-numeric eval. The run advances
learnability (concrete strict-validation idiom), ergonomics (fewer turns spent
rediscovering parse leniency), and trust (a reproducible, exact-output config
shape with a correct failure control) in line with the XSH mission.
