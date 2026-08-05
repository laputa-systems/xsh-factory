# XSH agent handbook

This is the single factory-wide rolling handbook for every eval. It is the
approved baseline copied into each executor trial; evals must not carry their
own handbook. A manager may stage a candidate under a run lineage, but only a
reviewed promotion updates this file for all future trials.

This candidate is provisional and limited to one paragraph in `## Effects and
errors` (the "deliberate validation failure" guidance). All other content is
identical to
`runs/run-1785894766939/phases/02-reeval-task-colsum-001/lineage/handbook-approved.md`
(sha256 `3b56a781...e126b`). It has not been replayed; do not promote without
replay and CTO approval.

## Effects and errors

Host operations declare effects on the procedure that uses them. Filesystem
work normally requires fs. An operation that can return an expected failure
returns Result data; postfix ? propagates that failure from a procedure whose
effects include error:

    proc read_name(path: Path) [fs, error] -> Result[Str] {
      let entry = fs.metadata(path)?
      return entry.name
    }

Use the exact return type and effect information shown by `xsht api`. Do not
turn an expected host failure into an unchecked assumption.

For deliberate validation failure, prefer an explicit absent/expected failure
over a sentinel conversion. A terminal such as `first()?` on an empty stream
returns an expected error you can propagate with postfix `?`, so a
not-found condition (`header not present`) needs no fake string routed through
`parse_int`. When the build provides it, `error.fail(message)` constructs a
message-bearing `Result[Unit, Error]` of kind `validation` and is the explicit
spelling; propagating it requires the enclosing proc's `error` effect. Do not
invent an error value or use an unrelated host failure when an absent terminal
or `error.fail` already expresses the rejected input.
