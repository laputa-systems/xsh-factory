# Eval task-safepath

## Status

Draft.

## Budget breach

None.

## Purpose

Measure a practical systems-administration and init/supervisor-glue workflow
that no current eval covers: joining an absolute root and a relative path,
normalizing `.` and `..` segments while guaranteeing the result stays under
the root, and deliberately failing with a nonzero status when the path would
escape. Existing evals transform argv/env scalar text (`task-tags`,
`task-envcfg`), walk a filesystem tree with the typed stream APIs
(`task-ecount`, `task-manifest`), and diff/sort line sets (`task-setdiff`,
`task-propsort`) — none exercises building a safe path from a dynamic relative
string and rejecting traversal, which is precisely the typed-Path and
deliberate-failure contract most needed by installers, chroot/jail setup, and
service supervisors.

## North-star hypothesis

An agent that has understood the XSH handbook should turn a small
path-traversal guard into a short, typed transformation over string segments:
split, ignore `""`/`.`, remove the most recent segment on `..`, and abort with
a nonzero exit on escape while keeping diagnostics off stdout. The task probes
two genuinely error-prone areas of the language: the absence of a
`pop`/last-index string primitive (so the "remove the most recent segment"
step has to be expressed via `reverse` + `find` + `byte_slice`), and deliberate
validation failure via an explicit `abort` rather than an invented error value
or a silent default. A successful run is evidence that the handbook makes
segment-wise string manipulation and explicit failure discoverable; a common
miss (popping the wrong segment, printing to stdout only to exit nonzero, or
treating `..` as escapable text) is a learnability or ergonomics signal, not an
obstacle. The root argument plus hidden normalizing and escaping cases prevent
hard-coding a fixed output.

## Task

Create `safepath.xsh`. It accepts two command-line arguments: an absolute root
directory and a relative path. It must print the normalized absolute path
formed by joining them while guaranteeing the result stays under root, or, if
the relative path escapes the root, print exactly one line

    escape: <relative path>

and exit with a nonzero status.

Normalization rules:

- Split the relative path on `/`.
- Ignore empty segments (from `//`, a trailing `/`, or an empty relative
  path) and `.` segments, so `a/./b` and `a//b` both behave like `a/b`.
- `..` removes the most recently added normal segment (`a/../b` → `b`). If
  there is no normal segment left to remove, the relative path escapes the
  root.
- A relative path that starts with `/` is always an escape.
- The final path is `root` if no segments remain, otherwise
  `root/<remaining segments joined with />`, with no trailing slash.

On success print only the normalized path and exit 0. On escape print only
`escape: <relative path>` and exit nonzero. Keep all diagnostics off stdout.
The root is given as an absolute directory without a trailing slash (it is
never just `/`).

Complete `review.md` using the supplied headings.

## Agent boundary

The worker runs as root in a minimal Alpine container with `/work` as its task
workspace. The image provides BusyBox, `xsh`, `xsht`, `curl`, and CA
certificates; it has no compiler, repository checkout, or implementation
source. The submitted program may not start subprocesses or invoke external
commands and must keep diagnostics off stdout.

## Oracle and evaluator

The evaluator runs in a separate read-only container so the worker cannot
inspect the harness. It invokes the candidate for one public and seven hidden
cases and compares each stdout byte-for-byte and each exit-success/failure
against an external `sh` oracle that implements the same normalize-and-reject
rules. It checks that the source does not contain a forbidden subprocess
boundary and that `review.md` preserves both required headings.

Hidden cases cover: collapsing `a/../b` → `b`; `.` and `//` collapsing (e.g.
`a/./b//c`, `a//b`); an empty relative path; and the failure controls — a
leading `..`, a mid-path escape `a/../../etc`, an absolute relative path, and a
path that climbs out after several `..` (`x/../../../y`). Every non-escape case
must match and exit 0; every escape case must print `escape:` and exit nonzero.
The oracle and candidate run under the same invocation form, so case coverage
stays in the harness, not the task.

## Metrics

Record correctness for all cases, restriction compliance, worker turns,
thinking blocks and reasoning tokens, token buckets, provider cost, tool calls
and errors, session wall span, candidate/oracle timing, and protocol
completion. This eval has no strict candidate/oracle timing gate; timing is
diagnostic until a stable envelope is established.

## Manager policy

Use one trial by default; the controller-owned `## Trial plan` in the cycle
request may explicitly raise this to two. Classify repeated friction as
handbook guidance or a product issue only when it is generalizable (for example
a discoverable `abort`/deliberate-failure idiom, or the missing
pop/last-index string primitive), not for an ordinary short-task miss or
evaluator noise. A handbook change must name the concept it teaches and be
replayed before it is trusted.

## Staged dry run

The reference candidate and the `sh` oracle were run together across the full
public + hidden case set in the proposal dry run and agreed on every case; the
evidence is archived under this proposal directory. The dry run exercised the
materialized package selector `executor.xsh`, the package-owned self-contained
`evaluate.xsh` → `evaluator.xsh` (no dependency on the legacy/common
controllers), the `/session/run.json` manifest, the read-only evaluator
isolation, and the review-heading protocol check. It did not spend a paid Pi
trial; a live agent run is deferred to the CTO's admission after approval.
