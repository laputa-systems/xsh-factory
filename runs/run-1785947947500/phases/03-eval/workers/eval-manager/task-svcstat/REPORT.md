# Eval-manager report

## Result

fail

## Effort metrics

One trial (the configured count), `task-svcstat-1`.
- assistant turns: 59 (1 user message)
- tool calls: 65 (bash 56, read 5, write 2, edit 2)
- tool results: 65; tool errors: 1
- session span: 407211 ms (agent wall 409000 ms)
- worker friction (minor): three fs.files named-arg parse probes (`exts=[...]`,
  `exts = [...]`) rejected by the checker before the worker settled on the
  `where .ext == "log"` / `where .kind == "file"` filter; one failed sed/grep
  exploration probe; two invalid `xsht api` discovery forms (`language:core.results`,
  `language.effect.error`) that returned exit 0 rather than erroring.
- Worker produced `svcstat.xsh` and `review.md` and reached a normal stop
  (`stop` 1, `toolUse` 58). The artifact is plausible and self-tested locally,
  but its correctness is UNVALIDATED this cycle.

## Usage and cost

Single worker session (provider `openrouter/deepseek/deepseek-v4-flash-0731`).
- input 58,671; output 22,724; cacheRead 1,446,208; cacheWrite 0
- provider total 1,527,603; bucket total 1,527,603 (match)
- reasoning (provider-reported) 15,285
- cost: total $0.035402; cacheRead $0.026032; input $0.005280; output $0.004090
- budget $0.50; budget_state pass; no budget breach.

## Thinking evidence

47 thinking blocks; the provider reported 15,285 reasoning tokens (subset of
output; not added to totals). The transcript shows the worker reasoning through
the exact parse contract (blank-line detection, strict two-space-separated
fields, service charset, decimal-digit count), CRLF handling, the
print-nothing-on-failure requirement, and the stream `group-by` +
accumulator `fold` design before writing the artifact. Reasoning was coherent
but was not checked against the oracle this cycle because the evaluator never
ran.

## Tool-error findings

The structured worker `tool_errors` array contains exactly one isError result
(session line idx 78, reported turn 34): a bash `sed -n '/Result (1 items)/,…'
/tmp/sum.txt; grep …` exploration probe that exited 1 (no matching region).
This is ordinary exploration noise and carries no product signal.

The two syntactically invalid `xsht api` discovery queries
(`language:core.results`, `language.effect.error`) returned exit 0 with
`isError: false`, so they are not entries in `tool_errors`; they are recorded
here as discovery friction (the correct `KIND:VALUE` form is `language:core.*`).

The manager and controller structured report lists the same single error
(reported as `tool: bash`, `turn: 34`). No other nonzero Pi tool result exists
in the current worker or manager sessions.

Root failure is not a worker tool error: the evaluator container never launched
(`evaluator.stderr`: `docker: Error response from daemon: Duplicate mount point:
/run/evaluator.xsh.`), so no evaluator manifest / `run.json` exists
(`evaluator_manifest` empty, `outcomes.infrastructure: fail`,
finding `missing-evaluator-manifest`).

## Timing evidence

No candidate/oracle timing was measured: the evaluator did not run (infrastructure
failure), so there is no `run.json` and no per-case candidate-vs-oracle timing.
`EVAL.md` declares no strict candidate/oracle ratio gate, so timing is diagnostic
and remains unmeasured this cycle.

## Observation classification

- Harness/infrastructure defect — strong, reproducible, general: `eval-executor.xsh`
  lines 147–148 duplicate the `--mount … dst=/run/evaluator.xsh,readonly` bind,
  so `docker run` rejects a duplicate mount point and the evaluator never starts.
  This blocks every eval through the generic evaluator path, not just
  `task-svcstat`. → one ticket.
- Worker friction (minor, not a new handbook gap): `fs.files` optional named-arg
  syntax was rejected; the worker fell back to the already-documented
  `where`/`kind` filter idiom the handbook teaches. No new lesson required.
- Worker friction (candidate only, unvalidated): `not` boolean keyword absent;
  worker used `r.valid == false` (flagged in `review.md`). Not promoted this run
  because evaluation was blocked; to be re-examined on a successful replay.
- Ordinary noise: the single sed/grep exploration probe (exit 1).
- Correctness: unknown — the candidate artifact is plausible and passed the
  worker's own representative self-tests, but there is no evaluator byte-exact
  comparison, no restriction check result, and no `run.json` this cycle.
- Provider telemetry: present but carries no signal (retry_count 0,
  provider_errors [], output_tokens_per_second 0, response_elapsed_ms 0), so the
  407 s span is not attributable to provider latency and no provider-health
  classification is warranted. The failure is the harness defect, not latency.

## Handbook decision

Unchanged. The approved snapshot `lineage/handbook-approved.md`
(sha256 `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b`)
was copied unchanged to `lineage/handbook-candidate.md` (verified identical
hash). No validated product signal exists this run because evaluation was
blocked by the executor defect; promoting the `not`/`== false` idiom or the
`fs.files` named-arg frictions before a verified replay would violate the
trust-through-replay standard.

## Tickets created

One: `tickets/task-svcstat-001.md` — eval-executor duplicates the
`/run/evaluator.xsh` bind mount, blocking the evaluator container for all evals.
Links this eval, the shared handbook lineage, this manager run, the executor
run, and XSH baseline `aaa968c73fd7649f70a6a94e21f77a90bf6a778c`. Merge-record
placeholders left unchanged.

## Post-merge decisions

None. The reconciler reported no merged tickets for this cycle.

## Next replay

Eval `task-svcstat`, same shared handbook lineage (approved snapshot,
unchanged), on the merged executor fix for the duplicated mount. Success
criterion: the evaluator emits a populated `run.json` with all eight cases
(public + 7 hidden, including the malformed failure control) and byte-exact
stdout comparison plus per-case candidate/oracle timing. If the replay is clean,
re-examine the `not`/`== false` and `fs.files` named-arg frictions as candidate
handbook guidance, and falsify the executor fix on one additional eval to
confirm the generic mount fix generalizes.

## North-star impact

The duplicated-mount defect silently blocked the evidence loop for this cycle:
the worker produced a plausible stream `group-by` + `fold` aggregation
implementation, but the factory got no correctness, restriction, or timing
signal to trust it. Fixing the one-line harness bug restores reproducible
byte-exact evaluation for `task-svcstat` and every other eval, letting the
factory measure whether the intended keyed rollup idiom is discoverable and
correct — the practical, learnable, trustworthy evidence the north star
requires.
