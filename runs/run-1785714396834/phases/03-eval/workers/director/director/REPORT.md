# Director report: eval cycle task-envcfg

## Result

pass. The controller ran one independent `task-envcfg` trial against XSH main
commit `de9880ce9cd13c4ef63acc212554d786358ed869`. The trial passed all gated
checks (correctness 10/10 byte-exact against the BusyBox `sh` oracle including
both failure controls, restrictions, protocol), the eval-worker finished with a
normal stop inside budget, and the eval-manager passed and produced a complete
narrative with a staged provisional handbook candidate and zero new tickets
(re-confirming existing open ticket `task-envcfg-001`). The phase
`report.json` shows `result: fail` only because the director narrative was
still missing when it was generated; this report completes the only absent
required output, so the cycle closes as pass with all controller-required
outputs present and valid. No child needed to be launched; every row was
already complete evidence or a `not-requested` record.

## Cycle

Mode: `eval` (controller-owned, no launch-and-wait responsibilities).
Selected eval: `task-envcfg`, 1 trial, on the XSH main commit
`de9880ce9cd13c4ef63acc212554d786358ed869`.
Controller plan: run the independent task-envcfg eval against the main commit;
0 new eval proposals; 0 approved tickets; new proposals and newly created
tickets wait for the next human-approved transition.

Executed evidence (all present, no contradictions with the dispatch rows):
- Trial 1 (`eval-worker/task-envcfg-1`): pass — 10/10 exact, protocol pass,
  restrictions pass, agent/budget/classification pass, image
  `sha256:4a25c105…`.
- Manager (`eval-manager/task-envcfg`): pass with narrative present; classifies
  the run, stages `lineage/handbook-candidate.md` (display-string /
  interpolation-boundary lesson), creates 0 tickets, and re-confirms open
  ticket `task-envcfg-001` (missing user-visible `Error` constructor /
  controlled failure primitive) at this new commit.
- Designer (`eval-designer/proposal-1`): `not-requested` record only (0 new
  proposals); not a child and not a required output.

## Children

One row per dispatched/recorded child (eval mode: all rows are already
complete evidence; no worker was launched by the director):

| Role | ID | Result | Evidence path |
|---|---|---|---|
| eval-worker | task-envcfg-1 | pass (10/10 exact, protocol/restrictions pass, in-budget, normal stop) | `workers/eval-worker/task-envcfg-1/run.json`, `workers/eval-worker/task-envcfg-1/report.json`, `workers/eval-worker/task-envcfg-1/session.jsonl.bz2`, artifact `envcfg.xsh`, `review.md` |
| eval-manager | task-envcfg | pass (narrative present, candidate staged, 0 tickets) | `workers/eval-manager/task-envcfg/REPORT.md`, `workers/eval-manager/task-envcfg/report.json`, `workers/eval-manager/task-envcfg/session.jsonl.bz2` |
| eval-designer | proposal-1 | not-requested (record only) | — (absent by design; `report.json` marks valid) |
| director | director | pass — this report | `workers/director/director/REPORT.md` |

## Required-output status

Controller-required outputs for this eval phase, checked against
`report.json` and the phase tree:

| Output | Status |
|---|---|
| Executor trial evidence `workers/eval-worker/task-envcfg-1/run.json` | present, valid (`result: pass`, `all_exact: true`) |
| Executor session `workers/eval-worker/task-envcfg-1/session.jsonl.bz2` | present |
| Executor candidate artifact `envcfg.xsh` + review + candidate/oracle streams | present (10 candidate + 10 oracle stdout/stderr, `review.md`) |
| Manager narrative `workers/eval-manager/task-envcfg/REPORT.md` | present, valid (pass) |
| Manager session `workers/eval-manager/task-envcfg/session.jsonl.bz2` | present |
| Phase lineage `lineage/handbook-approved.md`, `lineage/handbook-candidate.md` | present; candidate = approved + concise display-string/path-interpolation addition (diff verified) |
| Director narrative `workers/director/director/REPORT.md` | present (this report), valid |
| Designer `proposal-1` report | not required (row is `not-requested`, 0 proposals) |

No required output is missing or invalid after this report. The earlier
`findings[].director-report missing` finding is resolved by this write.

## North-star impact

The cycle produced durable product signal rather than activity noise. The
eval's capability hypothesis held: with the current handbook, an agent can
discover the `env` module (`env.get_or`), the explicit `?` propagation, and
`fs.write`, and solve a real config-validation boundary correctly (10/10,
byte-exact, deterministic). Learnability/ergonomics signal: the manager staged
a provisional handbook candidate that names the interpolation boundary (only
display strings `f"..."` interpolate; ordinary string and path literals do not;
dynamic paths via `Path.parse_bytes(bytes.from_text(s))`), which should remove
three repeated discoveries (`++` concatenation guess, f-string discovery, the
`p"${expr}"` literal-filename trap) in the next exact-output eval. Product
defect signal: the missing user-visible error-construction / controlled-fail
primitive was reproduced at a second commit (`de9880ce`, previously
`defa805a`) with a different misleading workaround (a fake
`regex.compile("[")?` failure whose stderr traceback hides the real
validation intent) — concrete, generalizable evidence strengthening open
ticket `task-envcfg-001`; the manager correctly did not duplicate the ticket.

Uncertainty: the handbook candidate is provisional by design and not yet
promoted; the north-star replay discipline requires it to survive a re-run of
`task-envcfg` and at least one other exact-output eval (`task-tags` or
`task-ecount`) on the next cycle before it can be trusted as general guidance.
The error-constructor gap's fix depends on the user's merge decision for the
ticket; until then the only controlled-failure mechanism remains a fake host
failure. Worker cost ($0.06, 91 turns) was near-minimal except for the
~25-turn avoidable error-construction exploration, which is precisely the
friction the open ticket targets at the product level.
