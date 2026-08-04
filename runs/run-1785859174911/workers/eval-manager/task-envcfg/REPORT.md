# Eval-manager report

Eval: `task-envcfg` · Run: `run-1785859174911` · Trial count: 1 · XSH commit under test: `434080dfe330cc3bb705bd8068d57a1015b7b218` (reported as `HEAD~1`)

## Result

pass

## Effort metrics

One fresh trial (`task-envcfg-1`), exec-enabled by the controller against the approved handbook snapshot
(`lineage/handbook-approved.md`, sha256 `97c5d8...a40e83`).

- Assistants turns: `29`
- Tool calls: `36` (tool results: `36`)
- Tool errors: `0`
- Stop reasons: `28` `toolUse`, `1` `stop`
- Tools used: `bash` 29, `edit` 2, `read` 3, `write` 2
- Session span: `session_span_ms` 359279 (~359 s); `agent_wall_ms` 360810
- Worker friction: minimal. One extra `edit` to rename `path` → `out_path` after the
  `standard-module-shadow` check; some `xsht api` query-form rediscovery that the handbook already
  documents; brief experimentation with `env.int` for validation.
- Classification: `pass`; agent/evaluator/protocol/restrictions/budget/reporting all `pass`.

## Usage and cost

Worker `task-envcfg-1` (model `openrouter/deepseek/deepseek-v4-flash-0731`):

- Buckets: input `56854`, output `8702`, cacheRead `276480`, cacheWrite `0`
- Provider total: `342036`; cache-bucket tokens `342036`
- Reasoning tokens: `4454` (subset of output; not added to totals)
- Cost USD: total `0.01165986`; input `0.00511686`, output `0.00156636`,
  cacheRead `0.00497664`, cacheWrite `0`
- Budget: `0.50` budget, `0` budget failures
- Aggregated across the single worker/trial: `$0.01166`.

## Thinking evidence

`thinking_blocks: 18`, `reasoning_tokens: 4454` reported by the provider. The session thinking trace
(`session.jsonl.bz2`) shows reasoning grounded in the oracle contract: `env.get_or` fallback applies
only on absence and keeps a present-but-empty value (matching `${VAR-default}`), Result handling and
`?` propagation for deliberate validation, and `Path` construction from a runtime string
(`Path.parse_bytes(bytes.from_text(...))`). The worker explicitly reasoned that `env.int("CFG_PORT")?`
should be the validation path and confirmed empty/non-decimal port yields a nonzero exit with no file.
Provider reasoning-token counts were reported, so quantitative reasoning-token evidence is available.

## Tool-error findings

None.

The current packet has zero structured tool errors: phase `report.json` `data.tool_errors = []`,
worker `report.json` `tool_errors = 0`, manager `tool_errors = 0`, and no failed (`isError`) tool
results in the manager or worker sessions. All `bash`/`edit`/`read`/`write` results succeeded.

## Timing evidence

No strict candidate/oracle ratio gate applies; `EVAL.md` states timing is diagnostic until a stable
envelope is established. Recorded wall times (ns) from `run.json`, candidate vs oracle:
public 11.78 / 12.21; hidden_defaults 14.14 / 13.84; hidden_partial 14.01 / 11.14;
hidden_empty 13.29 / 11.29; hidden_spaces 12.64 / 13.60; hidden_zero 11.23 / 12.25;
hidden_utf8 13.27 / 12.73; hidden_debug_false 13.63 / 13.74; hidden_malformed 13.24 / 11.97;
hidden_empty_port 11.10 / 13.15. Both sides are millisecond-scale and comparable with no systematic
advantage; the two failure controls (candidate exit nonzero, no output file) satisfied the gate.

## Observation classification

- **module-shadow (`standard-module-shadow`)** — reusable handbook guidance. `xsht check` rejected
  `let path = ...` with `err[check.standard-module-shadow]: name \`path\` shadows the standard module
  \`path\``; the worker renamed to `out_path` and re-checked. The message is reasonably explicit, so this
  is friction the handbook can pre-empt rather than a product defect. Generalizes beyond this task to any
  binding that collides with a standard module name.
- **`xsht api` query-form rediscovery** (dot vs colon `KIND:VALUE`, trailing-dot receiver rejection) —
  ordinary noise. The handbook already teaches the exact `KIND:VALUE` colon form and the bare/trailing-dot
  rejection; the worker re-derived it without lasting cost.
- **`env.int` exit code 3 vs oracle exit 1** — ordinary signal already in flight. The contract only
  requires nonzero, both sides exit nonzero, and every case matched byte-for-byte. It belongs to the
  deliberate-error thread already tracked by `task-envcfg-001` / `task-envcfg-002`; not a new defect.
- **Empty `candidate_sha256`** — harness expectation, not a defect. The deliverable is a file (stdout is
  intentionally empty), so the recorded candidate hash is the empty input; correctness was verified
  byte-for-byte on the written file across all ten cases.

## Handbook decision

Provisional candidate staged at `lineage/handbook-candidate.md` (copy of the approved snapshot plus one
short rule). Lesson: do not name a binding after a standard module (e.g. `path`); `xsht check` fails with
`standard-module-shadow`; use a distinct name such as `out_path`. This removes repeated guesswork for any
eval that binds a value near a module name. Replay scope: re-run `task-envcfg` (and, where the rule is
intended to generalize, the other typed-binding evals `task-tags`, `task-ecount`) against the promoted
candidate before trusting it. Promotion requires later review and CTO approval; not claimed as validated
by this single trial.

## Tickets created

Zero. The module-shadow friction is covered by the handbook candidate; its diagnostic is already
self-explanatory, and the deliberate-error observation is already tracked by open ticket
`task-envcfg-001`. No new product or tooling ticket is warranted by the evidence.

## Post-merge decisions

None. The reconciler for this run found no merged-ticket files, and the candidate re-evaluation field is
`not-reevaluation`; there are no post-merge acceptance assignments in this cycle.

## Next replay

Re-run `task-envcfg` (approved eval, `evals/task-envcfg/EVAL.md`) against the promoted handbook lineage
(`lineage/handbook-candidate.md`) after CTO review. The falsification check: the agent completes the
config-render task without a `standard-module-shadow` round-trip and still passes all ten evaluator cases.
Also continue the in-flight deliberate-error thread (`task-envcfg-001`).

## North-star impact

The eval passes and validates the north-star hypothesis: the `env` module (`env.get_or`) with
absence-only fallback, `?`-propagated `env.int` validation, and `fs.write` compose cleanly into a
byte-exact config-render workflow with a loud nonzero failure and clean stdout. The staged handbook
candidate improves learnability/ergonomics by removing a confusing binding-shadowing check failure, and
the clean low-effort pass (0 tool errors, ~$0.012) supports efficient agent use. The observation-and-
replay loop connects a practical systems-glue capability to durable, replayable handbook guidance.
