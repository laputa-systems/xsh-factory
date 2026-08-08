# Ticket task-histogram-010

## Status

Approved.

## CTO review — cycle 29 close

- Decision: Approved for one fresh engineer implementation slot.
- Basis: Review of merged commit `e6d3fd96f9fa654c0d1c9f434f83b6984a60c204`
  found a concrete parser-family inconsistency: `parse_uint` trims surrounding
  whitespace before validating, while the newly added `parse_uint_positive`
  validates the raw string and rejects the same surrounding whitespace. The
  positive parser was delivered correctly for the histogram argv contract, but
  the public parser family should have one explicit normalization contract.
- Scope guard: preserve rejection of signs, malformed text, zero, and
  out-of-range values; only align the positive parser's surrounding-whitespace
  behavior and tests/docs. Do not change `parse_uint` or add another API.
- Evidence: merged product commit above; linked cycle-29 replay
  `../runs/run-1786218719345/phases/02-reeval-task-histogram-009/` passed all
  nine cases and exercised `parse_uint_positive`.

## Change target

- `product`

Factory changes are CTO-owned. Do not create a factory-target ticket for
engineer dispatch; report infrastructure changes to the CTO instead.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-histogram`
- Shared handbook lineage: `../runs/run-1786218719345/phases/02-reeval-task-histogram-009/lineage/handbook-approved.md`
- Manager run: `../runs/run-1786218719345/phases/02-reeval-task-histogram-009/workers/eval-manager/task-histogram/REPORT.md`
- Executor run: `../runs/run-1786218719345/phases/02-reeval-task-histogram-009/workers/eval-worker/task-histogram-1/run.json`
- XSH baseline commit: `e6d3fd96f9fa654c0d1c9f434f83b6984a60c204`

## Observation

The merged parser family has inconsistent whitespace handling. `parse_uint`
calls `trim()` before checking unsigned decimal digits, but
`parse_uint_positive` checks the untrimmed input. Therefore equivalent inputs
such as `" 5 "` succeed through `parse_uint` and fail through
`parse_uint_positive`, despite both being decimal integer conversions.

## Evidence

- Product source: `../xsh/src/modules/text.rs` in merged commit
  `e6d3fd96f9fa654c0d1c9f434f83b6984a60c204`.
- Linked replay: cycle-29 `task-histogram` manager report confirms the new
  typed positive parser is discoverable and used successfully for the width;
  the task's argv cases do not exercise surrounding whitespace.
- The discrepancy is visible by comparing the two adjacent conversion
  implementations and is isolated to the new method.

## Diagnosis or hypothesis

This is a reusable library-contract inconsistency, not a task-specific
workaround. Agents use the parser family for ports, widths, counts, sizes, and
durations; inconsistent normalization forces each caller to guess whether to
trim before conversion. Aligning the new method with `parse_uint` keeps the
existing family predictable without expanding the language surface.

## North-star impact

Consistent typed conversions reduce agent guesswork and make numeric boundary
validation composable. Falsification requires the linked histogram eval to
remain byte-exact and native tests to show that positive parsing accepts the
documented surrounding-whitespace form while still rejecting zero, signs,
malformed text, and overflow.

## Proposed XSH change

## API-surface justification

- No new API, keyword, type, or syntax is proposed; this is a behavior fix to
  the newly merged `Str.parse_uint_positive()` method.
- The closest existing contract is `Str.parse_uint()`, which trims before
  validating. Reusing that normalization is smaller and clearer than adding a
  second conversion or a caller-side workaround.
- Maintenance cost is limited to the parser implementation, API contract
  wording if needed, native method tests, and one linked eval replay.
- Falsification evidence is the full nine-case `task-histogram` replay plus
  direct whitespace/zero/sign/malformed/overflow tests.

## Proposed XSH change

Trim the input at the start of `parse_uint_positive`, then apply its existing
positive-decimal validation and typed error behavior. Preserve all existing
`parse_uint` and `parse_int` behavior.

## Acceptance criteria

1. `" 5 ".parse_uint_positive()?` returns `5`.
2. Zero, signs, malformed text, and out-of-range text still return the existing
   typed `parse-uint-positive` error.
3. The linked `task-histogram` replay passes all nine cases byte-exact, with no
   restriction or protocol regression.
4. Native parser/API tests and the relevant XSH checks pass.

## Scope and non-goals

- Non-goal: changing `parse_uint` or `parse_int` behavior.
- Non-goal: adding another parser, generic error constructor, or syntax form.
- Non-goal: changing the histogram task contract or oracle.

## Post-merge evaluation

Replay `task-histogram` against the merged commit, including the existing nine
cases and the parser's typed positive-bound behavior; record the decision in
the linked eval-manager report.
