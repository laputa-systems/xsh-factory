# XSH factory

The factory improves XSH through small practical evals, evidence-backed
handbook changes, and user-reviewed product tickets. The product repository is
the adjacent `../xsh` checkout; this repository owns the factory, evals,
prompts, tickets, and run evidence.

Read [NORTH-STAR.md](NORTH-STAR.md) for the mission and
[FACTORY.md](FACTORY.md) for the contracts and engineering rules.

## Prerequisites

- Run commands from this directory.
- Have the local `xsh` binary available on `PATH`.
- Have Docker available.
- Have Pi installed and authenticated at `~/.pi/agent/auth.json`.
- Keep the product checkout at `../xsh`.

The default provider, model, thinking level, tools, and budget are coded in
`factory_control.xsh`. Override one role at invocation time with variables
such as `FACTORY_EVAL_MANAGER_MODEL` or `FACTORY_XSH_SWE_THINKING`.

## Common actions

Run the approved eval cycle:

```sh
XSH_MODULE_PATH=. xsh run.xsh cycle-task-tags.md
```

This automatically reconciles merged tickets, rebuilds the local XSH and
xsht distribution with `make dist-Linux-docker`, stages both binaries, and
rebuilds the Docker image with pull and no-cache enabled. Every child Pi
session and the run-level cost report are saved under `runs/run-<id>/`.

Run the explicit reconciliation pass without launching Pi:

```sh
XSH_MODULE_PATH=. xsh reconcile.xsh
```

Implement an approved ticket:

```sh
XSH_MODULE_PATH=. xsh run.xsh cycle-ticket-task-tags-001.md
```

The controller creates one worktree and one exact assignment per ticket. It
never merges the product branch. After the user merges the branch into XSH,
the next reconciliation changes that ticket's `## Status` from `Accepted.` to
`Merged.` and records the implementation branch, commit, source run, and
detected XSH commit in the same ticket file. Do not run the implementation
cycle again for a merged ticket; run its linked eval cycle for acceptance.

Inspect the latest run:

```sh
ls -td runs/run-* | head -1
less runs/run-<id>/RUN.md
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

Run the cheap non-agent checks with:

```sh
XSH_MODULE_PATH=. xsht test
```

These tests use synthetic Pi sessions and harmless process or Docker doubles;
they do not spend model budget. Do not run `make lint`, formatters, or
autofixers as part of factory verification.
