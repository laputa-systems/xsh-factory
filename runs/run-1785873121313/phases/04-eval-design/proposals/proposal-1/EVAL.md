# Eval task-intsum

## Status

Draft.

## Purpose

Measure one practical programming capability that the handbook's typed-boundary
ethos exists to make safe: summing a list of integer command-line arguments and
failing loudly on malformed input. XSH promises the old Unix argument-vector as
a typed List and explicit expected failures through `Result` and postfix `?`;
this eval probes whether an agent applies that model instead of reaching for an
external subprocess or a hard-coded answer.

## North-star hypothesis

An agent that has read the XSH handbook should sum argv with a short typed loop:
parse each argument with a typed conversion, propagate the expected failure with
postfix `?`, accumulate in a `var`, and print an exact single line. The three
distinct signatures (mixed values, zero arguments, and a malformed argument)
distinguish genuine typed argument handling from a hard-coded example, and the
malformed case checks that the agent lets a typed conversion turn a bad input
into a clear nonzero exit rather than silently coercing it. A successful run is
evidence about the learnability of typed command-line glue and the explicit
failure boundary, not about the whole language.

## Task

Create `intsum.xsh`. It accepts zero or more command-line arguments and prints
exactly one line: the integer sum of every argument. With no arguments it
prints `0`. Each argument must be a decimal integer (an optional leading `-`
followed by decimal digits); if any argument is not a valid integer, the program
must exit nonzero on that failure and print no numeric result to stdout. The
sum must be computed with XSH values and typed parsing, not by invoking an
external command. Complete `review.md` using the supplied headings.

## Agent boundary

The worker runs as root in a minimal Alpine container with `/work` as its task
workspace. The image provides BusyBox, `xsh`, `xsht`, `curl`, and CA
certificates. It has no compiler, repository checkout, or implementation
source. The submitted program may not start subprocesses or invoke external
commands and must keep diagnostics off stdout.

## Oracle and evaluator

The evaluator runs in a separate read-only container boundary. It invokes the
candidate for a public case, hidden mixed/empty/large/negative cases, and a
hidden malformed case. Numeric cases are compared byte-for-byte against a
portable `sh` oracle that sums the same argument list; the malformed case is
expected to make both the candidate and the oracle exit nonzero. The evaluator
checks that the source does not contain the forbidden subprocess boundary and
that `review.md` preserves both required headings.

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
