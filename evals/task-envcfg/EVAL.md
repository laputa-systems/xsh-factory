# Eval task-envcfg

## Status

Approved.

## Budget breach

None.

## Purpose

Measure a practical systems-administration workflow that no current eval
covers: reading typed configuration from the process environment with
defaults, writing a byte-exact config file, and propagating a malformed-value
failure instead of silently defaulting. Both approved evals (task-tags,
task-ecount) and the pending proposals (task-logroll, task-nhead,
task-jsonpick) produce stdout or traverse the filesystem; none reads the
`env` module or writes a file as the deliverable. `task-envcfg` fills that gap
with the classic container/sysadmin shape "render a config file from
environment variables."

## North-star hypothesis

XSH's stated role is practical systems glue ("connect processes, files,
paths, streams, JSON, and system state"); the process environment is the
cheapest form of system state. This eval probes whether an agent with the
handbook can:

- discover the `env` module and typed reads via `xsht api module:env` and
  `api:env.get_or` / `api:env.int` / `api:env.bool`;
- apply fallback defaults only on absence, not on empty values, matching the
  `env.get_or` contract and the oracle's `${VAR-default}` semantics;
- write the result to a path argument with `fs.write`;
- propagate an expected malformed-value failure with postfix `?` so a bad
  `CFG_PORT` exits nonzero and never produces a partial file;
- keep stdout clean while the deliverable is a file.

A successful run teaches the factory whether the environment/config surface
is discoverable and composable, and whether the handbook's Result/`?` lesson
transfers to a real config-validation boundary. The design resists
task-specific hacks because hidden cases vary which variables are set
(absent, empty, spaces, UTF-8, zero), and because the failure controls
require a loud nonzero exit with no output file — a hard-coded config, a
silent default, or a subprocess escape each fail a distinct gate.

## Task

Create `envcfg.xsh`. It accepts one output path argument. It reads three
environment variables and writes a config file at that path:

```text
host=<CFG_HOST or "localhost">
port=<CFG_PORT or 8080>
debug=<CFG_DEBUG or "false">
```

Each default applies only when the variable is absent; a present-but-empty
value is kept as-is. When `CFG_PORT` is present it must be a decimal integer;
if it is present but not a decimal integer, the program must exit nonzero and
must not create the output file. `CFG_DEBUG`, when present, is `true` or
`false` in the hidden cases. The behavior is defined by this oracle command
(environment is supplied by the evaluator):

```sh
sh /tmp/envcfg-oracle.sh
```

where `/tmp/envcfg-oracle.sh` contains:

```sh
case "${CFG_PORT-8080}" in
  *[!0-9]*|"") exit 1 ;;
esac
printf 'host=%s\nport=%s\ndebug=%s\n' "${CFG_HOST-localhost}" "${CFG_PORT-8080}" "${CFG_DEBUG-false}"
```

The evaluator invokes the candidate equivalently to `xsh envcfg.xsh OUT` and
compares the written file byte-for-byte with the oracle's stdout. Complete
`review.md` using the supplied headings.

## Agent boundary

The worker runs as root in a minimal Alpine container with `/work` as its task
workspace. The image provides BusyBox, `xsh`, `xsht`, `curl`, and CA
certificates, and no extra packages: the `sh` / `printf` oracle applets are
already in the shared base image, and the `env` / `fs` modules are part of
`xsh` itself. There is no compiler, repository checkout, or implementation
source. The submitted program may not use `run`, process APIs, `spawn`, shell
commands, or any other subprocess boundary; it must keep diagnostics off
stdout and must not hard-code one configuration's current values.

## Oracle and evaluator

The evaluator runs in a separate read-only container boundary. It writes the
oracle script under the evaluator's writable `/tmp`, builds per-case
environment records, and runs the candidate and the oracle with identical
`env:` records so both observe the same configuration. It compares
byte-for-byte and writes the comparison evidence plus timings to the run
manifest. Public and hidden cases:

- `public`: `CFG_HOST=node-a`, `CFG_PORT=9001`, `CFG_DEBUG=true`;
- `hidden_defaults`: no variables set;
- `hidden_partial`: only `CFG_HOST=api`;
- `hidden_empty`: `CFG_HOST=` (present but empty);
- `hidden_spaces`: `CFG_HOST="us east 1"`, `CFG_DEBUG=true`;
- `hidden_zero`: `CFG_PORT=0`;
- `hidden_utf8`: `CFG_HOST="héllo wörld"`;
- `hidden_debug_false`: only `CFG_DEBUG=false`;
- `hidden_malformed` (failure control): `CFG_PORT=abc` — candidate and oracle
  must both exit nonzero and the candidate must create no output file;
- `hidden_empty_port` (failure control): `CFG_PORT=` — same requirement.

The evaluator checks the source does not contain the forbidden subprocess
boundary, requires that the source references the environment module (`env.`)
so a hard-coded text workaround is classified as a restriction failure, and
checks that `review.md` preserves both required headings and contains no
template placeholders.

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
On approval, stage `evals/task-envcfg/` with this scaffolding and merge the
`run_task_envcfg` branch into the shared `evaluate_common.xsh` dispatch so the
normal `run-eval.xsh` build stages it into the image.

## Staged dry run

The proposal was dry-run in the current cycle: a reference XSH solution
(`envcfg.xsh` using `env.get_or` / `env.int` / `env.bool` and `fs.write`) was
checked with `xsht check` / `fmt` / `lint`, compared byte-for-byte against the
BusyBox `sh` oracle on all ten cases on the host, then the proposal's
evaluator was run in an isolated container against a staged `/work` directory
and produced a passing `run.json` with `classification: pass`. Negative
controls (hard-coded output, no-`env.` text workaround, subprocess escape,
missing `review.md`) were each rejected with the intended classification. The
agent half (a live Pi worker) was not exercised because it requires a paid
agent session and a Pi auth file; the agent path is inherited unchanged from
the approved base image. See `dry-run/DRY-RUN.md` for evidence.
