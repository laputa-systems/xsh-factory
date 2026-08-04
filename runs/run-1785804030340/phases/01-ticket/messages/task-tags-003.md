# Controller-assigned engineer ticket

This is an immutable controller assignment for one implementation worker.
The controller, not the worker, selected the ticket, snapshot, worktree, and
branch.

## Assignment authority

- Ticket ID: `task-tags-003`
- Ticket snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785804030340/phases/01-ticket/tickets/task-tags-003.md`
- Ticket snapshot SHA-256: `52c066f809ead74713ab166cd8647ce0258354a2085ff98c25cf5e05d3a624eb`
- Dedicated XSH worktree: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785804030340/phases/01-ticket/worktrees/task-tags-003`
- Branch: `factory/task-tags-003/1785804031017`
- XSH base commit: `5cee79306e2ce8c12fbd5b8575ff7accfcc5c82f`
- engineer report: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785804030340/phases/01-ticket/workers/engineer/task-tags-003/REPORT.md`
- Factory root: `/Users/josh/d/laputa-systems/xsh-factory`
- Run evidence root: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785804030340/phases/01-ticket`

You are an implementation worker, not a ticket selector. Implement only the
ticket identified above and inlined below. Do not search for open tickets,
choose another ticket, or broaden this assignment. Do not create or modify a
ticket assignment. If the ticket ID, worktree, branch, or snapshot is missing
or conflicts with the runner's `FACTORY_TICKET_ID` or `FACTORY_WORKDIR`, stop
and report the assignment problem; do not guess.

The snapshot path is retained for provenance. The inlined snapshot below is
the controller's authoritative task input, so no ticket-discovery read is
required. Relative links in that snapshot resolve from the factory root above,
not from the XSH product worktree; use exact paths under that root if linked
evidence needs to be consulted.

## Ticket snapshot

<!-- CONTROLLER_TICKET_SNAPSHOT_BEGIN -->
# Ticket task-tags-003

## Status

Approved.

## CTO review

- Review cycle: `pre-cycle-1785803972` (2026-08-03)
- Decision: Approved for the next two-engineer ticket cycle.
- Basis: The f-string interpolation span defect is reproducible in a minimal
  parser case and has a bounded source-location contract.
- Assignment boundary: Correct the source span for lex/parse errors inside
  f-string interpolation without changing valid interpolation semantics or
  unrelated diagnostic recovery.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-tags` (`evals/task-tags/EVAL.md`)
- Shared handbook lineage: `runs/run-1785693519510/lineage/handbook-approved.md` (approved `c7c9dd9a…`) and `runs/run-1785693519510/lineage/handbook-candidate.md` (provisional `01881761…`)
- Manager run: `runs/run-1785693519510/workers/eval-manager/task-tags/session.jsonl.bz2`
- Executor run: `runs/run-1785693519510/workers/eval-worker/task-tags-1` (trial 1) and `task-tags-2` (trial 2)
- XSH baseline commit: `de9880ce9cd13c4ef63acc212554d786358ed869`

## Observation

When an f-string interpolation body contains an invalid token, `xsht check`
reports the lex/parse error at the enclosing procedure signature instead of at
the interpolation content. In the task-tags trial-2 session, the worker wrote
`print f"tags: ${lowered.join(', ')}"` and `xsht check` answered:

```text
err[lex.unexpected-character]: unexpected character
  tag.xsh:1:14
  proc main(...argv: List[Str]) [io] {
               ^ not valid in source
err[lex.unexpected-character]: unexpected character
  tag.xsh:1:17
  proc main(...argv: List[Str]) [io] {
                  ^ not valid in source
err[parse.expected-expression]: expected expression
  tag.xsh:1:15
  proc main(...argv: List[Str]) [io] {
                ^ expected expression
err[parse.expected-token]: expected `)` after call arguments
  tag.xsh:1:15
```

The real mistake was a single-quoted string literal `', '` (unsupported by
XSH string syntax) inside the `${...}` interpolation. The diagnostic pointed
at the spread parameter `...argv` on line 1, which was valid and unchanged,
so the worker spent six-plus tool rounds (cat -A, xxd, head, re-writes)
hunting a phantom `...argv` problem. The identical single-quote mistake in a
normal expression is located correctly.

## Evidence

- Worker session (trial 2): `runs/run-1785693519510/workers/eval-worker/task-tags-2/session.jsonl.bz2` — tool results at lines 21/25/31 show the phantom `tag.xsh:1:14`/`1:17` errors for the f-string draft; line 31 shows the worker hexdumping the file because the bytes were obviously fine; line 19 shows the control: the same signature with `$lowered.join(", ")` interpolation passed `xsht check`/`fmt`/`lint` and ran correctly.
- Worker review: `runs/run-1785693519510/workers/eval-worker/task-tags-2/review.md`, `## xsht friction` item 1 — independent report of the same symptom: "the lexer reported unexpected characters at the `...argv` spread signature (columns 14-17) even though the signature was unchanged and valid on its own. The diagnostics were confusing and pointed at the wrong location."
- Host probes on the pinned build `xsh-factory-base:vb4285634fa55f262` (image id `sha256:b247b5317c5f3dc6cbc90a7ee1b746711f1d7ed2eab9c89a246f29a8ec42e6ec`, XSH commit `de9880ce9cd13c4ef63acc212554d786358ed869`), all via `xsht check`:
  - `print f"tags: ${lowered.join(', ')}"` → mislocated at `1:14`/`1:17` (reproduces the worker exactly).
  - `let s = lowered.join(', ')` (same single quote outside an f-string) → located correctly at `5:24`/`5:27`.
  - `print f"a ${1 + } b"` (malformed expression inside interpolation) → mislocated at `1:5`.
  - `print f"a ${x + y} b"` (valid syntax, unresolved name) → located correctly at `2:15`/`2:19`.
  - Scope conclusion: lex/parse errors inside f-string interpolation content misreport their span; check-phase errors inside interpolation are located correctly.
- Evaluator manifest: `run.json` in both trials — pass, all exact; the defect is diagnostic quality, not a correctness blocker.

## Diagnosis or hypothesis

XSH's fmt-string lexer/parser error recovery attributes lex/parse errors
inside `${...}` to an enclosing token position (the surrounding procedure
signature) rather than to the interpolation content's true span. This is a
general tooling correctness/ergonomics issue: any agent or person writing an
f-string with an invalid interpolation token — a typo, an unsupported
single-quoted literal, a malformed expression — receives a phantom error at
the `proc` line that names no actual mistake. It is not a task-tags recipe:
the same mislocation reproduces in minimal scripts independent of the task.
It also interacts badly with agent trust: a spread parameter that the
diagnostic falsely blames looks like something to delete, which would break
valid programs. The task-tags trial-2 worker correctly attributed the
problem to the f-string after debugging, but lost several turns and reached
for hexdump/cat -A because the tool pointed at the wrong bytes.

A secondary, related ergonomics point surfaced in the same trial: `'...'`
single-quoted literals are not string literals in XSH, and the lexer error
offers no hint to use `"..."`. A clearer diagnostic at the true location
would have taught the correction in one shot.

## North-star impact

The north star asks for explicit boundaries and trust: "an agent can
understand, use correctly, and explain." A tool error that points at the
wrong line of a valid signature is exactly the opaque, trust-eroding surface
the factory should remove. Fixing diagnostic spans for f-string interpolation
would help any eval or real script that uses `f"..."`, regardless of task.
Evidence of generalization: the mislocation reproduces with minimal
interpolation-only scripts (probes D/G/I), so a later replay can test it with
fresh content; a correctly located error plus a hint for the unsupported
quote form would have collapsed the worker's six-round debug loop into one
read.

## Proposed XSH change

Fix the fmt-string lexer/parser so lex/parse errors originating inside
`${...}` report the exact line/column of the interpolation content (or of the
f-string token when the span is genuinely the whole literal), never the
procedure signature. If feasible in the same fix, extend the
`unexpected-character` message for `'` inside a string/interpolation context
to note that XSH strings use `"..."`, not `'...'`. No runtime semantics
change.

## Acceptance criteria

- `xsht check` on a script whose f-string interpolation contains an invalid
  token (e.g., `'x'`, `1 + }`) reports the error at the true line/column of
  the offending token, with a message identifying it; the error never points
  at the `proc` signature's spread parameter when the signature is valid.
- Valid programs using `f"..."`, `...argv` spread parameters, `$name`
  command-word interpolation, and `r"..."` raw strings still pass
  `xsht check`/`fmt`/`lint` exactly as before.
- A replay of `task-tags` shows the worker resolving a single-quoted-string
  typo inside an f-string from a correctly located diagnostic, with no
  phantom-`...argv` debugging loop, and still passing all three argument
  cases byte-for-byte.

## Scope and non-goals

- No change to f-string or string runtime semantics; diagnostics only.
- No change to the `lint.dollar-in-expression-string` or
  `redundant-command-interpolation` rules.
- No handbook edit inside XSH; the factory lineage owns the agent-facing
  handbook.
- Not a task-tags shortcut; the fix must apply to f-string interpolation in
  any script.

## Post-merge evaluation

The `task-tags` eval-manager will run a controlled replay against the merged
XSH commit using the current approved handbook lineage, check that the
phantom signature-location diagnostic no longer appears for invalid
interpolation content, and record acceptance or rejection in that run's
manager report.

<!-- CONTROLLER_TICKET_SNAPSHOT_END -->

## Factory context required before coding

The factory documents below are outside the XSH worktree. Before coding, use
the `read` tool on each exact absolute path. This is required so the session
JSONL proves that the worker consumed the current factory guidance:

- North star: `/Users/josh/d/laputa-systems/xsh-factory/NORTH-STAR.md`
- Shared handbook: `/Users/josh/d/laputa-systems/xsh-factory/runtime/handbook.md`

Then use the `read` tool on the product worktree's exact guidance files:

- Product agent guide: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785804030340/phases/01-ticket/worktrees/task-tags-003/AGENTS.md`
- XSH rationale: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785804030340/phases/01-ticket/worktrees/task-tags-003/docs/CHAPTER-01-why-xsh.md`

## Implementation contract

Work only in `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785804030340/phases/01-ticket/worktrees/task-tags-003` on branch `factory/task-tags-003/1785804031017`. Do not edit XSH main, the
factory main tree, or the ticket diagnosis. Make the smallest general XSH
language, tooling, test, or canonical-documentation change supported by the
ticket. Run the narrowest relevant checks, commit the product change on this
branch, and leave the worktree clean.

The controller has staged a fail-closed `not-ready` report at
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785804030340/phases/01-ticket/workers/engineer/task-tags-003/REPORT.md`. Complete that file in place; do not spend turns
reconstructing its headings. Keep `## Result` as `not-ready` until the
acceptance checks, commit, and clean-worktree validation are complete.

Write `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785804030340/phases/01-ticket/workers/engineer/task-tags-003/REPORT.md` with these exact headings:

```markdown
## Result

ready-for-review

## Branch

<branch name>

## Commit

<commit hash>

## Files changed

<short list>

## Tests

<commands and results>

## North-star impact

<how this improves XSH or agent use>

## Remaining risks

<known limitations, or None.>
```

Change `## Result` to `ready-for-review` only when the branch is committed, the worktree is
clean, and the relevant checks passed. Do not merge the branch or update the
ticket status; the deterministic controller records it for CTO review.
