# Eval-manager report

## Result

pass

The eval outcome is pass: the single fresh trial (`task-pathparts-1`) passed all
seven correctness cases, restrictions, protocol, and reporting on the candidate
build. The phase-level `fail` in `report.json` is caused solely by this manager
report being absent at the time the controller snapshot was taken; writing this
report resolves it.

Candidate ticket `task-pathparts-003` (the `xsht lint` display-string
unused-local fix) is a **pre-merge validation, not a merged ticket**. On the
candidate build the eval passes with no regression, but the run does **not**
demonstrate the proposed fix: the agent composed output with the multi-argument
`print "dir="$dir` form rather than the display-string `f"dir=$dir"` form the
ticket targets, so the acceptance criteria were not exercised. Verdict:
**needs-replay** (details in Post-merge decisions).

## Effort metrics

Trial 1 (`eval-worker/task-pathparts-1`):
- Assistant turns: 17
- Tool calls: 18; tool results: 18; tool errors: 1
- Session span: 414116 ms (~6.9 min); agent wall 415270 ms
- Worker friction: one `xsht check` failure caused by naming a local `path`
  (shadows the standard module), recovered in one rename `path -> p`; minor.
- Turn/stop profile: 1 stop, 16 toolUse.

## Usage and cost

Trial 1 (single worker; aggregate equals trial 1):
- Tokens: input 64676, output 4422, cacheRead 95488, cacheWrite 0;
  bucket total 164586; provider-reported total 164586 (consistent).
- Reasoning tokens: 2351 (provider-reported, a subset of output).
- Cost: $0.008336 across buckets; budget $0.50; no budget breach.
- Model: openrouter/deepseek/deepseek-v4-flash-0731.
- No provider retries; telemetry present with 0 retries and no provider errors,
  so latency attribution is not a factor this run.

## Thinking evidence

10 thinking blocks recorded; reasoning tokens reported as 2351. Qualitative
findings from the session: the worker reasoned precisely about the oracle's
`dirname`/`basename`/`${name##*.}` extension semantics, chose
`p.dirname().display()`, `p.basename()`, and `p.ext_or("none")` based on exact
`xsht api` results, worked through the `path`-shadow check error, and verified
output against the oracle across many path shapes. Reasoning-token counts are
provider-reported; the reasoning text is qualitative evidence only.

## Tool-error findings

One failed Pi tool result (single tool error in the packet):
- Worker turn 9, tool `bash`: `xsht check pathparts.xsh` on the first draft
  returned code 2 with `err[check.standard-module-shadow]` (name `path` shadows
  the standard module) and three `err[check.unknown-module-api]` errors for
  `path.dirname()`, `path.basename()`, and `path.ext_or("none")`. The agent
  renamed the local to `p`; subsequent `check`/`fmt`/`lint` passed (exit 0).
- No invalid `xsht api` discovery queries: every `xsht api`/`search:` query in
  the session returned `status: exact` or `status: matches`.

## Timing evidence

No strict candidate/oracle ratio gate for this eval (both sides run in
milliseconds; timing is diagnostic). Per-case wall times (ns):
- public: cand 11599280 / oracle 11737989
- hidden_deep: 13972378 / 11381904
- hidden_plain: 12797912 / 14694466
- hidden_rel: 14455839 / 15850223
- hidden_dotdir: 12315118 / 15827431
- hidden_dotfile: 15918973 / 14405297
- hidden_targz: 15359887 / 11346320

All values are in the 11–16 ms band; the interleaving differences are ordinary
process-launch noise and are not used as a gate.

## Observation classification

- Worker friction / reusable handbook guidance (staged): naming a local `path`
  shadows the standard `path` module, so `xsht check` fails and then mis-reports
  the `path.method()` calls as unknown module APIs. The handbook's own example
  (`let extension = path.ext()`) uses `path` as an identifier, which misleads
  agents. One reproducible occurrence this run, independently flagged by the
  worker's `review.md`. General lesson, staged as a provisional handbook
  candidate (see Handbook decision).
- Correctness/restrictions/protocol: pass — all 7 cases byte-exact vs oracle,
  `path_referenced` true, no forbidden subprocess boundary, `review_ok` true.
- Product/tooling defect (candidate ticket): the display-string lint false
  positive that `task-pathparts-003` targets was **not** exercised. The agent
  chose multi-argument `print "dir="$dir`, which `xsht lint` already accepts;
  no new evidence either way for the fix. Ordinary agent form choice, not agent
  error.
- Harness/metadata noise: the phase `report.json` records `data.xsh_commit`
  e4059a... while the trial `run.json` and this assignment record the candidate
  f697fa... The inspected evaluator `run.json` states the trial ran on f697fa
  (the candidate worktree). Noted as a metadata mismatch with no behavioral
  impact; the trial is treated as the candidate commit.
- Provider health: telemetry present, 0 retries, no provider errors → no
  external-health confounder.

## Handbook decision

Provisional candidate staged at
`lineage/handbook-candidate.md` (added one note to the approved snapshot):
`path` is a standard module name, so a Path value should be bound to a distinct
local name (e.g. `p` or `path_val`) to avoid `check.standard-module-shadow` and
the resulting "unknown module API" follow-on errors. General lesson targets
learnability across every Path-using eval. This is provisional: it is based on
a single occurrence and must be replayed and CTO-reviewed before promotion to
`runtime/handbook.md`. The approved snapshot was not edited.

## Tickets created

Zero new tickets. No open ticket was re-observed in this run; the `path`
shadow friction is handled as a handbook candidate rather than a product
ticket because the check behaves correctly (avoiding shadowing) and the defect
is documentation/guidance. Candidate `task-pathparts-003` already exists and is
Approved (pre-merge); its validation decision is recorded below — it is not
dispatched and not marked merged.

## Post-merge decisions

None. The controller reconciled no merged tickets (`none`) in this run, so
there are no post-merge acceptance assignments.

Candidate pre-merge validation for `task-pathparts-003`:
- Candidate ticket: `task-pathparts-003` (Approved; product target).
- Implementation/candidate commit under test: `f697fa2453f676f686c685171f5a8a9d514f871e`.
- Verdict: **needs-replay** — the executor evidence supports the eval passing
  on the candidate build (no regression, all gates green) but does **not**
  support the proposed display-string lint fix.
- Evidence: the submitted artifact uses `print "dir="$dir`,
  `print "name="$name`, `print "ext="$ext` (multi-argument print with `$`
  dereference), not the display-string `f"dir=$dir"` form the ticket targets.
  Because `$dir` in print argument position is a recognized read, `xsht lint`
  exits 0 on this form regardless of the fix. Acceptance criteria 1 and 3
  (lint counting an f-string-interpolated local as read; the task-pathparts
  solution written with display strings passing lint without the `+`
  workaround) were not exercised by this agent. No revert is proposed; the fix
  is simply unverified in this form.
- Next evidence: a directed replay that requires the display-string idiom (or a
  second output-composing eval) before acceptance, per the ticket's
  `## Post-merge evaluation`.

## Next replay

1. Re-run `task-pathparts` on the candidate/merged build with the worker
   required to compose the three lines via display strings
   (`print f"dir=$dir"`, etc.) and confirm `xsht check`/`fmt`/`lint` all pass
   with lint exit 0 (no `+` workaround). This directly tests the
   `task-pathparts-003` acceptance criteria and falsifies or confirms the fix.
2. Per the ticket, add a second output-composing eval to confirm generality.
3. Replay the provisional `path`-as-module-name handbook note in the next
   Path-using eval (e.g. a subsequent `task-pathparts` or `task-safepath`
   trial) before promoting, subject to CTO approval.

## North-star impact

This run confirms the typed-`Path` decomposition surface (`dirname`, `basename`,
`ext_or`, dynamic `fp"${...}"`) is discoverable via `xsht api` and produces a
correct, byte-exact three-line result with low cost and no regression on the
candidate build — practical, composable XSH glue. It also sharpens two
learnability/trust signals: (a) the handbook's use of `path` as an identifier
conflicts with the standard-module shadow check (provisional handbook
candidate), and (b) the display-string lint false positive in
`task-pathparts-003` remains materially unverified because the agent
self-selected the multi-argument print idiom that sidesteps it. Verifying the
lint fix in the form an agent actually hits reduces workarounds and strengthens
trust in `xsht`'s own guidance, honoring the north-star goals of fewer guesses
and trustworthy tooling.
