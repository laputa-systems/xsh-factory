# XSH factory

The factory is the control plane for improving XSH coding agents. The XSH
repository is the product repository. This repository owns evals, prompts,
tickets, cycle requests, run reports, and the organization that connects them.

## Organization

```text
director
  ├─ eval-designer       proposes one new eval and stages a dry run
  ├─ eval-manager        runs an approved eval and proposes improvements
  │    └─ eval-executor  deterministically runs the isolated eval-worker
  └─ xsh-swe             implements already-open XSH tickets in worktrees
```

The `eval-executor` is a harness, not a Pi employee. Its Pi employee is the
`eval-worker`: the isolated coding agent whose task-solving behavior is being
measured. Every Pi employee uses `run-agent.xsh`; a bare `pi` invocation is not
part of the factory protocol because it would escape run accounting.

## Source of truth

The factory is intentionally Markdown-first. Role prompts, eval contracts,
cycle requests, manager reports, tickets, and approvals use fixed
headings and links rather than a second JSON schema. Pi's session JSONL is the
canonical structured evidence source. Generated reports summarize it in
Markdown and retain the original JSONL.

The standing Pi-session briefing in `roles/pi-session-briefing.md` explains
how to interpret session messages, thinking blocks, tool results, usage, cost,
and timing. Eval-managers read it before inspecting a run.

The deterministic control plane and tools have native XSH coverage under
`tests/`. Run it from this repository with `XSH_MODULE_PATH=. xsht test`; the
tests use synthetic sessions and process/container doubles, so they do not
launch Pi.

## North star

`NORTH-STAR.md` is the durable mission briefing for every role. It translates
the ethos in `docs/CHAPTER-01-why-xsh.md` into an operating standard:
improve XSH ergonomics, practical systems-glue capability, learnability,
AI/token efficiency, and trustworthiness. Role prompts require a
`## North-star impact` section so that each narrative output connects its local
work to that mission or explicitly records that it produced no product signal.

The factory must not optimize pass rate, activity, handbook size, or token
count in isolation. A useful result is a reproducible improvement in XSH or in
an agent's ability to use it, supported by evidence and a named next replay.

The detailed layer contracts and outputs are in
[`docs/FACTORY-LOOPS.md`](docs/FACTORY-LOOPS.md).

## One cycle

Run an eval cycle with:

```sh
xsh run.xsh cycle-request.md
```

`run.xsh` creates `runs/run-<id>/`, starts the director, and produces a
run-level report and cost report. The director resolves one clean XSH commit
once at cycle start. Every executor and SWE worktree records that snapshot or
its explicitly named candidate commit.

For an approved ticket implementation cycle, use a request with
`## Mode` set to `ticket-implementation` and an explicit `## Approved tickets`
list:

```sh
xsh run.xsh cycle-ticket-task-tags-001.md
```

The controller admits only tickets whose checked-in status is `Accepted.`,
creates one isolated XSH worktree per ticket, and asks the director to launch
one `xsh-swe` worker per worktree. The branch is validated and left pending
user review; no merge or ticket-status mutation is automatic. Each run records
stage callbacks as Markdown files under `events/`.

The controller-owned eval pipeline is:

1. parse the explicit trial and proposal counts;
2. write an ordered `DISPATCH.md` containing exactly the requested
   eval-manager and optional eval-designer rows;
3. launch those rows through the shared runner;
4. collect all worker reports and costs;
5. validate the full report contracts and handbook lineage;
6. fail with partial evidence when a required stage cannot complete.

New manager tickets become open for the next cycle. They are not dispatched to
SWE in the same eval cycle, which keeps diagnosis and implementation separate.

Ticket-only cycles intentionally omit the eval pipeline. They are for an
explicitly approved implementation handoff and produce reviewable branches;
post-merge acceptance remains a later controlled eval replay.

## Evals

An eval contract defines a practical task, agent-facing files, the image and
tool boundary, an external oracle, the evaluator, the review protocol,
quantitative metrics, and manager policy. Ecount is the current upper bound on
acceptable difficulty. Code quality remains qualitative; objective gates are
correctness, restrictions, protocol output, agent effort, and candidate/oracle
execution time.

All eval images inherit `evals/Dockerfile.base`, which owns the pinned Alpine
runtime, locally built `xsh` and `xsht`, and Pi. An eval Dockerfile only adds
task-specific packages and runtime files; `task-ecount` adds `fd` on top of the
same cached base image.

For strict timing tasks:

```text
0.90 <= median(candidate wall time) / median(oracle wall time) <= 1.10
```

Ecount is the reference upper bound for difficulty. The task-tags eval is the
approved low-cost capability seed; task-ecount is the approved upper-bound
seed. New capability evals remain pending review until the user approves their
proposal branch.

## Tickets and changes

An eval-manager may create a ticket after one strong reproducible observation.
The ticket must link the exact eval, shared-handbook lineage, manager session,
executor run, and XSH baseline. It must state an observation, evidence, diagnosis or
hypothesis, proposed change, acceptance criteria, and post-merge evaluation.

There is one factory-wide handbook lineage. Each eval trial receives an
immutable snapshot of that shared handbook. A manager may stage a candidate
under its run lineage, but promotion replaces `runtime/handbook.md` for every
eval only after a user-approved replay and handbook decision. The controller
locks the run, snapshots the approved handbook, and verifies both that snapshot
and the checked-in handbook are unchanged at validation. User rejection leaves
the shared handbook at its last approved version.

XSH SWE branches contain product changes and tests. The user alone merges them
into XSH main. After merge, the linked eval-manager performs a controlled
replay and records acceptance or rejection. A rejection names the exact merged
commit and creates a linked revert proposal; it does not silently mutate main.

## Run accounting

Every worker gets a separate Pi session and a hard two-dollar budget by
default. The shared runner records the worker identity, parent, role, eval or
ticket, model, thinking level, session JSONL, extracted thinking transcript,
and worker report.

The run cost report includes one row per worker, role totals, eval/ticket
totals, and the grand total. It includes input, output, cache, provider-total,
bucket-total, and provider-reported reasoning tokens; cost components and
total dollars; turns, tools, errors, wall time, model, and thinking level.
Reasoning is a subset of output and is shown as unknown when the provider did
not report it. Thinking-block count and transcript text are qualitative, not a
token count. Missing provider cost fails closed. A budget breach stops and
fails that worker while preserving its partial session.

## Launcher contract

`factory_control.xsh`, `run.xsh`, and `run-agent.xsh` are the executable
configuration. The runner
accepts these role-specific environment variables; defaults are explicit in
`factory_control.xsh` and all five Pi roles default to provider `openrouter`, model
`deepseek/deepseek-v4-flash-0731`, thinking `high`, and a `$2` worker budget:

```text
FACTORY_DIRECTOR_{PROVIDER,MODEL,THINKING,BUDGET_USD,TOOLS}
FACTORY_EVAL_DESIGNER_{PROVIDER,MODEL,THINKING,BUDGET_USD,TOOLS}
FACTORY_EVAL_MANAGER_{PROVIDER,MODEL,THINKING,BUDGET_USD,TOOLS}
FACTORY_EVAL_WORKER_{PROVIDER,MODEL,THINKING,BUDGET_USD,TOOLS}
FACTORY_XSH_SWE_{PROVIDER,MODEL,THINKING,BUDGET_USD,TOOLS}
```

`eval-executor` is deterministic and has no Pi model setting; it forwards the
`FACTORY_EVAL_WORKER_*` selection into the isolated worker container. `run.xsh`
registers SIGINT and SIGTERM with a zero pre-cancel budget, so an interrupted
cycle immediately cancels the active child process groups and their nested Pi
workers before writing the partial run evidence.

`FACTORY_WORKDIR` is an internal runner setting used for product workers. When
present, `run-agent.xsh` starts Pi with that directory as its actual process
working directory and records it in `WORKER.md`; this is what makes an
`xsh-swe` worktree boundary enforceable rather than prompt-only.

Ticket implementation is controller-assigned, not worker-selected. `run.xsh`
renders `templates/XSH-SWE-ASSIGNMENT.md` once per admitted ticket, inlines the
ticket snapshot, records the assignment SHA-256 in `TICKET-DISPATCH.md`, and
passes the exact ticket ID, worktree, assignment path, and hash to the director.
`run-agent.xsh` rejects a missing, altered, mismatched, or already-claimed
assignment before starting Pi. The controller also validates exact `read`
tool calls for the factory `NORTH-STAR.md` and shared `runtime/handbook.md`
paths in the worker session JSONL.
