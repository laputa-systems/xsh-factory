# XSH factory

The factory improves XSH through small practical evals, evidence-backed
handbook changes, and user-reviewed product tickets. The product repository is
the adjacent `../xsh` checkout; this repository owns the factory, evals,
prompts, tickets, and run evidence.

Read [NORTH-STAR.md](NORTH-STAR.md) for the mission and
[FACTORY.md](FACTORY.md) for the contracts and engineering rules.
For an unattended, bounded improvement loop, read
[CTO.md](CTO.md) and explicitly start the factory according to its
instructions.

## Prerequisites

- Run commands from this directory.
- Have the local `xsh` binary available on `PATH`.
- Have Docker available.
- Have Pi installed and authenticated at `~/.pi/agent/auth.json`.
- Keep the product checkout at `../xsh`.

The default provider, model, thinking level, tools, and role budget are coded
in `factory_control.xsh`. The default budgets are `$0.06` for the director,
`$0.15` for the eval-manager, `$0.25` for engineer, `$0.30` for the
eval-designer, and `$0.50` for the eval-worker. Budget overrides can lower a
ceiling but cannot raise it. Override other role settings at invocation time
with variables such as `FACTORY_EVAL_MANAGER_MODEL` or
`FACTORY_ENGINEER_THINKING`.

Each top-level cycle has a live aggregate cap of `$0.50`, which can be lowered
with `FACTORY_CYCLE_BUDGET_USD`. A breach terminates the full run tree and
writes `POSTMORTEM.md` in the run directory before returning control.

## Common actions

Run the approved eval cycle:

```sh
XSH_MODULE_PATH=. xsh run.xsh cycle-task-tags.md
```

This automatically reconciles merged tickets, rebuilds the local XSH and
xsht distribution with `make dist-Linux-docker`, stages both binaries, and
reuses the locally cached `Dockerfile.test` toolchain and Docker layers. The
cache key includes the product build files, target, and host architecture;
set `FACTORY_FORCE_XSH_TOOLCHAIN_REBUILD=true` and
`FACTORY_FORCE_IMAGE_REBUILD=true` when a deliberate full rebuild is needed.
The base and eval image tags are content-addressed by the XSH commit, staged
factory modules, Dockerfiles, toolchain inputs, target, and platform, so
repeated cycles reuse the same image names instead of creating timestamped
images. Each eval run records the resolved tags and whether the toolchain was
rebuilt or reused in `xsh-build.state`.
Every child Pi session and the run-level cost report are saved under
`runs/run-<id>/`.

Run the standard organization cycle (automatic first approved ticket, linked
pre-merge re-evaluation, independent task-ecount eval, and one new eval
proposal):

```sh
XSH_MODULE_PATH=. xsh run.xsh cycle-organization.md
```

If no approved ticket exists, the selected eval runs as the primary phase
instead. With an approved ticket, the independent active eval starts alongside
ticket implementation, while the linked candidate replay waits for the engineer
patch. The parent run is under
`runs/run-<id>/`; inspect its `RUN.md` and `COST.md`, then inspect each ordered
phase under `phases/`. `CTO-REPORT.md` is the deterministic first-pass briefing
with phase outcomes, per-role accounting, employee decisions, and the action
queue; use it to decide where deeper inspection is needed.

Before dispatching any child, `run.xsh` checks the request shape, XSH
worktree cleanliness, required factory files, Pi authentication, executable
availability, active-run markers, and—when an eval will run—the Docker daemon
and local build tool.

Run only the eval-design phase:

```sh
XSH_MODULE_PATH=. xsh run.xsh cycle-eval-design.md
```

This stages one proposal and dry-run evidence for review without approving or
modifying an eval.

Run the explicit reconciliation pass without launching Pi:

```sh
XSH_MODULE_PATH=. xsh reconcile.xsh
```

Implement an approved ticket:

```sh
XSH_MODULE_PATH=. xsh run.xsh cycle-ticket-task-tags-001.md
```

The controller creates one worktree and one exact assignment per ticket. It
never merges or applies the product branch. After the user applies the patch
or merges the branch into XSH,
the next reconciliation changes that ticket's `## Status` from `Approved.` (or
legacy `Accepted.`) to
`Merged.` and records the implementation branch, commit, source run, and
detected XSH commit in the same ticket file. Do not run the implementation
cycle again for a merged ticket; run its linked eval cycle for acceptance.

Every validated ticket cycle also writes a portable patch under the run's
`patches/` directory and removes its temporary worktree once the linked
re-evaluation has passed. The review branch remains available, but applying
the patch is the compact review path:

```sh
git -C ../xsh apply --check "$PWD/runs/run-<id>/patches/<ticket>.diff"
git -C ../xsh apply "$PWD/runs/run-<id>/patches/<ticket>.diff"
git -C ../xsh commit -am "Apply <ticket> factory patch"
XSH_MODULE_PATH=. xsh reconcile.xsh
```

Reconciliation recognizes either the original implementation commit or an
equivalent patch applied on XSH main. Inspect and approve the patch before
applying it; the factory never mutates XSH main automatically.

Clear generated factory state after inspecting the evidence:

```sh
make clean
```

This refuses to run during an active cycle, removes `runs/` evidence and build
cache, local eval build staging, and factory worktree contents, and retains
product branches, tickets, evals, and the shared handbook.

Inspect the latest run:

```sh
ls -td runs/run-* | head -1
less runs/run-<id>/RUN.md
less runs/run-<id>/CTO-REPORT.md
less runs/run-<id>/COST.md
less runs/run-<id>/AUDIT.md
```

Rebuild only the deterministic audit for an existing run:

```sh
XSH_MODULE_PATH=. xsh audit-run.xsh runs/run-<id> eval
```

The important evidence includes `PROVENANCE.md`, `DISPATCH.md`, child
`session.jsonl` files, `thinking.md`, worker reports, evaluator `run.json`,
`MANAGER-REPORT.md`, `DIRECTOR-REPORT.md`, and the deterministic audit.

The audit is derived after child completion. It keeps worker effort metrics
separate from evaluator protocol, correctness, restriction, and timing facts;
the raw Pi JSONL and evaluator manifests remain canonical. A failed audit is
an evidence or outcome failure, not a reason to discard the run directory.

## Safety and control

Press Ctrl-C during a run. `run.xsh` immediately terminates the registered
workers and Docker containers and leaves partial evidence in the run directory.
The controller uses a run lock, so overlapping cycles are rejected.

New eval proposals remain pending review. Ticket branches remain pending user
review until merged. The eval-manager decides whether a merged product change
meets its acceptance criteria; a rejection must name the merged commit and
propose a revert or follow-up.

If a worker crosses its hard budget, the controller preserves the partial run
and records the durable consequence: an eval-worker disables its eval, while
an engineer worker closes its assigned ticket as too difficult with a link to
the attempted run.

Run the cheap non-agent checks with:

```sh
XSH_MODULE_PATH=. xsht test
```

These tests use synthetic Pi sessions and harmless process or Docker doubles;
they do not spend model budget. Do not run `make lint`, formatters, or
autofixers as part of factory verification.
