# Controller-assigned engineer ticket

This is an immutable controller assignment for one implementation worker.
The controller, not the worker, selected the ticket, snapshot, worktree, and
branch.

## Assignment authority

- Ticket ID: `task-ecount-002`
- Ticket snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785797449435/phases/01-ticket/tickets/task-ecount-002.md`
- Ticket snapshot SHA-256: `c1ec5585bf5f257553b6305e4f43bd4b501893db5c40bed90b912445ec154ff8`
- Dedicated XSH worktree: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785797449435/phases/01-ticket/worktrees/task-ecount-002`
- Branch: `factory/task-ecount-002/1785797450137`
- XSH base commit: `84fe556cb48feb747d6b575e4925dbdc5848ecdb`
- engineer report: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785797449435/phases/01-ticket/workers/engineer/task-ecount-002/REPORT.md`
- Factory root: `/Users/josh/d/laputa-systems/xsh-factory`
- Run evidence root: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785797449435/phases/01-ticket`

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
# Ticket task-ecount-002

## Status

Approved.

## CTO review

- Review cycle: `pre-cycle-1785796761` (2026-08-03)
- Decision: Approved for the next two-engineer ticket cycle.
- Basis: The positional-optional-argument failure reproduces across `fs.files`
  and `fs.walk`, contradicts the public `xsht api` signatures, and has a
  narrow acceptance path covering runtime/checker agreement and named-argument
  compatibility.
- Assignment boundary: fix the compact-runtime/checker contract or provide a
  precise diagnostic and reference correction; do not broaden into unrelated
  indexed-IR work.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-ecount` (`evals/task-ecount/EVAL.md`)
- Shared handbook lineage: `runs/run-1785659012581/phases/03-eval/lineage/handbook-approved.md` (approved `c7c9dd9a…`; candidate unchanged)
- Manager run: `runs/run-1785659012581/phases/03-eval/workers/eval-manager/task-ecount/session.jsonl.bz2`
- Executor run: `runs/run-1785659012581/phases/03-eval/workers/eval-worker/task-ecount-1` (trial 1)
- XSH baseline commit: `a66ade8218aacb38a2d1247db192f0c550cbb5cd`

## Observation

Calling a module function with an optional argument **positionally** fails in
the pinned gym runtime with a cryptic IR error, while the same call using a
**named** argument succeeds. The `xsht api` contract advertises the optional
parameters, so positional calls look valid.

On the pinned image (`xsh-factory-task-ecount:latest`, XSH commit `a66ade82`,
image `sha256:31d7c25c5153c8d8983f9c4d7986b128de2751e49960b721a41f2cd9c91b32ec`):

```text
$ xsh probe.xsh          # let files = fs.files(root, false)?
err[compact.indexed-build]: indexed IR could not encode `full_ir_function_blocker`
  probe.xsh:1:47
  proc main(...argv: List[Str]) [fs, io, error] {
                                                ^ indexed IR could not encode `full_ir_function_blocker`
```

Reproduced for `fs.files(root, false)`, `fs.files(root, true)`,
`fs.walk(root, false)`: all fail with the same error. The named forms
`fs.files(root, gitignore: false)`, `fs.files(root, hidden: false)`,
`fs.walk(root, gitignore: false)` succeed.

`xsht api api:fs.files` reports:

```text
signature: fs.files(path: Path, gitignore: Bool = default, stat: Bool = default,
            exts: List[Str] = default, hidden: Bool = default) -> Result[...]
```

The eval-worker hit this while trying to disable the default gitignore
handling to match `fd` semantics; it documented the failure in its review and
worked around it with the single-argument call (which happens to match the
oracle for `/usr/share`, but is not faithful for trees containing a
`.gitignore`).

## Evidence

- Worker session: `runs/run-1785659012581/phases/03-eval/workers/eval-worker/task-ecount-1/session.jsonl.bz2` — tool result at line 237 (`call_00_4a5CvgtAG6pQ39CzjO6N4369`) shows the `full_ir_function_blocker` failure; the worker's thinking (blocks ~25–40) shows it trying to pass `gitignore: false` and positional forms.
- Worker review: `runs/run-1785659012581/phases/03-eval/workers/eval-worker/task-ecount-1/review.md`, section `## xsht friction` — "any call with a second argument ... fails in both `xsht check` and `xsh` with `err[compact.indexed-build]`" (note: the named-argument form actually succeeds; the precise reproducible defect is positional optional-argument calls).
- Manager host probe on the pinned image: positional `false`/`true` for `fs.files` and `fs.walk` all fail; named forms succeed; `xsht api` shows the optional-argument signature.
- Quantitative metrics: worker session completed 128 assistant turns, 146 tool calls, 2 tool errors (one is this blocker), 97 thinking blocks, $0.106; candidate artifact was byte-identical to the true oracle in a read-only host probe.

## Diagnosis or hypothesis

The compact indexed IR used by the gym runtime cannot encode positional
optional-argument calls, and the failure surfaces as an opaque
`full_ir_function_blocker` error at the `proc main` signature line rather than
a parse/type message naming the offending argument. The reference data
advertises the optional parameters without noting this limitation. This is a
general ergonomics/correctness defect, not an ecount recipe: any agent calling
any module function with a documented optional argument positionally will hit
the same opaque failure, while the named form silently behaves differently.
The fix should either (a) make positional optional-argument calls work in the
compact runtime, or (b) reject them with a clear diagnostic that names the
argument and recommends the named form, and (c) annotate the reference so the
contract does not promise positional optional-argument calls.

## North-star impact

The north star asks for a clear, typed language where "boundaries, types,
errors, and data flow" are explicit and where agents avoid "repeated
discoveries." A documented call shape that fails with an unrelated IR error
forces trial-and-error discovery and obscures the real language boundary.
Making optional-argument calls consistent (or clearly rejected) would let an
agent trust `xsht api` signatures and spend its turns on the task rather than
decoding a compiler error. Evidence of generalization: any eval agent that
passes an optional argument positionally would either compile or receive a
message naming the argument; a replay of task-ecount with a tree containing a
`.gitignore` would no longer require the single-argument workaround.

## Proposed XSH change

Smallest candidate, one of:

1. Support positional optional-argument calls in the compact indexed IR so
   `fs.files(root, false)` compiles and behaves identically to
   `fs.files(root, gitignore: false)`; or
2. If positional optional arguments are intentionally unsupported in the
   compact runtime, emit a diagnostic that names the function and argument
   (e.g. "positional optional argument 2 to fs.files is not supported by this
   build; use `gitignore:` named form") instead of
   `full_ir_function_blocker`, and update the `xsht api` reference to state
   the limitation.

No change to default-argument semantics for named calls.

## Acceptance criteria

- `xsh` (and `xsht check`) accepts either `fs.files(root, false)` or rejects
  it with a clear message naming `fs.files` argument 2 / `gitignore`, with a
  correct exit status and no `full_ir_function_blocker` text.
- The same holds for `fs.walk` and at least one non-fs module function with
  optional arguments.
- Named-argument calls (`fs.files(root, gitignore: false)`) keep working
  byte-for-byte as before.
- `xsht api api:fs.files` text matches the actual accepted call forms.
- A replay of `task-ecount` on the merged change: if the fix is option 1, the
  worker may pass optional arguments positionally or by name without the IR
  error; if the fix is option 2, the worker receives the clear diagnostic and
  switches to the named form, and the candidate still byte-for-byte matches
  the true oracle.

## Scope and non-goals

- No change to stream-stage or traversal semantics; behavior of the accepted
  call forms is unchanged.
- Not an ecount shortcut; the diagnostic or support must generalize to every
  module function with optional arguments.
- No change to the shared agent handbook inside XSH; the factory lineage owns
  the agent-facing handbook.

## Post-merge evaluation

The `task-ecount` eval-manager will run a controlled replay against the merged
XSH commit using the current approved handbook lineage, verify the positional
optional-argument behavior described in the acceptance criteria, and record
acceptance or rejection in that run's manager report.

<!-- CONTROLLER_TICKET_SNAPSHOT_END -->

## Factory context required before coding

The factory documents below are outside the XSH worktree. Before coding, use
the `read` tool on each exact absolute path. This is required so the session
JSONL proves that the worker consumed the current factory guidance:

- North star: `/Users/josh/d/laputa-systems/xsh-factory/NORTH-STAR.md`
- Shared handbook: `/Users/josh/d/laputa-systems/xsh-factory/runtime/handbook.md`

Then use the `read` tool on the product worktree's exact guidance files:

- Product agent guide: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785797449435/phases/01-ticket/worktrees/task-ecount-002/AGENTS.md`
- XSH rationale: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785797449435/phases/01-ticket/worktrees/task-ecount-002/docs/CHAPTER-01-why-xsh.md`

## Implementation contract

Work only in `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785797449435/phases/01-ticket/worktrees/task-ecount-002` on branch `factory/task-ecount-002/1785797450137`. Do not edit XSH main, the
factory main tree, or the ticket diagnosis. Make the smallest general XSH
language, tooling, test, or canonical-documentation change supported by the
ticket. Run the narrowest relevant checks, commit the product change on this
branch, and leave the worktree clean.

The controller has staged a fail-closed `not-ready` report at
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785797449435/phases/01-ticket/workers/engineer/task-ecount-002/REPORT.md`. Complete that file in place; do not spend turns
reconstructing its headings. Keep `## Result` as `not-ready` until the
acceptance checks, commit, and clean-worktree validation are complete.

Write `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785797449435/phases/01-ticket/workers/engineer/task-ecount-002/REPORT.md` with these exact headings:

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
