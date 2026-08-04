# Eval-manager report

## Result

pass

## Effort metrics

Trial 1 (eval-worker/task-envcfg-1), single fresh trial.
- Assistant turns: 35
- Tool calls: 46; tool results: 46
- Tool errors: 0 (structured `tool_errors` empty in worker `report.json` and phase `report.json`)
- Thinking blocks: 31
- Session span: 196,177 ms (~196 s); agent wall: 198,350 ms
- Model: openrouter `deepseek/deepseek-v4-flash-0731`; thinking level: high
- Stop reasons: 1 `stop`, 34 `toolUse`
- Artifact: `envcfg.xsh` present (`sha256 f65e44e6…`); `review.md` present and passes the two required headings
- Worker agent/executor/budget/reporting/evaluator states all `pass`; classification `pass`

The eval passed 10/10 byte-exact (`correctness.all_exact: true`) including both failure controls (`hidden_malformed`, `hidden_empty_port`), with `restrictions.passed: true` (`env.` referenced, no subprocess boundary) and `protocol.passed: true`.

## Usage and cost

Single worker session (Trial 1):
- input: 56,833 tokens; output: 15,609 tokens; cacheRead: 614,976; cacheWrite: 0
- reasoning (provider-reported, subset of output): 9,966 tokens
- provider total: 687,418; bucket total: 687,418 (matches; no mismatch)
- cost: input $0.005115, output $0.002810, cacheRead $0.011070, cacheWrite $0, cacheWrite cost $0; total $0.018994 (≈ $0.019)
- budget: $0.50; budget_state `pass` (unused ≈ $0.48)
- Aggregate across the one trial: $0.018994.

## Thinking evidence

31 thinking blocks across 35 assistant turns. The provider reports reasoning-token counts (`reasoning: 9966`), so reasoning tokens are available and are a subset of `output`. The transcript shows the worker reasoned methodically: it first traced the oracle's `${VAR-default}` (absence-only default) semantics, confirmed `env.int`/`parse_int` accept sign/space forms and are not strict decimal validators by direct probes (turns quoting `+5`, `-5`, `5`, `abc`, `12a`), then settled on `port.count_chars() == 0 or port.delete("0123456789").count_chars() != 0` plus a forced `parse_int()?` for the failure control. Thinking correlated correctly with the final passing artifact and the evaluator's 10/10 result.

## Tool-error findings

None. The worker and phase `report.json` structured `tool_errors` arrays are both empty (0), and the session JSONL contains zero `invalid API query` rejection messages.

## Timing evidence

No strict candidate/oracle ratio gate in this eval (both sides finish in milliseconds; timing is diagnostic). Per-case wall times (candidate / oracle, ns): public 12,243,870 / 11,778,497; hidden_defaults 22,026,416 / 11,188,082; hidden_partial 12,419,953 / 11,601,165; hidden_empty 41,806,841 / 14,827,735; hidden_spaces 15,179,609 / 13,986,947; hidden_zero 14,636,861 / 14,273,154; hidden_utf8 13,303,075 / 14,527,653; hidden_debug_false 12,630,035 / 14,132,904; hidden_malformed 12,076,454 / 12,159,453; hidden_empty_port 12,863,867 / 13,671,865. All cases finish within ~40 ms; the two inflated candidate figures (hidden_empty, hidden_defaults) are process-launch noise on a short program and are not gated.

## Observation classification

- **Reusable product signal (pre-merge, supports ticket task-envcfg-004):** The candidate XSH commit `6ad50260` implements "xsht api: accept bare `method:NAME` to list a receiver's members". In-session proof: `xsht api method:Result` returned `status: exact` with `api: method.Result.context` (a member list) instead of the previously-rejected `expected NAME.MEMBER`, and the session contains zero `invalid API query` messages. Exact lookups (`method:Str.delete`, `method:Str.parse_int`), `search:` (`search:error`, `search:Err`, `search:Ok`, `search:is_err`, `search:unwrap`), `module:` and `summary | grep` all still resolve. This is a genuine ergonomics improvement matching the ticket's acceptance intent.
- **Handbook gap (future, not current defect):** Despite the fix being present in the candidate container, the worker still enumerated `Str` members with `xsht api summary | grep` (turns using `grep -A60 "Str ("`, `grep -iE "Str|String"`) rather than the new `method:NAME` index query. The approved handbook still teaches summary|grep and the now-stale sentence "a bare receiver query such as method:Str or method:Str. is rejected". This gap is resolved only after the fix merges and the handbook is updated to point at `method:NAME`; it did not block the eval.
- **Ordinary short-task friction (not a ticket):** The worker wrote `||` and hit `parse.unsupported-boolean-operator`; `xsht`'s error message pointed at the word form `or`, and the worker fixed it in one edit. Single occurrence, constructive error — left as minor friction, not a handbook change this cycle.
- **Ordinary noise:** The worker's own in-session compare harness reported `MISMATCH` lines; these were bugs in its temporary shell oracle harness (env not exported into the oracle subshell, `exit 1` vs `exit 3`), not failures of the submitted program. The authoritative evaluator `run.json` shows all 10 cases exact. Several `status: missing` api probes (`api:pure.exit`, `api:proc.exit`, `api:script.exit`, `module:pure`, `language:core.result`) were discovery attempts that the worker resolved before submission; not a product defect (exit/panic is intentionally not a generic surface, and the handbook's `parse_int()?` failure path is within contract). The traceback exit code 3 is non-controllable but the eval contract requires only a nonzero exit and no file, so this is within contract and not a defect.

## Handbook decision

Unchanged. Copied the approved snapshot to `lineage/handbook-candidate.md` unchanged (both `sha256 97c5d804c42c7742c9edfea4480163828d864279391d391df77aa60ee4a40e83`, matching the run input `handbook_sha256`). No provisional handbook change is staged this cycle: this is a pre-merge validation of an engineering fix, the fix is not yet in main, and the only recurring friction (`||` vs `or`) is a single occurrence with a constructive error message. After ticket task-envcfg-004 merges, the handbook's development-loop section should replace the "bare receiver query is rejected" sentence with a pointer to `method:NAME` member listings; that update belongs to a post-merge replay, not this pre-merge run.

## Tickets created

None. The candidate fix was validated as functional; no new reproducible product/tooling defect was observed. The minor `||`/`or` friction does not meet the ticket bar (single occurrence, self-corrected).

## Post-merge decisions

None. The reconciler found no merged ticket files (`none`). The candidate ticket task-envcfg-004 is **not merged** (its implementation commit `6ad50260` is a worktree commit, not an ancestor of main HEAD `5546558`), so this is a pre-merge candidate validation, not a post-merge acceptance assignment.

Candidate-validation decision (task-envcfg-004 / commit `6ad50260`): **support the proposed fix.** The executor evidence confirms the fix is present and functional (bare `method:NAME` lists a receiver's members; exact lookups, `search:`, and `summary` regress cleanly; eval passes 10/10 byte-exact with restrictions and protocol intact). The ticket's "worker resolves Str members from one index query" acceptance nuance is only partially met in this replay because the worker still used `summary | grep` — a consequence of the approved handbook still teaching that path, not of a broken fix. Rejecting only on that basis would be unsound; the correct action is a post-merge replay with a one-line handbook pointer to `method:NAME`.

## Next replay

Post-merge replay of `evals/task-envcfg` on the merged commit whose ancestry includes `6ad50260`, using the same approved handbook lineage now updated to teach `xsht api method:NAME` for member listings. Verify: (1) the worker enumerates a receiver's members with one `method:NAME` index query (no `summary | grep` fallback), (2) exact lookups / `search:` / `summary` remain regression-free, and (3) all 10 oracle cases still pass byte-for-byte. That replay is the falsification gate for the per-type index query and the handbook pointer.

## North-star impact

Advances XSH ergonomics and learnability: the validated `method:NAME` per-type index query turns a ~10-turn `summary | grep` type-surface browse into a one-shot live-reference query, removing repeated discoveries for every future eval that touches a receiver type (Str, Path, Regex, Result). This is exactly the "live reference as source of truth, fewer repeated discoveries" goal in the north star. The eval itself also continues to confirm the env→config surface (absence-only defaults, typed env reads, `?`-propagated validation failure with no partial file) is discoverable and composable from the handbook. This run is a pre-merge engineering validation and produced no new product ticket; the product signal (a working per-type index query) is being staged for post-merge acceptance.
