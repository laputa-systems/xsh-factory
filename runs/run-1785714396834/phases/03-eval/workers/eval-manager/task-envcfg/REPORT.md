# Eval-manager report: task-envcfg

- Eval: `task-envcfg` (`evals/task-envcfg/EVAL.md`)
- Run: `runs/run-1785714396834` phase `03-eval`
- Approved handbook snapshot: `runs/run-1785714396834/phases/03-eval/lineage/handbook-approved.md` (`c7c9dd9abb6d50dac60562757a1824900f24d4bc2d38014d5cbf869f56bb0723`)
- XSH commit under test: `de9880ce9cd13c4ef63acc212554d786358ed869`
- Executor evidence: `runs/run-1785714396834/phases/03-eval/workers/eval-worker/task-envcfg-1/` (trial 1, the only trial; controller completed 1 fresh trial)
- Candidate re-evaluation: not applicable (`not-reevaluation`)

## Result

pass. The single completed trial passed correctness (10/10 cases byte-exact
against the BusyBox `sh` oracle, including both failure controls), restrictions
(`env.` referenced, no subprocess boundary, clean stdout), protocol
(artifact present, review.md complete), timing (no gate), and the agent
completed within budget with a normal stop. The agent produced a correct,
deterministic `envcfg.xsh` using `env.get_or`, a regex `^[0-9]+$` port check,
a display string for the config text, and `fs.write`; a malformed/empty
`CFG_PORT` exits nonzero (code 3) with no output file and no stdout. The phase
report's `fail` reflects only the missing narrative reports (manager and
director), not the trial outcome; this report resolves the manager component.

## Effort metrics

Trial 1 (`eval-worker/task-envcfg-1`):

- Assistant turns: 91 (1 user message; stop reasons 1 `stop` + 90 `toolUse`).
- Tool calls: 91 (84 `bash`, 2 `edit`, 2 `read`, 3 `write`); tool results 91.
- Tool errors: 4 (all in the worker session; see `## Tool-error findings`).
- Session span: 470,048 ms (`timing.session_span_ms`; `agent_wall_ms` 471,720).
- Worker friction: mixed. Discovery of the `env` module and `fs.write` was fast
  (2–3 `xsht api` queries each); the oracle harness and byte-comparison loop
  were built quickly with BusyBox tools. The dominant friction was error
  construction: roughly a quarter of the session (~25 of 91 assistant turns,
  session message indexes 39–141) was spent trying to construct a typed `Error`
  for the explicit malformed-port abort before settling on a semantically
  meaningless forced failure (`regex.compile("[")?`). Secondary friction:
  guessing `++` string concatenation (parse error), the `p"${expr}"` path
  literal trap (created a file literally named `${argv.get(0)}`), and one
  failed `python3` probe.

## Usage and cost

Trial 1, provider-reported (openrouter `deepseek/deepseek-v4-flash-0731`):

- Buckets: input 203,441; output 31,918; cacheRead 2,155,584; cacheWrite 0.
- Provider total: 2,390,943 tokens; bucket total 2,390,943 — no mismatch.
- Reasoning tokens: 22,522 (provider-reported subset of output; never added to
  totals).
- Cost: input $0.01830969, output $0.00574524, cacheRead $0.038800512,
  cacheWrite $0, provider total $0.062855442.
- Budget: $0.50, `budget_state: pass`, zero budget failures.

Aggregate (1 worker): $0.06286, 2,390,943 bucket tokens, 0 unknown costs.
The run is cheap; 91 turns at about 26k tokens/turn primarily reflect the
per-turn cache-read of the pinned handbook/task context, with the error-construction
exploration as the main avoidable spend.

## Thinking evidence

- Thinking blocks: 73; model thinking level `high`; reasoning tokens 22,522
  reported by the provider (available — this provider reports reasoning counts).
- Grounding: thinking blocks appear on most assistant turns and correlate with
  the four tool errors and the final workaround. The transcript shows genuine
  investigation of error construction (`Err("msg")` type mismatch,
  `Error(kind: ...)` removed by the checker with a misleading
  `FsError.NotFound(...)` suggestion, unresolved `RuntimeError`/`ValueError`/
  `ThreadError`/etc., `record:FsError` missing), a deliberate decision not to
  inspect `/usr/local/lib/xsh-factory` despite thinking about it, and a correct
  judgment that exit code 3 satisfies the task's "exit nonzero" contract.
- The final summary (turn 91) is accurate and matches the written artifact.

## Tool-error findings

All four nonzero tool results are from worker `task-envcfg-1`; the structured
`tool_errors` arrays in the phase report and worker report are fully accounted
for. The manager session had zero failed tool results at reporting time.

1. Turn 18 (`bash`): one multi-query `xsht api` call returned two exact matches
   (`api:fs.write`, `api:fs.write_atomic`) and one invalid discovery query
   `api:fs.path.write` → `invalid API query ... expected NAME.MEMBER`.
   Classified: agent API-discovery friction; self-corrected in the same call;
   no product defect.
2. Turn 44 (`bash`): `cat: can't open '/tmp/px1.out'` — the worker's local test
   expected a file that was not produced (the `p"${argv.get(0)}"` literal-name
   trap under investigation). Classified: worker self-test friction, ordinary
   noise; correlated with the later display-string/path discovery.
3. Turn 59 (`bash`): `sh: python3: not found` (exit 127) — the worker probed a
   runtime the minimal Alpine image does not provide. Classified: worker
   friction / image boundary; the handbook already states the image has no
   other language runtimes; the worker then used the `sh` oracle as specified.
4. Turn 71 (`bash`): parse failures (`expected expression`,
   `expected statement terminator`) for `print (a ++ "\n" ++ b)` — XSH has no
   `++` string-concatenation operator. Classified: worker friction from an
   uninvented operator; correlated with the display-string discovery
   (`language:core.display-strings`) and the final `f"..."` solution.

## Timing evidence

No strict candidate/oracle ratio gate (EVAL.md: timing is diagnostic until a
stable envelope exists). All ten cases finished in 11–17 ms on both sides:

- public: cand 12.4 ms / oracle 16.9 ms
- hidden_defaults: 12.7 / 11.9 ms; hidden_partial: 15.2 / 11.2 ms;
  hidden_empty: 15.6 / 15.5 ms; hidden_spaces: 13.3 / 14.0 ms;
  hidden_zero: 13.4 / 12.5 ms; hidden_utf8: 13.0 / 12.9 ms;
  hidden_debug_false: 15.3 / 15.6 ms; hidden_malformed: 12.1 / 13.2 ms;
  hidden_empty_port: 13.0 / 15.4 ms.

No timing concern; both sides are process-launch-bound noise.

## Observation classification

Reusable signal:

- Handbook gap — text construction / interpolation boundary. The worker guessed
  `++` concatenation (parse error), discovered display strings only via
  `xsht api language:core.display-strings`, and hit the `p"${expr}"` literal
  trap. The approved handbook teaches `print "count" $count` but never states
  the general rule: only display strings `f"..."` interpolate with `${expr}`;
  ordinary string literals and path literals do not; dynamic paths need
  `Path.parse_bytes(bytes.from_text(...))`. This is reusable for any exact
  text/file-output eval and is aligned with XSH's explicit-boundary ethos.
  Staged as a provisional handbook candidate.
- Product/tooling defect — no user-visible `Error` constructor or controlled
  `fail`, re-confirmed. The worker could not build a typed `Error` for the
  malformed-port abort: `Err("msg")` is `Result[<unknown>, Str]`, the checker
  says `Error(kind: ...)` was removed and suggests `FsError.NotFound(...)`
  (which `xsht check` rejects as unresolved), and `RuntimeError`/`ValueError`/
  `ThreadError`/etc. are unresolved. The resulting workaround
  (`regex.compile("[")?`) forces a traceback about an "unclosed character
  class" on stderr for a failure that is really a config-validation error.
  This is the same gap as open ticket `task-envcfg-001` (detected at commit
  `defa805a`); the current run reproduces it at `de9880ce` with a different
  workaround, strengthening the ticket. Host probes on the same API surface
  (`xsht api summary`) confirm no general abort/fail primitive: `halt` is
  `os.halt` (host power control) and `fail` is `test.fail` — neither is a
  script-level failure primitive.
- Ordinary noise / task nuance — `env.int` loose parse (`"-5"`, `" 5"`
  accepted) versus the oracle's digits-only check. This is arguably correct
  integer-parser behavior; the task simply needs stricter validation, which
  the worker correctly implemented with a regex. Not a defect; noted only as
  documentation nuance. Not ticketed.

No evaluator failure, harness mismatch, correctness issue, or protocol issue.

## Handbook decision

Provisional candidate staged at
`runs/run-1785714396834/phases/03-eval/lineage/handbook-candidate.md`
(approved snapshot copied with a concise addition).

General lesson: interpolation is explicit — only display strings `f"..."`
interpolate with `${expr}`; ordinary string literals and `p"..."` path
literals never interpolate; compose exact multi-line file content with a
display string and build dynamic paths via `Path.parse_bytes(bytes.from_text(s))`.

Replay scope (global, not eval-local): any exact-text or file-output eval.
Next replays: `task-envcfg` first (must still pass 10/10 and the agent should
reach `f"..."` without `++`/`p"${expr}"` friction), then at least one other
exact-output eval (`task-tags` or `task-ecount`) before promotion to
`runtime/handbook.md`, per north-star replay discipline.

The explicit-Error gap is deliberately NOT codified as a workaround in the
handbook; it belongs to product ticket `task-envcfg-001`, and the handbook
line will change only if the product fix lands.

## Tickets created

Zero new tickets. The one strong reproducible observation of this run — the
missing user-visible `Error` constructor / controlled failure primitive — is
already tracked by open ticket `tickets/task-envcfg-001.md` (detected at
`defa805a`). Creating a duplicate would fragment provenance. This run adds
reproduced evidence at `de9880ce`: worker session (error-construction
exploration, ~25 turns), review.md findings, and `candidate.9.stderr` /
`candidate.10.stderr` tracebacks from the `regex.compile("[")?` workaround.

## Post-merge decisions

None. The reconciler found no merged ticket files for this cycle
(`none`), so there are no post-merge acceptance assignments. Open ticket
`task-envcfg-001` remains Open and is re-confirmed by this run; it is not
dispatched to an engineer this cycle.

## Next replay

- Exact eval and lineage: `task-envcfg` against the lineage snapshot
  `runs/run-1785714396834/phases/03-eval/lineage/handbook-candidate.md`
  (provisional; promote only after replay), same image pattern, XSH commit
  from the next cycle.
- Check 1 (falsification of the handbook candidate): the agent builds the
  config text with a display string and reaches it without `++` concatenation
  guesses or the `p"${expr}"` literal trap.
- Check 2 (correctness regression): all 10 cases still byte-exact, both
  failure controls still exit nonzero with no output file and empty stdout.
- Check 3 (post-merge, when the controller reports `task-envcfg-001` as
  merged): the malformed-port path should use the documented constructor /
  fail primitive instead of a fake host failure; if merged, this is an
  acceptance replay. If still Open, note persistence.
- Cross-eval generalization: one replay of `task-tags` or `task-ecount` on
  the same lineage before the display-string rule is promoted to
  `runtime/handbook.md`.

## North-star impact

The run validates the eval's capability hypothesis: the `env` module, typed
`get_or` reads, and `fs.write` are discoverable with the current handbook, and
the Result/`?` lesson did transfer to a real config-validation boundary. The
provisional handbook candidate improves learnability and ergonomics by making
the interpolation boundary explicit (display strings vs literals), removing
three distinct repeated discoveries (`++` guess, f-string discovery, dynamic
path construction). The re-confirmed product gap — no user-visible way to
construct a typed error and fail loudly — is the opposite of the north star's
"explicit boundaries": today the only way to fail on validation is a
traceback about an unrelated host operation, which hides intent and would
recur in any config-check or assertion task. Correctness and clarity were both
achieved, so this run's token/cost efficiency concern is limited to the
avoidable error-construction exploration, which the open ticket addresses at
the product level.
