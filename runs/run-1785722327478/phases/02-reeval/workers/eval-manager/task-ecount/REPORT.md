# Eval-manager report: task-ecount — candidate re-evaluation (phase 02-reeval)

Run: `runs/run-1785722327478` · Phase: `02-reeval` · Eval: `task-ecount`
Candidate ticket: `task-ecount-003` (pre-merge validation) · XSH candidate commit: `c2e1039d8856c04ad8466504d445dc93a341f720` (worktree `phases/01-ticket/worktrees/task-ecount-003`, clean, HEAD == candidate)
Handbook under review: `lineage/handbook-approved.md` (sha256 `c7c9dd9abb6d50dac60562757a1824900f24d4bc2d38014d5cbf869f56bb0723`)
Base/main commit recorded in phase report: `ea7dea2f2b436cce34262d7a02105cbb029243dd`; the trial itself ran the candidate image (worker `run.json` `xsh_commit` `c2e1039d…`).

## Result

pass.

Trial 1 (`workers/eval-worker/task-ecount-1/run.json`) passed on the candidate commit: `correctness.exact_output` true, `oracle_ok` true, candidate and oracle stdout byte-identical (both sha256 `c7c356092b7731520891c6ec695ba9de9f5faa40967a7f9689a1f6d199a2fbb1`), `restrictions.passed` true, `protocol` pass (artifact present, `review_ok` true), `timing` pass (ratio 0.9965 within the 0.90..1.10 gate). The executor evidence supports the proposed task-ecount-003 fix:

- The candidate patch (`phases/01-ticket/patches/task-ecount-003.diff`) implements compound record sort keys (lexicographic, field-name order), loud runtime rejection of non-orderable keys (`stream-sort-key` diagnostic naming the stage and key type), stable `sort`/`sort-by`, checker acceptance of record keys/items, and contract documentation in `crates/xsh-registry/src/reference.rs`, `docs/SPEC.md`, `docs/STREAMS.md`; it adds sema and native stream tests for compound keys, stability, `--desc`, and the loud failure.
- The new contract is live in the gym image: the worker's `xsht api language:stream.sort-by` query (session line 11) returned the exact new text documenting supported key types, ascending/`--desc` semantics, stability, and the two-pass idiom — satisfying acceptance criterion 1 in the actual run.
- The worker adopted the documented two-pass stable-sort idiom (`sort-by .ext |> sort-by .count`) directly and never attempted a record-key projection or stability trial-and-error, so the baseline discovery loop described in the ticket did not recur.
- The standard `/usr/share` tree has no count ties, so this trial does not end-to-end exercise tie ordering or the compound-key path; the native tests in the patch cover those. Acceptance criterion 5's synthetic tie-containing replay remains a next-step check.

Decision: the candidate is ACCEPTED for pre-merge validation. Do not mark the ticket merged and do not dispatch engineer; `task-ecount-003` stays `Approved.` and merge is the user's decision. The branch is not main.

## Effort metrics

Trial 1 (only trial configured; `## Trial plan` count `1`):

- Assistant turns: 122 (1 user message; stop reasons: 1 `stop`, 121 `toolUse`)
- Tool calls: 139 (bash 104, write 29, edit 4, read 2); tool results 139
- Tool errors: 1 (see `## Tool-error findings`)
- Session span: 614,630 ms (~10.2 min); agent wall 616,224 ms; budget state pass
- Worker friction: one failed `python3` probe (recovered next turn); discovery loops on fold/reduce signature, group-by record shape, Str→Path conversion, count padding (`tui.left_pad`), and the `print` parse restriction, all documented by the worker in `review.md`. The sort-by stability loop from the ticket baseline did not recur.

## Usage and cost

Trial 1 (provider: openrouter, model `deepseek/deepseek-v4-flash-0731`):

- input 197,977 tokens ($0.01781793); output 46,781 ($0.00842058); cacheRead 6,205,312 ($0.111695616); cacheWrite 0 ($0)
- Provider total 6,450,070 = bucket total 6,450,070 (no mismatch); malformed lines 0
- Reasoning tokens 31,405 (provider-reported subset of output; not added to totals)
- Cost total $0.137934126; budget $0.50; budget failures 0
- Aggregate phase cost equals the single trial: $0.1379, 122 assistant turns, 1 tool error, unknown costs 0.

## Thinking evidence

Thinking-block count: 87 (worker `report.json`); provider-reported reasoning tokens 31,405. There is no separate `thinking.md` artifact in this packet; raw thinking is in `session.jsonl.bz2` (the briefing notes thinking-block count and text are qualitative evidence, not a token estimate). Grounded findings:

- After reading the new `language:stream.sort-by` contract (session line 11), the worker's first substantive draft already used the documented two-pass idiom (`sort-by .ext |> sort-by .count`); no stability or compound-key experimentation occurred anywhere in the session. This is direct evidence that the product fix removed the discovery friction the ticket described.
- The worker thought through oracle semantics (fd hidden-file behavior, symlink exclusion, dot-in-directory handling, `%6d`-style padding) and verified byte-for-byte against the oracle before finishing.
- The fold/reduce, group-by shape, `var` vs `let`, `print`-argument, and Str→Path probes were empirical trial-and-error, consistent with `review.md`; these are separate from the sort-by fix.

## Tool-error findings

Structured `tool_errors` arrays (worker report and phase report) contain exactly one nonzero Pi tool result:

- turn 25, tool `bash`, summary `(no output)\n\nCommand exited with code 127` — the agent ran `xsht api language:stream.group-by --format jsonl | python3 -c "…"`; `python3` is not present in the Alpine gym image (handbook already states no other language runtimes). The agent recovered within one turn by using plain `xsht api` output. Classified as ordinary worker friction.

Invalid `xsht api` discovery queries: two `search:` probes returned `status: missing` (`search:Path constructor`, `search:from string to Path`); a third (`search:parse path`) matched and surfaced `method:Path.parse_bytes`. The missing-status probes returned non-error tool results and are not in the structured arrays, but they are discovery friction: the agent needed several probes to find the Str→Path conversion (evidence for the handbook candidate below).

Manager session: zero tool errors; the manager performed no `xsht api` queries this run.

## Timing evidence

- candidate: wall 10,950,171 ns (~10.95 ms); user 1,070,000 ns; system 3,211,000 ns
- oracle: wall 10,989,088 ns (~10.99 ms); user 4,058,000 ns; system 1,762,000 ns
- ratio 0.9964586 — within the strict 0.90..1.10 gate in `EVAL.md`; `timings.passed` true.

Candidate/oracle wall time is a diagnostic here; the gate holds. Process-launch noise is comparable for both commands, and the agent session clock (10.2 min) is not conflated with program timing.

## Observation classification

- Product/tooling defect — VALIDATED FIX (task-ecount-003): `sort-by` on compound record keys and loud rejection of unsupported keys, stable sort, and the documented contract are present in the candidate image and worked for the agent. This is the ticket's proposed change, not a new defect.
- Reusable handbook guidance — Str→Path conversion gap: the approved handbook teaches `p"..."` literals but not converting a Str argument to a Path; the worker needed multiple `xsht api` probes (`status: missing` searches) to find `Path.parse_bytes(bytes.from_text(...))`, which `review.md` calls awkward. General lesson: explicit Str→Path boundary for argv paths. Staged as the one provisional handbook candidate.
- Worker friction / ordinary noise: the `python3` 127 error (recovered next turn); the `print` parse restriction `err[parse.command-call-expr]` is loud, self-diagnosing, and has a documented workaround (`$.len()` or bind-to-let), so it is not a strong ticket candidate; the `var` vs `let` and fold/reduce signature gaps overlap the empty-signature reference gap already tracked in `task-ecount-001`; the Any-key check rejection and terminal-stage exit-3 crash are already tracked in `task-ecount-004` and `task-ecount-005`.
- Harness noise: `container.stderr` contains `tail: write error: Resource temporarily unavailable` from the executor's stderr capture; it did not affect the candidate, oracle, or evaluation result (pass).
- No evaluator failure: `run.json` is internally consistent; `inputs.handbook_sha256` matches the approved snapshot under review; `outputs.candidate_sha256 == outputs.oracle_sha256`.

## Handbook decision

provisional candidate staged at `lineage/handbook-candidate.md` (approved snapshot copied, one concise addition only):

When a path arrives as a Str — for example a command-line argument — convert it explicitly with `Path.parse_bytes(bytes.from_text(argv.get(0, "")))?`; the `p"..."` literal does not interpolate runtime values.

General lesson: make the Str→Path typed boundary explicit for argv-derived paths, removing a repeated discovery loop for any path-taking task. Replay scope: this candidate is global — replay `task-ecount` and any future path-argument eval on a lineage that includes the addition; promote to `runtime/handbook.md` only after review and successful replay. No other handbook change is justified: sort-by semantics now live in the `xsht api` reference that the handbook already delegates to, and the run shows that delegation working once the reference is complete.

## Tickets created

zero.

Rationale: the run's strongest new observations are either already tracked (`task-ecount-001` reference-signature gap covering fold/reduce and group-by shape; `task-ecount-004` Any-typed sort-by keys; `task-ecount-005` terminal-stage runtime crash) or are self-diagnosing with immediate workarounds (`print` parse restriction, `var` vs `let`). No single strong reproducible observation from this run warrants a new next-cycle product ticket, and this phase's purpose is candidate validation rather than new defect discovery.

## Post-merge decisions

None. The reconciler found no merged ticket files (`none`), so there are no post-merge acceptance assignments this cycle. `task-ecount-003` remains `Approved.` pending the user's merge decision; this run records a pre-merge ACCEPT (see `## Result`) and no revert proposal.

## Next replay

- Eval: `task-ecount`, same shared handbook lineage (approved `c7c9dd9a…`, plus the staged Str→Path candidate once reviewed).
- Post-merge check: after the user merges the `task-ecount-003` branch (implementation commit `c2e1039d8856c04ad8466504d445dc93a341f720`), replay `task-ecount` against the merged commit with (a) the standard `/usr/share` root and (b) a synthetic tie-containing root, and confirm byte-for-byte oracle match, the documented two-pass idiom producing count-major/name-minor ties, and no stability discovery loop.
- Falsification check: `sort-by { |r| {c: r.count, n: r.name} }` must either sort deterministically by the documented compound comparison or fail loudly with a diagnostic naming `sort-by` and the record key type; scalar-key sorts must be unchanged; unsupported key types must never silently return input order with exit 0.
- Handbook candidate check: a replay should show an agent converting an argv path with `Path.parse_bytes(bytes.from_text(...))` without the `status: missing` search loop.

## North-star impact

The run validates the sort-by fix against the north-star objectives: ordering is now explicit, typed, and stable — the silent-unsorted trap that cost baseline agents a discovery loop is replaced by either a documented deterministic compound comparison or a loud diagnostic, directly serving the "explicit boundaries, no hidden surprises, trust" ethos and reducing agent exploration (tokens/turns) without sacrificing correctness. The run also demonstrates that the handbook's delegation to `xsht api` works once the reference is complete, and the staged Str→Path handbook candidate removes a repeated typed-boundary discovery that will recur in any path-argument eval. Practicality: byte-exact oracle match on the candidate commit; learnability: the sort contract is now self-documenting in the gym; ergonomics: fewer trial-and-error probes for sorting; trust: the fix comes with native and sema regression tests and a defined replay/falsification path.
