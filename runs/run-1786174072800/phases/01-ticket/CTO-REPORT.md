# CTO briefing 01-ticket

This is the deterministic first-pass briefing for the CTO. The structured
`report.json` files and raw Pi sessions remain the source of truth.

## Result

pass
## Result

pass

## Outcome dimensions

- Product: `pass`
- Evaluator: `pass`
- Infrastructure: `pass`

## Operating context

- Mode: `ticket-implementation`
- Request: `CYCLE-REQUEST.md`
- Structured report: `report.json`

## Phase outcomes

- `report.json`: result `pass`; report `report.json`
- `workers/director/director/report.json`: result `pass`; report `workers/director/director/report.json`
- `workers/engineer/task-pathparts-003/report.json`: result `pass`; report `workers/engineer/task-pathparts-003/report.json`


## Employee accounting

### Worker metrics

- `director/director` (`director`): result `pass`; report `workers/director/director/report.json`
  - Execution: `not recorded`; classification: `not recorded`
  - Turns: `10`; bucket tokens: `190763`; thinking blocks: `9`
  - Provider telemetry: `present=true; retries=1; retry_delay_ms=2000; retry_successes=1; retry_failures=0; provider_errors=unknown; event_turns=10; observed_output_tps=0`
  - Tool errors: `0`; cost: `0.011865`; budget: `0.060000`
- `engineer/task-pathparts-003` (`engineer`): result `pass`; report `workers/engineer/task-pathparts-003/report.json`
  - Execution: `not recorded`; classification: `not recorded`
  - Turns: `88`; bucket tokens: `5884856`; thinking blocks: `34`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=88; observed_output_tps=0`
  - Tool errors: `7`; cost: `0.100047`; budget: `0.350000`


### Nonzero tool results
### Provider health and latency

Provider retry, latency, and attribution data are in worker `report.json`
`provider_telemetry` fields. Missing telemetry is `unknown`, not evidence of
normal provider health. Provider switching is out of scope and tracked in
`TODO.md`.

### Nonzero tool results

- `engineer/task-pathparts-003`, turn `17`, tool `bash`:    Compiling libc v0.2.186
   Compiling cfg-if v1.0.4
   Compiling crossbeam-utils v0.8.21
   Compiling pin-project-lite v0.2.17
   Compiling find-msvc-tools v0.1.9
   Compiling bitflags v2.13.0
   Compiling shlex v2.0.1
   Compiling rustix v1.1.4
   Compiling parking v2.2.1
   Compiling futures-core v0.3.32
   Compiling futures-io v0.3.32
   Compiling fastrand v2.4.1
   Compiling value-bag v1.13.1
   Compiling once_cell v1.21.4
   Compiling fs_extra v1.3.0
   Compiling dunce v1.0.5
   Compiling proc-macro2 v1.0.106
   Compiling quote v1.0.46
   Compiling unicode-ident v1.0.24
   Compiling log v0.4.33
   Compiling futures-lite v2.6.1
   Compiling io-lifetimes v3.0.1
   Compiling io-lifetimes v2.0.4
   Compiling io-extras v0.19.0
   Compiling atomic-waker v1.1.2
   Compiling slab v0.4.12
   Compiling aws-lc-rs v1.17.0
   Compiling concurrent-queue v2.5.0
   Compiling cap-primitives v4.0.2
   Compiling zeroize v1.9.0
   Compiling typenum v1.20.1
   Compiling jobserver v0.1.34
   Compiling errno v0.3.14
   Compiling event-listener v5.4.1
   Compiling memchr v2.8.1
   Compiling maybe-owned v0.3.4
   Compiling cc v1.2.66
   Compiling ambient-authority v0.0.2
   Compiling itoa v1.0.18
   Compiling cap-std v4.0.2
   Compiling autocfg v1.5.1
   Compiling ipnet v2.12.0
   Compiling event-listener-strategy v0.5.4
   Compiling syn v2.0.118
   Compiling rustls-pki-types v1.15.0
   Compiling foldhash v0.2.0
   Compiling async-io v2.6.0
   Compiling bytes v1.11.1
   Compiling async-task v4.7.1
   Compiling hybrid-array v0.4.12
   Compiling crc32fast v1.5.0
   Compiling hashbrown v0.17.1
   Compiling adler2 v2.0.1
   Compiling rustls v0.23.41
   Compiling cmake v0.1.58
   Compiling crypto-common v0.2.2
   Compiling block-buffer v0.12.0
   Compiling http v1.5.0
   Compiling getrandom v0.4.2
   Compiling core-foundation-sys v0.8.7
   Compiling const-oid v0.10.2
   Compiling simd-adler32 v0.3.9
   Compiling untrusted v0.9.0
   Compiling aws-lc-sys v0.41.0
   Compiling miniz_oxide v0.8.9
   Compiling async-executor v1.14.0
   Compiling async-channel v2.5.0
   Compiling aho-corasick v1.1.4
   Compiling piper v0.2.5
   Compiling digest v0.11.3
   Compiling tracing-core v0.1.36
   Compiling regex-syntax v0.8.11
   Compiling subtle v2.6.1
   Compiling zlib-rs v0.6.3
   Compiling httparse v1.10.1
   Compiling fs-set-times v0.20.3
   Compiling polling v3.11.0
   Compiling equivalent v1.0.2
   Compiling indexmap v2.14.0
   Compiling tracing v0.1.44
   Compiling blocking v1.6.2
   Compiling http-body v1.1.0
   Compiling security-framework-sys v2.17.0
   Compiling core-foundation v0.10.1
   Compiling async-lock v3.4.2
   Compiling cpufeatures v0.3.0
   Compiling regex-automata v0.4.14
   Compiling smallvec v1.15.2
   Compiling try-lock v0.2.5
   Compiling event-listener v2.5.3
   Compiling futures-sink v0.3.33
   Compiling compression-core v0.4.32
   Compiling zmij v1.0.21
   Compiling fnv v1.0.7
   Compiling thiserror v2.0.18
   Compiling option-ext v0.2.0
   Compiling async-global-executor v2.4.1
   Compiling thiserror-impl v2.0.18
   Compiling h2-futures v0.4.15 (https://github.com/joshuarli/h2-futures-lite?rev=732e8770cc6bbf998c573844f62e0afaccec3192#732e8770)
   Compiling dirs-sys v0.5.0
   Compiling pin-project-internal v1.1.13
   Compiling async-channel v1.9.0
   Compiling security-framework v3.7.0
   Compiling want v0.3.1
   Compiling libmimalloc-sys v0.1.49
   Compiling crossbeam-epoch v0.9.18
   Compiling kv-log-macro v1.0.7
   Compiling futures-channel v0.3.32
   Compiling same-file v1.0.6
   Compiling miniserde v0.1.45
   Compiling cap-fs-ext v4.0.2
   Compiling pin-utils v0.1.0
   Compiling xsh-registry v0.0.1 (/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786174072800/task-pathparts-003/crates/xsh-registry)
   Compiling async-std v1.13.2
   Compiling pin-project v1.1.13
   Compiling bstr v1.12.1
   Compiling walkdir v2.5.0
   Compiling crossbeam-deque v0.8.6
   Compiling directories v6.0.0
   Compiling globset v0.4.18
   Compiling mini-internal v0.1.45
   Compiling cap-net-ext v4.0.2
   Compiling flate2 v1.1.9
   Compiling hyper v1.11.0 (https://github.com/joshuarli/hyper-futures-lite?rev=c99b20ce178251a962289977fdfa2474e2564f8e#c99b20ce)
   Compiling sha2 v0.11.0
   Compiling uuid v1.23.3
   Compiling compression-codecs v0.4.38
   Compiling http-body-util v0.1.4
   Compiling rustls-pemfile v2.2.0
   Compiling filetime v0.2.29
   Compiling async-compression v0.4.42
   Compiling crossbeam-channel v0.5.15
   Compiling libbz2-rs-sys v0.2.5
   Compiling rustc-hash v2.1.3
   Compiling async-tar v0.6.1 (https://github.com/dignifiedquire/async-tar.git?rev=109365969684b9cfdbe2696d5185b4ebcfb29b4c#10936596)
   Compiling lzma-rust2 v0.16.5
   Compiling xsh v0.0.1 (/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786174072800/task-pathparts-003)
   Compiling astral_async_zip v0.0.20
   Compiling cap-tempfile v4.0.2
   Compiling bzip2 v0.6.1
   Compiling ignore v0.4.25
   Compiling cap-directories v4.0.2
   Compiling sha1 v0.11.0
   Compiling tempfile v3.27.0
   Compiling md-5 v0.11.0
   Compiling diffy v0.5.0
   Compiling regex-lite v0.1.9
   Compiling jiff v0.2.31
   Compiling data-encoding v2.11.0
   Compiling mimalloc v0.1.52
   Compiling rustls-webpki v0.103.13
   Compiling rustls-platform-verifier v0.7.0
   Compiling futures-rustls v0.26.0
   Compiling xsh-net v0.0.1 (/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786174072800/task-pathparts-003/crates/xsh-net)
   Compiling xsht v0.0.1 (/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786174072800/task-pathparts-003/crates/xsht)
    Finished `test` profile [unoptimized] target(s) in 38.77s
     Running tests/integration.rs (target/debug/deps/integration-c7997979fd314f42)

running 1 test
test lint::linter_marks_display_string_interpolation_as_used ... FAILED

failures:

---- lint::linter_marks_display_string_interpolation_as_used stdout ----

thread 'lint::linter_marks_display_string_interpolation_as_used' (15046442) panicked at crates/xsht/tests/lint.rs:326:5:
[Diagnostic { severity: Error, code: Some("lex.unexpected-character"), message: "unexpected character", span: None, labels: [Label { style: Primary, span: Span { source_id: SourceId(0), start: 0, len: 1 }, message: Some("not valid in source") }], notes: [], fix_hints: [] }]
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace


failures:
    lint::linter_marks_display_string_interpolation_as_used

test result: FAILED. 0 passed; 1 failed; 0 ignored; 0 measured; 98 filtered out; finished in 0.00s

error: test failed, to rerun pass `-p xsht --test integration`


Command exited with code 101
  - Structured report: `workers/engineer/task-pathparts-003/report.json`
- `engineer/task-pathparts-003`, turn `22`, tool `bash`:    Compiling xsht v0.0.1 (/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786174072800/task-pathparts-003/crates/xsht)
    Finished `test` profile [unoptimized] target(s) in 0.87s
     Running tests/integration.rs (target/debug/deps/integration-c7997979fd314f42)

running 1 test
test lint::linter_marks_display_string_interpolation_as_used ... FAILED

failures:

---- lint::linter_marks_display_string_interpolation_as_used stdout ----

thread 'lint::linter_marks_display_string_interpolation_as_used' (15047146) panicked at crates/xsht/tests/lint.rs:339:5:
display-string interpolation should count as a use: [Diagnostic { severity: Warning, code: Some("lint.unused-local"), message: "unused local variable `dir`", span: None, labels: [Label { style: Secondary, span: Span { source_id: SourceId(0), start: 16, len: 16 }, message: Some("binding is never read") }], notes: [], fix_hints: [] }, Diagnostic { severity: Warning, code: Some("lint.unused-local"), message: "unused local variable `unused`", span: None, labels: [Label { style: Secondary, span: Span { source_id: SourceId(0), start: 34, len: 26 }, message: Some("binding is never read") }], notes: [], fix_hints: [] }]
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace


failures:
    lint::linter_marks_display_string_interpolation_as_used

test result: FAILED. 0 passed; 1 failed; 0 ignored; 0 measured; 98 filtered out; finished in 0.01s

error: test failed, to rerun pass `-p xsht --test integration`


Command exited with code 101
  - Structured report: `workers/engineer/task-pathparts-003/report.json`
- `engineer/task-pathparts-003`, turn `30`, tool `grep`: rg: regex parse error:
    (?:interpolation_chunks()
    ^
error: unclosed group
  - Structured report: `workers/engineer/task-pathparts-003/report.json`
- `engineer/task-pathparts-003`, turn `45`, tool `bash`:    Compiling xsht v0.0.1 (/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786174072800/task-pathparts-003/crates/xsht)
    Finished `test` profile [unoptimized] target(s) in 0.85s
     Running tests/integration.rs (target/debug/deps/integration-c7997979fd314f42)

running 54 tests
test lint::linter_autofixes_redundant_path_display_in_command_args ... ok
test lint::formatter_preserves_single_newline_triple_string_lint_fix ... ok
test lint::linter_autofixes_needless_var_annotation ... ok
test lint::linter_autofixes_needless_str_annotation ... ok
test lint::linter_autofixes_needless_export_str_annotation ... ok
test lint::linter_autofixes_needless_scalar_annotations ... ok
test lint::linter_autofixes_redundant_command_interpolations_for_run_args ... ok
test lint::linter_autofixes_needless_list_annotations ... ok
test lint::linter_autofixes_single_newline_triple_string ... ok
test lint::linter_autofixes_redundant_tail_ok_return ... ok
test lint::linter_does_not_autofix_tail_return_binding_across_comment ... ok
test lint::linter_autofixes_single_value_command_fstrings ... ok
test lint::linter_does_not_rewrite_branching_list_accumulation_loop ... ok
test lint::linter_does_not_rewrite_unique_accumulation_loop ... ok
test lint::linter_autofixes_redundant_tail_return_binding ... ok

thread 'lint::linter_marks_display_string_interpolation_as_used' (15053056) panicked at crates/xsht/tests/lint.rs:339:5:
display-string interpolation should count as a use: [Diagnostic { severity: Warning, code: Some("lint.unused-local"), message: "unused local variable `dir`", span: None, labels: [Label { style: Secondary, span: Span { source_id: SourceId(0), start: 16, len: 16 }, message: Some("binding is never read") }], notes: [], fix_hints: [] }, Diagnostic { severity: Warning, code: Some("lint.unused-local"), message: "unused local variable `unused`", span: None, labels: [Label { style: Secondary, span: Span { source_id: SourceId(0), start: 34, len: 26 }, message: Some("binding is never read") }], notes: [], fix_hints: [] }]
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
test lint::linter_marks_display_string_interpolation_as_used ... FAILED
test lint::linter_autofixes_typed_empty_list_tail_return_binding ... ok
test lint::linter_marks_indexed_assignment_keys_as_used ... ok
test lint::linter_autofixes_contains_membership_to_in ... ok
test lint::linter_autofixes_typed_tail_return_bindings_when_initializer_already_matches ... ok
test lint::linter_does_not_suggest_unparseable_tail_return_for_typed_records ... ok
test lint::linter_reports_named_underscore_locals_but_allows_sink_binding ... ok
test lint::linter_autofixes_unreachable_return_after_all_returning_match ... ok
test lint::linter_reports_missing_effects_from_imported_module_proc ... ok
test lint::linter_reports_missing_effects_from_called_restricted_proc ... ok
test lint::linter_reports_top_level_const_order_without_default_fix ... ok
test lint::linter_autofixes_redundant_path_display_parse_roundtrips ... ok
test lint::linter_skips_interpolating_string_and_literal_dollar_contexts ... ok
test lint::linter_skips_contains_to_in_when_rewrite_could_reorder_effects ... ok
test lint::linter_reports_unsorted_import_blocks_with_fix ... ok
test lint::linter_skips_needless_for_dynamic_try_initializer ... ok
test lint::linter_reports_missing_declared_effects_with_fix ... ok
test lint::linter_skips_needless_for_empty_list_initializer ... ok
test lint::linter_needless_annotation_fix_preserves_source ... ok
test lint::linter_skips_needless_for_module_call_initializer ... ok
test lint::linter_skips_needless_for_proc_params ... ok
test lint::linter_skips_needless_for_method_call_initializer ... ok
test lint::linter_skips_unbound_dollar_lookalikes_in_expression_string ... ok
test lint::linter_reports_redundant_result_unit_ceremony ... ok
test lint::linter_reports_redundant_json_and_stream_roundtrips ... ok
test lint::linter_sorts_multiple_import_groups_independently ... ok
test lint::linter_warns_for_commented_import_blocks_without_fix ... ok
test lint::linter_suggests_empty_map_literal_for_map_empty ... ok
test lint::linter_warns_for_dollar_lookalike_in_expression_string ... ok
test lint::linter_suggests_string_concat_over_join_empty ... ok
test lint::linter_warns_for_dollar_lookalike_in_triple_quoted_and_parenthesized_expressions ... ok
test lint::linter_warns_for_redundant_tail_ok_return_without_type_info ... ok
test lint::linter_suggests_list_comprehension_for_accumulation_loop ... ok
test lint::linter_suggests_multiline_tag_union ... ok
test lint::linter_suggests_guarded_list_comprehension_for_guarded_accumulation_loop ... ok
test lint::linter_suggests_map_comprehension_for_map_building_loop ... ok
test lint::linter_reports_stage_12_warning_rules_deterministically ... ok
test lint::linter_suggests_stream_producer_for_proc_list_accumulator ... ok
test lint::linter_autofixes_redundant_type_driven_roundtrips ... ok

failures:

failures:
    lint::linter_marks_display_string_interpolation_as_used

test result: FAILED. 53 passed; 1 failed; 0 ignored; 0 measured; 45 filtered out; finished in 0.02s

error: test failed, to rerun pass `-p xsht --test integration`


Command exited with code 101
  - Structured report: `workers/engineer/task-pathparts-003/report.json`
- `engineer/task-pathparts-003`, turn `60`, tool `read`: ENOENT: no such file or directory, access '/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786170696452/phases/01-ticket/workers/engineer/task-pathparts-002/REPORT.md'
  - Structured report: `workers/engineer/task-pathparts-003/report.json`
- `engineer/task-pathparts-003`, turn `63`, tool `grep`: rg: regex parse error:
    (?:expr_references_name()
    ^
error: unclosed group
  - Structured report: `workers/engineer/task-pathparts-003/report.json`
- `engineer/task-pathparts-003`, turn `78`, tool `bash`: error: unexpected argument 'syntax::parser_accepts_nested_interpolation_boundaries_from_shared_scanner' found

Usage: cargo test [OPTIONS] [TESTNAME] [-- [ARGS]...]

For more information, try '--help'.


Command exited with code 1
  - Structured report: `workers/engineer/task-pathparts-003/report.json`


### Cycle total

- Workers: `2`
- Assistant turns: `98`
- Bucket tokens: `6075619`
- Cost (USD): `0.111912`
- Nonzero tool results: `7`
- Budget failures or unknown costs: `0`


## Employee decisions

### director/director

- Role: `director`
- Result: `pass`
- Report: `workers/director/director/REPORT.md`

#### Efficiency and evidence

Mode `ticket-implementation`. Controller-selected approved ticket
`task-pathparts-003` (change target `product`, XSH base commit
`e4059a21ae8942fa07a0e8e61bac971ed703237c`) was implemented once in the
isolated worktree
`/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786174072800/task-pathparts-003`.
This was a reconcile-only pass (`FACTORY_DIRECTOR_RECONCILE_ONLY=true`): the
controller already launched the single admitted engineer row concurrently and
staged fail-closed worker reports. The director reconciled the completed
reports; the linked replay is owned by a separate reuse phase, so no merge was
performed and the branch is retained for CTO review.

#### Handbook or proposal decision

not reported

#### Ticket or product decision

not reported

#### Next action

- Engineer implementation branch and commit — present and valid. Branch
  `factory/task-pathparts-003/1786174073904`, HEAD `dbd65254080ca62b4f69534f848add50ab146978`, on XSH base `e4059a2`; worktree clean (`git status --porcelain` empty); diff touches `src/syntax/literal.rs`, `crates/xsht/tests/lint.rs`, `tests/syntax.rs`, `docs/SPEC.md` per the report.
- Engineer `REPORT.md` — present and valid. Contains all required headings
  (`Result`, `Branch`, `Commit`, `Files changed`, `Tests`, `North-star impact`,
  `Remaining risks`) with `## Result` = `ready-for-review`.
- Engineer `report.json` — present, result `pass`, dispatch claim
  `f814654f…d719` matches the dispatch manifest.
- Handbook candidate — present. `lineage/handbook-candidate.md` adds the
  display-string `$name`/field shorthand read lesson over the approved lineage.
- No merge performed; branch retained for CTO review and separate replay phase.

#### North-star impact

This cycle produced a focused, general product improvement: XSH's lint
unused-local analysis was counting a local read inside a display-string
(`f"...$name..."`) interpolation as unused, hard-failing the handbook's own
recommended idiom for exact dynamic output. The engineer's change makes the
shared interpolation scanner recognize `$name`/`$field.path` shorthand and makes
lint treat those reads as real uses while still diagnosing genuinely unused
locals. That directly reduces the "guesses, workarounds, repeated discoveries"
friction the north star targets, and it removes an internally inconsistent
surface where documented guidance fails the language's own quality check.

Uncertainty: the phase was verify-only and did not include a merge or a
product replay. Durability depends on the CTO reviewing the branch and the
linked `task-pathparts` replay passing against this provenance commit, and on a
second output-composing eval confirming the same. The engineer's own regression
tests and full `xsht` lint/integration suites passed; no open product signal
remains inside this cycle.

### engineer/task-pathparts-003

- Role: `engineer`
- Result: `ready-for-review`
- Report: `workers/engineer/task-pathparts-003/REPORT.md`

#### Efficiency and evidence

- `cargo test --test integration syntax::parser_accepts_display_string_shorthand_interpolation -- --exact` — passed.
- `cargo test --test integration syntax::parser_accepts_raw_triple_and_nested_fmt_strings` — passed.
- `cargo test --test integration syntax::parser_accepts_nested_interpolation_boundaries_from_shared_scanner` — passed.
- `cargo test --test integration syntax::` — 101 passed.
- `cargo test -p xsht --test integration lint::` — 54 passed.
- `cargo test -p xsht --test integration` — 99 passed.
- Acceptance smoke test: `xsht check` passed; `xsht lint` passed for `print f"dir=$dir"`; runtime output was `dir=tmp`.
- `git diff --check` — passed.

#### Handbook or proposal decision

not reported

#### Ticket or product decision

None known. The product worktree is clean and the committed branch is ready for CTO review.

#### Next action

not reported

#### North-star impact

Display strings now use the same `$name` shorthand already accepted by XSH's documented output idiom, and lint's AST traversal sees the shorthand as an actual binding read. Agents can compose exact dynamic output without discovering a concatenation workaround, while genuinely unused locals remain diagnosed. The shared scanner also keeps expression interpolation and path-format interpolation behavior consistent.

The reusable lesson was staged in the supplied run-scoped handbook candidate: display strings support `$name`/field shorthand and both forms count as lint reads.



## Eval proposal review

No CTO eval review was recorded.

## Handbook lineage

Checked-in `runtime/handbook.md`: `44d8ba3d8a0edb2fa823023b55a95ffa4388dd195ce77987804983cc255a832c`
- approved snapshot: `factory-source/handbook-approved.md` sha256 `44d8ba3d8a0edb2fa823023b55a95ffa4388dd195ce77987804983cc255a832c` — promoted by CTO ledger; matches checked-in handbook
- approved snapshot: `lineage/handbook-approved.md` sha256 `44d8ba3d8a0edb2fa823023b55a95ffa4388dd195ce77987804983cc255a832c` — promoted by CTO ledger; matches checked-in handbook
- candidate: `lineage/handbook-candidate.md` sha256 `0fa33e12d3c0245d6b2c7fd11d1d601843ef179f40329a60c3d0d12efe888e67` — DIFFERS; CTO promotion or rejection decision required


## Historical handbook backlog

Historical candidates: 61; differing: 60; ledger-dispositioned: 59; unresolved: 1.
Unresolved candidates requiring one explicit CTO decision:
- `runs/run-1786174072800/phases/01-ticket/lineage/handbook-candidate.md` sha256 `0fa33e12d3c0245d6b2c7fd11d1d601843ef179f40329a60c3d0d12efe888e67`


## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
