# Eval-manager report

## Result

fail

The cycle-level result is **fail**, but the failure is entirely at the
evaluator/harness level, not candidate correctness. The single worker produced
a byte-for-byte-correct `findexec.xsh` (verified against the `find ... -perm
-u+x | sort` oracle on a crafted fixture, `/usr/share`, `/usr`, and `/`), but
the package-owned evaluator crashed with a runtime error
(`err[runtime.error]: status ... missing-field: status` at
`/run/evaluator.xsh:35`), so no evaluator `run.json` was written and the phase
counted the trial as incomplete (`trial-count` observed 0,
`missing-evaluator-manifest`). No XSH product defect was observed, and no
product ticket is warranted. The evaluator.harness defect is reported as a
factory finding for the CTO.

## Effort metrics

Trial 1 (evaluator-worker task-findexec-1, single trial plan):

- Assistant turns: 22 (1 user message; 1 normal `stop` + 21 `toolUse` stops)
- Tool calls: 23; tool results: 23; tool errors: 2
- Session span: 74 854 ms (~74.9 s) — very fast, no idle gaps in transcript
- Worker friction: 2 recoverable tool errors (see Tool-error findings); both
  resolved in the following turn with no repeated exploration. The agent read
  `agents.md`/`handbook.md`/`task.md` first, ran 2 targeted `xsht api` probes
  (`api:fs.files`/`api:fs.walk`, `language:stream.sort-by`), built a small
  fixture, and verified byte-equality on four trees before finalizing. No
  unproductive exploration.

## Usage and cost

Trial 1 (provider-reported; openrouter/deepseek/deepseek-v4-flash-0731):

- Input tokens: 14 317; output tokens: 3 004
- Cache read: 181 824; cache write: 0
- Bucket total: 199 145; provider total: 199 145 (buckets reconcile exactly)
- Reasoning tokens reported: 748 (subset of output). Thinking blocks: 12
- Dollars: input $0.00128853; output $0.00054072; cacheRead $0.003272832;
  cacheWrite $0; total $0.005102082
- Budget: $0.5 (budget_state `pass`); aggregate cost for the 1-trial plan is
  $0.0051.

## Thinking evidence

12 thinking blocks; the provider reported 748 reasoning tokens (subset of
output, not added to totals). Grounded in the session transcript: the agent's
thinking shows it correctly (a) discovered `owner_executable`/`kind`/`hidden`
from `xsht api api:fs.files`, (b) reasoned that `sort-by` on a `Path` key gives
byte/lexicographic order and that `fs.files(root, hidden: true)` matches the
oracle's dotfile inclusion, and (c) deliberately avoided C-style `&&` after the
parse error. Thinking was concise, hypothesis-driven, and matched the observed
tool sequence. 12 thinking blocks is qualitative evidence, not a proof of
correctness; correctness is established independently by the byte-for-byte
output match.

## Tool-error findings

Worker `task-findexec-1` session, 2 nonzero Pi tool results (both recovered
without changing strategy):

1. `bash` @ turn 9 — `err[parse.unsupported-boolean-operator]` for `&&` in the
   `where` predicate, plus a cascade of expected-terminator/expression errors.
   XSH rejects `&&`; the error message directs the agent to `and`. The agent
   corrected to `and` in one edit + re-check. Not a product defect (it is
   intended language design with a good diagnostic); candidate for a concise
   handbook note.
2. `edit` @ turn 20 — "Found 2 occurrences of the text in /work/review.md. The
   text must be unique." The agent edited `None.` which appears twice; it
   re-read the file, determined the review was already correct with both
   sections present, and left `None.` untouched. Recoverable, self-corrected,
   no change to the artifact. Ordinary friction/noise.

No invalid `xsht api` discovery queries occurred; all three `xsht api` calls
returned `exact`/`matches` status. Manager session produced zero tool errors
(`None.` for the manager-side structured report). The worker's 2 errors above
are the complete current-packet tool-error set.

## Timing evidence

This eval has **no strict candidate/oracle timing gate** (per EVAL.md, timing
is diagnostic until a stable envelope exists). No candidate/oracle timing was
captured in the worker report (`timing.session_span_ms` is the Pi session, not
the submitted program). The agent session was 74.9 s with no provider-latency
signal: `provider_telemetry` present, `retry_count` 0, `provider_errors` []
and `retry_errors` [], response_elapsed_ms 0. Latency attribution is clean
(normal provider health); the low turns/tokens/errors independently support an
agent-efficiency-positive reading.

## Observation classification

- **Correctness (positive):** Candidate stdout equals oracle stdout
  byte-for-byte (`candidate.stdout` == `oracle.stdout`):
  `/tmp/task-findexec-root/nested/owner-hidden` and
  `/tmp/task-findexec-root/owner`; the agent independently matched `/`, `/usr`,
  `/usr/share`, and a crafted dotfile/symlink/group-only fixture. Uses typed
  `owner_executable`, `kind == "file"`, `hidden: true`, `sort-by` on `Path` —
  exactly the north-star hypothesis. Evidence: session turns 12–19 and the
  artifact/work/findexec.xsh.
- **Evaluator/harness failure (factory finding):** `/run/evaluator.xsh:35`
  `missing-field: status` aborted evaluation before `run.json` was written
  (`run.json` absent throughout the phase; `evaluator_manifest` empty;
  `trial-count` observed 0; phase outcomes infrastructure fail). The
  `setup.status.ok and candidate.status.ok and expected.status.ok` chain
  dereferences a `.status` field that the `process.run` result does not expose
  in this build. Candidate/restriction/protocol content was almost certainly
  correct; the gate crashed. Owned by the CTO as factory/eval-harness
  infrastructure; do not dispatch an engineer and do not open a factory-target
  product ticket.
- **Worker friction (reusable handbook guidance):** the one real friction was
  the `&&` parse error. It is a general, reproducible language fact resolved
  only by the run-time diagnostic, not by the current handbook (handbook lists
  no boolean-op note). Small but generalizable → provisional handbook
  candidate (see Handbook decision). Not a product defect.
- **Ordinary noise:** the second `edit` ambiguity on `review.md` is noise; the
  agent self-corrected and the deliverable was already valid.
- No restriction violation: artifact is pure `fs` pipeline (no `run`/process/
  spawn), confirmed by the artifact source and the agent's own consistency.

## Handbook decision

**Provisional candidate** staged at
`runs/run-1785958228987/phases/01-eval/lineage/handbook-candidate.md` —
approved snapshot copied verbatim plus one added sentence under "Values have
explicit types":

> Boolean conditions are composed with the word-form operators `and` and `or`
> (`e.kind == "file" and e.owner_executable`); the C-style `&&` and `||` are
> rejected at parse time with a message that suggests the word form, so reach
> for the word operators rather than the shell/C form.

General lesson taught: XSH boolean composition uses the word operators, not
C/shell symbols — a cross-cutting language fact that any `where`/predicate task
can hit. It is short, general (not task-specific), and removes a guaranteed
first-try parse error for agents coming from shell/C. This is one-trial
evidence only; the candidate must be replayed (see Next replay) and reviewed by
the CTO before promotion to `runtime/handbook.md`. The approved snapshot and
the checked-in `runtime/handbook.md` were not modified.

## Tickets created

Zero. No XSH product/tooling defect was reproduced that would warrant an
engineer ticket: the candidate was correct, the `&&`→`and` behavior is
intended design with a good diagnostic (handbook candidate instead), and the
only failing component was the evaluation harness, which belongs to the CTO,
not to an engineer ticket.

## Post-merge decisions

None. The reconciler found no merged ticket files (`none`) for this cycle, and
candidate re-evaluation is `not-reevaluation` (no pre-merge validation
required). No acceptance/revert decisions apply.

## Next replay

Re-run `eval task-findexec` (same eval id, same XSH commit
`1cf4ad3d7ee5fde9b3160b11d8073cbd7ce5e7c4`) against the provisional
handbook-candidate lineage **after the CTO fixes the evaluator
`missing-field: status` defect** so a valid `run.json` is produced. The replay
is a falsification check of the one-sentence boolean-operators handbook claim
(a second eval, ideally one using compound `where` predicates such as
`task-manifest` or `task-ecount`, should also replay the global claim before
promotion). The candidate should only be promoted to `runtime/handbook.md`
after that replay agrees and the CTO approves.

## North-star impact

This run advances the practical, learnable, ergonomic, trustworthy aims of XSH
on three axes: (1) it demonstrates that a systems-administration workflow the
suite previously lacked — executable-file discovery via typed permission
metadata — is reachable through the fs stream with a short, direct, subprocess-
free pipeline that matches the `find` oracle byte-for-byte, strengthening the
case that the typed metadata boundary is usable and discoverable; (2) the
provisional handbook candidate turns a guaranteed first-attempt parse error
(`&&` vs `and`) into one explicit, reusable rule, reducing repeated discovery
for future agents and improving learnability; and (3) the clearly-attributed
evaluator crash separates candidate-correctness evidence from harness
reliability, so the CTO can harden the eval gate without mis-attributing a
product regression. The single reused diagnostic is trustworthy only after
replay across the shared lineage, as the evidence loop requires.
