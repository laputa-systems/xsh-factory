# Eval-manager report

## Result

pass

## Effort metrics

One controller-executed trial (task-envcfg-1). Single worker over the approved
handbook snapshot (`lineage/handbook-approved.md`, sha `97c5d804…a40e83`).

- Assistant turns: 35
- Tool calls: 37 (bash 30, edit 2, read 3, write 2)
- Tool results: 37
- Tool errors: 3 (all warning-severity; see Tool-error findings)
- User messages: 1
- Session span: 234,759 ms (agent_wall 236,034 ms)
- Stop reasons: 34 toolUse, 1 stop; worker result `pass`, state completed
- Worker friction: 3 recoverable tool errors, each self-corrected within 1–2
  turns; no unresolvable discovery, no budget breach (budget $0.50, used $0.016).

## Usage and cost

Provider: openrouter, model `deepseek/deepseek-v4-flash-0731`, thinking level
`high`.

Trial 1 token buckets (provider-reported):
- input 26,510 ($0.0023859)
- output 18,176 ($0.0032717)
- cacheRead 581,440 ($0.0104659)
- cacheWrite 0 ($0)
- provider total 626,126; bucket total 626,126 (match, no discrepancy)
- cost total $0.0161235; unknown costs 0
- reasoning tokens 13,215 (provider-reported); thinking blocks 27

No second trial. Aggregate equals trial 1.

## Thinking evidence

27 thinking blocks; the provider reported 13,215 reasoning tokens (subset of
output, not added to totals). Thinking transcripts (session.jsonl.bz2) show the
worker reasoning through the byte-exact contract: it probed `Str.parse_int`
behavior on signs/whitespace/empty (`"-5" "+5" " 12" "12 " ""`), discovered
that `env.int`/`parse_int` are not staunch validators, and settled on a
guaranteed-failing `parse_int()?` to force failure for malformed and empty
`CFG_PORT`. Thinking correlated with the eventual accept decision.

## Tool-error findings

All three structured tool errors are from worker session task-envcfg-1
(report `workers/eval-worker/task-envcfg-1/report.json`); no manager-session
tool errors.

1. Turn 5 (bash): `xsht api` rejected `api:method.Str.parse_int` — wrong
   prefix (`api:method.` instead of `method:`). The same call's
   `method:Result`/`method.Result.context` probes succeeded. Recovered at turn 6
   with the correct `method:Str.parse_int`. Handbook already documents the
   `method:NAME.MEMBER` form. Discovery friction, not a harness/product defect.
2. Turn 8 (bash): `xsht api` rejected `language.core.results` — dotted form
   instead of `KIND:VALUE`. Recovered at turn 10 with `language:core.results`.
   Handbook documents language ids under `language:core.*`. Discovery friction.
3. Turn 26 (bash): `xsht lint` emitted `warn[lint.path-constructor]: prefer
   p-string interpolation over Path(...)` on the `fs.write(Path(out), …)`
   call and exited 1. This is a lint hint (not `check` failure); the worker
   refactored to `fp"${out}"` in the final artifact. Handbook already states
   p-strings are the lint-preferred interpolated form. Noise.

Each maps to guidance already present in the approved snapshot and was
self-corrected; none is a repeated discovery or product defect.

## Timing evidence

Candidate/oracle wall clocks per case (ns) — all 10 cases:
- public 11,081,132 / 12,445,018
- hidden_defaults 13,099,899 / 13,282,026
- hidden_partial 13,125,607 / 13,296,192
- hidden_empty 11,711,763 / 12,522,977
- hidden_spaces 13,187,899 / 13,227,275
- hidden_zero 12,010,640 / 13,339,359
- hidden_utf8 11,571,970 / 13,061,607
- hidden_debug_false 13,181,900 / 12,134,141
- hidden_malformed 10,910,340 / 13,248,359
- hidden_empty_port 13,363,484 / 13,327,525

Timing is diagnostic only; the eval contract sets no strict candidate/oracle
ratio gate. Both sides finish in ~11–13 ms per case; no timing concern.

## Observation classification

- Correctness: pass on all 10 cases (`all_exact: true`), including both
  failure controls — `CFG_PORT=abc` and `CFG_PORT=` exit nonzero (proven by
  runtime tracebacks in candidate.9/10.stderr) with no output file written
  (candidate.9/10.stdout empty). A hard-coded config, silent default, or
  subprocess escape would have failed a distinct gate; none did.
- Restriction: pass (`env_referenced: true`, `forbidden_operations: true`).
  Artifact uses `env.get_or` and `fs.write` with `[fs, env, error]`; no
  subprocess boundary; stdout clean; deliverable in file.
- Protocol: pass (`artifact_present`, `review_ok`); `review.md` keeps both
  required headings and no template placeholders.
- Worker friction (tool errors 1–2): reusable guidance already covered by the
  approved handbook; the worker self-corrected within 1–2 turns. Not a ticket.
- Worker friction (tool error 3): lint hint consistent with handbook p-string
  guidance; worker complied. Noise.
- Product-signal (from `review.md`): the worker documented a real general
  ergonomics gap — there is no first-class `assert`/`fail`/`raise` primitive to
  emit a deliberate validation failure, and `Err("...")` yields a Str-family
  Result that cannot propagate from a procedure declared `[error]`. This is a
  genuine, general XSH observation, but it is single-session evidence from a
  passing run; the worker did find a working mechanism (guaranteed-failing
  `parse_int()?`). Not strong enough to open a product ticket this cycle. It is
  carried forward as a concise handbook candidate (see Handbook decision).

## Handbook decision

Provisional candidate staged at
`lineage/handbook-candidate.md` (a copy of the approved snapshot with one
clarifying addition to the Effects and errors section). General lesson: this
XSH build has no `assert`/`fail`/`raise` primitive, `Err(...)` cannot propagate
from `[error]`, so a deliberate validation failure after an explicit byte check
is expressed by propagating a guaranteed-to-fail typed conversion
(`residue.parse_int()?`) and letting `?` produce the nonzero exit. This removes
the ~8-turn discovery loop (turns 15–22) the worker spent hunting for an
assert/panic primitive, is general (any strict-validation task, not just
envcfg), and stays within the north-star explicit-error ethos.

Replay scope: task-envcfg on this run's lineage with the candidate snapshot,
plus one other strict-validation/failure-control eval when one exists, before
promotion to `runtime/handbook.md`. Promotion requires later review and it was
not replayed in this cycle (one-trial plan).

## Tickets created

None. Product-ticket candidacy for deliberate-validation ergonomics was
considered and deferred pending replay of the handbook candidate.

## Post-merge decisions

None. The reconciler merged no tickets this cycle (`none`); no post-merge
acceptance assignment.

## Next replay

Replay `task-envcfg` against `lineage/handbook-candidate.md` (same XSH commit
`e8f64a244af1727f64b4ee368441d04ca820d774`) to confirm the candidate removes
the deliberate-failure discovery loop while preserving an all-ten-case pass
and restriction compliance. If a second strict-validation eval exists, replay
it too to support generalization before CTO promotion.

## North-star impact

This run demonstrates the environment/config surface is discoverable and
composable: the worker found `env module` / `env.get_or` / `env.int` /
`env.bool` via `xsht api`, applied defaults only on absence (not on empty),
wrote a byte-exact file with `fs.write`, and propagated malformed values with
postfix `?` — exactly the systems-glue shape the eval targets, and the
Result/`?` lesson transferred to a real validation boundary. Low cost (~$0.016)
and normal effort for a correct, clear solution. The staged handbook candidate
turns the run's sole friction into a short, general, learnable rule about
deliberate validation failure, in line with XSH's explicit-boundary and
trustworthy-error goals.
