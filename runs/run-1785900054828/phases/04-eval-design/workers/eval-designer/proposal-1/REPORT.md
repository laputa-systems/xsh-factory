# Eval-designer report

## Result

ready-for-review

## Proposal

One new eval package `task-treecmp` was designed under
`runs/run-1785900054828/phases/04-eval-design/proposals/proposal-1/`:

- `EVAL.md` — contract, oracle, public/hidden cases, agent boundary, metrics,
  manager policy, `## Difficulty justification`, and `Draft.` status;
- `runtime/task.md` — agent-facing task instructions;
- `runtime/artifact.md` — artifact name `treecmp.xsh`;
- `executor.xsh` — thin `task-treecmp` selector into the shared
  `eval-executor.xsh`;
- `evaluator.xsh` — package-owned evaluator (fixture, oracle, correctness,
  restriction, protocol, run.json);
- `evaluate.xsh` — unchanged generic package selector.

The task reconciles a live filesystem tree against a declared size manifest
and emits a deterministic `missing` / `changed` / `extra` deviation report. The
ID is a new valid `task-*` id, the source eval title/ID were replaced, and the
package status is `Draft.`.

## Dry run

Exercised (smallest available reference checks only, per the designer
boundary):

- `xsht check evaluator.xsh` and `xsht check executor.xsh` both pass;
- exactly two `xsht api` queries (`api:fs.files`, `api:fs.walk`) confirmed the
  filesystem entry contract has no relative-path field, so the agent must
  derive each file's relative path from the absolute `path` — this is called
  out in `task.md`;
- the oracle shell logic was validated standalone against representative
  fixtures (public, combined, all-ok, empty-tree, empty-manifest, spaces,
  UTF-8, malformed-manifest, missing-manifest); this surfaced and fixed the
  `FNR==NR` empty-first-file pitfall, replacing the reconciliation `awk` with a
  `getline`-based `BEGIN` read that is robust to an empty manifest.

Not exercised / remains unproven, and therefore not claimed as dry-run
evidence: no candidate `treecmp.xsh` was written or compared against the oracle
(the designer does not build a candidate implementation or a custom oracle
runner), and the container-isolated worker/evaluator mount (the shared
`/usr/local/lib/xsh-factory` path) was not run end-to-end in a container this
cycle; it is inherited unchanged from the approved scaffold and is a
container-only surface.

## North-star impact

Hypothesis: an agent with the XSH handbook should be able to perform a
declared-state-vs-observed reconciliation — parsing a size manifest into a
keyed lookup with strict validation, walking a tree with the typed `fs`
stream, deriving relative paths and byte sizes, and folding the two keyed sets
into a three-way deviation classification with a byte-exact sorted report —
entirely in typed XSH values with a loud `?`-propagated failure control. This
is the canonical immutable-deployment / inventory drift check, a first-class
systems-glue shape that combines **two independent transforms** (manifest →
keyed lookup; filesystem traversal → relative path + size) plus **stateful
merge/classification** (join two keyed sets into missing/changed/extra). It
matters because drift detection is a recurring admin chore whose shell
incarnation (`find | sort | join | size-compare`) is exactly the sludge XSH is
meant to replace with explicit, composable glue. A successful run would teach
whether dual-source reconciliation, relative-path derivation, and
validation-propagated failure are discoverable and composable in XSH.

## Known risks

- **Relative-path derivation is novel.** There is no relative-path field on
  `fs.files`/`fs.walk` entries; the agent must strip the absolute root prefix.
  If XSH lacks a convenient relative-path helper, this could be a friction
  point that turns a reconciliation task into a path-string exercise; the
  manager should watch for that and fold generalizable guidance into the
  handbook rather than a task-specific ticket.
- **Output ordering across encodings.** The report is sorted by full line; the
  candidate (XSH sort-by) and oracle (`sort`) must agree on byte order. Hidden
  cases were designed so paths within a category sort by distinct ASCII-leading
  segments, and the UTF-8 case has a single deviation, limiting ordering
  ambiguity — but a mismatch in XSH's string sort semantics would surface only
  in the container and is the main residual oracle risk.
- **Empty-manifest/empty-tree edge cases.** These are covered and the oracle
  was verified; they are the likeliest place a hand-rolled candidate diverges
  (misrouting the first live record into the manifest map).
- **Failure controls** (missing manifest, malformed manifest) require the
  candidate to exit nonzero with empty stdout; a silently-defaulting or
  partial-report solution fails those gates, which is intended.
- **Missing checks.** No candidate comparison or container end-to-end run was
  performed in this phase (designer does not build a candidate). The CTO should
  replay the package end-to-end in the container and, if passed, set
  `Approved.`; the correctness gate is otherwise unproven until then.

## Review path

Promotion target: `evals/task-treecmp/` (not yet created; the CTO promotes the
package). Evidence for the CTO decision: the contract, difficulty
justification, oracle, agent boundary, metrics, manager policy, and scaffolding
are complete under `proposals/proposal-1/`; `evaluator.xsh` and `executor.xsh`
pass `xsht check`; the oracle logic was verified against representative
fixtures (including the empty-manifest pitfall). The CTO must run the
containerized worker+evaluator end-to-end to confirm candidate-vs-oracle
correctness and then set the package `Approved.` before it is admitted to paid
work; until then the package remains `Draft.`.
