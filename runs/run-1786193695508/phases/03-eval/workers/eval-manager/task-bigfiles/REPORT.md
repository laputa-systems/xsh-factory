# Eval-manager report

## Result

pass

## Effort metrics

Single fresh trial (`task-bigfiles-1`), XSH baseline `c77b01a3e2fb676cc57cdeddbb7575be7723aa32`.
Worker: 17 assistant turns, 19 tool calls (13 `bash`, 3 `read`, 2 `write`, 1 `edit`),
0 tool errors, 0 tool results in error. Session span 213505 ms (agent wall 214828 ms).
Worker friction: none. No repeated exploration, no failed checks, no rework; the candidate
was produced and verified in one pass. This is efficient for a first-ever run of this eval
against the shared handbook.

## Usage and cost

Budget $0.50; actual cost $0.00725787 (well within). Token buckets (provider-reported):
input 56027, output 3092, cacheRead 92160, cacheWrite 0; provider total 151279,
bucket total 151279 (consistent, no mismatch). Reasoning tokens 1056 (subset of output).
Dollars: input $0.00504243, output $0.00055656, cacheRead $0.00165888, cacheWrite $0,
total $0.00725787. Unknown costs: 0. malformed_lines 0.

## Thinking evidence

13 thinking blocks; provider reported 1056 reasoning tokens. Qualitative reading of the
artifact shows a single, direct construction: dynamic `fp"${argv[0]}"` path, `parse_int()?`
failure propagation, `fs.files(root, stat: true)` with a `kind == "file"` filter, `sort-by
--desc { |e| e.size }`, `take(n)`, `collect()`, and `each { |f| print $f.size $f.path }`.
No over-thinking or abandoned approaches. Reasoning-token counts were reported by the
provider, so no gap in evidence here.

## Tool-error findings

None. The structured `tool_errors` arrays in the worker `report.json`, the phase
`report.json`, and the manager context are all empty. The worker committed zero failed Pi
tool results; there were no invalid `xsht api` discovery probes (the session solved the task
without any failed query).

## Timing evidence

No strict candidate/oracle ratio gate for this eval. Per-case wall times are all in the
10–16 ms envelope (public 12.9/11.8, hidden_default 11.6/14.4, hidden_n2 15.4/14.6,
hidden_single 12.4/15.0, hidden_deep 13.9/13.4, hidden_spaces 14.6/15.6, hidden_utf8
12.3/12.4, hidden_empty 15.4/12.4, hidden_bad_n 13.4/15.0 ms candidate/oracle). The
failure control exited nonzero from both sides (candidate 3, oracle 1) with empty stdout;
byte-for-byte matches on all nine cases. Timing is diagnostic only, and both sides are well
within a stable envelope.

## Observation classification

- Correctness: pass on all nine cases including the failure control (`hidden_bad_n`)
  — both candidate and oracle exit nonzero and print nothing. Worker friction: none.
- Restrictions: pass. Source references the filesystem stream module (`fs.files`) and a
  `sort-by` stage, contains no subprocess boundary, no hard-coded answers, no stdout
  diagnostics. This addresses the eval's stated resistance to per-tree hard-coding.
- Protocol: pass (artifact present, `review.md` present and placeholder-free).
- Reusable signal: the `sort-by --desc { |e| e.size }` command-word + `take(n)`
  composition, the `stat: true` requirement for the `size` field, and the `parse_int()?`
  validation idiom all map directly onto existing handbook guidance; no new general lesson
  surfaced. No product/tooling defect, no image/harness mismatch, no evaluator failure, no
  stochastic noise worth a ticket.

## Handbook decision

unchanged. The staged `lineage/handbook-candidate.md` is the approved snapshot copied
verbatim (no edits). The worker solved the task using idioms already present in the
approved handbook (command-word stream stages, `sort-by --desc` flag-then-block form,
`take(n)` parenthesized int, `parse_int()?` failure propagation, `stat: true` metadata
boundary). No candidate was proposed and no replay scope is required.

## Tickets created

None. No strong reproducible observation, product defect, or length of friction warranted
a ticket. `review.md` also records no language proposal and no xsht friction, which agrees
with this assessment. Existing pre-manager tickets were left untouched.

## Post-merge decisions

None. The controller reconciler found no merged tickets for this eval; there are no
post-merge acceptance assignments to decide.

## Next replay

None required this cycle. `task-bigfiles` established a clean first-pass baseline against
the shared handbook with a fully passing single trial. If this eval is re-run after a
future handbook or language change, the replay should re-confirm the nine-case byte-exact
match and the nonzero-exit failure control.

## North-star impact

This run demonstrates that XSH's numeric stream composition — sort a filesystem stream by a
per-file `size` field and take a top-N — is discoverable and correct from the shared
handbook alone, with a byte-exact `du`/`sort`/`head` analogue, a typed validation failure
for non-integer N, and no subprocess escape. It is exactly the practical, learnable,
ergonomic systems-glue surface the north star targets, and it did so with a low-cost,
low-friction, single-pass session. No product or handbook change is warranted; the baseline
is healthy.
