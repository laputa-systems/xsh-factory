# Director report

## Result

fail

## Cycle

Mode `ticket-implementation` (run `run-1785973336705`, phase `01-ticket`).
Controller-selected plan: implement exactly one approved ticket,
`task-findexec-001` (make `if`/`else` a first-class expression accepted in a
stream stage block's tail), in one isolated XSH worktree
(`factory/task-findexec-001/1785973339489`, base XSH commit
`1cf4ad3d7ee5fde9b3160b11d8073cbd7ce5e7c4`). Reconcile-only was set
(`FACTORY_DIRECTOR_RECONCILE_ONLY=true`): the controller launched the single
assigned engineer row; the director only reconciles the completed output and
records the evidence. No eval rows were dispatched in this mode.

## Children

- **engineer / task-findexec-001** — result: **fail (dispatch rejected)**
  Evidence path: `runs/run-1785973336705/phases/01-ticket/engineer-task-findexec-001.stderr`
  (`engineer dispatch does not match the controller assignment`) and the empty
  worker root `workers/engineer/task-findexec-001/` (no `REPORT.md`,
  `session.jsonl.bz2`, or commit). The runner's fail-closed validation aborted
  before Pi started.
  Root cause: the controller-authored assignment message
  (`messages/task-findexec-001.md`, line 12) writes the dedicated worktree as
  `/Users/josh/d/laputa-systems/xsh-factory/../.xsh-factory-worktrees/run-1785973336705/task-findexec-001`
  (factory-root-relative `xsh-factory/../` prefix), while the dispatch record
  (`dispatch/engineer-task-findexec-001.json`) and the inherited
  `FACTORY_WORKDIR` carry the normalized absolute path
  `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1785973336705/task-findexec-001`.
  `control.engineer_assignment_ok` compares
  `assignment.contains(f"- Dedicated XSH worktree: \`${workdir}\`")`, which
  cannot match the different spelling, so the runner aborts. The assignment
  message and the dispatch record must agree on the worktree path.
  No child branch or commit was produced; the worktree remains clean at the
  base commit.

## Required-output status

Controller-required outputs for a passing ticket-implementation cycle:

- Engineer narrative `REPORT.md` with `## Result` = `ready-for-review`, plus
  branch/commit/files/tests — **missing** (worker never launched; no Pi
  session was created).
- A committed implementation branch with the `if`/`else` tail change and
  passing `xsht` checks / clean worktree — **missing** (worktree clean at base
  `1cf4ad3`).
- Director `REPORT.md` — **present and written** (this file).
- Portable patch / merge record for the ticket — **not produced**, correctly,
  because no implementation exists.

The required product output is absent because the engineer dispatch was
rejected at the fail-closed boundary before any work could begin; this is an
infrastructure failure, not a product or agent outcome.

## North-star impact

This cycle produced no product signal: no XSH change was implemented and the
north-star question (does uniform `if`/`else` tail acceptance improve
learnability, agent efficiency, and the `task-findexec` replay) remains
untested. The durable finding is a **factory-infrastructure defect**: the
ticket-implementation assignment message and the dispatch record disagree on
the spellings of the dedicated worktree path (`xsh-factory/../` prefix vs.
normalized absolute path), which trips `control.engineer_assignment_ok` and
aborts the engineer before Pi starts. Because the fail-closed boundary worked
as designed (no altered/guessed assignment ran), the correct resolution is a
CTO-level factory fix — align the controller's message-path template with the
normalized `FACTORY_WORKDIR` in the dispatch record — then re-dispatch this
approved ticket in a fresh cycle to obtain the intended product evidence.
Uncertainty: the mismatch was reproduced once and is deterministic from the
string comparison; a second fresh run after the fix is the replay that would
falsify or confirm this diagnosis.
