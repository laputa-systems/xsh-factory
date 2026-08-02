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

run-organization.xsh
  ├─ primary: run-ticket.xsh or run-eval.xsh
  ├─ candidate re-evaluation: run-eval.xsh, only after a ticket passes
  └─ eval-design: run-design.xsh, exactly one proposal
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

## Factory engineering rules

The factory has a high quality bar because it is intended to improve the
language that will run other automation. Every change must preserve the
following rules:

- Simplicity is a requirement, not a future cleanup task. Prefer one clear
  owner, one state transition, one durable output, and one parameterized
  template over parallel variants, wrapper layers, or per-case files. Delete
  abstractions when a direct path is clearer.
- Controller XSH must not contain inline Markdown report, prompt, assignment,
  or event bodies. Put Markdown on disk in `templates/`, then fill explicit
  placeholders. Markdown headings in parsers, validators, and test fixtures
  are contracts and are the exception; they must not become a second output
  mechanism.
- Separate orchestration from judgment. `run.xsh`, `run-eval.xsh`, and
  `run-ticket.xsh` own admission, process boundaries, state transitions,
  cancellation, and validation. Pi roles own interpretation and decisions.
  No role may discover work that the controller did not assign.
- Keep orchestration testable without Pi. Pure parsing and lifecycle rules
  belong in `factory_control.xsh`; process, filesystem, and reconciliation
  boundaries belong in `factory_runtime.xsh` or a focused XSH tool. Add native
  XSH tests with synthetic sessions, fake processes, or mocked commands before
  considering an agent-backed check.
- Dogfood XSH. Factory control scripts and tools must be written in XSH. Use
  external commands only at explicit system boundaries such as Git, Docker,
  the local XSH distribution build, or a test double. Do not add Python or a
  second orchestration language.
- Fail closed at boundaries. Validate exact assignments, paths, commits,
  report headings, handbook lineage, image identity, and required evidence.
  Never silently fall back to a different ticket, eval, handbook, model, or
  product worktree.
- Preserve the evidence chain. A run must identify its XSH commit, freshly
  staged binaries, image ID, inputs, child sessions, reports, costs, and
  decision. User approval remains required for evals, merges, handbook
  promotion, and reversions.

These rules apply to new roles, evals, templates, tools, and controller code.
When a proposed design needs an exception, document the boundary and add the
native test that makes the exception observable.

## One cycle

Run a standard bounded organization cycle with:

```sh
XSH_MODULE_PATH=. xsh run.xsh cycle-organization.md
```

`run.xsh` creates one parent `runs/run-<id>/` and dispatches the phases. The
organization controller reconciles product branches, admits at most one
approved ticket, and starts the independent `eval-design` phase alongside the
primary ticket or eval phase. Ticket implementation must finish before its
linked candidate replay; the independent active eval remains a separate
phase. When no ticket is admitted, that independent eval is the primary phase
and design still overlaps it. Each child phase has its own run directory,
provenance, audit, sessions, lock, and cost report; the parent also writes an
aggregate cost report and `RUN.md`.

The organization controller resolves one clean XSH commit once at admission.
Every executor and SWE worktree records that snapshot or its explicitly named
candidate commit. A candidate replay points at the exact clean SWE worktree;
it does not mark the ticket merged or alter the user's branch.

For a direct approved eval cycle, use a request with `## Mode` set to `eval`.
For a direct ticket implementation cycle, use `ticket-implementation`. For a
standalone proposal phase, use `eval-design`; it dispatches exactly one
eval-designer and leaves the proposal pending review.

For an approved ticket implementation cycle, use a request with
`## Mode` set to `ticket-implementation` and an explicit `## Approved tickets`
list:

```sh
xsh run.xsh cycle-ticket-task-tags-001.md
```

The controller admits only tickets whose checked-in status is `Approved.`;
`Accepted.` remains a legacy-compatible status,
creates one isolated XSH worktree per ticket, and asks the director to launch
one `xsh-swe` worker per worktree. The branch is validated and left pending
user review; the controller never merges it. On a later reconciliation, an
implementation commit proven to be an ancestor of XSH `HEAD` changes that
same ticket's status to `Merged.` and fills its merge-record fields. Each run
records stage callbacks as Markdown files under `events/`.

The controller-owned eval pipeline is:

1. resolve the clean XSH admission commit and reconcile merged tickets;
2. parse the explicit trial and proposal counts;
3. rebuild and stage the local `xsh` and `xsht` image inputs;
4. write an ordered `DISPATCH.md` containing exactly the requested
   eval-manager and optional eval-designer rows;
5. launch those rows through the shared runner;
6. collect all worker reports and costs;
7. validate the full report contracts and handbook lineage;
8. compile `AUDIT.md` from the canonical sessions, evaluator manifests,
   reports, costs, and provenance;
9. fail with partial evidence when a required stage cannot complete.

New manager tickets become open for the next cycle. They are not dispatched to
SWE in the same eval cycle, which keeps diagnosis and implementation separate.
An organization cycle may implement one already-approved ticket, immediately
re-evaluate its linked eval against the unmerged worktree, run one independent
eval against XSH main, and then dispatch one eval-design proposal.

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
into XSH main. Reconciliation detects that merge from the recorded
implementation commit and updates the linked ticket in place. After that, the
linked eval-manager performs a controlled replay and records acceptance or
rejection. A rejection names the exact merged commit and creates a linked
revert proposal; it does not silently mutate main.

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

`AUDIT.md` is the run-level normalized index. It is generated by
`audit-run.xsh` from on-disk evidence after the child processes exit. Its
worker rows answer how difficult and expensive each role's session was. Its
evaluator rows keep protocol, correctness, restriction, and timing outcomes
independent, so a protocol miss is not mislabeled as a product correctness
failure. The audit result is an evidence gate for `RUN.md`; it never replaces
the raw session JSONL, evaluator manifest, or manager judgment.

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
