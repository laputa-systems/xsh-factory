# Eval-manager report: task-ecount

- Run: `runs/run-1785726325461/phases/03-eval`
- Eval: `evals/task-ecount/EVAL.md`
- XSH commit under test: `ea7dea2f2b436cce34262d7a02105cbb029243dd`
- Approved handbook snapshot: `lineage/handbook-approved.md` (sha256 `c7c9dd9abb6d50dac60562757a1824900f24d4bc2d38014d5cbf869f56bb0723`)
- Trials configured: 1 (controller completed trial 1; no trial 2)
- Executor evidence: `workers/eval-worker/task-ecount-1/` (report.json, run.json, session.jsonl.bz2, ecount.xsh, review.md, candidate.stdout, oracle.stdout)
- Merged tickets: none (reconciler found `none`); candidate re-evaluation: `not-reevaluation`
- Open-ticket snapshot: task-ecount-001..008 Open/Approved, task-envcfg-001 Open, task-tags-003 Open (read for context only)

## Result

pass

Trial 1 passed on correctness (byte-exact stdout match), restriction compliance
(no subprocess boundary used), protocol (artifact and review present), timing
(ratio within gate), and classification. The phase-level `report.json` still
shows `result: fail` only because the controller-owned findings were
`manager-report missing`, `director-report missing`, and `handbook-lineage
missing`; this manager report and the staged `lineage/handbook-candidate.md`
resolve the manager and lineage findings. The director report is outside the
eval-manager role.

## Effort metrics

Trial 1 (`workers/eval-worker/task-ecount-1/report.json`):

- Assistant turns: 53 (stop reasons: 1 `stop`, 52 `toolUse`)
- Tool calls: 73 (bash 68, read 3, edit 1, write 1); tool results 73; user messages 1
- Tool errors (isError=true): 3, all `bash` check/run rejections (see Tool-error findings)
- Thinking blocks: 44
- Session span: 295,543 ms (~4.9 min); worker agent wall 297,295 ms
- Budget: $0.039 of $0.50; budget_state pass
- Invalid `xsht api` discovery queries (isError=false, plain stdout): 4
  (`method:Str`, `method:Path`, `language.core.records`, `language.stream.range`)

Manager review effort: host-file evidence inspection only (read/bash/grep on
the phase artifact tree); no Pi tools launched, no Pi tool errors in the
manager session. Manager turn budget 0.15, wall 900 s per `WORKER.md`.

## Usage and cost

Trial 1 (provider-reported, openrouter/deepseek/deepseek-v4-flash-0731):

- input 55,901 ($0.00503109); output 24,149 ($0.00434682)
- cacheRead 1,659,136 ($0.029864448); cacheWrite 0 ($0)
- reasoning 15,304 (provider-reported; subset of output, not added to totals)
- total bucket 1,739,186; provider total 1,739,186 (match); malformed lines 0
- Total cost $0.039242358; unknown-cost entries 0

Aggregate equals trial 1 because the configured count is 1. No budget failure.

## Thinking evidence

44 thinking blocks recorded; the provider reported 15,304 reasoning tokens.
Raw thinking text is not stored in this session JSONL (thinking blocks carry
empty text), so the blocks are qualitative counts only — do not treat them as
an extractable transcript. Block placement correlates with the recovery path:
each of the three tool errors was followed by a thinking block plus a new
probe, and the worker reached a byte-exact solution without re-planning loops.
Examples: after the `sort-by` composite-key rejection (session line 83), the
worker pivoted to a padded string sort key and validated padding behavior
against the oracle across widths (lines 63–64, 95, 100); after the `max`
display error (line 102), the final artifact used `max)?` plus `byte_len()`.

## Tool-error findings

All three nonzero structured tool results from the worker `report.json` are
accounted for; each is a `bash` invocation of `xsht check`/`xsh` on a scratch
script that returned exit code 2 (session lines 83, 85, 102):

1. turn 30 — `sort-by { |r| [r.n, r.ext] }` rejected:
   `err[check.type-mismatch] expected Int, found Str` and
   `err[check.stream-sort] sort-by keys must be Int, Str, Bool, or Path`.
   Recoverable: clear diagnostic; worker moved to a padded-string key.
2. turn 31 — group-by record shape guessed wrong:
   `unknown method keys on List[Record]`, `expected Record, found List`,
   `unknown method len on Record` (note lists only `get()`). Recoverable:
   worker printed the group record and confirmed fields `keys0 items,key`
   (line 93).
3. turn 39 — `Str.len()` rejected (`unknown method len on Str`, note lists
   `byte_len()`, `count_bytes()`, `count_chars()`), plus
   `value cannot be displayed by print` for a `Result` from `max`.
   Recoverable: worker used `byte_len()` and `?`.

No other failed Pi tool results exist in the current evidence packet. The four
invalid `xsht api` discovery queries (`method:Str`, `method:Path`,
`language.core.records`, `language.stream.range`) returned plain stdout with
`isError=false` (lines 39–40, 76, 98); they are discovery friction, not
structured tool errors, and are classified below. Manager sessions: no Pi tool
errors (None for the manager side).

## Timing evidence

Evaluator manifest (`run.json`, trial 1):

- candidate wall 11,854,549 ns (~11.85 ms); user 1,072,000 ns; system 4,290,000 ns
- oracle wall 11,753,216 ns (~11.75 ms); user 756,000 ns; system 5,261,000 ns
- ratio 1.0086 — inside the strict 0.90..1.10 gate; evaluator timing `pass`

Both processes are sub-12 ms, so process-launch noise is plausible, but the
measured ratio is comfortably inside the contract; no timing failure to
separate from correctness. Session span (~295 s) is the agent conversation
clock and is not the candidate/oracle clock.

## Observation classification

- `sort-by` composite-key rejection (isError #1): ordinary recoverable
  friction with a helpful diagnostic. Related to ticket task-ecount-003's
  subject; at this commit (`ea7dea2`) the failure is loud, not the silent
  no-op that 003 documented at `a66ade82`. No new ticket.
- `group-by` shape discovery (isError #2 plus 4 discovery probes): product/
  tooling defect class already tracked by ticket task-ecount-001 — reproduced
  at this commit: `xsht api language:stream.group-by --format jsonl` still
  returns `"signatures":[]` with `example:null` (session line 89), forcing
  empirical discovery of the `{key, items}` record shape. Not new.
- `Str.len()` rejection and `max` display error (isError #3): ordinary
  recoverable friction; the compiler note lists the correct alternatives and
  the handbook's `?`-propagation pattern is documented. No new ticket.
- Path-from-Str construction and `xsht api` constructor naming (≈8 tool calls,
  lines 38–62): repeated discovery friction. The queries
  `api:Path.parse_bytes` and `method:Path_constructor.parse_bytes` are
  "missing" while `method:Path.parse_bytes` and `search:parse_bytes` resolve
  exactly; the worker reached the working pattern only after several probes.
  Classification: reusable handbook gap (no documented Str→Path conversion)
  plus a mild api-naming wart. The handbook candidate addresses the durable
  part; the wart is subsumed by ticket task-ecount-001's api-discoverability
  class and is not a new strong product defect.
- Map accumulator typing (`map.empty()` is `Map[Any]`, `Map.get` fallback is
  `Any`): product/tooling defect class already tracked by ticket
  task-ecount-004 and the fold issue by task-ecount-007; worker sidestepped
  with `group-by` + `items.len()`. Not new.
- Timing ratio 1.0086, zero budget failures, one clean stop: ordinary noise
  free; no harness or image mismatch observed (image `0ed5aa61…` served the
  task correctly).

## Handbook decision

provisional candidate staged at `lineage/handbook-candidate.md`.

Change (one inserted rule in `Paths and filesystem values`):

> To build a Path from a runtime string (such as a CLI argument), convert
> explicitly with `Path.parse_bytes(bytes.from_text(s))`; the pinned image has
> no `Str.to_path` conversion.

General lesson: when a task supplies a filesystem root as a CLI string, the
agent should convert Str→Path directly instead of re-discovering the
constructor across `xsht api` variants. This is the longest repeated-discovery
sequence in the session (≈8 tool calls, lines 38–62) and is a general language
fact, not an ecount recipe. The approved snapshot is unchanged; the candidate
is provisional until replay and human review.

Replay scope: task-ecount against the same oracle plus a nearby filesystem
case, and any future eval that passes a path string as a script argument;
promote only after at least one replay confirms the sentence removes the
discovery loop.

## Tickets created

zero.

Rationale: the three structured tool errors are recoverable check-time
rejections with helpful diagnostics; every underlying product defect surfaced
this cycle (empty `language:stream` signatures, scalar-only `sort-by` keys,
`Map[Any]` accumulator typing, `fold` parsing) already has an open ticket
(task-ecount-001, -003, -004, -007), and the strongest reusable gap (Str→Path
conversion) is addressed by the handbook candidate rather than a product
change. No new strong reproducible product defect warrants a next-cycle
ticket.

## Post-merge decisions

None. The reconciler found no merged ticket files for this cycle
(`merged tickets: none`), and the candidate ticket is `not-reevaluation`, so
there are no post-merge acceptance assignments and no revert proposals.

## Next replay

Replay `task-ecount` (same eval and oracle) at the next XSH main commit using
this run's lineage: approved `handbook-approved.md` `c7c9dd9a…`, candidate
`handbook-candidate.md` `385e6673…` (sha256 of the staged candidate). Verify
that (a) the Str→Path conversion sentence removes the discovery loop, and
(b) whether `language:stream.group-by` signatures still arrive empty — a
falsification check for ticket task-ecount-001 if its fix merges. Also
confirm the phase's remaining `director-report` finding is resolved by the
director role, since the phase currently marks `fail` on missing narratives
only.

## North-star impact

This run demonstrates the handbook + `xsht api` + `xsht check` loop is
practical at the current upper-bound difficulty: a single agent produced a
byte-exact, no-subprocess XSH program in 53 turns with three self-recoverable
errors and a 1.009 candidate/oracle ratio — no hard-coded answer, and oracle
runs were limited to permitted local verification (the handbook explicitly
allows running the evaluator's oracle from the gym). The residual friction (Str→Path conversion, group-by shape,
scalar-only sort keys, Map accumulator typing) is precisely the learnability
and ergonomics surface the factory should reduce next: each item maps to one
concise handbook rule or one already-ticketed api/language fix. Lowering that
discovery cost directly serves the north-star AI-efficiency goal without
trading correctness, and the staged candidate is the smallest general rule the
evidence supports.
