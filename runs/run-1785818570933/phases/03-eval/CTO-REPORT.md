# CTO briefing 03-eval

This is the deterministic first-pass briefing for the CTO. The structured
`report.json` files and raw Pi sessions remain the source of truth.

## Result

pass

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
  - Turns: `10`; bucket tokens: `276615`; thinking blocks: `8`
  - Tool errors: `0`; cost: `0.010592`; budget: `0.150000`
- `eval-worker/task-envcfg-1` (`eval-worker`): result `pass`; report `workers/eval-worker/task-envcfg-1/report.json`
  - Execution: `pass`; classification: `pass`
  - Turns: `48`; bucket tokens: `1426991`; thinking blocks: `37`
  - Tool errors: `6`; cost: `0.043411`; budget: `0.500000`


### Nonzero tool results

- `eval-worker/task-envcfg-1`, turn `6`, tool `bash`: query: language:effect.error
status: exact

api: language.effect.error
kind: language
purpose: Declares explicit error propagation with postfix ?.
contract: The error effect is required when ? can propagate outside a retry attempt block; it does not describe a host capability.
effects: none
tags: effect, error, propagation
example:
  proc load(path: Path) [fs, error] -> Result[Str] {
    return path.read_text()?
  }
=====
query: language:core.postfix-question
status: exact

api: language.core.postfix-question
kind: language
purpose: Defines postfix ? error propagation.
contract: ? unwraps a Result or returns its error and requires the declared error effect outside retry attempt blocks.
effects: none
tags: language, postfix-question
example:
  let value = Ok("ready")?
=====


Command exited with code 1
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`
- `eval-worker/task-envcfg-1`, turn `29`, tool `bash`: err[parse.expected-expression]: expected expression
  /tmp/mix.xsh:4:14
    return Ok(())
               ^ expected expression

err[parse.expected-terminator]: expected statement terminator
  /tmp/mix.xsh:4:15
    return Ok(())
                ^ expected statement terminator

sh: syntax error: bad substitution


Command exited with code 2
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`
- `eval-worker/task-envcfg-1`, turn `31`, tool `bash`: err[check.try-error]: incompatible propagated error
  /tmp/mix2.xsh:2:11
    let h = env.get_or("CFG_HOST", "x")?
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ cannot propagate Error from function returning Str

err[check.type-mismatch]: type mismatch
  /tmp/mix2.xsh:4:10
    return Ok(1)
           ^^^^^ expected Result[Int, Str], found Result[Int, Error]
sh: syntax error: bad substitution


Command exited with code 2
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`
- `eval-worker/task-envcfg-1`, turn `33`, tool `bash`: err[check.effect-violation]: `?` requires the `error` effect
  /tmp/path.xsh:3:3
    fs.write(out, "hello\n")?
    ^^^^^^^^^^^^^^^^^^^^^^^^^ `?` requires the `error` effect
exit=2
cat: can't open '/tmp/outtest.cfg': No such file or directory


Command exited with code 1
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`
- `eval-worker/task-envcfg-1`, turn `42`, tool `bash`: all absent                   xsh_exit=0 oracle_exit=0
  xsh file:   oracle  : sh: %q\n: invalid format
sh: %q\n: invalid format
valid all                    xsh_exit=0 oracle_exit=0
  xsh file:   oracle  : sh: %q\n: invalid format
sh: %q\n: invalid format
present empty host/debug     xsh_exit=0 oracle_exit=0
  xsh file:   oracle  : sh: %q\n: invalid format
sh: %q\n: invalid format
runtime traceback
executable: /usr/local/bin/xsh
operation: result.propagate
error: parse-int: invalid integer `abc`
call path:
  1. proc main at envcfg.xsh:1:1-1:1
port abc                     xsh_exit=3 oracle_exit=1
runtime traceback
executable: /usr/local/bin/xsh
operation: result.propagate
error: parse-int: expected integer
call path:
  1. proc main at envcfg.xsh:1:1-1:1
port empty                   xsh_exit=3 oracle_exit=1
runtime traceback
executable: /usr/local/bin/xsh
operation: result.propagate
error: parse-int: invalid integer `a`
call path:
  1. proc main at envcfg.xsh:1:1-1:1
port 12a                     xsh_exit=3 oracle_exit=1
runtime traceback
executable: /usr/local/bin/xsh
operation: result.propagate
error: parse-int: expected integer
call path:
  1. proc main at envcfg.xsh:1:1-1:1
port -1                      xsh_exit=3 oracle_exit=1
runtime traceback
executable: /usr/local/bin/xsh
operation: result.propagate
error: parse-int: expected integer
call path:
  1. proc main at envcfg.xsh:1:1-1:1
port +10                     xsh_exit=3 oracle_exit=1
port leading zero            xsh_exit=0 oracle_exit=0
  xsh file: sh: %q\n: invalid format
  oracle  : sh: %q\n: invalid format
runtime traceback
executable: /usr/local/bin/xsh
operation: result.propagate
error: parse-int: invalid integer `.`
call path:
  1. proc main at envcfg.xsh:1:1-1:1
port 1.5                     xsh_exit=3 oracle_exit=1


Command exited with code 1
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`
- `eval-worker/task-envcfg-1`, turn `47`, tool `bash`: -rw-r--r--    1 root     root           489 Aug  4 05:18 envcfg.xsh
-rw-r--r--    1 root     root          2028 Aug  4 05:18 review.md
=== valid full ===
host=node-a
port=9001
debug=true
=== invalid (no file, nonzero) ===
runtime traceback
executable: /usr/local/bin/xsh
operation: result.propagate
error: parse-int: expected integer
call path:
  1. proc main at envcfg.xsh:1:1-1:1
exit=3
ls: /tmp/oc: No such file or directory


Command exited with code 1
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`


### Cycle total

- Workers: `2`
- Assistant turns: `58`
- Bucket tokens: `1703606`
- Cost (USD): `0.054003`
- Nonzero tool results: `6`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-manager/task-envcfg

- Role: `eval-manager`
- Result: `pass`
- Report: `workers/eval-manager/task-envcfg/REPORT.md`

#### Efficiency and evidence

Trial 1 (`workers/eval-worker/task-envcfg-1/`):
- Assistant turns: 48 (47 `toolUse` stops, 1 final `stop`).
- Tool calls: 48; tool results: 48; tool errors: 6.
- Tool mix: bash 43, write 2, read 2, edit 1.
- Session span: 553,120 ms (~9.2 min); agent wall 554,405 ms; budget pass (0.5 USD cap).
- Worker friction: moderate — the worker iterated several compile/check cycles (turns 29/31/33) to nail the `error` effect declaration and a byte-exact validation idiom, then a long self-check harness run (turn 42) and a final verification (turn 47). All friction was resolved within budget; the artifact `envcfg.xsh` (489 B) was placed on the first correct attempt after those iterations.

Manager session: no tool calls, no tool errors.

#### Handbook or proposal decision

Unchanged. The approved handbook snapshot already contains the `Environment and configuration` section (`module:env`, `env.get_or` absence-not-empty semantics, "typed `env.int`/`env.bool` are convenience readers, not strict format validators"), the `?`/`error`-effect rule, and the "deliberate validation failure via typed conversion" guidance — all of which the worker needed and used successfully. The one genuine re-usable gap (missing deliberate-error primitive) is a product-language issue already owned by approved ticket task-envcfg-001; a handbook rule here would only restate the contradictory workaround the handbook already warns against. No new provisional handbook lesson meets the "short general rule, removes repeated friction" bar from a single passing trial. Lineage candidate copied from `handbook-approved.md` unchanged.

#### Ticket or product decision

Zero. The strong reproducible observation (missing deliberate-error/`Error` primitive that propagates through `?`) is already materialized as approved ticket `tickets/task-envcfg-001.md` (status `Approved.`, from the prior two-worker run); this trial independently reproduces its diagnosis but opening a duplicate would be noise. All other observations are noise or already-documented friction.

#### Next action

No handbook candidate was staged, so there is no pending handbook replay for `task-envcfg`. The next replay is the post-merge acceptance of ticket `task-envcfg-001`: once the deliberate-error primitive lands and is merged, replay `evals/task-envcfg` (and, per the ticket, `task-ecount`/`task-tags`) against the merged XSH commit, reapplying this run's `handbook-approved.md` lineage (sha `97c5d804...`), to confirm the sentinel idiom is replaced by the primitive and all cases still pass.

#### North-star impact

The trial passes cleanly on the existing handbook, demonstrating that the env/config surface is discoverable and composable on the approved snapshot — the config-from-variables, byte-exact write, and loud-nonzero-failure pattern all transferred from the handbook plus `xsht api`. It independently re-confirms the single most important ergonomics gap: there is no first-class deliberate-error primitive that propagates through `?`, so agents must abuse an unrelated `parse_int` on a sentinel to reject malformed input — exactly the kind of opaque, contradiction-ridden workaround the north star says structured, learnable errors should eliminate. That finding is already owned by an approved ticket, so the correct next step is to implement and then re-accept it, which will make XSH's error story more trustworthy and more learnable for any config/argument validation boundary.



## Eval proposal review

No CTO eval review was recorded.

## Handbook lineage

Checked-in `runtime/handbook.md`: `97c5d804c42c7742c9edfea4480163828d864279391d391df77aa60ee4a40e83`
- approved snapshot: `lineage/handbook-approved.md` sha256 `97c5d804c42c7742c9edfea4480163828d864279391d391df77aa60ee4a40e83` — promoted by CTO ledger; matches checked-in handbook
- candidate: `lineage/handbook-candidate.md` sha256 `97c5d804c42c7742c9edfea4480163828d864279391d391df77aa60ee4a40e83` — promoted by CTO ledger; matches checked-in handbook


## Historical handbook backlog

Historical candidates: 45; differing: 34; ledger-dispositioned: 34; unresolved: 0.
No unresolved candidate content is present.

## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
