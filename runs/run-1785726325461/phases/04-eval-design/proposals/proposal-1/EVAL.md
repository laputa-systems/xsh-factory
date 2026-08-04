# Eval task-jsonfilter

## Status

Draft.

## Budget breach

None.

## Purpose

Measure a practical programming/systems-glue workflow that no approved eval
covers: reading one JSON document from the process environment, validating it
against a named schema, filtering, sorting, and projecting typed records, and
writing a byte-exact JSON file. `task-tags` transforms argv text,
`task-ecount` traverses the filesystem, and `task-envcfg` renders a config
file from scalar environment variables; none crosses a JSON boundary or
exercises the `json` module. The north star names JSON as one of the
boundaries XSH should connect ("connect processes, files, paths, streams,
JSON, and system state"), and the handbook's JSON section teaches a specific
trust pattern (`.require(Type)?`). `task-jsonfilter` is the smallest practical
shape for that capability: extract active records from a JSON report/config,
sort them, and emit JSON for a downstream consumer.

## North-star hypothesis

An agent with a mature XSH handbook should be able to replace a small
`jq` pipeline with a clear, typed XSH program: `json.decode` the environment
document, `.require(Type)` the schema it intends to trust, filter and sort
typed records with stream stages, project to a record literal, and write the
result with `json.write`/`fs.write`. The eval exposes whether the handbook
makes the JSON boundary discoverable (`xsht api module:json`), whether the
`.require(Type)` trust lesson transfers from docs to a real task, and whether
exact JSON serialization (compact, key-sorted, final newline) is easy to
match. A successful run teaches the factory whether the JSON surface is
ergonomic for agents and whether the Result/`?` failure lesson extends to
malformed JSON input.

The design resists task-specific hacks because hidden cases vary the
`CFG_DOC` document (unknown to the worker), the output is a file written only
on success, the failure controls require a loud nonzero exit with no output
file, and the evaluator rejects sources that do not reference the `json`
module or that start a subprocess — a hard-coded file, a text workaround, or
a `jq` escape each fails a distinct gate.

## Task

Create `jsonfilter.xsh`. It accepts one output path argument and writes a
JSON array to that path. It reads a JSON document from the environment
variable `CFG_DOC` with shape `{"records": [{"name": Str, "active": Bool,
"count": Int}, ...]}` and writes the records with `active == true`, sorted
by `name` ascending, projected to `{"name": ..., "count": ...}`. The
behavior is defined by the oracle command in `runtime/task.md`: `jq -cS`
over the same `CFG_DOC`. When `CFG_DOC` is absent, empty, or not valid JSON,
the program must exit nonzero and must not create the output file. Complete
`review.md` using the supplied headings.

## Agent boundary

The worker runs as root in a minimal Alpine container with `/work` as its task
workspace. The image provides BusyBox, `xsh`, `xsht`, `curl`, CA
certificates, and the task-specific `jq` oracle utility. It has no compiler,
repository checkout, or implementation source. The submitted program may not
use `run`, process APIs, `spawn`, shell commands, `jq`, or any other
subprocess boundary, and must keep diagnostics off stdout.

## Oracle and evaluator

The evaluator runs in a separate read-only container boundary so the worker
cannot inspect the oracle harness. It builds per-case environment records,
runs the candidate and the oracle with identical `env:` records, and compares
the written output files byte-for-byte. It verifies both processes, checks
that no output file exists on the failure controls, checks that the source
references the JSON module (`json.`), checks that the source does not contain
the forbidden subprocess boundary, and checks that `review.md` preserves both
required headings and contains no template placeholders. Public and hidden
cases:

- `public`: four records, mixed active/inactive, names out of order;
- `hidden_empty`: `records: []`;
- `hidden_all_inactive`: every record `active: false`;
- `hidden_single`: exactly one active record;
- `hidden_unicode`: names `héllo`, `beta`, `äpple` (UTF-8 ordering and raw
  serialization);
- `hidden_spaces`: name `us east 1`;
- `hidden_zero`: `count: 0`;
- `hidden_large`: `count: 1048576`;
- `hidden_malformed` (failure control): `CFG_DOC` is not valid JSON —
  candidate and oracle must both exit nonzero and create no output file;
- `hidden_missing` (failure control): `CFG_DOC` absent or empty — same
  requirement.

The evaluator records candidate and oracle wall, user, and system time per
case in the run manifest.

## Metrics

Record correctness for all ten cases (including the two failure controls),
restriction compliance, worker turns, thinking blocks and reasoning tokens,
token buckets, provider cost, tool calls and errors, session wall span,
candidate/oracle timing per case, and protocol completion. This eval has no
strict candidate/oracle timing gate; both sides finish in milliseconds, so
timing is diagnostic until a stable envelope is established.

## Manager policy

Use one trial by default; the controller-owned `## Trial plan` in the cycle
request may explicitly raise this to two. Classify repeated friction as
handbook guidance or a product issue only when it is generalizable; do not
create a ticket for an ordinary short-task miss or evaluator noise. A handbook
change must name the concept it teaches and be replayed before it is trusted.
On approval, stage `evals/task-jsonfilter/` with this scaffolding and merge
the `run_task_jsonfilter` branch into the shared `evaluate_common.xsh`
dispatch so the normal `run-eval.xsh` build stages it into the image.

## Staged dry run

The proposal was dry-run in the current cycle. A reference solution
(`jsonfilter.xsh` using `env.get` / `json.decode` / `.require(Type)` /
`where` / `sort-by` / `map` / `fs.write`) passed `xsht check` and `xsht
lint` inside the task image on the pinned Linux build, then was compared
byte-for-byte against the Alpine `jq 1.8.1` oracle inside the same image on
all ten cases (eight success cases plus the malformed and missing/empty
failure controls) with identical `CFG_DOC`; every case passed and both
failure controls exited nonzero with no output file. Negative controls
(hard-coded output with no `json.` reference, subprocess escape via
`process.run`/`jq`, missing review heading, template placeholders) were each
rejected with the intended classification. The live Pi agent half was not
exercised (paid agent session not used in the design phase); the agent path
is inherited unchanged from the approved base image. The controller-owned
evaluator dispatch is wired only after approval. See
`dry-run/DRY-RUN.md` and `dry-run/transcript.txt` for evidence.
