# Eval-manager report

## Result

pass

## Effort metrics

Single trial (`trial 1`) at XSH commit
`26d59eb844b670365931d91ffb15ae8c109bae12`.

- Worker `task-bigfiles-1`: 31 assistant turns, 35 tool calls (24 `bash`,
  5 `write`, 4 `read`, 2 `edit`), 0 tool errors, 35 tool results,
  20 thinking blocks, 1 stop + 30 toolUse stop reasons.
- Session span 219426 ms (~3.7 min); agent wall 226010 ms.
- Friction: none measured — zero tool errors and zero retry events. The
  worker produced a correct `bigfiles.xsh` without repeated discovery loops.
  The `review.md` records two deliberate design observations (strict-decimal
  parse, print-call-expression binding), not agent stumbles.

## Usage and cost

Worker (provider `openrouter/deepseek/deepseek-v4-flash-0731`):

- input 23161, output 7606, cacheRead 404800, cacheWrite 0 tokens;
  bucket total 435567, provider total 435567 (buckets reconcile).
- Budget $0.50; cost $0.01073997 (cacheRead $0.0072864, input $0.00208449,
  output $0.00136908). Budget state pass, 0 budget failures.
- Report dollar fields all present; no unknown-cost fields.

## Thinking evidence

Provider reported reasoning-token counts: `reasoning = 4030`, with
20 thinking blocks. Reasoning is a subset of output and not added to totals.
Qualitative evidence comes from the session transcript; the structured report
shows a clean, linear progression (no error recovery or repeated probes), so
the thinking blocks correspond to composing the single correct pipeline.

## Tool-error findings

None. The structured `tool_errors` arrays in the phase report, the worker
report, and the evaluator manifest are all empty; there are no nonzero Pi
tool results and no invalid `xsht api` discovery queries in this run.

## Timing evidence

Candidate/oracle wall-clock per case (candidate vs oracle, ns):
public 30253169/24967770, hidden_default 18959653/39004611, hidden_n2
15805239/15639237, hidden_single 12087984/14142635, hidden_deep 12481906/
32637991, hidden_spaces 42733283/16459913, hidden_utf8 14577890/14667100,
hidden_empty 14070217/18417354, hidden_bad_n 13509876/13805422. Both sides
finish in tens of milliseconds. This eval has no strict timing gate
(`timings.passed = true`, diagnostic only). Candidate `hidden_bad_n` exits 3
vs oracle exit 1 — both nonzero and print nothing, satisfying the failure
control exactly.

## Observation classification

- Correctness: pass — all nine cases byte-exact (`all_exact: true`), including
  failure control (both nonzero, no stdout).
- Restrictions: pass — `review_ok: true`, required headings present,
  no template placeholders, no subprocess boundary, uses `fs.files` and a
  `sort-by` stage (no hard-coded answer).
- Protocol: pass — artifact present, review present.
- Worker friction: none (0 tool errors, 0 retries, 31 clean turns).
- Product signal (strong, reproducible): `Str.parse_int()` is not a strict
  decimal parser (accepts `0x` hex, leading `+`/`-`, surrounding whitespace,
  leading zeros); there is no decimal-only parse primitive and no generic
  `Error(...)` constructor. The worker satisfied the eval's strict-decimal
  `N` failure gate only via a digit-check plus force-invalid-string
  (`parse_int("invalid")?`) hack. This is a general ergonomics/correctness
  gap, not task-specific confusion; byte-exact decimal contracts recur across
  evals and real systems-glue programs. Recorded as a new product ticket.
- Minor ergonomics (not ticket-worthy alone): a call expression cannot appear
  directly as a `print` argument (`parse.command-call-expr`); binding to a
  `let` first is required. The handbook already teaches building text in
  expression position, so this is mostly noise.
- Ordinary noise / harness: none observed; image, evaluator, and timing all
  nominal.

## Handbook decision

Unchanged. The worker completed the task cleanly with zero tool errors; the
two `review.md` observations are product-language gaps (decimal parsing,
print conveyance) rather than handbook absences, and the existing handbook
already covers the command-word spelling, Result/`?` failure idiom, and
print-argument guidance. Writing
`lineage/handbook-candidate.md` as a verbatim copy of the approved snapshot;
no provisional handbook change this cycle. The strict-decimal observation is
better expressed as a product ticket (unique capability gap) than a handbook
recipe, because the fix belongs to the language, not to agent guidance.

## Tickets created

`/Users/josh/d/laputa-systems/xsh-factory/tickets/task-bigfiles-005.md`
(Open, `product`): strict-decimal integer parsing. Next-unused identity after
the four merged task-bigfiles tickets; all pre-existing ticket files left
unchanged.

## Post-merge decisions

None. The reconciler found no newly merged tickets this cycle
(merged files: `none`). Tickets 001–004 are already `Merged.` in the
pre-manager identity set and were reconciled in their prior runs; the
post-merge acceptance for each was recorded there. No revert proposed.

## Next replay

Replay `task-bigfiles` (all nine byte-exact cases) on a later XSH image after
any decimal-parsing change to confirm that a strict-decimal `N` validation
can be expressed with a single typed call and propagate a nonzero exit
without the force-invalid-string hack, while the failure control
(`hidden_bad_n`) still prints nothing and exits nonzero.

## North-star impact

Confirms XSH's ranked-report composition (`fs.files` -> filter -> `sort-by --desc`
-> `take` -> `each`/`print`) is a clean, composable, byte-exact operation an
agent can reach without friction. The one durable signal is the
strict-decimal-parse gap: byte-exact numeric contracts (counts, ports, sizes)
currently require an opaque force-invalid-string workaround because
`Str.parse_int()` is lenient and no decimal-only Result-returning primitive
exists. Removing that hack advances the north-star goals of explicit,
trustworthy boundaries and ergonomic systems glue.
