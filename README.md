# XSH factory

This repository is the control plane for improving XSH: practical evals,
agent guidance, product tickets, and CTO-reviewed changes. The product
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
Engineers default to `openai/gpt-5.6-luna`; the other roles default to
`deepseek/deepseek-v4-flash-0731`, all with high thinking.
Provider, model, thinking, tools, turn, wall, and dollar ceilings are
individually configurable with `FACTORY_<ROLE>_*` variables. The coded role
budgets and aggregate cycle cap are in `factory_control.xsh`. The default
session wall limits are 12 minutes for eval designers, 15 minutes for eval
managers, and 30 minutes for eval workers and engineers; dollar and aggregate
caps remain hard limits. Ticket-implementation cycles may dispatch up to two
engineers concurrently, with a default aggregate cap of `$1.00`.

## Start a cycle

Run the standard organization request:

```sh
XSH_MODULE_PATH=. xsh run.xsh cycle-organization.md
```

Before launch, the CTO reviews every remaining `Open.` ticket. The CTO checks
evidence, duplication, scope, and acceptance criteria.
The controller reconciles merged tickets and admits up to two implementations.
It starts safe independent phases concurrently.
It replays successful tickets against linked evals.
It runs a different independent active eval.
It can produce, review, and promote one eval proposal.
With no approved ticket, the selected eval becomes the primary phase.

When reviewing ticket state, use the deterministic CTO inventory before an
organization request:

```sh
```
```sh
XSH_MODULE_PATH=. xsh run-cto.xsh
```

The CTO inventory also reports stale factory branches and their ticket status;
use that evidence before retiring any branch.

The organization controller also persists the same inventory as
`CTO-TICKET-INVENTORY.md` and `CTO-TICKET-INVENTORY.json` in every run before
ticket admission.

If an approved ticket has an unmerged factory branch, the organization
controller reuses that branch for the linked replay. It captures a portable
patch, then removes the temporary detached worktree.

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
runs/run-<id>/workers/<role>/<worker>/session.jsonl.bz2 compressed raw Pi session
runs/run-<id>/workers/<role>/<worker>/report.json  normalized worker metrics
runs/run-<id>/workers/<role>/<worker>/REPORT.md   employee judgment
runs/run-<id>/events.jsonl                        canonical lifecycle and process-output ledger
runs/run-<id>/CTO-REPORT.md                       human navigation briefing
runs/run-<id>/CTO-EVAL-REVIEW.md                  immediate CTO eval review
runs/run-<id>/CTO-IMPROVEMENT.md                  measurable CTO handoff
evals/<new-id>/                                   promoted package and CTO status.
```

Read `CTO-REPORT.md` first, then follow the report paths it names. The
structured schema and field meanings are in
[docs/REPORT-SCHEMA.md](docs/REPORT-SCHEMA.md). Tool failures are entries in
the worker `tool_errors` array; there is no separate tool-error Markdown
file. Pi's raw JSONL remains available for exact inspection. New evals provide
a package-owned `evaluator.xsh`; adding one must not modify
`evaluate_common.xsh`.

Every completed cycle must leave one measurable factory-wide improvement in
`CTO-IMPROVEMENT.md`. The CTO may implement it immediately and leave it
`pending-validation`; that status is a verification handoff, not an approval
gate. The next CTO pass validates or safely reverts it before starting paid
work.

For ticket cycles, the review artifact is a portable patch:

```sh
git -C ../xsh apply --check "$PWD/runs/run-<id>/patches/<ticket>.diff"
git -C ../xsh apply "$PWD/runs/run-<id>/patches/<ticket>.diff"
```

The factory removes a clean temporary worktree after its patch is captured.
The CTO reviews the patch and decides whether to merge or apply the product
change. The next reconciliation updates the linked `TICKET.md` to `Merged.`
when the recorded implementation is proven in XSH `HEAD`.

The CTO closes each paid cycle by committing the scoped factory changes with a
`cto: close <run-id>` commit. Generated `runs/` evidence and unrelated local
work stay out of that commit.

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
