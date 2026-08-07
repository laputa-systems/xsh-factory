# Eval-manager report — task-ecount

Eval `task-ecount`, phase `01-eval`, run `run-1786131191668`, XSH commit
`857154dfe505f0d01053c1b5311f44422070eb34`. One fresh controller trial against
the approved handbook snapshot (`3b56a781…`, verified: hash of
`lineage/handbook-approved.md` matches `run.json` inputs `handbook_sha256`).
Coordinator-supplied merged-ticket list: `none`. Candidate
re-evaluation: `not-reevaluation`.

## Result

pass

Trial 1 passed every gate: correctness pass (byte-exact stdout), restrictions
pass (no-subprocess boundary honored; `fs.files` + typed streams only, no
`run`/`spawn`), protocol pass (`ecount.xsh` artifact present, `review.md`
complete), timing pass. Phase `report.json` records `outcomes.product: pass`
and `outcomes.cycle: fail` only because the manager `REPORT.md` was not yet
present (now filled) and the handbook candidate was not yet staged. Both are
reporting artifacts, not language failures. XSH commit fingerprint per phase:
`857154dfe505f0d01053c1b5311f44422070eb34`.

## Effort metrics

Trial 1 (only trial):
- assistant turns: 64; stop reasons: 1 normal stop, 63 `toolUse`.
- tool calls: 80 (bash 70, read 4, edit 3, write 3); tool results 80.
- tool errors: 13 (all `bash`; see Tool-error findings).
- session span: 657581 ms (~11 min) worker, `agent_wall_ms` 658895.
- worker friction: high, clustered around XSH function-declaration and
  value-return idiom discovery (`fn` vs `pure`, if/else final expression,
  `List.get` overload, `path` shadowing) and padding-width measurement from the
  oracle. The agent recovered and passed without re-probes beyond the session.

## Usage and cost

Trial 1 (only trial; aggregate equals trial):
- input: 156,986; output: 23,872; cacheRead: 1,428,928; cacheWrite: 0.
- bucket total: 1,609,786; provider `totalTokens`: 1,609,786 (match).
- reasoning tokens: 13,278 (provider-reported, subset of output; not added to
  totals).
- cost: input $0.01412874, output $0.00429696, cacheRead $0.025720704,
  cacheWrite $0, total $0.044146404. Budget $0.50, budget failures 0, unknown
  costs 0.

## Thinking evidence

53 thinking blocks; provider reported `reasoning_tokens: 13278`. Raw thinking
in `session.jsonl.bz2`. Topics: matching `fs.files` default set to `fd -tf`
(including symlink exclusion), `Str.split` field semantics vs `awk -F.`,
whether an empty trailing field contributes a count, count formatting from the
oracle output, and function-keyword discovery. Thinking is qualitative; the
correctness/timing gates confirm the explanation. Reasoning-token count was
reported, so no `unavailable` caveat is needed.

## Tool-error findings

All 13 nonzero `bash` results from the structured `tool_errors` array are
accounted for (worker `task-ecount-1`):
- turn 7: `Path(argv.get(0))` type mismatch (expected Str, found
  Result[Str,Error]) + ``?`` requires `error` effect. Agent needed the
  `argv.get(0, default)` fallback and the `error` effect.
- turn 15: API query returned `purpose: Wraps text to a requested width.` with
  exit 1 — a `pad`/format lookup with no exact pad method; discovery friction.
- turn 22: parse errors building a spacer via `stream.range |> map |> collect
  |> List.join(...)` (module function chained as a method).
- turn 25: unresolved name `List.join`.
- turn 26: `|>` into a braced lambda misparsed as boolean `|`/record.
- turns 28, 30: closing-brace `expected expression` — the `fn` keyword
  (later diagnosed as `pure`).
- turn 34: `path` param shadows module; `path.display` unsupported;
  `.lower()` on `Result`; missing-return.
- turn 36: `python3: not found` (agent editing helper) + same `ext_of` errors.
- turn 38: missing-return `ext_of`; probe `cand.txt` missing.
- turn 39: missing-return on standalone if_test.
- turn 42: diff shows candidate lacked leading-space padding (count width
  mismatch versus the oracle).
- turn 46: BusyBox `sh` `bad for loop variable` while testing padding.

All 13 explained. Each is agent discovery/idiom friction (recurring,
reusable), environment noise (`python3`), or task-specific padding (BusyBox
`uniq -c`), not a confirmed XSH correctness defect. No `xsht api` invalid
query errors other than the exit-1 pad lookup at turn 15.

## Timing evidence

Candidate wall 12.798 ms, oracle wall 11.722 ms; ratio 1.0917, within the
strict `0.90..1.10` gate → timing `pass`. Candidate user/sys 1.142/3.427 ms,
oracle user/sys 2.901/3.489 ms. Timed noisily at this scale; a language
correctness pass, not a timing failure. No ratio gate breach.

## Observation classification

- Reusable handbook guidance (strong, recurring): `fn` is not a keyword —
  effect-free functions use `pure`; a function body ends with a value
  expression and a bare `if`/`else` final statement triggers `missing-return`
  (bind it to `let` and return the binding); `List.get(index)` is Result-typed
  so the `.get(index, default)` overload is required in pure functions; param
  names that shadow standard modules (e.g. `path`) are rejected. These recurred
  across turns 7–39 and are general XSH learnability gaps.
- Task/environment noise: padding width must be read from the BusyBox `uniq -c`
  oracle (right-aligned width 7 for one-digit counts), and `python3` is absent
  from the base image. BusyBox-sh for-loop test syntax error at turn 46. These
  are not XSH product signal.
- Worker friction: the iterations themselves (token/cost footprint) track the
  idiom re-discovery above.
- No confirmed product/tooling correctness defect in this trial; all language
  errors were discoverable, idiomatic gaps rather than wrong runtime behavior.

## Handbook decision

Provisional candidate staged at
`lineage/handbook-candidate.md` (copy of the approved snapshot plus a new
"Function declarations and value returns" section): `pure` vs `fn`, final-expression returns and the `let`-bound `if`/`else` idiom, the `List.get`
fallback overload, and standard-module parameter shadowing. Single general
lesson: document the function-declaration and value-return idioms once so
agents stop re-discovering them per task. Approved snapshot and checked-in
`runtime/handbook.md` are untouched. The candidate is a hypothesis pending
replay; not promoted.

## Tickets created

None. The recurring friction is learnability/guidance rather than a confirmed
general product defect within a single trial; staged as handbook candidate and
left for replay evidence rather than an engineer ticket this cycle.

## Post-merge decisions

None. The reconciler reported merged tickets `none`; no accepted post-merge
assignment to evaluate against this XSH commit.

## Next replay

Replay `task-ecount` against `lineage/handbook-candidate.md` with the same
oracle and a nearby filesystem case, and replay at least one other
filesystem/composition eval (e.g. `task-dupcheck` or `task-histogram`) to test
whether the function/`pure`, if-else-return, and `List.get` overload guidance
is general. Promote to `runtime/handbook.md` only after both replays confirm a
reduction in the documented tool errors and turns.

## North-star impact

Improves XSH learnability and ergonomics — the stated factory focus — by
making effect-free function declarations and value returns explicit and
discoverable, so an agent (or person) reaches a correct, clear program with
fewer failed checks and less exploration. Directly reduces repeated
`fn`/`pure`, missing-return, and `List.get` friction observed this cycle. The
remaining friction (padding width, `python3` absence) is environment/oracle
noise, not product signal, and keeps the composition bar honest rather than
rewarding a task-specific trick.
