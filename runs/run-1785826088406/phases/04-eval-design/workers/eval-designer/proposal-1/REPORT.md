# Eval-designer report

## Result

ready-for-review

## Proposal

New eval **task-groupsum** (per-key numeric aggregation / grouped sum), staged
as a `Draft.` proposal under:

`runs/run-1785826088406/phases/04-eval-design/proposals/proposal-1/`

- `EVAL.md` — full contract (status `Draft.`, id `task-groupsum`, purpose,
  north-star hypothesis, task, agent boundary, oracle/evaluator, metrics,
  manager policy). No remaining `task-tags` identifier; the retired seed name
  is fully replaced.
- `runtime/task.md` — the user-facing task prompt (accept one file path,
  print sorted `KEY SUM` rows, fail closed on malformed lines/unreadable file).
- `runtime/artifact.md` — `groupsum.xsh`.
- `executor.xsh` — thin selector calling the shared `eval-executor.xsh` for
  `task-groupsum`.
- `evaluate.xsh` — generic selector unchanged (shared evaluator protocol).
- `evaluator.xsh` — package-owned self-contained evaluator: writes hidden
  fixtures, runs `xsh /work/groupsum.xsh <file>` per case, compares byte-for-byte
  against an independent `printf` / `sh -c 'exit 1'` oracle, enforces the
  `read_text` and no-subprocess restrictions, validates `review.md` headings,
  and writes `run.json`. Uses `GROUPSUM_WORK/SESSION/EXPORT` overrides so it can
  be validated on a host without root `/work`.
- `dry-run/` — preserved evidence (see below).

The scaffold was created by renaming the `task-tags` reference, setting
`Draft.`, then making only task-specific edits to the task/artifact/executor/
evaluator files. No custom runner, helper language, or controller was added.

## Dry run

The staged evaluator was run on the local build (two `xsht api` queries used:
`search:parse_int`, `search:split`; the rest by source inspection and
`xsht check`/`xsh`).

- **Reference candidate** (`dry-run/pass/groupsum-ref.xsh`) passes `xsht check`
  and `xsht lint`. Run over all nine cases the evaluator exited 0 with
  `result: pass`, `classification: pass`, `all_exact: true`, and every case
  `exact: true`: public (`alpha 1/beta 2/gamma 3`), hidden_accumulate
  (`server 10+5`, `db 3+1` -> `db 4`, `server 15`), hidden_order (byte-order
  trap: `10` sorts before `2`), hidden_many, hidden_blank (blank lines
  ignored), hidden_empty (empty stdout, exit 0), and the three failure controls
  (bad_fields, bad_value, missing) all exit nonzero with empty stdout. The
  `run.json` (`dry-run/pass/run.json`) records per-case exactness and
  candidate/oracle timing; `review.md` headings and `read_text` + no-subprocess
  restrictions passed; `groupsum.xsh` and `review.md` were exported.
- **Wrong candidate** (`dry-run/fail/wrong-candidate.xsh`, negated sum with the
  same valid structure) was rejected: evaluator exit 1, `result: fail`,
  `classification: candidate_failed`, `all_exact: false`
  (`dry-run/fail/run.json`). This proves the evaluator fails closed on
  incorrect output while still passing restriction/protocol.

Remaining unproven: a live container trial of the exact `/work`, `/session`,
`/export` mounts and a real agent session. The correctness, oracle, isolation,
protocol, and fail-closed paths are proven on the local build.

## North-star impact

Capability hypothesis: an agent that has internalized the XSH handbook should
resolve a classic sysadmin aggregation — "sum the second field per first field,
print sorted `KEY SUM` rows" — with a short typed program that reads through fs
text APIs, splits a line into fields, validates an integer with `parse_int`,
accumulates into an immutable-update `Map` (`sums = sums.set(k, sums.get(k,0)+v)`),
sorts keys, and formats rows. This is practical systems glue (bytes per user,
totals per endpoint, usage per account) and exercises a capability no approved
eval covers: building an arbitrary-key Map of accumulated numbers and emitting a
sorted keyed summary (existing evals only count a fixed field, single-record
lookup, or sort plain lines). A pass is evidence about learnability and
ergonomics of the Map + integer-parse + keyed-sort trio; a miss isolates which
of those idioms is still unclear for handbook guidance. The design resists
task-specific hacks: every hidden fixture has different keys, accumulation
shape, and byte-order traps, and malformed/unreadable input must fail with a
clean nonzero exit and no stdout, so a hard-coded summary or a
throwing-in-the-towel candidate cannot pass.

## Known risks

- **Hard-coding:** a candidate could in principle special-case the public
  fixture. This is resisted by the hidden fixtures (accumulation, byte-order,
  many rows, blank, empty) whose outputs the author cannot know in advance.
- **Oracle independence:** success expected rows are authored literals passed
  to `printf` (the approved task-iniget pattern), validated across all cases by
  the reference candidate; the missing/bad-value failure controls use an
  external `sh -c 'exit 1'` double so the nonzero/empty-stdout semantics are
  oracle-anchored.
- **Timing:** candidate/oracle wall ns is recorded but is diagnostic only; no
  strict envelope. On the local build both sides are in the same order of
  magnitude.
- **Traceback on stderr:** `?` propagation and `abort(1)` emit a runtime
  traceback to stderr on failure cases. This is acceptable (contract forbids
  stdout diagnostics only) and matches approved evals; stdout remains empty.
- **Missing checks:** a live `/work`/`/session` container mount and a real agent
  session were not exercised in this design dry run and remain unproven until
  the promoted eval's first paid trial.

## Review path

Package (Draft.) is staged for CTO promotion into `evals/task-groupsum/` with
`EVAL.md`, `executor.xsh`, `evaluator.xsh`, `evaluate.xsh`, and
`runtime/{task.md,artifact.md}`. Evidence for the approval decision:
- `EVAL.md` and `runtime/task.md` define a well-posed, ecount-grade systems
  task distinct from the existing eval portfolio;
- `dry-run/pass/run.json` — every case byte-exact, restrictions + review
  protocol pass (result `pass`);
- `dry-run/pass/groupsum-ref.xsh` — `xsht check`/`lint` clean reference;
- `dry-run/fail/run.json` — wrong-sum candidate rejected as `candidate_failed`
  with a nonzero evaluator exit (fail-closed proven);
- `REPORT.md` (this file) — narrative, north-star impact, and risks.

The CTO review gate decides whether the promoted package becomes `Approved.`
or remains `Draft.`.
