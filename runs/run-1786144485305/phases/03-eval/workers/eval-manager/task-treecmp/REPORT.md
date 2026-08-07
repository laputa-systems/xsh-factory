# Eval-manager report

## Result

pass

## Effort metrics

Single fresh trial (`task-treecmp-1`) against approved handbook snapshot
`lineage/handbook-approved.md`
(sha256 `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b`),
XSH commit `a248267612439dfcfa203fba583ac3e95d37f70c`.

- assistant turns: 56
- tool calls: 68 (63 bash, 1 edit, 4 read)
- tool results: 68
- tool errors: 0 (structured `tool_errors` arrays empty)
- thinking blocks: 47
- session span: 244418 ms (~244 s)
- stop reasons: 1 `stop`, 55 `toolUse`

Worker friction: moderate but productive. The agent followed the documented
`xsht api` discovery path, issuing many small API queries (fs, stream stage,
method:Map, method:Path, Str/Int conversions) before assembling the program.
No repeated tool failures, no dead-end loops that would indicate a harness or
provider problem.

## Usage and cost

From worker `report.json` (provider-reported buckets, deepseek-v4-flash):

- input: 45210
- output: 15590
- cacheRead: 1164416
- cacheWrite: 0
- reasoning (provider-reported): 8393 (subset of output)
- total bucket / provider total: 1225216
- budget_usd: 0.5 (budget_state pass)
- cost_usd: 0.027834588
  - input_cost: 0.0040689, output_cost: 0.0028062,
    cache_read_cost: 0.020959488, cache_write_cost: 0
- malformed_lines: 0, unknown_costs: 0

Aggregate = the single trial. No budget breach. Well under budget.

## Thinking evidence

47 thinking blocks recorded; provider reported 8393 reasoning tokens (subset of
output, not added to totals). The transcript shows a deliberate, well-ordered
investigation: parsing manifest through `fs.read_text`, validating each line
(via `split`, `byte_len`, `delete`, and `parse_int` for the decimal-size
gate), deriving relative paths with `Path.relative_to`, building `Map` values
via `map.empty()` + `set`, classifying missing/changed/extra, and sorting the
deviation lines. The agent correctly reasoned through the failure-control
contract (nonzero exit + empty stdout for missing/malformed manifest) and
hand-verified the malformed and missing-manifest cases before finishing, which
the run.json confirms (exit 3, empty stdout, byte-exact).

The dominant discovery effort in the reasoning transcript was language-shape
learning: no Map literal (`map.empty()`), no `for` loop (stream-stage
accumulation into an outer `var`), boolean word operators `and`/`or`, and the
`method:` vs `api:` query prefix. All were resolved correctly; none blocked
completion.

## Tool-error findings

None.

Both the worker and the phase `report.json` report `tool_errors: []` and the
manager session has no tool calls. There are no failed Pi tool results and no
invalid `xsht api` discovery queries recorded as structured tool errors in the
current evidence packet. (The review notes that `api:method:Path.display` is
rejected in favor of `method:Path.display`, but this surfaced as a one-line
self-correction in the transcript, not a registered tool error.)

## Timing evidence

No strict candidate/oracle ratio gate for this eval (both sides finish in
single-digit-to-low-tens of ms). Candidate/oracle wall-clock per case are
diagnostic only:

- public: 16.25 / 14.78 ms
- hidden_all_ok: 15.40 / 17.24 ms
- hidden_missing: 12.50 / 15.32 ms
- hidden_changed: 13.40 / 14.49 ms
- hidden_extra: 14.53 / 13.02 ms
- hidden_combined: 13.49 / 13.05 ms
- hidden_empty_tree: 13.11 / 13.60 ms
- hidden_empty_manifest: 14.72 / 25.02 ms
- hidden_spaces: 13.00 / 24.33 ms
- hidden_utf8: 13.47 / 16.06 ms
- hidden_missing_manifest: 14.75 / 13.88 ms (candidate exit 3, oracle exit 1;
  both nonzero)
- hidden_bad_manifest: 14.40 / 14.27 ms (candidate exit 3, oracle exit 1)

All 12 cases byte-exact. Failure-control exit codes differ in value (3 vs 1)
but the contract only requires nonzero, so this is compliance, not a defect.

## Observation classification

- Correctness: PASS. All 12 cases byte-exact; both failure controls exit
  nonzero with empty stdout. Strong, durable signal.
- Restrictions: PASS. No subprocess boundary; traversal via `fs.files`, manifest
  via `fs.read_text`, relative path derived (not from a field). review.md
  preserves both headings, no placeholders.
- Reusable handbook guidance (signal): the session's main effort was discovering
  three general XSH idioms not stated in the handbook snapshot — no Map literal
  (`map.empty()`), no `for` loop (stream accumulation into an outer `var`), and
  boolean word operators `and`/`or` (`&&`/`||` parse-error). These are
  language-level, reusable across any map/iteration/conditional eval, not
  treecmp-specific.
- Ordinary noise / not a defect: the `method:` vs `api:` prefix subtlety
  (self-corrected in one step; handbook already shows `method:` correctly) and
  the absence of a generic `Error(...)` constructor are known, pre-documented
  product realities in this build, not new observations worthy of a ticket this
  cycle. No product/tooling defect ticket is justified from this single clean
  run.
- External health: provider telemetry present with retry_count 0,
  provider_errors [], retry_errors []. `output_tokens_per_second` and
  `response_elapsed_ms` are 0 (client-side fields not populated),
  so external latency attribution is essentially unknown; there is no
  provider-health concern and no reason to attribute wall time to latency.

## Handbook decision

Provisional candidate staged. The approved snapshot is unchanged; a candidate
was written to
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786144485305/phases/03-eval/lineage/handbook-candidate.md`
(sha256 differs from approved), adding three short, general rules:

1. No Map literal — `{"a": 1}` is a Record; create an empty map with
   `map.empty()` and add with `set` / check with `has`.
2. No `for` loop — iterate via stream stages and accumulate into an outer
   `var`.
3. Boolean logic uses word operators `and`/`or`; `&&`/`||` cause a parse error.

These are general XSH idioms that reduce repeated discovery across all future
evals that build keyed lookups, aggregate over collections, or write compound
conditions. They do not teach a treecmp-specific trick. Promotion requires
replay and CTO approval.

## Tickets created

None. The run passed cleanly; the frictions observed are generalizable handbook
facts now captured as a provisional candidate rather than a product-defect
ticket. No strong reproducible product/tooling defect was observed in this
single trial.

## Post-merge decisions

None. The reconciler found no merged tickets for this run (`none`); there are
no post-merge acceptance assignments to evaluate here.

## Next replay

- Eval: `task-treecmp` (replay the staged provisional
  `lineage/handbook-candidate.md`).
- Also replay a cross-eval that exercises `Map` construction and stream
  accumulation to test whether the no-Map-literal / no-`for` / `and`/`or`
  rules generalize, e.g. an approved keyed-merge eval (`task-keyjoin`) or
  aggregation eval (`task-groupsum` / `task-svcstat`) with the candidate
  handbook.
- Falsification check: the candidate is trusted only if a later replay with the
  candidate handbook reaches correctness with fewer discovery turns (no
  re-derivation of `map.empty()`, word operators, or stream accumulation) and
  still passes all cases.

## North-star impact

This run advances the practical, learnable, ergonomic, trustworthy-XSH mission
by demonstrating, on a substantive dual-source reconciliation task (manifest →
keyed lookup, tree walk → relative path + size, three-way merge), that the
current handbook is sufficient to reach a byte-exact, restriction-clean
solution across all 12 cases including the two loud failure controls. It also
surfaces three general language idioms — no Map literal, no `for` loop, boolean
`and`/`or` — whose absence caused the dominant discovery effort. Capturing those
in a provisional handbook candidate reduces repeated agent exploration for keyed,
aggregating, and conditional work, which is exactly the "fewer guesses,
workarounds, and repeated discoveries" ergonomics goal in the North Star, and
the cross-eval replay plan keeps the claim honest until it generalizes beyond
this single task.
