# Eval task-ecount

## Status

Approved.

## Purpose

Measure a practical filesystem-oriented systems-glue workflow: traversing a
root with XSH APIs, extracting and counting extension values, matching a
byte-exact external oracle, and respecting a no-subprocess boundary. Ecount is
the current upper bound on acceptable eval difficulty.

## North-star hypothesis

An agent with a mature XSH handbook should be able to replace a small shell
pipeline with a clear, typed XSH program that preserves Unix filesystem
semantics without falling back to subprocesses. The eval exposes whether the
handbook makes filesystem streams, text, maps, sorting, and exact output easy
to discover and combine. The root argument and external oracle prevent a
hard-coded answer.

## Task

Create `ecount.xsh`. It accepts one root directory and prints a count of file
name extensions below that root. Traverse directly through XSH filesystem APIs;
do not start subprocesses or invoke external commands. The evaluator invokes
`xsh ecount.xsh /usr/share` and compares byte-for-byte with:

```sh
fd --color=never -tf . /usr/share | awk -F. 'NF > 1 {print tolower($NF)}' | sort | uniq -c | sort -n
```

The candidate must visit the same regular files, omit complete paths without a
period, use the final period-separated field lowercased, count equal values,
match numeric/tie ordering and leading padding, emit only result lines, and
leave the root unchanged. Complete `review.md` using the supplied headings.

## Agent boundary

The worker runs as root in a minimal Alpine container with `/work` as its task
workspace. The image provides BusyBox, `xsh`, `xsht`, `curl`, CA certificates,
and the task-specific `fd` oracle utility. It has no compiler, repository
checkout, or implementation source. The submitted program may not use `run`,
process APIs, `spawn`, shell commands, or any other subprocess boundary.

## Oracle and evaluator

The evaluator runs in a separate read-only container boundary so the worker
cannot inspect the oracle harness. It runs the candidate and the exact `fd` /
`awk` / `sort` oracle, compares stdout byte-for-byte, checks both processes,
and verifies the review headings. It records candidate and oracle wall, user,
and system time in the run manifest.

## Metrics

Record correctness, restriction compliance, worker turns, thinking blocks and
reasoning tokens, token buckets, provider cost, tool calls and errors, session
wall span, and candidate/oracle timing. For a stable repeated trial set, the
candidate/oracle wall-time ratio must be within `0.90..1.10`; the manager must
report the ratio and keep a timing failure separate from a language-correctness
failure.

## Manager policy

Use one trial by default while porting; the controller-owned `## Trial plan`
in the cycle request may explicitly raise this to two. Increase trials before
treating timing or handbook effects as causal. Open a ticket only for a strong reproducible
language/tooling observation that generalizes beyond this filesystem shape.
Handbook changes are provisional until replayed with the same oracle and a
nearby filesystem case.
