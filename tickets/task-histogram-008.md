# Ticket task-histogram-008

## Status

Open.

## Change target

- `product`

Factory changes are CTO-owned. Do not create a factory-target ticket for
engineer dispatch; report the infrastructure change to the CTO instead.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-histogram`
- Shared handbook lineage: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786126514242/phases/01-eval/lineage/handbook-approved.md`
- Manager run: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786126514242/phases/01-eval/workers/eval-manager/task-histogram/REPORT.md`
- Executor run: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786126514242/phases/01-eval/workers/eval-worker/task-histogram-1/run.json`
- XSH baseline commit: `1477f472d5b4d57db3584357116ef97c32358ab6`

## Observation

Constructing a record literal in XSH is over-restrictive and produces cryptic
parse errors. A bare typed record literal at a binding fails when any field
name collides with reserved words, and the documented diagnostics do not name
the cause:

- `let rec = { run: 0, lines: [] }` fails at the `run` field with a cascade
  `err[parse.expected-record-field]: expected record field` plus
  `expected `}` after record` and `expected statement terminator`, none of
  which mention that `run` (or `lines`) is a reserved field name.
- Even a declared type rejects reserved names:
  `type Accum = {run: Int, lines: List[Str]}` fails with
  `err[parse.expected-ident]: expected schema field name` at `run`.
- With a declared type and non-reserved names
  (`type Config = {name: Str, enabled: Bool}`, `let cfg: Config = {...}`) the
  literal parses and runs.
- A record type introduced only so that a literal can parse is additionally
  flagged by `xsht lint` as `unused-type` until the type name is explicitly
  referenced by an annotated binding, and there is no working inline annotation
  at a call site (`fold(({...}: Acc))` fails to parse), so an agent must add a
  throwaway type-annotated helper binding.

The `task-histogram` worker spent roughly seven consecutive turns (session
turns 42-48) probing these forms before finding the declared-type,
non-reserved-name spelling it needed for the cumulative-fold accumulator.

## Evidence

- Session: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786126514242/phases/01-eval/workers/eval-worker/task-histogram-1/session.jsonl`
  (turns 42-48): probe outputs — `{ run: 0, lines: [] }` and
  `type Accum = {run: Int, lines: List[Str]}` both fail with
  `parse.expected-record-field` / `parse.expected-ident` pointing at `run`;
  `type Config = {name: Str, enabled: Bool}` with a non-reserved literal prints
  `demo` (rc 0). The `unused-type` lint friction is reproduced across the
  `/tmp/f.xsh` and `/tmp/hist2.xsh` probes and the `sed` rewrite that adds a
  type annotation.
- Review: `workers/eval-worker/task-histogram-1/review.md`, "XSH language
  proposals" item 2 (record-literal parse + reserved field names + `unused-type`
  lint) and "xsht friction" item 1 (`unused-type` until the type is referenced,
  no inline call-site annotation).
- Artifact: the final `histogram.xsh` declares `type Acc = {total: Int, out:
  List[Str]}` with an `init0: Acc` annotated binding and passes all nine cases
  byte-exact (run.json), so the workaround is real but non-obvious.

## Diagnosis or hypothesis

This is a general XSH ergonomics and learnability problem, not task-specific
confusion. Records are a core user-facing value type that any stateful or
structured task will construct, yet the interaction of (a) reserved field
names (`run`, `lines`) with (b) a requirement to already declare the record
type and (c) a misleading `unused-type` lint produces a multi-turn
discover-and-verify loop on a language feature, with error messages that do
not explain what the agent did wrong. Making record-literal construction
predictable and its diagnostics actionable would remove friction from every
eval that builds a Map-ish or accumulator record, independent of task shape.

## North-star impact

Predictable, well-diagnosed record literals improve ergonomics, learnability,
and trust for the most common XSH data-shaping operation. The success evidence
is a fresh `task-histogram` (and at least one other record-using eval) replay
where the agent composes the typed accumulator record in a single pass with no
`expected-record-field`/`unused-type` probe chain, and where a check-time
diagnostic (`expected record field`) names the reserved word or the missing
type instead of a generic token/terminator cascade.

## Proposed XSH change
## API-surface justification

- Semantic capability not expressible today: constructing a record literal
  without already declaring a compatible record type and without tripping over
  reserved field names; today the agent must pre-declare a `type`, must
  reference it via an annotated binding to avoid `unused-type`, and must avoid
  reserve names such as `run`/`lines`.
- Closest existing spelling and why it is insufficient: the declared-type
  literal works but is undiscoverable (no readable diagnostic), and inline
  annotation at a call site does not parse. The reserved-name rejection is
  reported as a generic `expected record field`.
- Whether a desugaring/type-directed rule or library API would solve it with
  less surface: most of the fix is diagnostics and smaller surface changes —
  (1) a readable `check`-time diagnostic that names the reserved field word, or
  (2) permitting reserved identifiers as record field names, and (3) letting
  `xsht lint`/the checker recognize a record type used to type an in-scope
  literal, or accepting an inline type annotation at the call site (e.g.
  `fold(((total: 0, out: []): Acc))`). A type-directed rule already infers
  record shapes, so (3) is a checker acceptance change, not new runtime or
  syntax surface.
- Implementation and maintenance cost: primarily parser/checker diagnostics and
  lint acceptance; new syntax is optional and smaller than a new operator.
  Cost touches the parser topic, checker typing, lint, and (for any new inline
  annotation spelling) the API registry and docs, plus native tests.
- Evidence and falsification replay required before approval: a non-reserved
  record literal compiles without a pre-declared type (or with the declared
  type not flagged `unused-type`), a reserved field name produces a diagnostic
  naming the word, and `task-histogram` stays 9/9 byte-exact with the
  accumulator built without the probe-plus-`unused-type` detour.

## Proposed XSH change

Smallest candidate: improve record-literal ergonomics and diagnostics without
changing core record semantics. Specifically (a) emit a `check`-time diagnostic
that names a reserved field word instead of the generic `expected record
field`/`expected `}` cascade, (b) allow a record type used to type an in-scope
literal to satisfy `xsht lint` (no spurious `unused-type`), and (c) if
feasible without new syntax risk, accept an inline type annotation on a record
literal at a call site. Do not claim any of these are already implemented.

## Acceptance criteria

1. A script using a reserved field name receives a diagnostic naming that word
   (e.g. "`run` is reserved"), and a script using only non-reserved names with
   a declared type compiles cleanly.
2. A record type declared only to type a literal used by an annotated binding
   no longer triggers `xsht lint unused-type`.
3. `task-histogram` re-run stays 9/9 byte-exact; the worker composes the
   typed accumulator record without a multi-turn probe/`unused-type` detour.
4. No regression in the other approved eval suite.

## Scope and non-goals

- Non-goal: changing record value semantics, destructuring, or the type system.
- Non-goal: renaming or removing reserved words beyond accommodating them as
  record fields.
- Non-goal: altering the eval task contract or its oracle.
- The descriptive handbook note (record literals require a declared type,
  `run`/`lines` are reserved) is staged separately as a provisional handbook
  candidate and does not depend on this product change.

## Post-merge evaluation

A linked eval-manager replay of `task-histogram` against the merged commit,
verifying the record accumulator is composed without the
`expected-record-field`/`unused-type` probe loop while all nine cases remain
byte-exact, with the decision recorded in `## Post-merge decisions` of the
manager report.
