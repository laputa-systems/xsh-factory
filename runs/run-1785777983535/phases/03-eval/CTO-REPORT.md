# CTO briefing 03-eval

This is the deterministic first-pass briefing for the CTO. The structured
`report.json` files and raw Pi sessions remain the source of truth.

## Result

fail

## Operating context

- Mode: `eval`
- Request: `CYCLE-REQUEST.md`
- Structured report: `report.json`

## Phase outcomes

- `report.json`: result `pass`; report `report.json`
- `workers/eval-manager/task-envcfg/report.json`: result `pass`; report `workers/eval-manager/task-envcfg/report.json`
- `workers/eval-worker/task-envcfg-1/report.json`: result `pass`; report `workers/eval-worker/task-envcfg-1/report.json`


## Employee accounting

### Worker metrics

- `eval-manager/task-envcfg` (`eval-manager`): result `pass`; report `workers/eval-manager/task-envcfg/report.json`
  - Execution: `not recorded`; classification: `not recorded`
  - Turns: `21`; bucket tokens: `662909`; thinking blocks: `17`
  - Tool errors: `1`; cost: `0.019728`; budget: `0.150000`
- `eval-worker/task-envcfg-1` (`eval-worker`): result `pass`; report `workers/eval-worker/task-envcfg-1/report.json`
  - Execution: `pass`; classification: `pass`
  - Turns: `91`; bucket tokens: `2193368`; thinking blocks: `68`
  - Tool errors: `6`; cost: `0.056416`; budget: `0.500000`


### Nonzero tool results

- `eval-manager/task-envcfg`, turn `10`, tool `bash`: num calls 93 num results 0
Traceback (most recent call last):
  File "<stdin>", line 21, in <module>
TypeError: unsupported format string passed to NoneType.__format__


Command exited with code 1
  - Structured report: `workers/eval-manager/task-envcfg/report.json`
- `eval-worker/task-envcfg-1`, turn `29`, tool `bash`: err[check.unresolved-proc-command]: unresolved proc command
  probe6.xsh:2:3
    panic "boom"
err[check.unresolved-proc-command]: unresolved proc command
  probe6.xsh:2:3
    panic "boom"
    ^^^^^^^^^^^^ unresolved proc command
sh: syntax error: bad substitution


Command exited with code 2
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`
- `eval-worker/task-envcfg-1`, turn `38`, tool `bash`: err[check.type-mismatch]: type mismatch
  probe7.xsh:2:10
    return Err("bad config")
           ^^^^^^^^^^^^^^^^^ expected Result[Str, Error], found Result[<unknown>, Str]
err[check.type-mismatch]: type mismatch
  probe7.xsh:2:10
    return Err("bad config")
           ^^^^^^^^^^^^^^^^^ expected Result[Str, Error], found Result[<unknown>, Str]
sh: syntax error: bad substitution


Command exited with code 2
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`
- `eval-worker/task-envcfg-1`, turn `51`, tool `bash`: sh: syntax error: unexpected "("


Command exited with code 2
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`
- `eval-worker/task-envcfg-1`, turn `57`, tool `bash`: language reference items: 95
total queryable items: 621
documented items: 621

modules
├── applet (8 items)
│   ├── current_euid (1 overload)
│   ├── current_exe (1 overload)
│   ├── hash_password (1 overload)
│   ├── login_session (1 overload)
│   ├── mdev (1 overload)
│   ├── su_session (1 overload)
│   ├── sulogin_session (1 overload)
│   └── verify_password (1 overload)
├── archive (11 items)
│   ├── compress (1 overload)
│   ├── cpio_create (1 overload)
│   ├── cpio_extract (1 overload)
│   ├── cpio_list (1 overload)
│   ├── decompress (1 overload)
│   ├── decompress_bytes (1 overload)
│   ├── tar_create (1 overload)
│   ├── tar_extract (1 overload)
│   ├── tar_list (1 overload)
│   ├── zip_extract (1 overload)
│   └── zip_list (1 overload)
├── bytes (14 items)
│   ├── concat (1 overload)
│   ├── copy (1 overload)
│   ├── copy_file (1 overload)
│   ├── from_ints (1 overload)
│   ├── from_text (1 overload)
│   ├── human (1 overload)
│   ├── pack_be (1 overload)
│   ├── pack_le (1 overload)
│   ├── read_at (1 overload)
│   ├── unpack_be (1 overload)
│   ├── unpack_le (1 overload)
│   ├── write_at (1 overload)
│   ├── zero (1 overload)
====


Command exited with code 1
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`
- `eval-worker/task-envcfg-1`, turn `58`, tool `bash`: (no output)

Command exited with code 1
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`
- `eval-worker/task-envcfg-1`, turn `61`, tool `bash`: --- run ---
runtime traceback
executable: /usr/local/bin/xsh
operation: main
error: runtime-error: runtime error
sh: syntax error: bad substitution


Command exited with code 2
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`


### Cycle total

- Workers: `2`
- Assistant turns: `112`
- Bucket tokens: `2856277`
- Cost (USD): `0.076144`
- Nonzero tool results: `7`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-manager/task-envcfg

- Role: `eval-manager`
- Result: `pass`
- Report: `workers/eval-manager/task-envcfg/REPORT.md`

#### Efficiency and evidence

One configured trial (controller-requested count = 1). Single worker
`task-envcfg-1` on model `openrouter/deepseek/deepseek-v4-flash-0731`.

Per trial (worker `report.json`):
- assistant turns: 91
- tool calls: 93; tool results: 93; tool errors: 6
- session wall span: 690,775 ms (~11.5 min); agent wall 692,595 ms
- tools used: bash 88, read 3, edit 1, write 1
- user messages: 1; stop reasons: 1 stop, 90 toolUse
- worker friction: high. The task's correct solution is ~10 lines, yet the
  worker burned most of the session discovering the planned `api:env.int` /
  `api:env.bool` typed-read surface and, above all, searching for a clean way
  to exit nonzero on a malformed `CFG_PORT` (see Tool-error findings and
  Observation classification). The dominant cost driver was language
  discovery, not task logic.

#### Handbook or proposal decision

Provisional candidate staged at
`runs/run-1785777983535/phases/03-eval/lineage/handbook-candidate.md`
(approved snapshot `c7c9dd9a…` plus one sentence in the "Development loop and
tooling" section). General lesson: when `xsht api` rejects a bare receiver
query (`method:Str`), browse a type's full member surface with
`xsht api summary | grep NAME`, rather than probing rejected query forms one at
a time. This is a short, reusable learning guide that does not depend on the
product-index fix in `task-envcfg-004` and would remove the recurring
rejected-query discovery loop seen in this run and in the `task-envcfg-004`
run.

This was a one-trial plan, so the candidate is a hypothesis only; promotion to
`runtime/handbook.md` requires a later replay. The largest friction of this run
(the missing error/fail primitive) is a product defect tracked in
`task-envcfg-001`, not fixable by a handbook edit, so no handbook candidate is
offered for it.

#### Ticket or product decision

None. All distinct observations map to already-open tickets: the
error-construction/no-fail-primitive gap to `task-envcfg-001` (this run's
out-of-bounds-index workaround and the two error probes #1/#2 are fresh,
reproducible evidence for it), and the per-type API index gap to
`task-envcfg-004`. No manager-session evidence warrants a new ticket for the
next cycle.

#### Next action

`task-envcfg`, on the shared `runtime/handbook.md` lineage, at whatever XSH
commit the merged implementation of `task-envcfg-001` and/or `task-envcfg-004`
lands. After `task-envcfg-001` merges, replay `task-envcfg` and require the
malformed-port path to use the documented error constructor (or `fail`/`assert`
primitive) instead of an out-of-bounds-index or fake-host-call workaround,
with all 10 oracle cases still byte-exact. Replay the handbook candidate
(`xsht api summary | grep NAME` browsing note) in a later task-envcfg or
task-tags trial to see whether it removes the rejected-query discovery loop
before promoting it to `runtime/handbook.md`.

#### North-star impact

This run confirms that XSH's central failure mechanism (`?` propagation) can
only be fed by real host failures: an agent handling a plain validation
boundary had to manufacture a runtime crash (out-of-bounds list index) or,
in the earlier run, a fake failing `env` call, to exit nonzero — exactly the
opaque, boundary-hiding trick the north star says XSH must avoid. That is a
durable ergonomics/correctness product gap, already on the shared lineage as
`task-envcfg-001`. The secondary signal (type-surface browsing requires a
full-index dump + grep) is a learnability/reference gap tracked in
`task-envcfg-004`, with a provisional handbook safety-net sentence staged for
replay. Together these move the mission forward by making "abort on bad
input" a first-class, teachable action and by removing repeated discovery
friction, while this run itself passed all ten correctness cases byte-for-byte
against the oracle.



## Eval proposal review

No CTO eval review was recorded.

## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` (required; next CTO must
  validate or revert it before paid work)
