# CTO briefing 02-reeval-task-envcfg-001

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
  - Turns: `22`; bucket tokens: `1127348`; thinking blocks: `18`
  - Tool errors: `1`; cost: `0.039842`; budget: `0.150000`
- `eval-worker/task-envcfg-1` (`eval-worker`): result `pass`; report `workers/eval-worker/task-envcfg-1/report.json`
  - Execution: `pass`; classification: `pass`
  - Turns: `51`; bucket tokens: `954906`; thinking blocks: `35`
  - Tool errors: `3`; cost: `0.027607`; budget: `0.500000`


### Nonzero tool results

- `eval-manager/task-envcfg`, turn `10`, tool `bash`: total lines: 107
--- line 57 toolResult (isError=False) ---
query: language:core.results
status: exact

api: language.core.results
kind: language
purpose: Defines Result values and error families.
contract: Expected host failures remain Result data until ? or another explicit boundary propagates them.
effects: none
tags: language, results
example:
  let value: Result[Str] = Ok("ready")
=====search Error=====
query: search:Error
status: matches

api: language.core.fallback
kind: language
purpose: Defines fallback expressions for recoverable values.

api: language.core.postfix-question
kind: language
purpose: Defines postfix ? error propagation.
=====search error family=====
query: search:error
status: matches

api: language.core.fallback
kind: language
purpose: Defines fallback expressions for recoverable values.

api: language.core.postfix-question
Traceback (most recent call last):
  File "<stdin>", line 16, in <module>
KeyError: slice(None, 400, None)


Command exited with code 1
  - Structured report: `workers/eval-manager/task-envcfg/report.json`
- `eval-worker/task-envcfg-1`, turn `3`, tool `bash`: query: api:env.get
status: exact

api: module.env.get
kind: module-function
purpose: Reads one environment variable as text.
contract: Missing variables and invalid host bytes remain distinguishable results.
effects: env
signature: env.get(name: Str) -> Result[Str, Error]
tags: env, get, lookup, utf8
---signature---
xsht api: invalid API query 'signature:env.get_or'; unknown selector kind 'signature'


Command exited with code 2
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`
- `eval-worker/task-envcfg-1`, turn `16`, tool `bash`: xsht api: invalid API query 'api:language.core.fallback'; expected NAME.MEMBER
=RESULTS=
xsht api: invalid API query 'api:language.core.results'; expected NAME.MEMBER


Command exited with code 2
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`
- `eval-worker/task-envcfg-1`, turn `42`, tool `bash`: warn[lint.needless-annotation]: needless type annotation
  /work/envcfg.xsh:7:12
      let _: Int = "".parse_int()?
             --- this type annotation is redundant with the initializer
help: remove needless annotation
warn[lint.path-constructor]: prefer p-string interpolation over `Path(...)`
  /work/envcfg.xsh:10:12
    fs.write(Path(out), text)?
             --------- use path string syntax instead
note: `Path(...)` remains a cast, but p-strings are the preferred path syntax
help: replace with path string -> fp"${out}"
lint exit=1
== tests ==
all-default            mine_code=0 oracle_code=0 mine_created=y oracle_created=y MATCH
all-set                mine_code=0 oracle_code=0 mine_created=y oracle_created=y MATCH
port-leadzero          mine_code=0 oracle_code=0 mine_created=y oracle_created=y MATCH
port-empty             mine_code=3 oracle_code=1 mine_created=y oracle_created=y DIFF:
--- /tmp/m.cfg
+++ /tmp/o.cfg
@@ -1,3 +0,0 @@
-host=h
-port=0042
-debug=false
port-abc               mine_code=3 oracle_code=1 mine_created=y oracle_created=y DIFF:
--- /tmp/m.cfg
+++ /tmp/o.cfg
@@ -1,3 +0,0 @@
-host=h
-port=0042
-debug=false
port-neg               mine_code=3 oracle_code=1 mine_created=y oracle_created=y DIFF:
--- /tmp/m.cfg
+++ /tmp/o.cfg
@@ -1,3 +0,0 @@
-host=h
-port=0042
-debug=false
port-0x                mine_code=3 oracle_code=1 mine_created=y oracle_created=y DIFF:
--- /tmp/m.cfg
+++ /tmp/o.cfg
@@ -1,3 +0,0 @@
-host=h
-port=0042
-debug=false
host-empty             mine_code=0 oracle_code=0 mine_created=y oracle_created=y MATCH
debug-empty            mine_code=0 oracle_code=0 mine_created=y oracle_created=y MATCH
debug-false            mine_code=0 oracle_code=0 mine_created=y oracle_created=y MATCH
port-space             mine_code=3 oracle_code=1 mine_created=y oracle_created=y DIFF:
--- /tmp/m.cfg
+++ /tmp/o.cfg
@@ -1,3 +0,0 @@
-host=localhost
-port=8080
-debug=false


Command exited with code 1
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`


### Cycle total

- Workers: `2`
- Assistant turns: `73`
- Bucket tokens: `2082254`
- Cost (USD): `0.067450`
- Nonzero tool results: `4`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-manager/task-envcfg

- Role: `eval-manager`
- Result: `fail`
- Report: `workers/eval-manager/task-envcfg/REPORT.md`

#### Efficiency and evidence

Single trial (controller executed 1 fresh trial against the candidate build).
Eval-worker `task-envcfg-1`:

- Assistant turns: 51 (1 user message; 1 `stop`, 50 `toolUse`)
- Tool calls: 52; tool results: 52; tool errors: 3
- Session span: 576,994 ms (~9.6 min); agent wall: 578,340 ms
- Thinking blocks: 35
- Model: `openrouter/deepseek/deepseek-v4-flash-0731`, thinking `high`

The phase-level `report.json` data block mirrors this worker (`assistant_turns 51`,
`tool_errors 3`, `cost_usd 0.0276`). No eval-manager session friction was
recorded before this report; the report skeleton was the only missing artifact.
Worker friction concentrated in the error-raising search (turns 53-81), which is
the core observation below.

#### Handbook or proposal decision

Unchanged (candidate `lineage/handbook-candidate.md` is a byte-identical copy of
`lineage/handbook-approved.md`). A handbook sentence teaching `fail(message)` is
premature here: this run proves the primitive is not discoverable via `xsht api`,
so a handbook rule would point an agent at an undiscoverable surface, and a
one-trial plan cannot replay a promoted claim anyway. The durable, general lesson
is a product fix (register the primitive in the API reference and keep that
reference in sync with the runtime surface), captured as the ticket below. The
handbook should be revisited for a `fail(message)` sentence only after that
registry fix is merged and an agent actually adopts it in a replay.

#### Ticket or product decision

One product ticket for the next cycle:
`/Users/josh/d/laputa-systems/xsh-factory/tickets/task-envcfg-002.md` — "Runtime
keyword/constructor primitives (e.g. `fail`) are not surfaced in the `xsht api`
reference, so agents cannot discover them during an eval."

#### Next action

Re-run `task-envcfg` (and ideally `task-ecount`/`task-tags` where a loud nonzero
exit is required) against the candidate commit after `fail(message)` is registered
in `crates/xsh-registry/src/reference.rs` (an `xsht api search:fail` /
`api:...fail` so it resolves), then confirm the eval agent adopts `fail(...)?`
instead of the sentinel `parse_int` idiom, with all 10 cases and both failure
controls still passing. That is both the falsification check for ticket
`task-envcfg-001` (post-merge) and the validation check for ticket
`task-envcfg-002`.

#### North-star impact

The eval's purpose is a practical config-rendering boundary that must reject
malformed input loudly with no partial file — a core XSH "structured errors /
expected failures visible" scenario. The candidate correctly implements the
mechanical `fail` propagation, but XSH's north-star ergonomics/learnability bar
is "fewer guesses, workarounds, tool errors, and repeated discoveries" and "agents
reach a correct solution with less exploration." This run is direct evidence that
the tooling contract broke: an agent spent tens of turns and could not learn of a
newly shipped primitive, so the very workaround the ticket targeted is still the
only reachable path during an eval. Keeping the runtime surface and the `xsht api`
reference in lock-step is a precondition for a learnable language; this report ties
that general principle to concrete, reproducible evidence and names the exact
replay that can falsify it.



## Eval proposal review

No CTO eval review was recorded.

## Handbook lineage

Checked-in `runtime/handbook.md`: `97c5d804c42c7742c9edfea4480163828d864279391d391df77aa60ee4a40e83`
- approved snapshot: `lineage/handbook-approved.md` sha256 `97c5d804c42c7742c9edfea4480163828d864279391d391df77aa60ee4a40e83` — promoted by CTO ledger; matches checked-in handbook
- candidate: `lineage/handbook-candidate.md` sha256 `97c5d804c42c7742c9edfea4480163828d864279391d391df77aa60ee4a40e83` — promoted by CTO ledger; matches checked-in handbook


## Historical handbook backlog

Historical candidates: 47; differing: 34; ledger-dispositioned: 34; unresolved: 0.
No unresolved candidate content is present.

## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
