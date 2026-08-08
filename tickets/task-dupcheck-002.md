# Ticket task-dupcheck-002

## Status

Approved.

## CTO decision — cycle-17 close

- Decision: Approved for implementation in cycle 18.
- Basis: The original `task-dupcheck` trial produced a reproducible,
  cross-probe mismatch between `xsht api` defaulted-parameter signatures and
  positional-only call syntax. The ticket has a narrow documentation/reference
  remedy, an explicit API-surface justification, and a linked acceptance
  replay. The evidence is present in the checked-in run, and the queue has no
  other fresh approved product row.
- Scope: Implement the smallest honest `xsht api` signature/contract wording
  change; do not add named-argument grammar. The linked replay must confirm
  existing positional calls and the independent histogram eval must remain
  green.
- Evidence: `runs/run-1786128115649/phases/03-eval/workers/eval-manager/task-dupcheck/REPORT.md`
  and `runs/run-1786128115649/phases/03-eval/workers/eval-worker/task-dupcheck-1/run.json`.

## CTO review

- Review cycle: run-1786128115649.
- Decision: Deferred; do not approve or dispatch.
- Basis: The named-argument/signature mismatch is reproducible and general,
  but this is one fresh eval. The manager requires replay of `task-dupcheck`
  plus a second defaulted-parameter eval before promotion of the handbook
  candidate or engineer admission. Preserve the Open observation while the
  current approved histogram implementation remains in branch review.
- Evidence: `runs/run-1786128115649/phases/03-eval/workers/eval-manager/task-dupcheck/REPORT.md`
  and `runs/run-1786128115649/phases/03-eval/workers/eval-worker/task-dupcheck-1/run.json`.

## Change target

- `product`

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-dupcheck`
- Shared handbook lineage: `runs/run-1786128115649/phases/03-eval/lineage/handbook-approved.md`
- Manager run: `runs/run-1786128115649/phases/03-eval/workers/eval-manager/task-dupcheck/`
- Executor run: `runs/run-1786128115649/phases/03-eval/workers/eval-worker/task-dupcheck-1/`
- XSH baseline commit: `1477f472d5b4d57db3584357116ef97c32358ab6`

## Observation

During a clean, all-eight-case passing `task-dupcheck` trial, the eval-worker
found that `xsht api` renders module-function signatures that invite
named-argument call syntax which the parser rejects. `xsht api api:fs.files`
prints:

```
api: module.fs.files
signature: fs.files(path: Path, gitignore: Bool = default, stat: Bool = default, exts: List[Str] = default, hidden: Bool = default)
```

The `name: Type = default` rendering strongly implies that `name = value`
named arguments are accepted. The worker tried `fs.files(root, hidden = true)?`
and `fs.files(root, hidden=true)?`, each producing the parse error
`expected ')' after call arguments`, and reproduced it standalone
(`/tmp/named.xsh`) without the postfix `?`:

```
let f = fs.files(p"/tmp/example", hidden = true)
                                       ^ expected `)` after call arguments
```

Function calls are positional-only in this build; a defaulted parameter can
only be overridden by supplying values positionally in signature order
(verified: `fs.files(root, false, false, [], true)` enables hidden traversal).
The rendered signature does not communicate that positional-only constraint,
so any agent that reads the signature and tries the natural named spelling
spends extra turns on parse errors.

## Evidence

- Session transcript `task-dupcheck-1/session.jsonl` turns 22, 24, 46: repeated
  `expected ')' after call arguments` parse errors for `hidden = true`,
  `hidden=true`, and the standalone `named.xsh` probe.
- Worker review `task-dupcheck-1/review.md` records the friction and the
  verified positional spelling `fs.files(root, false, false, [], true)`.
- Final artifact `task-dupcheck-1/dupcheck.xsh` uses the positional spelling
  and passes all eight cases against the BusyBox oracle (`run.json`
  `correctness.all_exact = true`).

## Diagnosis or hypothesis

This is a general XSH tooling/ergonomics surface problem, not task-specific
confusion. `xsht api` is the documented live reference for function contracts,
and any eval whose program calls a module function with defaulted parameters
(fs.files, fs.walk, env helpers, and others) can hit the same wall: the
rendered signature reads like labeled/named parameters, but the parser is
positional-only. The mismatch is deterministic and reproducible across two
independent probes in this session. Resolving it improves agent ergonomics
("fewer guesses, workarounds, tool errors, and repeated discoveries") for the
whole factory, not just task-dupcheck.

## North-star impact

The XSH rationale names ergonomics and honest, explicit boundaries as first
priorities. A reference surface that displays `name: Type = default` but
rejects `name = value` is a boundary that misleads the reader. Either accepting
named/optional arguments (so the displayed signature is honest) or rendering
the positional-only constraint plainly would remove a repeated-discovery class
across evals. Evidence of generalization: the same parse error stops occurring
in other evals that call defaulted-parameter module functions, confirmed by
replay of a second eval against the merged change.

## Proposed XSH change

Two candidate directions, smallest-surface first:

1. Make the rendered signature honest about positional-only calling, e.g. print
   `fs.files(path: Path, gitignore: Bool, stat: Bool, exts: List[Str], hidden: Bool)` with a note that `= default` marks an omit-able value and that calls
   are positional-only, so an agent reading the reference does not try invalid
   named syntax.
2. Alternatively, accept named/optional arguments in call position so the
   displayed signature is literally true.

## API-surface justification

Existing position-only calls already express everything this task needs, so the
capability gap is a documentation/ergonomics mismatch at the `xsht api`
surface, not a missing behavior. Option 1 adds no grammar surface and only
changes how signatures/contracts are rendered; Option 2 adds named-argument
syntax, which is a larger grammar/checker change and must be justified against
the positional-only design. The manager proposes Option 1 as the
minimal-surface fix and recommends it for the ticket.

## Proposed XSH change

Clarify the `xsht api` signature rendering so a defaulted parameter is not
displayed in a way that implies `name = value` named-argument support, or
otherwise state positional-only calling in the rendered contract. No language
semantics change is claimed here.

## Acceptance criteria

- `xsht api api:fs.files` (and any other signature with `= default` params)
  renders in a way that does not read as named-argument support, or documents
  positional-only calling explicitly.
- A fresh task-dupcheck trial (or a focused probe) no longer attempts named
  arguments after reading the rendered signature.
- Existing positional calls (e.g. `fs.files(root, false, false, [], true)`)
  still parse and pass the eight-case oracle.

## Scope and non-goals

- No change to the task contract, fixture cases, or evals.
- No provider/fallback change.
- If Option 2 (named arguments) is chosen, that is a separate, larger
  admission and must be justified on its own.

## Post-merge evaluation

Replay `task-dupcheck` and one other eval that calls a defaulted-parameter
module function against the merged build; the eval-manager records whether any
agent still attempts invalid `name = value` calls after reading the reference.
