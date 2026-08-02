# Factory agent guide

This repository is the XSH improvement factory: its controllers, evals,
prompts, tickets, shared handbook, and run evidence. The adjacent
`../xsh` repository is the XSH product. Keep those boundaries explicit.

## Start here

Read these files in this order before making a substantive decision:

1. [`NORTH-STAR.md`](NORTH-STAR.md) for the product mission.
2. [`FACTORY.md`](FACTORY.md) for layer contracts, invariants, and coding rules.
3. [`README.md`](README.md) for supported actions and operator commands.
4. [`docs/FACTORY-LOOPS.md`](docs/FACTORY-LOOPS.md) for the inner, outer, and
   organization loops.

If acting as the CTO, read [`CTO.md`](CTO.md) after the files above. It is the
bounded operating loop for inspecting evidence, making at most the permitted
decisions, and starting one cycle. Do not invent a broader autonomous loop.

Read only the role, cycle request, eval contract, ticket, template, or tool
files relevant to the task after this entry-point pass. The latest run's
`CTO-REPORT.md` is the first place to look when reviewing a completed cycle;
follow its links into `report.json`, employee narratives, evaluator manifests,
and raw Pi sessions only as needed.

## Repository boundary

The product checkout is `../xsh`. Its local contract is
[`../xsh/AGENTS.md`](../xsh/AGENTS.md), and its canonical rationale is
[`../xsh/docs/CHAPTER-01-why-xsh.md`](../xsh/docs/CHAPTER-01-why-xsh.md).

The product guide applies when editing files in `../xsh`; it is not the
factory's guide. For factory work, this file and the factory documents above
are authoritative. Engineer assignments must read the product guide because
they modify an isolated XSH worktree.

## Factory working contract

- Use XSH for factory controllers and tools. Do not add Python or another
  orchestration language.
- Keep orchestration deterministic and testable without Pi. Controllers own
  admission, exact assignments, process boundaries, cancellation, state
  transitions, and validation; agents own qualitative judgment.
- Do not put generated prompts, reports, or assignments inline in controller
  source. Store Markdown in `templates/` and substitute explicit fields.
- Add or update native XSH tests for pure parsing, lifecycle, reconciliation,
  cleanup, budget, and failure behavior. Use mocks and synthetic Pi sessions;
  do not spend model budget to test deterministic infrastructure.
- Preserve run evidence and user changes. Never reset unrelated work, merge
  product branches, or push to a remote without explicit instruction.
- Treat `run.xsh` as the only top-level launch path. Do not launch Pi directly
  or ask an employee to discover unassigned work.
- Keep cycles bounded by the coded role limits and aggregate cap. A budget
  breach must stop the factory cleanly and leave its postmortem/evidence.

## First checks

From this directory, inspect both repositories before editing:

```sh
git status --short
git -C ../xsh status --short
XSH_MODULE_PATH=. xsht test
```

For a cycle, use the documented request through `run.xsh`; run its preflight
and let the controller create the run directory, structured reports, child
sessions, lifecycle ledger, and CTO briefing. Do not bypass the controller.

For a product-language change, read the nearest product contract and test map
in `../xsh/docs/`, then follow `../xsh/AGENTS.md`. For a factory change, start
with the nearest controller/tool and its native test under `tests/`.

## Terminology

Use the current organization names: `CTO`, `director`, `eval-designer`,
`eval-manager`, `eval-executor`, `eval-worker`, and `engineer`. Older references
to “automator” or “xsh-swe” are legacy terminology, not new role names.
