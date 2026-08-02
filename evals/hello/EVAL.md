# Eval hello

## Status

Approved seed.

## Purpose

Exercise the complete factory path at negligible task cost: task staging,
isolated eval-worker execution, review protocol, session capture, and
run-level cost accounting.

## Task

Create `/work/answer.txt` containing exactly `hello` followed by a newline.
Complete `/work/review.md` using the supplied review headings.

## Agent boundary

The worker runs as root in a minimal Alpine container with `/work` mounted as
its task workspace. It receives `agents.md`, `handbook.md`, `review.md`, and
`task.md`. It may use only the tools available in the image and must not read
the factory repository, host checkout, evaluator, or hidden inputs.

## Oracle and evaluator

The evaluator checks that `answer.txt` trims to `hello`, that `review.md` is
non-empty and preserves both required headings, and that the worker session
completed successfully. There is no candidate program timing contract for
this bootstrap eval.

## Metrics

Record worker turns, tool calls and errors, thinking blocks and reasoning
tokens, token buckets, provider cost, wall span, and protocol completion. The
run-level report must include the worker and all parent Pi sessions.

## Manager policy

Use one trial by default. The manager should classify any friction honestly;
do not invent a product ticket merely to satisfy a quota.

## Staged dry run

The hello bootstrap run is the first staged executor proof. It must leave the
worker session JSONL, full thinking transcript, executor report, and cost
report under one run directory.
