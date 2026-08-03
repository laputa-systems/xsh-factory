# XSH factory

This repository is the control plane for improving XSH: practical evals,
agent guidance, product tickets, and user-reviewed changes. The product
checkout is the adjacent `../xsh` repository.

Start with [NORTH-STAR.md](NORTH-STAR.md), then read
[FACTORY.md](FACTORY.md) for the engineering contract and
[docs/FACTORY-LOOPS.md](docs/FACTORY-LOOPS.md) for the loop boundaries.

## Prerequisites

Run commands from this directory with:

- `xsh` and `xsht` on `PATH`;
- Docker running;
- Pi installed and authenticated at `~/.pi/agent/auth.json`; and
- a clean `../xsh` checkout.

The launcher, rather than a Markdown configuration file, owns role defaults.
All roles default to `deepseek/deepseek-v4-flash-0731` with high thinking.
Provider, model, thinking, tools, turn, wall, and dollar ceilings are
individually configurable with `FACTORY_<ROLE>_*` variables. The coded role
budgets and aggregate cycle cap are in `factory_control.xsh`. The default
session wall limits are 12 minutes for eval designers, 15 minutes for eval
managers, and 30 minutes for eval workers and engineers; dollar and aggregate
caps remain hard limits.

## Start a cycle

Run the standard organization request:

```sh
XSH_MODULE_PATH=. xsh run.xsh cycle-organization.md
```

It reconciles merged tickets, admits at most one approved implementation,
starts safe independent phases concurrently, replays a successful ticket
against its linked eval, and may stage one new eval proposal. With no approved
ticket, the selected eval becomes the primary phase.

If an approved ticket already has an unmerged factory branch, the organization
controller reuses that exact branch for the linked replay instead of dispatching
another engineer. It captures a portable patch, then removes only the temporary
detached worktree after replay.

Run a focused eval, ticket implementation, or design phase with its request:

```sh
XSH_MODULE_PATH=. xsh run.xsh cycle-task-tags.md
XSH_MODULE_PATH=. xsh run.xsh cycle-task-tags-minimum.md
XSH_MODULE_PATH=. xsh run.xsh cycle-ticket-task-tags-001.md
XSH_MODULE_PATH=. xsh run.xsh cycle-eval-design.md
```

Never launch Pi directly. `run.xsh` performs preflight, owns cancellation,
and delegates every Pi process through `run-agent.xsh`.

## Inspect a run

Every cycle is stored under `runs/run-<id>/`. The durable machine-readable
boundary is always `report.json`:

```text
runs/run-<id>/report.json                         run or phase report
runs/run-<id>/phases/<phase>/report.json          child phase report
runs/run-<id>/workers/<role>/<worker>/session.jsonl raw Pi session
runs/run-<id>/workers/<role>/<worker>/report.json  normalized worker metrics
runs/run-<id>/workers/<role>/<worker>/REPORT.md   employee judgment
runs/run-<id>/events.jsonl                        append-only lifecycle events
runs/run-<id>/CTO-REPORT.md                       human navigation briefing
```

Read `CTO-REPORT.md` first, then follow the report paths it names. The
structured schema and field meanings are in
[docs/REPORT-SCHEMA.md](docs/REPORT-SCHEMA.md). Tool failures are entries in
the worker `tool_errors` array; there is no separate tool-error Markdown
file. Pi's raw JSONL remains available for exact inspection.

For ticket cycles, the review artifact is a portable patch:

```sh
git -C ../xsh apply --check "$PWD/runs/run-<id>/patches/<ticket>.diff"
git -C ../xsh apply "$PWD/runs/run-<id>/patches/<ticket>.diff"
```

The factory removes a clean temporary worktree after its patch is captured.
It never merges or applies a product change. User review and merge remain the
authority; the next reconciliation updates the linked `TICKET.md` to
`Merged.` when the recorded implementation is proven in XSH `HEAD`.

## Reset and test

`make clean` removes generated runs, caches, staged eval binaries, and local
factory worktree state while retaining tickets, evals, branches, and the
shared handbook. It refuses to run during an active cycle.

Run the cheap native infrastructure suite before spending model budget:

```sh
XSH_MODULE_PATH=. xsht test
```

The tests use synthetic Pi JSONL and process/container doubles. They do not
launch Pi or Docker workloads.

Press Ctrl-C during a cycle. The top-level signal handler terminates all
registered descendants, including nested Pi and Docker workers, and leaves a
partial structured report plus any required postmortem.
