# task-iniget — staged dry run

Local validation of the materialized proposal on the current XSH build. The
package-owned evaluator's sandbox roots were relocated via `INIGET_WORK` /
`INIGET_SESSION` / `INIGET_EXPORT` (defaults are the container `/work`,
`/session`, `/export`); this host has no root-level `/work`. The shipped
evaluator keeps the container path contract.

## Reference candidate fixture sweep (`/tmp/iniget-dry`, exit + empty-stdout shown)

| case | section/key | expected | result |
| --- | --- | --- | --- |
| public | server/host | example.test | exit 0, matches |
| hidden_port (success) | server/port | 8080 | exit 0, matches |
| hidden_spaces (success) | app/name | hello world | exit 0, matches |
| hidden_trim (success) | alpha/path | /usr/local/bin | exit 0, matches |
| hidden_global (success) | service/name | api | exit 0, matches |
| hidden_missing_key (fail) | server/absent | nonzero, empty | exit 3, empty stdout |
| hidden_missing_section (fail) | nosuch/host | nonzero, empty | exit 3, empty stdout |
| hidden_malformed (fail) | duplicate key | nonzero, empty | exit 3, empty stdout |

All eight evaluator cases: `exact = true`.

## Evaluator decision controls (via the evaluator, `run.json` classification)

| control | candidate | classification | result |
| --- | --- | --- | --- |
| pass | correct reference `iniget.xsh` | pass | evaluator exit 0 |
| A | wrong hardcoded output | candidate_failed | evaluator exit 1 |
| B | uses `process.` | restriction_failed | evaluator exit 1 |
| C | hand-written parser, no `ini.` | restriction_failed (uses_ini false) | evaluator exit 1 |
| D | missing/incomplete `review.md` | protocol_failed | evaluator exit 1 |

Evidence: `evidence/pass.run.json` (byte-exact pass manifest with per-case
candidate/oracle exit, wall ns, and `uses_ini`/protocol flags).

## What remains unproven

- A live container trial of the exact `/work` `/session` `/export` paths and a
  real agent session (this dry run used a reference candidate, not a Pi).
- The pinned gym image actually exposing `ini.decode` (confirmed present in the
  local build and standard-module source, but not yet in a container run).
- Candidate vs oracle timing envelope (recorded, diagnostic only).
