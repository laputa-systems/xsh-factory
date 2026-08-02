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

## One cycle

Run one organization cycle with:

```sh
xsh run.xsh cycle-request.md
```

`run.xsh` creates `runs/run-<id>/`, starts the director, and produces a
run-level report and cost report. The director resolves the current XSH main
commit once at cycle start. Every executor and SWE worktree records that
snapshot or its explicitly named candidate commit.

The default bounded pipeline is:

1. run each active eval-manager for its configured trial count;
2. ask eval-designer for one new eval with a staged dry run;
3. launch one xsh-swe per open ticket that existed at cycle start;
4. collect all worker reports, branches, and costs;
5. fail with partial evidence when a required stage cannot complete.

New manager tickets become open for the next cycle. They are not dispatched to
SWE in the same cycle, which keeps diagnosis and implementation separate.

## Evals

An eval contract defines a practical task, agent-facing files, the image and
tool boundary, an external oracle, the evaluator, the review protocol,
quantitative metrics, and manager policy. Ecount is the current upper bound on
acceptable difficulty. Code quality remains qualitative; objective gates are
correctness, restrictions, protocol output, agent effort, and candidate/oracle
execution time.

For strict timing tasks:

```text
0.90 <= median(candidate wall time) / median(oracle wall time) <= 1.10
```

The current ecount eval is the first approved seed. New evals remain pending
review until the user approves their proposal branch.

## Tickets and changes

An eval-manager may create a ticket after one strong reproducible observation.
The ticket must link the exact eval, manager lineage, manager session, executor
run, and XSH baseline. It must state an observation, evidence, diagnosis or
hypothesis, proposed change, acceptance criteria, and post-merge evaluation.

Manager lineages are provisional branches per eval. Later runs may follow the
latest provisional handbook before approval. User rejection returns the eval to
the last approved lineage.

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
totals, and the grand total. It includes input, output, cache, reasoning, and
total tokens, provider-reported dollars, turns, tools, errors, wall time,
model, and thinking level. Missing provider cost fails closed. A budget breach
stops and fails that worker while preserving its partial session.

## Launcher contract

`run.xsh` and `run-agent.xsh` are the executable configuration. The runner
accepts these role-specific environment variables; defaults are explicit in
`run-agent.xsh` and all five Pi roles default to provider `openrouter`, model
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
