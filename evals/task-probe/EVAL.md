# Eval task-probe

## Status

Draft.

## Budget breach

None.

## Purpose

Measure a practical systems-administration workflow that no approved eval
covers: orchestrating an external command through the XSH process boundary and
reporting its outcome. task-tags, task-ecount, and task-envcfg all forbid
subprocesses; none exercises `process.which`, `process.command_argv`,
`process.run`, or `Status`. The process module is XSH's core identity
("coarse-grained reuse, explicit process boundaries"), so this eval fills the
largest capability gap in the current portfolio with the classic sysadmin
shape "run a preflight/health check and report whether it succeeded".

## North-star hypothesis

XSH's stated role is practical systems glue; its differentiator is that
process orchestration is explicit, typed, and observable. This eval probes
whether an agent with the handbook can:

- discover the process module via `xsht api module:process` and resolve an
  executable with `process.which`;
- build a typed argv with `process.command_argv`, preserving each argument as
  its own element (including empty and space-containing arguments);
- interpret the `Status` value from `process.run` (`.ok`, `.exit_code()`);
- treat a missing executable as an expected failure and handle it with
  `match`/Result recovery instead of `?`-aborting the whole program;
- keep stdout to the exact report while the child's own output flows through,
  matching the shell oracle byte-for-byte.

A successful run teaches the factory whether the process surface is
discoverable and whether the Result/`?` lesson transfers to a real process
boundary. The design resists task-specific hacks because hidden cases vary
exit codes, argv shapes (empty element, space-containing element), and the
missing-command case requires genuine Result handling: a hard-coded outcome,
an unconditional `?` abort, or a naive string join/re-split of argv each fail
a distinct gate.

## Task

Create `probe.xsh`. It accepts a command name followed by optional arguments
and prints exactly one line reporting how that command finished:

```text
ok                 when the command exits with status 0
fail:<code>        when the command exits nonzero, <code> is the decimal status
missing            when the command name cannot be found as an executable
```

The evaluator always supplies a command name as the first argument. The
program itself exits 0 after printing its report and prints no other text to
stdout. The command's own stdout and stderr flow through unchanged, exactly as
they do in the oracle. The program must launch the command through the XSH
process boundary and preserve each argument as its own argv element. Complete
`review.md` using the supplied headings.

## Agent boundary

The worker runs as root in a minimal Alpine container with `/work` as its task
workspace. The image provides BusyBox, `xsh`, `xsht`, `curl`, and CA
certificates, and no extra packages: the `true` / `false` / `sh` / `printf`
applets used by the hidden cases are already in the shared base image, and the
`process` module is part of `xsh` itself. There is no compiler, repository
checkout, or implementation source. Unlike the filesystem-only evals, starting
the requested child command is the point of the task; the boundary that must
be respected is that the child is launched through XSH process APIs
(`process.which` / `process.command_argv` / `process.run`, or the `run` /
`spawn` forms), not through a hidden string-eval hack, and that the program
must not hard-code an outcome or add diagnostic text to stdout.

## Oracle and evaluator

The evaluator runs in a separate read-only container boundary. It writes the
oracle script under the evaluator's writable `/tmp`, builds per-case argument
lists, and runs the candidate and the oracle with identical arguments in the
same environment so both observe the same PATH, cwd, and applets. It compares
stdout byte-for-byte and exit codes, and writes the comparison evidence plus
timings to the run manifest. The oracle is this POSIX/BusyBox script:

```sh
#!/bin/sh
if command -v "$1" >/dev/null 2>&1; then
  "$@"
  code=$?
  if [ "$code" -eq 0 ]; then
    echo ok
  else
    echo "fail:$code"
  fi
else
  echo missing
fi
```

Public and hidden cases:

- `public_ok`: `true` → `ok`;
- `hidden_fail1`: `false` → `fail:1`;
- `hidden_fail42`: `sh -c "exit 42"` → `fail:42` (multi-digit status);
- `hidden_missing`: `definitely-not-a-real-command-xyz` → `missing`
  (expected-failure control);
- `hidden_two_words`: `sh -c "printf '%s\n' 'two words'"` →
  `two words\nok` (space inside one argv element);
- `hidden_hello_world`: `printf '%s\n' "hello world"` →
  `hello world\nok` (space-containing argument stays one element);
- `hidden_empty_arg`: `sh -c "exit 0" ""` → `ok` (empty argv element
  preserved);
- `hidden_exact_join`: `printf 'ready'` → `readyok` (child output without a
  trailing newline, byte-exact join);
- `hidden_stderr_exit5`: `sh -c "echo err >&2; exit 5"` → `fail:5` (stdout
  exact, stderr passes through).

All hidden cases use commands that exit normally; signal-terminated children
are out of scope because `Status.exit_code()` is absent for a signaled child
and the oracle's `$?` reports `128+signal`, so the two sides cannot agree by
contract. The evaluator checks that the source references the process
boundary (`process.`, `run`, or `spawn`) so a hard-coded text workaround is
classified as a restriction failure, and checks that `review.md` preserves
both required headings and contains no template placeholders.

## Metrics

Record correctness for all nine cases (including the missing-command failure
control), restriction compliance, worker turns, thinking blocks and reasoning
tokens, token buckets, provider cost, tool calls and errors, session wall
span, candidate/oracle timing per case, and protocol completion. This eval has
no strict candidate/oracle timing gate; both sides finish in milliseconds, so
timing is diagnostic until a stable envelope is established.

## Manager policy

Use one trial by default; the controller-owned `## Trial plan` in the cycle
request may explicitly raise this to two. Classify repeated friction as
handbook guidance or a product issue only when it is generalizable; do not
create a ticket for an ordinary short-task miss or evaluator noise. A handbook
change must name the concept it teaches and be replayed before it is trusted.
The CTO promotes `evals/task-probe/` with this scaffolding, including its
package-owned `evaluator.xsh`, after each design phase. The generic evaluator
protocol stages and mounts that script; do not add a task branch to
`the shared evaluator dispatcher`. Its `Draft.` status keeps it out of active cycles until
explicit admission.

## Staged dry run

The proposal was dry-run in the current cycle: a reference XSH solution
(`probe.xsh` using `process.which` / `process.command_argv` / `process.run` and
a `match` on the resolution Result) was checked with `xsht check` / `fmt` /
`lint`, then compared byte-for-byte against the BusyBox `sh` oracle on all nine
cases both on the host and inside the current `xsh-factory-base` container
image, where all nine cases matched. The proposal's package-owned evaluator was
then run against a staged `/work` directory and produced a passing manifest
with `classification: pass`. Negative controls (hard-coded `ok` output,
no-process-module text workaround, missing `review.md`) were each rejected with
the intended classification. The agent half (a live Pi worker) was not
exercised because it requires a paid agent session and a Pi auth file; the
agent path is inherited unchanged from the approved base image. Evidence is
preserved under the proposal's `dry-run/` directory.

## CTO review

- Result: `rejected`
- Promotion: `promoted`
- Source run: `runs/run-1785733794880/phases/04-eval-design`
- Status remains `Draft.` pending explicit eval admission.
