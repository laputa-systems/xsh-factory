# Factory report schema

Factory-generated facts use one versioned JSON envelope. Markdown remains the
input and judgment surface for prompts, eval contracts, tickets, handbook
candidates, and employee narratives. It is not a second machine-state schema.

## Files

Each boundary has one `report.json`:

```text
runs/run-<id>/report.json
runs/run-<id>/phases/<phase>/report.json
runs/run-<id>/workers/<role>/<worker>/report.json
```

The Pi `session.jsonl` beside a worker report is raw evidence and remains
canonical for session details. The top-level `CTO-REPORT.md` is a generated
human briefing, not a source of facts.

## Envelope

Every report contains:

```json
{
  "schema_version": 1,
  "kind": "worker|phase|run",
  "identity": {},
  "state": "completed",
  "result": "pass|fail|cancelled|unknown",
  "findings": [],
  "artifacts": []
}
```

`identity` names the run, phase, role, worker, eval, or ticket relevant to the
boundary. `findings` are structured observations or failures. `artifacts`
contains typed paths and optional hashes.

Worker reports add `session`, `usage`, `timing`, `models`, `stop_reasons`,
`tools`, and `tool_errors`. A failed Pi tool invocation is represented directly
as an entry in `tool_errors`, with its turn, tool name, short result text, and
the raw session path. There is no separate `TOOL-ERRORS.md`; the complete
payload remains in `session.jsonl`.

Phase reports add the mode, admission commit, session paths, normalized worker
rows, evaluator manifest evidence, employee narrative states, open-ticket
snapshot, handbook lineage, and phase cost totals. Organization reports add
the child phase results and aggregate cost/error rows. Lifecycle facts are in
the sibling `events.jsonl`; they are not copied into a second report format.

Numbers that Pi does not report are `null` or omitted; the factory never
infers provider reasoning-token counts from thinking text. Controllers validate
the envelope and required fields with `report_schema.xsh` and native XSH tests
before a report can advance a cycle.

## Ownership

Controllers write structured facts. Employees write one narrative
`REPORT.md` in their worker directory using the role's required headings.
Generated indexes such as current evidence, open-ticket lists, cost tables,
provenance, dispatch ledgers, and audits are intentionally gone. Their useful
facts are fields or views of `report.json`, not independent sources of truth.
