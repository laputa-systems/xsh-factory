# Eval-manager report: task-propsort

## Result

fail

The single controller trial (run-1786136684797, XSH commit
`857154dfe505f0d01053c1b5311f44422070eb34`) produced a byte-exact, correct
solution whose only failing gate is the eval's restriction heuristic.
Correctness passed (`exact: true`), protocol passed (`review_ok: true`), and
restrictions failed (`restriction_ok: false`) because the package evaluator
requires the literal substring `"fs."` in the source
(`let restriction_ok = "fs." in source and ! source_has_forbidden(source)`),
while the agent read the input through the typed `Path.read_text()` host API.
`Path.read_text()` is a real, checked, non-subprocess file read that the task
text itself permits ("read the file through XSH filesystem/text APIs"), and
the submitted program is not hard-coded and runs no subprocess. The fail is an
evaluator restriction-proxy false negative on an otherwise correct solution,
not an agent-ergonomics or product defect.

## Effort metrics

Single trial (`task-propsort-1`), eval-worker:
- Assistant turns: 24 (1 user message)
- Tool calls: 28; tool results: 28; tool errors: 4
- Worker friction: 4 resolved dev-loop errors (see Tool-error findings). All
  were the model learning the effects contract, path interpolation, and lint
  feedback; none were blockers and all were corrected within the session.
- Session span: 55,891 ms (agent wall 59,902 ms) — fast, no latency concern.

Provider telemetry present; `retry_count` 0, `provider_errors` [], retry
delays 0. No external-health signal. Latency attribution: not a factor;
efficiency judged from turns/tokens/tool errors/correctness.

## Usage and cost

Worker provider-reported buckets (single trial):
- input 14,943; output 3,958; cacheRead 216,832; cacheWrite 0
- total bucket tokens 235,733; provider_total_tokens 235,733 (equal, no
  mismatch)
- reasoning_tokens 1,169 (provider-reported; subset of output, not added)
- cost: input $0.00134487, output $0.00071244, cacheRead $0.003902976,
  cacheWrite $0, total $0.005960286
- budget $0.50; budget_state pass; budget_failures 0

Aggregate across trials: only trial 1 ran, so aggregate equals trial 1.

## Thinking evidence

14 thinking blocks in the worker session; reasoning_tokens 1,169. The provider
reported a reasoning-token count, so no "reasoning unavailable" caveat applies.
Thinking transcript (in session.jsonl.bz2) shows the model reasoning through: the
`?`/`error` effect contract, `p"..."` non-interpolation vs `fp"${expr}"`,
`Str.lines()` behavior (trailing-newline handling, whitespace preservation),
the `sort` stream stage, and the standard-module-shadow on the name `path`.
The thinking was directly correlated with the tool errors and the final fix.
No evidence of hidden or misleading reasoning.

## Tool-error findings

4 nonzero Pi tool results, all from the eval-worker structured `tool_errors`
array (the manager report packet itself has zero tool errors):

1. Turn 6 `bash`: `xsht api language:stream.sort-by` returned `status: exact`
   with the full `sort-by` contract/signature but exited code 1 (empty
   `===LIST===` trailer). The query succeeded and supplied the needed info;
   the nonzero exit is an `xsht api` quirk. Classified: ordinary tooling
   noise / resolved.
2. Turn 9 `bash`: `err[check.effect-violation]` — `?` requires the `error`
   effect in a probe. The agent added `[fs, error]` and continued. Classified:
   worker dev-loop friction, resolved.
3. Turn 12 `bash`: `err[parse.expected-terminator]` from nested quotes in
   `let path = p"${argv.get(0, "")}"`. Agent switched to binding the name
   then `fp"${name}"`. Classified: worker dev-loop friction, resolved.
4. Turn 17 `bash`: `xsht check/fmt/lint` reported `standard-module-shadow`
   (`path` shadows the standard module), `unknown-module-api`, and
   `bare-print-ident` (`print l` vs `print $l`). Agent renamed to `fpath` and
   dereferenced with `$l`. Classified: worker dev-loop friction (real XSH
   diagnostics doing their job), resolved.

None of the four represents a product defect or a failed manager query.

## Timing evidence

This eval declares no strict candidate/oracle timing gate; both sides finish in
milliseconds. Candidate stdout for the public fixture matched the BusyBox
oracle byte-for-byte (`alpha/beta/zebra`). Timing is diagnostic only; no
gate implicated. Agent session span (~56 s) is separate from candidate run
time.

## Observation classification

- **Correctness: pass.** Final `propsort.xsh` produced byte-exact output
  matching the oracle on the public case and on the agent's local whitespace,
  comment-only, and empty fixtures; `xsht check|lint` clean.
- **Restriction / evaluator heuristic: fail.** The gate `"fs." in source`
  rejected a valid `Path.read_text()` read. The eval's semantic intent —
  reject hard-coded text literals and subprocess escape — is satisfied by the
  submitted file read, and the task text explicitly permits "XSH
  filesystem/text APIs". This is a reproducible, single-target
  evaluator/harness false negative, not an XSH product problem and not agent
  inefficiency.
- **Protocol: pass.** `review.md` present, both `## XSH language proposals`
  and `## xsht friction` headings preserved, no `{{` placeholders.
- **Worker friction: low.** 4 tool errors, all resolved; 24 turns for a small
  task is reasonable and output-model cost was ~$0.006.
- **Product/tooling defect: none identified.** The `xsht api` exit-1-on-exact
  quirk is minor and non-blocking and already within the documented
  discovery surface.
- **Noise:** the sort-by query exit code. No further scan warranted.

Overall signal: the read->trim->filter->sort pipeline works through the typed
host API, but the eval's `fs.`-substring proxy means the run does not cleanly
exercise the intended "discover the `fs` read facade" hypothesis and yields a
false fail.

## Handbook decision

Unchanged. Copied `lineage/handbook-approved.md`
(`sha256 3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b`)
to `lineage/handbook-candidate.md` unchanged (same hash). No agent friction
justified a new rule: the dev-loop errors were already covered by existing
handbook guidance (effects, `fp"${expr}"`, `print $var`), and the one real
finding is an evaluator restriction heuristic that no handbook sentence can
cure. No candidate to promote; no replay of a candidate occurred.

## Tickets created

None. The restriction-proxy false negative is an eval-evaluator issue, not a
general XSH ergonomics/correctness product problem, and not factory shared
infrastructure. Per manager policy it is reported as an evaluator/harness
finding rather than a ticket; no engineer dispatch.

## Post-merge decisions

None. The reconciler reported merged tickets: `none`. There is no post-merge
acceptance assignment for this cycle, and the candidate re-evaluation flag is
`not-reevaluation`, so no clean-engineer-worktree validation applies.

## Next replay

No handbook candidate to falsify. The useful next step is a fresh
`task-propsort` trial after the eval designer decides whether `Path.read_text()`
(and any typed, non-hard-coded read) should satisfy the "reads through XSH
filesystem/text APIs" restriction gate, or whether the `"fs."` proxy should be
relaxed to check for subprocess escape and hard-coded output only. A
subsequent trial under the same `handbook-approved.md`
(`3b56a781...`) would then measure whether the eval's stated fs-facade
hypothesis is exercised.

## North-star impact

Muted, infrastructure-leaning. The agent produced a correct, small,
subprocess-free program through the typed `Path.read_text()` host API,
tentatively confirming that the text/file/stream read->filter->sort->exact
output pipeline is reachable. But because the eval's restriction proxy
rejected that correct read, the run did not cleanly test the design
hypothesis (discoverability of the `fs` read facade) and recorded a false
fail. No durable product or handbook improvement emerged this cycle; the
durable takeaway is a request to correct the eval's restriction heuristic so
the eval measures the intended capability rather than a literal `"fs."`
substring.
