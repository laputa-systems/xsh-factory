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

The compressed `session.jsonl.bz2` beside a worker report is raw evidence and
remains canonical for session details. The runtime transparently reads it when
needed. The top-level `CTO-REPORT.md` is a generated
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
boundary. Eval-worker reports include `identity.eval_id` and, when available,
`identity.run_id` so historical effort can be grouped without path inference.
`findings` are structured observations or failures. `artifacts`
contains typed paths and optional hashes.

Worker reports add `session`, `usage`, `timing`, `models`, `stop_reasons`,
`tools`, `provider_telemetry`, and `tool_errors`. `provider_telemetry` records
whether Pi's structured event stream was captured, automatic retry count and
delays, retry error messages, and event-derived turn counts. Client-observed
throughput is diagnostic and must not be presented as provider-side tok/s unless
the provider reports generation timing. A failed Pi tool invocation is represented directly
as an entry in `tool_errors`, with its turn, tool name, short result text, and
the raw session path. There is no separate `TOOL-ERRORS.md`; the complete
payload remains in compressed `session.jsonl.bz2`.

Phase reports add the mode, admission commit, session paths, normalized worker
rows, evaluator manifest evidence, employee narrative states, open-ticket
snapshot, handbook lineage, and phase cost totals. Organization reports add
the child phase results and aggregate cost/error rows. Lifecycle facts are in
the sibling `events.jsonl`; they are not copied into a second report format.

Numbers that Pi does not report are `null` or omitted; the factory never
infers provider reasoning-token counts from thinking text. Controllers validate
the envelope and required fields with `factory/schema.xsh` and native XSH tests
before a report can advance a cycle.

## Ownership

Controllers write structured facts. Employees write one narrative
`REPORT.md` in their worker directory using the role's required headings.
Generated indexes such as current evidence, open-ticket lists, cost tables,
provenance, dispatch ledgers, and audits are intentionally gone. Their useful
facts are fields or views of `report.json`, not independent sources of truth.
