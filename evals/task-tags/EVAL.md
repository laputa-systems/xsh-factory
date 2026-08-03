# Eval task-tags

## Status

Disabled.

## Retirement record

This was the factory's minimal proof-of-concept seed. Per the CTO's explicit
retirement decision, treat it as a special exception to the normal repeated-
run threshold: it is too trivial to justify further paid cycles and does not
exercise a distinct systems boundary. Preserve the contract and history for
provenance while focusing active cycles on more diverse scenarios.

## Purpose

Measure the smallest useful XSH programming workflow: transforming command-line
values, preserving argument boundaries, using a standard library method, and
producing an exact output contract. This is the factory's minimal practical
eval and a reference shape for future eval proposals.

## North-star hypothesis

An agent that has understood the XSH handbook should solve this task with a
short, direct, typed value transformation and little exploratory friction. The
three argument cases distinguish genuine argument handling from a hard-coded
example. A successful run is evidence about basic learnability and ergonomics,
not about the whole language.

## Task

Create `tag.xsh`. It accepts zero or more command-line arguments and prints
exactly one line:

```text
tags: <lowercase argument 1>, <lowercase argument 2>, ...
```

Lowercase each argument independently, preserve spaces inside an argument, and
separate arguments with `, `. With no arguments, print `tags:` followed by the
final newline. Complete `review.md` using the supplied headings.

## Agent boundary

The worker runs as root in a minimal Alpine container with `/work` as its task
workspace. The image provides BusyBox, `xsh`, `xsht`, `curl`, and CA
certificates. It has no compiler, repository checkout, or implementation
source. The submitted program may not start subprocesses or invoke external
commands and must keep diagnostics off stdout.

## Oracle and evaluator

The evaluator runs in a separate read-only container boundary. It invokes the
candidate for public, hidden mixed/empty-argument, and zero-argument cases and
compares each output byte-for-byte with an external `printf` oracle. It checks
that the source does not contain the forbidden subprocess boundary and that
`review.md` preserves both required headings.

## Metrics

Record correctness for all cases, restriction compliance, worker turns,
thinking blocks and reasoning tokens, token buckets, provider cost, tool calls
and errors, session wall span, candidate/oracle timing, and protocol
completion. This eval has no strict candidate/oracle timing gate; timing is
diagnostic until a stable envelope is established.

## Manager policy

Use one trial by default; the controller-owned `## Trial plan` in the cycle
request may explicitly raise this to two. Classify repeated friction as
handbook guidance or a product issue only when it is generalizable; do not
create a ticket for an ordinary short-task miss or evaluator noise. A handbook
change must name the concept it teaches and be replayed before it is trusted.
