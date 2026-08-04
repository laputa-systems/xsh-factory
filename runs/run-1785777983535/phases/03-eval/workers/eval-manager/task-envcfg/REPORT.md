# Eval-manager report

## Result

pass

## Effort metrics

One configured trial (controller-requested count = 1). Single worker
`task-envcfg-1` on model `openrouter/deepseek/deepseek-v4-flash-0731`.

Per trial (worker `report.json`):
- assistant turns: 91
- tool calls: 93; tool results: 93; tool errors: 6
- session wall span: 690,775 ms (~11.5 min); agent wall 692,595 ms
- tools used: bash 88, read 3, edit 1, write 1
- user messages: 1; stop reasons: 1 stop, 90 toolUse
- worker friction: high. The task's correct solution is ~10 lines, yet the
  worker burned most of the session discovering the planned `api:env.int` /
  `api:env.bool` typed-read surface and, above all, searching for a clean way
  to exit nonzero on a malformed `CFG_PORT` (see Tool-error findings and
  Observation classification). The dominant cost driver was language
  discovery, not task logic.

## Usage and cost

Provider-reported usage for the single worker (all buckets in tokens):
- input: 162,426; output: 32,350; cacheRead: 1,998,592; cacheWrite: 0
- provider total: 2,193,368; bucket total (input+output+cacheRead+cacheWrite):
  2,193,368 (buckets reconcile exactly)
- reasoning tokens reported: 22,384 (subset of output; not added to totals)
- thinking blocks: 68
- cost: total $0.056415996; input $0.01461834; output $0.005823;
  cacheRead $0.035974656; cacheWrite $0
- budget: $0.5, usage well under; budget_state pass
- Aggregate = per-trial here (one trial): $0.0564, 2.19M total bucket tokens.

## Thinking evidence

68 thinking blocks recorded in the session (`thinking` content items, count
matches the 68 in `report.json`). Provider reported 22,384 reasoning tokens,
so reasoning counts are available but are a subset of output tokens.

Finding grounded in the transcript: most thinking was spent navigating the
error/warning surface of the language. Blocks around the failing probes
(evt 48–124, `panic`/`fail`/`Err`/`Error`/`FsError` searches) show the agent
repeatedly trying to originate a controlled failure, and blocks around
`xsht api summary | grep` (evt 64–122) show it compensating for the lack of a
per-type API index. Neither is a comprehension error; the worker understood
the task oracle and the `?` propagation model (it wrote `env.get_or(...)?` and
correct `...argv` rest-form `main` from the start of the final solution). The
thinking is qualitative confirmation that the friction is a language/reference
gap rather than task confusion.

## Tool-error findings

All six nonzero tool results live in the worker session `task-envcfg-1`
(no manager-session tool errors). Each is accounted for:

1. (report turn 29 / evt 60) `probe6.xsh` — `panic "boom"` →
   `err[check.unresolved-proc-command]: unresolved proc command`. The worker
   probed for a `panic` abort primitive; none exists. This is the
   error-construction / no-fail-primitive gap, already tracked in open ticket
   `task-envcfg-001`.
2. (report turn 38 / evt 78) `probe7.xsh` — `return Err("bad config")` →
   `type mismatch: expected Result[Str, Error], found Result[<unknown>, Str]`.
   Same error-constructor gap as #1; directly reproduces the diagnostics in
   `task-envcfg-001`.
3. (report turn 51 / evt 104) shell `syntax error: unexpected "("` in a
   `for FsError.NotFound ...` variant probe loop. A Bash/heredoc quoting slip
   by the worker while probing error variants; self-inflicted harness friction,
   ordinary noise, no product signal.
4. (report turn 57 / evt 116) `xsht api summary | sed -n '/^l...'` printed the
   module index but exited 1 (sed range did not match). An unsuccessful
   discovery query; the worker recovered by narrowing the `sed`/`grep` filters.
   Minor reference-browsing friction, weakly related to `task-envcfg-004`.
5. (report turn 58 / evt 118) `xsht api language:proc | grep ...` → no output,
   exit 1. An API discovery query that resolved nothing; grep no-match. Same
   discovery friction as #4.
6. (report turn 61 / evt 124) `printf 'proc main() -> Result[Str, ...'` →
   `sh: syntax error: bad substitution` plus a runtime traceback. A shell
   quoting slip while printing an XSH sketch with `$`-delimited text inside a
   double-quoted Bash `printf`; self-inflicted harness friction, ordinary
   noise.

Net: errors 1–2 are the reproduced error-constructor product gap; 4–5 are
reference-browsing discovery friction; 3 and 6 are worker shell-quoting noise.
None indicate an evaluator or harness mismatch, and none blocked the eval.

## Timing evidence

No strict candidate/oracle timing gate (per EVAL.md, both sides finish in
milliseconds and timing is diagnostic until a stable envelope is established).
Candidate vs oracle wall times (ns) for the 10 cases — candidate range
11.0–13.2 ms, oracle range 10.9–13.5 ms; all within ~2.5 ms of each other and
roughly symmetric (no case shows a consistent candidate penalty):

- public: 11,053,235 vs 11,985,408
- hidden_defaults: 11,011,026 vs 12,640,537
- hidden_partial: 11,786,781 vs 12,231,576
- hidden_empty: 13,119,540 vs 11,470,779
- hidden_spaces: 12,755,953 vs 13,429,583
- hidden_zero: 13,119,081 vs 13,506,208
- hidden_utf8: 11,192,111 vs 12,959,747
- hidden_debug_false: 11,230,153 vs 10,973,318
- hidden_malformed: 12,928,622 vs 13,287,249 (both nonzero, no file)
- hidden_empty_port: 13,161,664 vs 12,275,201 (both nonzero, no file)

Timing is diagnostic only; both the failure controls exited nonzero when
required. `timing: pass`.

## Observation classification

- Correctness: pass — all 10 cases byte-exact, including the two failure
  controls (nonzero exit, no output file). `restrictions.passed: true`
  (`env_referenced: true`, no forbidden subprocess), `protocol.review_ok: true`.
- Product/tooling defect (strong, reproduced): no user-constructible error
  value and no `fail`/`assert`/`panic` primitive. The worker's only way to
  exit nonzero was to exploit an out-of-bounds list index
  (`let p = [0][rawport.byte_len() + 1]`) so the program crashes with a
  runtime error before `fs.write`. The review.md records this as the top
  `## xsht friction` item ("There is no clean, lint-clean way to make a program
  exit nonzero on an invalid-input condition"). This reproduces open ticket
  `task-envcfg-001` (which documented the fake `env.get` workaround at commit
  `defa805a`); this run strengthens it with a second, distinct workaround at
  the current commit `ea7dea2f`. No new ticket — the observation is already
  tracked.
- Reference friction (recurring, medium): the worker repeatedly fell back to
  `xsht api summary | grep/sed` to browse type members and error variants
  because bare receiver queries (`method:Str`) are rejected. Matches open
  ticket `task-envcfg-004`. Not a new ticket.
- Worker friction / ordinary noise: shell-quoting slips in two discovery
  probes (errors 3 and 6) cost a few turns but are not a product or handbook
  signal. Combined with the intended `api:env.int`/`api:env.bool` typing not
  being used (the worker validated with `regex.compile` instead) this is task
  exploration, not a defect.
- No evaluator failure, harness mismatch, or image mismatch observed.
- Generalization: the error-construction and api-index gaps are both general to
  any validation/abort or type-browsing workflow, not envcfg-specific, and both
  already have open product tickets.

## Handbook decision

Provisional candidate staged at
`runs/run-1785777983535/phases/03-eval/lineage/handbook-candidate.md`
(approved snapshot `c7c9dd9a…` plus one sentence in the "Development loop and
tooling" section). General lesson: when `xsht api` rejects a bare receiver
query (`method:Str`), browse a type's full member surface with
`xsht api summary | grep NAME`, rather than probing rejected query forms one at
a time. This is a short, reusable learning guide that does not depend on the
product-index fix in `task-envcfg-004` and would remove the recurring
rejected-query discovery loop seen in this run and in the `task-envcfg-004`
run.

This was a one-trial plan, so the candidate is a hypothesis only; promotion to
`runtime/handbook.md` requires a later replay. The largest friction of this run
(the missing error/fail primitive) is a product defect tracked in
`task-envcfg-001`, not fixable by a handbook edit, so no handbook candidate is
offered for it.

## Tickets created

None. All distinct observations map to already-open tickets: the
error-construction/no-fail-primitive gap to `task-envcfg-001` (this run's
out-of-bounds-index workaround and the two error probes #1/#2 are fresh,
reproducible evidence for it), and the per-type API index gap to
`task-envcfg-004`. No manager-session evidence warrants a new ticket for the
next cycle.

## Post-merge decisions

None. The reconciler reported no merged ticket for this run (`none`), so there
are no post-merge acceptance assignments to evaluate.

## Next replay

`task-envcfg`, on the shared `runtime/handbook.md` lineage, at whatever XSH
commit the merged implementation of `task-envcfg-001` and/or `task-envcfg-004`
lands. After `task-envcfg-001` merges, replay `task-envcfg` and require the
malformed-port path to use the documented error constructor (or `fail`/`assert`
primitive) instead of an out-of-bounds-index or fake-host-call workaround,
with all 10 oracle cases still byte-exact. Replay the handbook candidate
(`xsht api summary | grep NAME` browsing note) in a later task-envcfg or
task-tags trial to see whether it removes the rejected-query discovery loop
before promoting it to `runtime/handbook.md`.

## North-star impact

This run confirms that XSH's central failure mechanism (`?` propagation) can
only be fed by real host failures: an agent handling a plain validation
boundary had to manufacture a runtime crash (out-of-bounds list index) or,
in the earlier run, a fake failing `env` call, to exit nonzero — exactly the
opaque, boundary-hiding trick the north star says XSH must avoid. That is a
durable ergonomics/correctness product gap, already on the shared lineage as
`task-envcfg-001`. The secondary signal (type-surface browsing requires a
full-index dump + grep) is a learnability/reference gap tracked in
`task-envcfg-004`, with a provisional handbook safety-net sentence staged for
replay. Together these move the mission forward by making "abort on bad
input" a first-class, teachable action and by removing repeated discovery
friction, while this run itself passed all ten correctness cases byte-for-byte
against the oracle.
