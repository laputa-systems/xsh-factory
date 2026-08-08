# Ticket task-histogram-010

## Status

Merged.

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

## CTO replay repair — cycle 30 close

- Decision: keep the approved implementation branch and repair the linked
  replay contract before its next delivery attempt.
- Basis: cycle 30's manager correctly found that the nine-case evaluator did
  not distinguish the whitespace-normalization fix. The evaluator now includes
  `hidden_padded_width` and documents the ten-case contract.
- Evidence: `runs/run-1786220380763/phases/02-reeval-task-histogram-010/`
  records the non-discriminating replay; the repaired package is checked in by
  `b451bf1` and covered by
  `test_task_histogram_restriction_accepts_typed_unsigned_parse`.
- Evidence ownership: native parser/API tests and `xsht` checks remain
  primary engineer evidence; the linked replay must prove the padded-width
  behavior and the evaluator restriction/protocol boundary.

## Change target

- `product`

Factory changes are CTO-owned. Do not create a factory-target ticket for
engineer dispatch; report infrastructure changes to the CTO instead.

## Budget breach

None.

## Merge record

- Implementation branch: `factory/task-histogram-010/1786220391269`
- Implementation commit: `1231645ddce6a8aec37854109d57d3bbfd56691b`
- Detected at XSH commit: `1231645ddce6a8aec37854109d57d3bbfd56691b`
- Implementation run: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786220380763/phases/01-ticket`

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
  the task's argv cases did not exercise surrounding whitespace until the
  replay repair recorded above.
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
remain byte-exact, including its padded-width case, and primary native tests to show that positive parsing accepts the
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
- Falsification evidence is the full ten-case `task-histogram` replay plus
  direct whitespace/zero/sign/malformed/overflow tests.

## Proposed XSH change

Trim the input at the start of `parse_uint_positive`, then apply its existing
positive-decimal validation and typed error behavior. Preserve all existing
`parse_uint` and `parse_int` behavior.

## Acceptance criteria

1. `" 5 ".parse_uint_positive()?` returns `5`.
2. Zero, signs, malformed text, and out-of-range text still return the existing
   typed `parse-uint-positive` error.
3. The linked `task-histogram` replay passes all ten cases byte-exact, including
   a surrounding-whitespace width, with no restriction or protocol regression.
4. The primary engineer report records native parser/API tests and the
   relevant XSH checks as passing; the replay need not duplicate the native
   suite.

## Scope and non-goals

- Non-goal: changing `parse_uint` or `parse_int` behavior.
- Non-goal: adding another parser, generic error constructor, or syntax form.
- Non-goal: changing the histogram task contract or oracle.

## Post-merge evaluation

Replay `task-histogram` against the merged commit, including all ten cases and
the parser's typed positive-bound behavior; record the decision in the linked
eval-manager report. Treat the primary engineer report as the evidence source
for native parser/API tests.
