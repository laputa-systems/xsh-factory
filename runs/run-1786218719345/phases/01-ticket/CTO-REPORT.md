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
- `workers/engineer/task-histogram-009/report.json`: result `pass`; report `workers/engineer/task-histogram-009/report.json`


## Employee accounting

### Worker metrics

- `director/director` (`director`): result `pass`; report `workers/director/director/report.json`
  - Execution: `not recorded`; classification: `not recorded`
  - Turns: `11`; bucket tokens: `302050`; thinking blocks: `11`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=11; observed_output_tps=0`
  - Tool errors: `1`; cost: `0.009600`; budget: `0.060000`
- `engineer/task-histogram-009` (`engineer`): result `pass`; report `workers/engineer/task-histogram-009/report.json`
  - Execution: `not recorded`; classification: `not recorded`
  - Turns: `53`; bucket tokens: `3558329`; thinking blocks: `11`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=53; observed_output_tps=0`
  - Tool errors: `4`; cost: `0.069765`; budget: `0.350000`


### Nonzero tool results
### Provider health and latency

Provider retry, latency, and attribution data are in worker `report.json`
`provider_telemetry` fields. Missing telemetry is `unknown`, not evidence of
normal provider health. Provider switching is out of scope and tracked in
`TODO.md`.

### Nonzero tool results

- `director/director`, turn `2`, tool `bash`: total 96
drwxr-xr-x  19 josh  staff    608 Aug  8 12:52 .
drwxr-xr-x  64 josh  staff   2048 Aug  8 12:52 ..
-rw-r--r--   1 josh  staff   1545 Aug  8 12:52 CTO-IMPROVEMENT.md
-rw-r--r--   1 josh  staff   1380 Aug  8 12:52 CTO-PRODUCTIVITY-REPORT.md
-rw-r--r--   1 josh  staff  10819 Aug  8 12:52 CTO-TICKET-INVENTORY.json
-rw-r--r--   1 josh  staff   4558 Aug  8 12:52 CTO-TICKET-INVENTORY.md
-rw-r--r--   1 josh  staff      0 Aug  8 12:52 cycle-budget-watch.stderr
-rw-r--r--   1 josh  staff      0 Aug  8 12:52 cycle-budget-watch.stdout
-rw-r--r--   1 josh  staff   2637 Aug  8 12:52 CYCLE-REQUEST.md
-rw-r--r--   1 josh  staff   1499 Aug  8 12:52 events.jsonl
-rw-r--r--   1 josh  staff     65 Aug  8 12:52 factory-source.sha256
-rw-r--r--   1 josh  staff      0 Aug  8 12:52 independent-eval-task-bigfiles.stderr
-rw-r--r--   1 josh  staff    229 Aug  8 12:57 independent-eval-task-bigfiles.stdout
drwxr-xr-x   4 josh  staff    128 Aug  8 12:52 phase-requests
drwxr-xr-x   5 josh  staff    160 Aug  8 12:52 phases
-rw-r--r--   1 josh  staff      0 Aug  8 12:52 primary.stderr
-rw-r--r--   1 josh  staff    231 Aug  8 12:52 primary.stdout
drwxr-xr-x   3 josh  staff     96 Aug  8 12:52 processes
drwxr-xr-x   7 josh  staff    224 Aug  8 12:52 states
---DISPATCH---


Command exited with code 1
  - Structured report: `workers/director/director/report.json`
- `engineer/task-histogram-009`, turn `12`, tool `read`: ENOENT: no such file or directory, access '/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786218719345/phases/01-ticket/patches/task-histogram-005.diff'
  - Structured report: `workers/engineer/task-histogram-009/report.json`
- `engineer/task-histogram-009`, turn `38`, tool `bash`:     Finished `test` profile [unoptimized] target(s) in 0.18s
     Running tests/integration.rs (target/debug/deps/integration-0d8e0e4a2df73a3f)

running 1 test
   Compiling xshi v0.0.1 (/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/crates/xshi)
   Compiling xsht v0.0.1 (/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/crates/xsht)
    Finished `dev` profile [unoptimized] target(s) in 2.51s
test runtime::coverage::xsh_native_tests ... FAILED

failures:

---- runtime::coverage::xsh_native_tests stdout ----

thread 'runtime::coverage::xsh_native_tests' (17094974) panicked at tests/runtime/coverage.rs:1577:5:
xsh native tests
stdout:
running 321 tests
core/tests/test-basename.xsh::test_basename_runs_as_executable_shebang_script ... skipped: /bin/xsh is not installed 5ms
core/tests/test-basename.xsh::test_basename_suffix_and_multiple ... ok 136ms
core/tests/test-basename.xsh::test_basename_basic ... ok 138ms
core/tests/test-cut.xsh::test_cut_fields ... ok 170ms
core/tests/test-df.xsh::test_df_matches_alpine_kp ... skipped: Alpine-only df comparison 8ms
core/tests/test-cat.xsh::test_cat_file_and_stdin ... ok 196ms
core/tests/test-df.xsh::test_df ... ok 80ms
core/tests/test-cp.xsh::test_cp_file_and_recursive_dir ... ok 227ms
core/tests/test-date.xsh::test_date_format ... ok 91ms
core/tests/test-chgrp.xsh::test_chgrp_current_group ... ok 228ms
core/tests/test-dirname.xsh::test_dirname ... ok 68ms
core/tests/test-env.xsh::test_env_uses_direct_xsh_shebang ... ok 5ms
core/tests/test-chown.xsh::test_chown_current_user ... ok 262ms
core/tests/test-env.xsh::test_env_assignment_runs_command ... ok 64ms
core/tests/test-chmod.xsh::test_chmod_recursive ... ok 292ms
core/tests/test-env.xsh::test_env_split_string_as_single_shebang_arg_runs_command ... ok 67ms
core/tests/test-fd.xsh::test_fd_finds_by_name_extension_and_type ... ok 45ms
core/tests/test-env.xsh::test_env_split_string_runs_command ... ok 83ms
core/tests/test-du.xsh::test_du ... ok 116ms
core/tests/test-du.xsh::test_du_recursive_all_and_total ... ok 95ms
core/tests/test-fold.xsh::test_fold_width ... ok 27ms
core/tests/test-head.xsh::test_head_lines ... ok 28ms
core/tests/test-ifdown.xsh ... FAILED 0ms
core/tests/test-ifup.xsh ... FAILED 0ms
core/tests/test-getty.xsh::test_getty_requires_baud_and_tty ... ok 40ms
core/tests/test-fd.xsh::test_fd_multiple_roots_exclude_depth_and_executable ... ok 44ms
core/tests/test-host.xsh::test_host_localhost ... ok 30ms
core/tests/test-hostname.xsh::test_hostname_short ... ok 29ms
core/tests/test-head.xsh::test_head_reads_stdin ... ok 42ms
core/tests/test-ip.xsh::test_ip_addr_smoke ... ok 28ms
core/tests/test-link.xsh::test_link ... ok 30ms
core/tests/test-ln.xsh::test_ln_symbolic_force ... ok 32ms
core/tests/test-fd.xsh::test_fd_hidden_and_glob ... ok 118ms
core/tests/test-host.xsh::test_host_type_and_usage ... ok 77ms
core/tests/test-mdev.xsh::test_mdev_wrapper_preserves_platform_boundary ... ok 41ms
core/tests/test-mkdir.xsh::test_mkdir ... ok 46ms
core/tests/test-nproc.xsh::test_nproc ... ok 47ms
core/tests/test-mv.xsh::test_mv_file_and_target_directory ... ok 59ms
core/tests/test-passwd.xsh::test_passwd_rejects_extra_operands ... ok 54ms
core/tests/test-printenv.xsh::test_printenv_named ... ok 37ms
core/tests/test-pstree.xsh::test_pstree_default_prints_visible_root ... skipped: macOS pstree is unavailable 4ms
core/tests/test-printenv.xsh::test_printenv_processes_all_names_before_missing_status ... ok 44ms
core/tests/test-paste.xsh::test_paste_parallel_serial_and_delimiters ... ok 97ms
core/tests/test-pwd.xsh::test_pwd ... ok 33ms
core/tests/test-paste.xsh::test_paste_reads_stdin_and_rejects_flags ... ok 104ms
core/tests/test-printf.xsh::test_printf_escapes_and_usage ... ok 88ms
core/tests/test-realpath.xsh::test_realpath ... ok 31ms
core/tests/test-ls.xsh::test_ls ... ok 173ms
core/tests/test-printf.xsh::test_printf_strings_repeat_without_implicit_newline ... ok 101ms
core/tests/test-rev.xsh::test_rev_rejects_options ... ok 28ms
core/tests/test-rg.xsh::test_rg_reports_matches_with_line_numbers ... ok 41ms
core/tests/test-readlink.xsh::test_readlink ... ok 90ms
core/tests/test-rm.xsh::test_rm_force_recursive ... ok 38ms
core/tests/test-rev.xsh::test_rev_lines_files_and_stdin ... ok 79ms
core/tests/test-rmdir.xsh::test_rmdir_parents ... ok 38ms
core/tests/test-seq.xsh::test_seq_range ... ok 38ms
core/tests/test-seq.xsh::test_seq_rejects_zero_step ... ok 44ms
core/tests/test-rg.xsh::test_rg_count_and_filename ... ok 120ms
core/tests/test-pstree.xsh::test_pstree_rejects_unknown_pid ... ok 212ms
core/tests/test-shuf.xsh::test_shuf_head_count ... ok 44ms
core/tests/test-split.xsh::test_split_lines ... ok 44ms
core/tests/test-seq.xsh::test_seq_descending_negative_separator_and_width ... ok 118ms
core/tests/test-strings.xsh::test_strings_min_len ... ok 51ms
core/tests/test-sort.xsh::test_sort_unique_reverse ... ok 94ms
core/tests/test-tail.xsh::test_tail_lines ... ok 40ms
core/tests/test-su.xsh::test_su_returns_failure_for_unknown_user ... ok 62ms
core/tests/test-rg.xsh::test_rg_word_line_pattern_and_globs ... ok 195ms
core/tests/test-tee.xsh::test_tee_input_file ... ok 34ms
core/tests/test-tee.xsh::test_tee_reads_stdin_and_appends ... ok 35ms
core/tests/test-tr.xsh::test_tr_rejects_bad_usage ... ok 33ms
core/tests/test-stat.xsh::test_stat ... ok 121ms
core/tests/test-uname.xsh::test_uname_all ... ok 24ms
core/tests/test-touch.xsh::test_touch ... ok 63ms
core/tests/test-uniq.xsh::test_uniq_counts ... ok 33ms
core/tests/test-wc.xsh::test_wc_reads_stdin ... ok 30ms
core/tests/test-wc.xsh::test_wc_counts ... ok 41ms
core/tests/test-which.xsh::test_which_finds_shell ... ok 24ms
core/tests/test-tree.xsh::test_tree_supports_multiple_roots_and_rejects_flags ... ok 94ms
core/tests/test-which.xsh::test_which_processes_all_names_before_missing_status ... ok 45ms
showcase/tests/test-backup-rotate.xsh::test_backup_rotate ... ok 46ms
core/tests/test-tree.xsh::test_tree_renders_sorted_branches_and_symlinks ... ok 156ms
showcase/tests/test-bump-version.xsh::test_bump_version_usage ... ok 39ms
showcase/tests/test-archive-unpack.xsh::test_archive_unpack ... ok 99ms
showcase/tests/test-bench.xsh::test_bench ... ok 68ms
showcase/tests/test-batch-rename.xsh::test_batch_rename ... ok 91ms
showcase/tests/test-bytes-inspect.xsh::test_bytes_inspect ... ok 41ms
showcase/tests/test-csv-query.xsh::test_csv_query ... ok 44ms
core/tests/test-tar.xsh::test_tar_create_list_extract ... ok 257ms
showcase/tests/test-df.xsh::test_showcase_df_kp_path ... ok 39ms
showcase/tests/test-dedup.xsh::test_dedup ... ok 52ms
showcase/tests/test-df.xsh::test_showcase_df_root ... ok 34ms
core/tests/test-tr.xsh::test_tr_translate_delete_squeeze_and_stdin ... ok 245ms
showcase/tests/test-ecount.xsh::test_ecount_can_sum_sizes ... ok 39ms
showcase/tests/test-ecount.xsh::test_ecount_counts_extensions ... ok 43ms
showcase/tests/test-dot-env-run.xsh::test_dot_env_run ... ok 66ms
showcase/tests/test-flamegraph.xsh::test_flamegraph ... ok 32ms
showcase/tests/test-env-diff.xsh::test_env_diff ... ok 42ms
showcase/tests/test-file-report.xsh::test_file_report ... ok 46ms
showcase/tests/test-git-digest.xsh::test_git_digest_usage ... ok 29ms
showcase/tests/test-hosts-ping.xsh::test_hosts_ping_usage ... ok 28ms
showcase/tests/test-file-audit.xsh::test_file_audit_findings ... ok 62ms
showcase/tests/test-hyperfine.xsh::test_hyperfine_usage ... ok 36ms
showcase/tests/test-jq.xsh::test_jq_arith_stream ... ok 204ms
showcase/tests/test-jq.xsh::test_jq_construct ... ok 199ms
showcase/tests/test-jq.xsh::test_jq_alt_and_try ... ok 363ms
showcase/tests/test-jq.xsh::test_jq_identity ... ok 188ms
showcase/tests/test-jq.xsh::test_jq_number_roundtrip ... ok 204ms
showcase/tests/test-jq.xsh::test_jq_pipe_index ... ok 204ms
core/tests/test-pstree.xsh::test_pstree_renders_tree_with_pid_labels ... ok 1.2s
showcase/tests/test-jq.xsh::test_jq_assign ... ok 764ms
showcase/tests/test-jq.xsh::test_jq_stream ... ok 193ms
showcase/tests/test-json-diff.xsh::test_json_diff ... ok 42ms
showcase/tests/test-jq.xsh::test_jq_bindings ... ok 801ms
showcase/tests/test-loc.xsh::test_loc ... ok 33ms
showcase/tests/test-music-convert.xsh::test_music_convert ... ok 34ms
showcase/tests/test-parse-log.xsh::test_parse_log ... ok 37ms
showcase/tests/test-jq.xsh::test_jq_defs ... ok 839ms
showcase/tests/test-path-audit.xsh::test_path_audit_findings ... ok 52ms
showcase/tests/test-perf-collapse.xsh::test_perf_collapse ... ok 39ms
showcase/tests/test-px.xsh::test_px_kill_requires_a_filter ... ok 71ms
showcase/tests/test-px.xsh::test_px_kill_signal_is_parse_bounded ... ok 59ms
showcase/tests/test-jq.xsh::test_jq_paths ... ok 768ms
showcase/tests/test-jq.xsh::test_jq_builtins ... ok 1.1s
showcase/tests/test-release-pack.xsh::test_release_pack ... ok 54ms
showcase/tests/test-rgrep.xsh::test_rgrep ... ok 44ms
showcase/tests/test-jq.xsh::test_jq_regex ... ok 965ms
showcase/tests/test-secret-scan.xsh::test_secret_scan ... ok 39ms
showcase/tests/test-todo-scan.xsh::test_todo_scan ... ok 33ms
showcase/tests/test-px.xsh::test_px_finds_current_test_process ... ok 604ms
showcase/tests/test-wait-for.xsh::test_wait_for_usage ... ok 23ms
showcase/tests/test-jq.xsh::test_jq_strings ... ok 916ms
showcase/tests/test-watch-run.xsh::test_watch_run_once ... ok 44ms
showcase/tests/test-webp-dir.xsh::test_webp_dir_help ... ok 26ms
showcase/tests/test-xfetch.xsh::test_xfetch_summary ... ok 26ms
showcase/tests/test-px.xsh::test_px_kill_accepts_numeric_signal ... ok 720ms
tests/xsh/basic.xsh::test_dns_mock ... ok 1ms
tests/xsh/basic.xsh::test_net_mock ... ok 2ms
tests/xsh/basic.xsh::test_pass ... ok 2ms
tests/xsh/basic.xsh::test_language_sugar_edge_cases ... ok 11ms
tests/xsh/basic.xsh::test_skip ... skipped: later 1ms
tests/xsh/basic.xsh::test_temp ... ok 4ms
tests/xsh/basic.xsh::test_process_command_builder ... ok 12ms
tests/xsh/collections.xsh::test_ergonomic_sugar_pass_forms ... ok 15ms
tests/xsh/collections.xsh::test_list_comprehension_basic_transform ... ok 2ms
tests/xsh/collections.xsh::test_list_comprehension_guard_can_produce_empty_list ... ok 4ms
tests/xsh/collections.xsh::test_list_comprehension_with_guard_filters_elements ... ok 3ms
tests/xsh/collections.xsh::test_list_comprehension_with_record_destructuring ... ok 1ms
tests/xsh/collections.xsh::test_local_accumulator_field_mutation ... ok 2ms
tests/xsh/collections.xsh::test_nominal_error_payload_and_facet_patterns ... ok 3ms
tests/xsh/collections.xsh::test_compact_sugar_forms ... ok 37ms
showcase/tests/test-tokei.xsh::test_tokei_json_shape_counts_and_ignores ... ok 192ms
showcase/tests/test-px.xsh::test_px_kill_signals_default_matches ... ok 657ms
tests/xsh/effects.xsh::test_annotated_proc_not_flagged_by_linter ... ok 36ms
tests/xsh/effects.xsh::test_correct_annotation_passes ... ok 35ms
tests/xsh/effects.xsh::test_io_covers_net ... ok 38ms
tests/xsh/effects.xsh::test_io_does_not_cover_time ... ok 31ms
tests/xsh/effects.xsh::test_linter_infers_fs_error ... ok 30ms
tests/xsh/effects.xsh::test_linter_infers_net ... ok 33ms
tests/xsh/effects.xsh::test_linter_infers_process_from_run ... ok 31ms
tests/xsh/effects.xsh::test_module_call_blocked_by_annotation ... ok 32ms
tests/xsh/effects.xsh::test_print_requires_no_effect ... ok 28ms
tests/xsh/effects.xsh::test_proc_to_proc_subset_passes ... ok 30ms
showcase/tests/test-run-retry.xsh::test_run_retry ... ok 516ms
tests/xsh/effects.xsh::test_question_mark_requires_error_effect ... ok 32ms
tests/xsh/effects.xsh::test_restricted_cannot_call_unrestricted_proc ... ok 29ms
tests/xsh/implicit-result-return.xsh::test_implicit_result_return_in_par_map ... ok 2ms
tests/xsh/effects.xsh::test_run_form_requires_process_effect ... ok 29ms
tests/xsh/implicit-result-return.xsh::test_nested_result_calls_in_par_map ... ok 1ms
tests/xsh/implicit-result-return.xsh::test_result_alias_return_shape ... ok 1ms
tests/xsh/implicit-result-return.xsh::test_explicit_result_return_shapes ... ok 22ms
tests/xsh/implicit-result-return.xsh::test_result_return_shapes_agree ... ok 1ms
tests/xsh/effects.xsh::test_unrestricted_proc_unchecked ... ok 31ms
tests/xsh/par-map-result.xsh::test_par_map_all_ok ... ok 2ms
tests/xsh/par-map-result.xsh::test_par_map_collect_all ... ok 4ms
showcase/tests/test-webp-dir.xsh::test_webp_dir_dry_run ... ok 265ms
tests/xsh/implicit-result-return.xsh::test_implicit_result_return_through_module ... ok 33ms
tests/xsh/retry.xsh::test_retry_attempt_defers_run_before_next_attempt ... ok 28ms
tests/xsh/retry.xsh::test_retry_attempts_are_traced ... ok 38ms
tests/xsh/retry.xsh::test_retry_exhaustion_returns_final_error ... ok 29ms
tests/xsh/run.xsh::test_boolean_operators_short_circuit ... ok 2ms
tests/xsh/implicit-result-return.xsh::test_value_returning_error_helper ... ok 58ms
tests/xsh/run.xsh::test_command_proc_args_resolve_bare_value_references ... ok 5ms
tests/xsh/retry.xsh::test_retry_repeats_until_attempt_succeeds ... ok 37ms
showcase/tests/test-px.xsh::test_px_returns_one_when_no_process_matches ... ok 715ms
tests/xsh/retry.xsh::test_return_inside_retry_returns_from_enclosing_proc ... ok 35ms
showcase/tests/test-px.xsh::test_px_default_search_matches_executable_substrings ... ok 996ms
tests/xsh/run.xsh::test_function_tail_values_return_declared_values ... ok 7ms
tests/xsh/formatter.xsh::test_fmt_fixture ... ok 103ms
tests/xsh/run.xsh::test_byte_pipeline_executes_without_shell_and_redirects_stdout ... ok 32ms
tests/xsh/run.xsh::test_grouped_multiline_run_invocation_executes ... ok 19ms
tests/xsh/run.xsh::test_invalid_utf8_text_capture_is_a_run_error ... ok 32ms
tests/xsh/run.xsh::test_acceptance_tar_gzip_pipeline_writes_archive ... ok 54ms
tests/xsh/run.xsh::test_path_absolute_uses_current_runtime_cwd_without_existing_path ... ok 1ms
tests/xsh/run.xsh::test_modules_are_not_command_namespaces ... ok 36ms
tests/xsh/run.xsh::test_foundation_literals_defers_streams_and_builders ... ok 53ms
tests/xsh/run.xsh::test_pipeline_status_preserves_exec_failure_and_broken_pipe_segments ... ok 24ms
tests/xsh/run.xsh::test_large_stdout_capture_drains_and_limit_is_error ... ok 57ms
tests/xsh/run.xsh::test_result_unit_statements_propagate_by_default ... ok 2ms
tests/xsh/run.xsh::test_run_builtin_unknown_name_returns_process_error ... ok 3ms
tests/xsh/run.xsh::test_nested_traceback_includes_user_procs_and_pure_functions ... ok 66ms
tests/xsh/run.xsh::test_plain_run_updates_last_status_and_direct_binding ... ok 55ms
tests/xsh/run.xsh::test_run_builtin_forms_execute_like_plain_run_forms ... ok 53ms
tests/xsh/run.xsh::test_legacy_test_and_getopt_spellings_are_not_command_aliases ... ok 112ms
tests/xsh/run.xsh::test_run_status_can_drive_conditions ... ok 31ms
tests/xsh/run.xsh::test_run_capture_record_captures_status_stdout_and_stderr ... ok 77ms
tests/xsh/run.xsh::test_script_stdout_can_emit_invalid_utf8_bytes ... ok 1ms
tests/xsh/run.xsh::test_nul_run_targets_proc_splice_and_match_diagnostics ... ok 165ms
tests/xsh/run.xsh::test_run_text_captures_stdout_and_inherits_stderr ... ok 83ms
tests/xsh/run.xsh::test_run_timeout_error ... ok 103ms
tests/xsh/run.xsh::test_signaled_status_exposes_total_signal_helpers ... ok 55ms
tests/xsh/run.xsh::test_run_fixture_behaviors ... ok 168ms
tests/xsh/run.xsh::test_signaled_status_exit_code_is_structured_error ... ok 111ms
tests/xsh/run.xsh::test_pipeline_failures_and_trace_are_visible ... ok 227ms
tests/xsh/stdlib/archive.xsh::test_archive_zip_error_contracts ... ok 10ms
tests/xsh/stdlib/args.xsh::test_args_parse_tokens_and_commands ... ok 3ms
tests/xsh/stdlib/args.xsh::test_cli_applet_last_scalar_occurrence_wins ... ok 1ms
tests/xsh/stdlib/args.xsh::test_cli_applet_parses_cp_compatibility_flags ... ok 1ms
tests/xsh/stdlib/args.xsh::test_cli_applet_parses_fd_clusters_and_repeated_values ... ok 2ms
tests/xsh/stdlib/args.xsh::test_cli_applet_parses_head_attached_value ... ok 1ms
tests/xsh/stdlib/args.xsh::test_cli_applet_parses_rg_long_assignment_and_attached_values ... ok 1ms
tests/xsh/stdlib/args.xsh::test_cli_applet_parses_sort_cluster_and_attached_values ... ok 1ms
tests/xsh/stdlib/args.xsh::test_cli_commands_accept_aliases_forms_and_options ... ok 2ms
tests/xsh/stdlib/args.xsh::test_cli_parse_advanced_descriptors ... ok 12ms
tests/xsh/run.xsh::test_trace_output_covers_baseline_event_kinds ... ok 102ms
tests/xsh/stdlib/args.xsh::test_cli_parse_compact_forms ... ok 1ms
tests/xsh/stdlib/auth.xsh::test_applet_mdev_scans_empty_roots ... skipped: mdev is Linux-only 1ms
tests/xsh/run.xsh::test_redirection_paths_and_fd_duplication_use_typed_boundaries ... ok 260ms
tests/xsh/run.xsh::test_whole_script_cli_usage_and_auto_main_errors ... ok 91ms
tests/xsh/run.xsh::test_run_trace_reports_redirection_method_and_env_details ... ok 178ms
tests/xsh/stdlib/cpu.xsh::test_cpu_count ... ok 1ms
tests/xsh/stdlib/bytes.xsh::test_bytes_construction_encoding_and_copy ... ok 3ms
tests/xsh/stdlib/bytes.xsh::test_bytes_methods_and_decode_errors ... ok 2ms
tests/xsh/stdlib/auth.xsh::test_auth_lib_passwd_and_shadow_parse_render ... ok 13ms
tests/xsh/stdlib/dns.xsh::test_dns_module_with_mocks ... ok 2ms
tests/xsh/stdlib/diff.xsh::test_diff_unified ... ok 5ms
tests/xsh/stdlib/elf.xsh::test_elf_inspect ... ok 6ms
tests/xsh/stdlib/fs.xsh ... FAILED 0ms
tests/xsh/stdlib/archive.xsh::test_archive_tar_cpio_and_compression ... ok 77ms
tests/xsh/run.xsh::test_whole_script_run_error_diagnostics ... ok 82ms
tests/xsh/stdlib/hash.xsh::test_hash_digests_checksums_and_digest_methods ... ok 2ms
tests/xsh/stdlib/ini.xsh::test_ini_decode_encode_and_files ... ok 2ms
tests/xsh/stdlib/json.xsh::test_json_decode_type_patterns_and_public_boundaries ... ok 1ms
tests/xsh/stdlib/json.xsh::test_json_path_helpers_report_invalid_paths ... ok 1ms
tests/xsh/stdlib/env.xsh::test_env_overlays_blocks_lookup_and_path_mutation_affect_children ... ok 27ms
tests/xsh/stdlib/json.xsh::test_json_read_write_lines_and_paths ... ok 5ms
tests/xsh/stdlib/env.xsh::test_path_literals_method_sugar_and_expr_env_blocks ... ok 32ms
tests/xsh/stdlib/map.xsh::test_map_module_and_methods ... ok 1ms
tests/xsh/stdlib/methods.xsh::test_collection_number_text_status_and_result_methods ... FAILED 2ms
tests/xsh/stdlib/mime.xsh::test_mime_lookup_and_parse ... ok 1ms
tests/xsh/stdlib/group.xsh::test_group_lookup_and_mutation_contracts ... ok 38ms
tests/xsh/stdlib/net.xsh::test_net_module_with_mocks ... ok 2ms
tests/xsh/stdlib/module.xsh::test_module_load ... ok 6ms
tests/xsh/stdlib/linux.xsh::test_linux_dry_run_covers_module_surface ... ok 21ms
tests/xsh/stdlib/path.xsh::test_membership_operator_supports_strings_lists_bytes_and_paths ... ok 1ms
tests/xsh/stdlib/path.xsh::test_path_absolute ... ok 1ms
tests/xsh/stdlib/patch.xsh::test_patch_apply ... ok 7ms
tests/xsh/stdlib/env.xsh::test_env_functions_and_path_list ... ok 54ms
tests/xsh/stdlib/json.xsh::test_json_rejection_is_trace_visible ... ok 28ms
tests/xsh/stdlib/path.xsh::test_absolute_glob_traverses_symlinked_literal_components ... ok 40ms
tests/xsh/run.xsh::test_whole_script_exit_status_and_abort_behavior ... ok 167ms
tests/xsh/stdlib/process.xsh::test_process_spawn_setup_errors ... ok 13ms
tests/xsh/stdlib/path.xsh::test_path_methods ... ok 61ms
tests/xsh/stdlib/io.xsh::test_io_stdin_text_line_bytes_and_stdout ... ok 111ms
tests/xsh/stdlib/process.xsh::test_process_timeout_errors ... ok 21ms
tests/xsh/stdlib/record.xsh::test_record_require_and_any_require ... ok 4ms
tests/xsh/stdlib/record.xsh::test_schema_runtime_checks_unknown_values ... ok 49ms
tests/xsh/stdlib/process.xsh::test_process_command_redirections ... ok 142ms
tests/xsh/stdlib/auth.xsh::test_applet_auth_helpers_and_sessions ... ok 213ms
tests/xsh/stdlib/regex.xsh::test_regex_module_and_methods ... ok 1ms
tests/xsh/stdlib/path.xsh::test_path_edge_cases_and_standard_record_schema ... ok 145ms
tests/xsh/stdlib/set.xsh::test_set_module ... ok 3ms
tests/xsh/stdlib/shlex.xsh::test_shlex_quote_and_join ... ok 4ms
tests/xsh/stdlib/record.xsh::test_standard_record_schemas_reject_bad_dynamic_records ... ok 22ms
tests/xsh/stdlib/streams.xsh::test_flat_map_consumes_live_streams_returned_by_blocks ... ok 10ms
tests/xsh/stdlib/streams.xsh::test_direct_collect_of_lazy_module_stream_is_a_list ... ok 13ms
tests/xsh/stdlib/streams.xsh::test_if_else_is_a_stream_stage_tail_value ... ok 6ms
tests/xsh/stdlib/process.xsh::test_process_spawn_timeout_and_return_transfer ... ok 137ms
tests/xsh/stdlib/streams.xsh::test_implicit_standard_read_helpers_and_pipe_shorthand ... ok 12ms
tests/xsh/stdlib/streams.xsh::test_flat_map_identity_reduce_by_matches_direct_rows ... ok 21ms
tests/xsh/stdlib/streams.xsh::test_line_methods_and_adapters_are_lazy_sources ... ok 9ms
tests/xsh/stdlib/streams.xsh::test_core_commands_and_byte_pipeline ... ok 43ms
tests/xsh/stdlib/streams.xsh::test_parallel_stream_preserves_filtered_order ... ok 22ms
tests/xsh/stdlib/streams.xsh::test_parallel_stream_stages_are_bounded_and_deterministic ... ok 17ms
tests/xsh/stdlib/streams.xsh::test_predicate_stage_blocks_bind_local_lets ... ok 4ms
tests/xsh/stdlib/process.xsh::test_process_wait_and_handle_contracts ... ok 142ms
tests/xsh/stdlib/process.xsh::test_process_spawn_traces ... ok 176ms
tests/xsh/stdlib/streams.xsh::test_reduce_by_stream_aggregates ... ok 5ms
tests/xsh/stdlib/streams.xsh::test_sort_by_compound_record_keys_and_stability ... ok 2ms
tests/xsh/stdlib/streams.xsh::test_fs_files_lazy_folding_terminals_match_eager_results ... ok 67ms
tests/xsh/stdlib/streams.xsh::test_sort_by_desc_reverses_sort_order ... ok 1ms
tests/xsh/stdlib/streams.xsh::test_sort_by_map_accumulator_any_typed_fields ... ok 1ms
tests/xsh/stdlib/streams.xsh::test_projected_reduce_by_sums_output_fields ... ok 31ms
tests/xsh/stdlib/streams.xsh::test_stream_adapters_bridge_text_bytes_and_json_lines ... ok 18ms
tests/xsh/stdlib/streams.xsh::test_stream_adapters_and_transform_stages ... ok 28ms
tests/xsh/stdlib/streams.xsh::test_sort_by_rejects_non_orderable_keys_at_runtime ... ok 45ms
tests/xsh/stdlib/streams.xsh::test_stream_producers_are_lazy_and_run_defers_on_stop ... ok 36ms
tests/xsh/stdlib/streams.xsh::test_structured_stream_batch_count_and_argv_limits ... ok 43ms
tests/xsh/stdlib/streams.xsh::test_structured_streams_walk_filter_map_collect_and_count ... ok 41ms
tests/xsh/stdlib/streams.xsh::test_terminal_newline_does_not_add_empty_line_for_round_trip ... ok 3ms
tests/xsh/stdlib/system.xsh::test_system_module ... ok 6ms
tests/xsh/stdlib/test.xsh::test_error_fail_constructs_validation_result ... ok 4ms
tests/xsh/stdlib/streams.xsh::test_stream_errors_include_trace_context ... ok 116ms
tests/xsh/stdlib/streams.xsh::test_table_print_wraps_cells_to_terminal_width ... ok 44ms
tests/xsh/stdlib/streams.xsh::test_stream_stages_are_trace_observable ... ok 104ms
tests/xsh/stdlib/test.xsh::test_test_helpers ... ok 1ms
tests/xsh/stdlib/test.xsh::test_skip_function_is_covered ... skipped: covered skip 1ms
tests/xsh/stdlib/text.xsh::test_text_fields_replacement_and_counts ... ok 1ms
tests/xsh/stdlib/time.xsh::test_time_module ... ok 23ms
tests/xsh/stdlib/tui.xsh::test_tui_helpers ... ok 3ms
tests/xsh/stdlib/test.xsh::test_run_script_captures_status_env_args_and_bytes ... ok 58ms
tests/xsh/stdlib/test.xsh::test_run_xsht_trace_accepts_trace_flags_and_script_args ... ok 50ms
tests/xsh/stdlib/unix.xsh::test_wait_pid1_event_timeout_kind ... ok 3ms
tests/xsh/stdlib/time.xsh::test_time_module_formats_local_time_under_tz ... ok 65ms
tests/xsh/stdlib/tui.xsh::test_tui_read_secret_piped_lines ... ok 41ms
tests/xsh/stdlib/utils.xsh::test_utils_cache ... ok 2ms
tests/xsh/stdlib/user.xsh::test_user_lookup_and_mutation_contracts ... ok 50ms
tests/xsh/stdlib/unix.xsh::test_unix_dry_run_covers_module_surface ... ok 165ms
tests/xsh/stdlib/process.xsh::test_process_module ... ok 919ms
tests/xsh/stdlib/streams.xsh::test_parallel_count_and_group_by_match_serial ... ok 899ms
tests/xsh/stdlib/streams.xsh::test_par_map_reduce_by_fuses_to_worker_aggregation ... ok 934ms
tests/xsh/stdlib/streams.xsh::test_reduce_by_parallel_jobs_match_serial ... ok 2.5s

failures:

---- core/tests/test-ifdown.xsh ----
err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifdown.xsh:11:30
      pre-down echo "pre-down:$IFACE:$LOGICAL:$ADDRFAM:$METHOD" >> ${hook_log.display()}
                               ^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifdown.xsh:11:37
      pre-down echo "pre-down:$IFACE:$LOGICAL:$ADDRFAM:$METHOD" >> ${hook_log.display()}
                                      ^^^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifdown.xsh:11:46
      pre-down echo "pre-down:$IFACE:$LOGICAL:$ADDRFAM:$METHOD" >> ${hook_log.display()}
                                               ^^^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifdown.xsh:11:55
      pre-down echo "pre-down:$IFACE:$LOGICAL:$ADDRFAM:$METHOD" >> ${hook_log.display()}
                                                        ^^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifdown.xsh:12:22
      down echo "down:$IFACE:$IF_ADDRESS" >> ${hook_log.display()}
                       ^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifdown.xsh:12:29
      down echo "down:$IFACE:$IF_ADDRESS" >> ${hook_log.display()}
                              ^^^^^^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifdown.xsh:13:32
      post-down echo "post-down:$PHASE" >> ${hook_log.display()}
                                 ^^^^^ unresolved name

---- core/tests/test-ifup.xsh ----
err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifup.xsh:11:23
      pre-up echo "pre:$IFACE:$LOGICAL:$ADDRFAM:$METHOD" >> ${hook_log.display()}
                        ^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifup.xsh:11:30
      pre-up echo "pre:$IFACE:$LOGICAL:$ADDRFAM:$METHOD" >> ${hook_log.display()}
                               ^^^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifup.xsh:11:39
      pre-up echo "pre:$IFACE:$LOGICAL:$ADDRFAM:$METHOD" >> ${hook_log.display()}
                                        ^^^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifup.xsh:11:48
      pre-up echo "pre:$IFACE:$LOGICAL:$ADDRFAM:$METHOD" >> ${hook_log.display()}
                                                 ^^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifup.xsh:12:18
      up echo "up:$IFACE:$IF_ADDRESS:$IF_GATEWAY" >> ${hook_log.display()}
                   ^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifup.xsh:12:25
      up echo "up:$IFACE:$IF_ADDRESS:$IF_GATEWAY" >> ${hook_log.display()}
                          ^^^^^^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifup.xsh:12:37
      up echo "up:$IFACE:$IF_ADDRESS:$IF_GATEWAY" >> ${hook_log.display()}
                                      ^^^^^^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifup.xsh:13:25
      post-up echo "post:$PHASE" >> ${hook_log.display()}
                          ^^^^^ unresolved name

---- tests/xsh/stdlib/fs.xsh ----
err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/tests/xsh/stdlib/fs.xsh:53:8
  print $entry.size
         ^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/tests/xsh/stdlib/fs.xsh:417:8
  print $entry.size
         ^^^^^ unresolved name

---- tests/xsh/stdlib/methods.xsh::test_collection_number_text_status_and_result_methods ----
test-fail: expected error kind `parse-uint-positive`, found `parse-uint`

test result: FAILED. 311 passed; 4 failed; 6 skipped

stderr:

note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace


failures:
    runtime::coverage::xsh_native_tests

test result: FAILED. 0 passed; 1 failed; 0 ignored; 0 measured; 496 filtered out; finished in 33.62s

error: test failed, to rerun pass `--test integration`


Command exited with code 101
  - Structured report: `workers/engineer/task-histogram-009/report.json`
- `engineer/task-histogram-009`, turn `40`, tool `bash`:    Compiling xsh v0.0.1 (/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009)
   Compiling xsht v0.0.1 (/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/crates/xsht)
    Finished `test` profile [unoptimized] target(s) in 5.16s
     Running tests/integration.rs (target/debug/deps/integration-0d8e0e4a2df73a3f)

running 1 test
   Compiling xshi v0.0.1 (/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/crates/xshi)
   Compiling xsht v0.0.1 (/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/crates/xsht)
    Finished `dev` profile [unoptimized] target(s) in 2.06s
test runtime::coverage::xsh_native_tests ... FAILED

failures:

---- runtime::coverage::xsh_native_tests stdout ----

thread 'runtime::coverage::xsh_native_tests' (17101159) panicked at tests/runtime/coverage.rs:1577:5:
xsh native tests
stdout:
running 321 tests
core/tests/test-basename.xsh::test_basename_runs_as_executable_shebang_script ... skipped: /bin/xsh is not installed 4ms
core/tests/test-basename.xsh::test_basename_basic ... ok 133ms
core/tests/test-basename.xsh::test_basename_suffix_and_multiple ... ok 134ms
core/tests/test-cat.xsh::test_cat_file_and_stdin ... ok 176ms
core/tests/test-df.xsh::test_df_matches_alpine_kp ... skipped: Alpine-only df comparison 9ms
core/tests/test-cut.xsh::test_cut_fields ... ok 188ms
core/tests/test-df.xsh::test_df ... ok 59ms
core/tests/test-date.xsh::test_date_format ... ok 79ms
core/tests/test-cp.xsh::test_cp_file_and_recursive_dir ... ok 217ms
core/tests/test-chgrp.xsh::test_chgrp_current_group ... ok 224ms
core/tests/test-chown.xsh::test_chown_current_user ... ok 226ms
core/tests/test-env.xsh::test_env_uses_direct_xsh_shebang ... ok 4ms
core/tests/test-dirname.xsh::test_dirname ... ok 60ms
core/tests/test-chmod.xsh::test_chmod_recursive ... ok 255ms
core/tests/test-env.xsh::test_env_assignment_runs_command ... ok 54ms
core/tests/test-du.xsh::test_du_recursive_all_and_total ... ok 80ms
core/tests/test-env.xsh::test_env_split_string_as_single_shebang_arg_runs_command ... ok 65ms
core/tests/test-fd.xsh::test_fd_finds_by_name_extension_and_type ... ok 54ms
core/tests/test-env.xsh::test_env_split_string_runs_command ... ok 74ms
core/tests/test-du.xsh::test_du ... ok 105ms
core/tests/test-fd.xsh::test_fd_multiple_roots_exclude_depth_and_executable ... ok 48ms
core/tests/test-fold.xsh::test_fold_width ... ok 37ms
core/tests/test-ifdown.xsh ... FAILED 0ms
core/tests/test-ifup.xsh ... FAILED 0ms
core/tests/test-head.xsh::test_head_reads_stdin ... ok 34ms
core/tests/test-head.xsh::test_head_lines ... ok 40ms
core/tests/test-host.xsh::test_host_localhost ... ok 30ms
core/tests/test-getty.xsh::test_getty_requires_baud_and_tty ... ok 54ms
core/tests/test-hostname.xsh::test_hostname_short ... ok 31ms
core/tests/test-ip.xsh::test_ip_addr_smoke ... ok 37ms
core/tests/test-link.xsh::test_link ... ok 29ms
core/tests/test-fd.xsh::test_fd_hidden_and_glob ... ok 109ms
core/tests/test-mdev.xsh::test_mdev_wrapper_preserves_platform_boundary ... ok 31ms
core/tests/test-ln.xsh::test_ln_symbolic_force ... ok 39ms
core/tests/test-host.xsh::test_host_type_and_usage ... ok 79ms
core/tests/test-mkdir.xsh::test_mkdir ... ok 46ms
core/tests/test-mv.xsh::test_mv_file_and_target_directory ... ok 48ms
core/tests/test-nproc.xsh::test_nproc ... ok 42ms
core/tests/test-printenv.xsh::test_printenv_processes_all_names_before_missing_status ... ok 33ms
core/tests/test-pstree.xsh::test_pstree_default_prints_visible_root ... skipped: macOS pstree is unavailable 4ms
core/tests/test-passwd.xsh::test_passwd_rejects_extra_operands ... ok 78ms
core/tests/test-printenv.xsh::test_printenv_named ... ok 59ms
core/tests/test-paste.xsh::test_paste_parallel_serial_and_delimiters ... ok 92ms
core/tests/test-printf.xsh::test_printf_escapes_and_usage ... ok 78ms
core/tests/test-pwd.xsh::test_pwd ... ok 39ms
core/tests/test-paste.xsh::test_paste_reads_stdin_and_rejects_flags ... ok 114ms
core/tests/test-realpath.xsh::test_realpath ... ok 28ms
core/tests/test-printf.xsh::test_printf_strings_repeat_without_implicit_newline ... ok 110ms
core/tests/test-rev.xsh::test_rev_rejects_options ... ok 32ms
core/tests/test-ls.xsh::test_ls ... ok 188ms
core/tests/test-rg.xsh::test_rg_reports_matches_with_line_numbers ... ok 31ms
core/tests/test-readlink.xsh::test_readlink ... ok 93ms
core/tests/test-rev.xsh::test_rev_lines_files_and_stdin ... ok 76ms
core/tests/test-rm.xsh::test_rm_force_recursive ... ok 41ms
core/tests/test-rmdir.xsh::test_rmdir_parents ... ok 34ms
core/tests/test-seq.xsh::test_seq_range ... ok 44ms
core/tests/test-seq.xsh::test_seq_rejects_zero_step ... ok 45ms
core/tests/test-shuf.xsh::test_shuf_head_count ... ok 46ms
core/tests/test-rg.xsh::test_rg_count_and_filename ... ok 119ms
core/tests/test-pstree.xsh::test_pstree_rejects_unknown_pid ... ok 201ms
core/tests/test-split.xsh::test_split_lines ... ok 45ms
core/tests/test-seq.xsh::test_seq_descending_negative_separator_and_width ... ok 107ms
core/tests/test-sort.xsh::test_sort_unique_reverse ... ok 81ms
core/tests/test-strings.xsh::test_strings_min_len ... ok 64ms
core/tests/test-tail.xsh::test_tail_lines ... ok 32ms
core/tests/test-su.xsh::test_su_returns_failure_for_unknown_user ... ok 77ms
core/tests/test-rg.xsh::test_rg_word_line_pattern_and_globs ... ok 199ms
core/tests/test-tee.xsh::test_tee_input_file ... ok 33ms
core/tests/test-tee.xsh::test_tee_reads_stdin_and_appends ... ok 38ms
core/tests/test-stat.xsh::test_stat ... ok 113ms
core/tests/test-tr.xsh::test_tr_rejects_bad_usage ... ok 44ms
core/tests/test-touch.xsh::test_touch ... ok 72ms
core/tests/test-uname.xsh::test_uname_all ... ok 30ms
core/tests/test-uniq.xsh::test_uniq_counts ... ok 27ms
core/tests/test-tree.xsh::test_tree_supports_multiple_roots_and_rejects_flags ... ok 60ms
core/tests/test-wc.xsh::test_wc_counts ... ok 29ms
core/tests/test-wc.xsh::test_wc_reads_stdin ... ok 33ms
core/tests/test-which.xsh::test_which_processes_all_names_before_missing_status ... ok 30ms
core/tests/test-which.xsh::test_which_finds_shell ... ok 44ms
showcase/tests/test-backup-rotate.xsh::test_backup_rotate ... ok 34ms
showcase/tests/test-bump-version.xsh::test_bump_version_usage ... ok 39ms
showcase/tests/test-bench.xsh::test_bench ... ok 66ms
core/tests/test-tree.xsh::test_tree_renders_sorted_branches_and_symlinks ... ok 176ms
showcase/tests/test-archive-unpack.xsh::test_archive_unpack ... ok 112ms
showcase/tests/test-batch-rename.xsh::test_batch_rename ... ok 95ms
showcase/tests/test-bytes-inspect.xsh::test_bytes_inspect ... ok 43ms
core/tests/test-tar.xsh::test_tar_create_list_extract ... ok 265ms
showcase/tests/test-csv-query.xsh::test_csv_query ... ok 40ms
showcase/tests/test-df.xsh::test_showcase_df_kp_path ... ok 43ms
showcase/tests/test-dedup.xsh::test_dedup ... ok 50ms
showcase/tests/test-df.xsh::test_showcase_df_root ... ok 37ms
core/tests/test-tr.xsh::test_tr_translate_delete_squeeze_and_stdin ... ok 237ms
showcase/tests/test-ecount.xsh::test_ecount_can_sum_sizes ... ok 42ms
showcase/tests/test-ecount.xsh::test_ecount_counts_extensions ... ok 45ms
showcase/tests/test-file-report.xsh::test_file_report ... ok 31ms
showcase/tests/test-dot-env-run.xsh::test_dot_env_run ... ok 68ms
showcase/tests/test-env-diff.xsh::test_env_diff ... ok 38ms
showcase/tests/test-flamegraph.xsh::test_flamegraph ... ok 40ms
showcase/tests/test-git-digest.xsh::test_git_digest_usage ... ok 31ms
showcase/tests/test-hosts-ping.xsh::test_hosts_ping_usage ... ok 28ms
showcase/tests/test-file-audit.xsh::test_file_audit_findings ... ok 58ms
showcase/tests/test-hyperfine.xsh::test_hyperfine_usage ... ok 31ms
showcase/tests/test-jq.xsh::test_jq_arith_stream ... ok 198ms
showcase/tests/test-jq.xsh::test_jq_construct ... ok 198ms
showcase/tests/test-jq.xsh::test_jq_alt_and_try ... ok 368ms
showcase/tests/test-jq.xsh::test_jq_identity ... ok 203ms
showcase/tests/test-jq.xsh::test_jq_number_roundtrip ... ok 215ms
showcase/tests/test-jq.xsh::test_jq_pipe_index ... ok 179ms
showcase/tests/test-jq.xsh::test_jq_assign ... ok 735ms
showcase/tests/test-jq.xsh::test_jq_stream ... ok 188ms
showcase/tests/test-jq.xsh::test_jq_bindings ... ok 766ms
showcase/tests/test-json-diff.xsh::test_json_diff ... ok 38ms
core/tests/test-pstree.xsh::test_pstree_renders_tree_with_pid_labels ... ok 1.4s
showcase/tests/test-loc.xsh::test_loc ... ok 37ms
showcase/tests/test-jq.xsh::test_jq_defs ... ok 811ms
showcase/tests/test-music-convert.xsh::test_music_convert ... ok 44ms
showcase/tests/test-parse-log.xsh::test_parse_log ... ok 40ms
showcase/tests/test-perf-collapse.xsh::test_perf_collapse ... ok 46ms
showcase/tests/test-path-audit.xsh::test_path_audit_findings ... ok 87ms
showcase/tests/test-px.xsh::test_px_kill_requires_a_filter ... ok 103ms
showcase/tests/test-px.xsh::test_px_kill_signal_is_parse_bounded ... ok 56ms
showcase/tests/test-jq.xsh::test_jq_paths ... ok 853ms
showcase/tests/test-jq.xsh::test_jq_builtins ... ok 1.4s
showcase/tests/test-release-pack.xsh::test_release_pack ... ok 63ms
showcase/tests/test-rgrep.xsh::test_rgrep ... ok 40ms
showcase/tests/test-jq.xsh::test_jq_regex ... ok 1.2s
showcase/tests/test-secret-scan.xsh::test_secret_scan ... ok 27ms
showcase/tests/test-todo-scan.xsh::test_todo_scan ... ok 26ms
showcase/tests/test-px.xsh::test_px_finds_current_test_process ... ok 813ms
showcase/tests/test-wait-for.xsh::test_wait_for_usage ... ok 40ms
showcase/tests/test-watch-run.xsh::test_watch_run_once ... ok 66ms
showcase/tests/test-px.xsh::test_px_kill_accepts_numeric_signal ... ok 921ms
showcase/tests/test-webp-dir.xsh::test_webp_dir_help ... ok 39ms
showcase/tests/test-tokei.xsh::test_tokei_json_shape_counts_and_ignores ... ok 215ms
showcase/tests/test-px.xsh::test_px_kill_signals_default_matches ... ok 792ms
tests/xsh/basic.xsh::test_dns_mock ... ok 3ms
tests/xsh/basic.xsh::test_net_mock ... ok 2ms
tests/xsh/basic.xsh::test_pass ... ok 1ms
tests/xsh/basic.xsh::test_language_sugar_edge_cases ... ok 7ms
tests/xsh/basic.xsh::test_skip ... skipped: later 3ms
showcase/tests/test-jq.xsh::test_jq_strings ... ok 1.1s
showcase/tests/test-webp-dir.xsh::test_webp_dir_dry_run ... ok 104ms
tests/xsh/basic.xsh::test_temp ... ok 8ms
tests/xsh/collections.xsh::test_list_comprehension_basic_transform ... ok 1ms
tests/xsh/collections.xsh::test_list_comprehension_guard_can_produce_empty_list ... ok 1ms
tests/xsh/basic.xsh::test_process_command_builder ... ok 16ms
tests/xsh/collections.xsh::test_list_comprehension_with_record_destructuring ... ok 2ms
tests/xsh/collections.xsh::test_list_comprehension_with_guard_filters_elements ... ok 2ms
tests/xsh/collections.xsh::test_local_accumulator_field_mutation ... ok 2ms
tests/xsh/collections.xsh::test_ergonomic_sugar_pass_forms ... ok 10ms
tests/xsh/collections.xsh::test_nominal_error_payload_and_facet_patterns ... ok 2ms
showcase/tests/test-xfetch.xsh::test_xfetch_summary ... ok 41ms
tests/xsh/collections.xsh::test_compact_sugar_forms ... ok 30ms
tests/xsh/effects.xsh::test_io_covers_net ... ok 46ms
tests/xsh/effects.xsh::test_annotated_proc_not_flagged_by_linter ... ok 51ms
tests/xsh/effects.xsh::test_io_does_not_cover_time ... ok 52ms
tests/xsh/effects.xsh::test_correct_annotation_passes ... ok 68ms
tests/xsh/effects.xsh::test_linter_infers_fs_error ... ok 54ms
tests/xsh/effects.xsh::test_linter_infers_net ... ok 58ms
tests/xsh/effects.xsh::test_linter_infers_process_from_run ... ok 53ms
tests/xsh/effects.xsh::test_module_call_blocked_by_annotation ... ok 58ms
tests/xsh/effects.xsh::test_print_requires_no_effect ... ok 62ms
tests/xsh/effects.xsh::test_proc_to_proc_subset_passes ... ok 61ms
showcase/tests/test-run-retry.xsh::test_run_retry ... ok 531ms
tests/xsh/effects.xsh::test_restricted_cannot_call_unrestricted_proc ... ok 54ms
tests/xsh/implicit-result-return.xsh::test_implicit_result_return_in_par_map ... ok 3ms
tests/xsh/effects.xsh::test_question_mark_requires_error_effect ... ok 61ms
tests/xsh/effects.xsh::test_run_form_requires_process_effect ... ok 53ms
tests/xsh/implicit-result-return.xsh::test_result_alias_return_shape ... ok 2ms
tests/xsh/implicit-result-return.xsh::test_nested_result_calls_in_par_map ... ok 2ms
tests/xsh/implicit-result-return.xsh::test_result_return_shapes_agree ... ok 2ms
tests/xsh/effects.xsh::test_unrestricted_proc_unchecked ... ok 40ms
tests/xsh/implicit-result-return.xsh::test_explicit_result_return_shapes ... ok 32ms
tests/xsh/par-map-result.xsh::test_par_map_all_ok ... ok 3ms
tests/xsh/par-map-result.xsh::test_par_map_collect_all ... ok 3ms
showcase/tests/test-px.xsh::test_px_default_search_matches_executable_substrings ... ok 1.2s
tests/xsh/implicit-result-return.xsh::test_implicit_result_return_through_module ... ok 28ms
tests/xsh/retry.xsh::test_retry_attempts_are_traced ... ok 25ms
tests/xsh/retry.xsh::test_retry_attempt_defers_run_before_next_attempt ... ok 34ms
tests/xsh/run.xsh::test_boolean_operators_short_circuit ... ok 2ms
tests/xsh/retry.xsh::test_retry_exhaustion_returns_final_error ... ok 42ms
tests/xsh/retry.xsh::test_retry_repeats_until_attempt_succeeds ... ok 33ms
tests/xsh/run.xsh::test_command_proc_args_resolve_bare_value_references ... ok 1ms
tests/xsh/run.xsh::test_function_tail_values_return_declared_values ... ok 1ms
tests/xsh/implicit-result-return.xsh::test_value_returning_error_helper ... ok 57ms
tests/xsh/run.xsh::test_acceptance_tar_gzip_pipeline_writes_archive ... ok 26ms
tests/xsh/retry.xsh::test_return_inside_retry_returns_from_enclosing_proc ... ok 39ms
tests/xsh/run.xsh::test_grouped_multiline_run_invocation_executes ... ok 15ms
tests/xsh/formatter.xsh::test_fmt_fixture ... ok 103ms
tests/xsh/run.xsh::test_byte_pipeline_executes_without_shell_and_redirects_stdout ... ok 34ms
showcase/tests/test-px.xsh::test_px_returns_one_when_no_process_matches ... ok 911ms
tests/xsh/run.xsh::test_path_absolute_uses_current_runtime_cwd_without_existing_path ... ok 0ms
tests/xsh/run.xsh::test_invalid_utf8_text_capture_is_a_run_error ... ok 28ms
tests/xsh/run.xsh::test_foundation_literals_defers_streams_and_builders ... ok 48ms
tests/xsh/run.xsh::test_modules_are_not_command_namespaces ... ok 33ms
tests/xsh/run.xsh::test_large_stdout_capture_drains_and_limit_is_error ... ok 48ms
tests/xsh/run.xsh::test_result_unit_statements_propagate_by_default ... ok 2ms
tests/xsh/run.xsh::test_nested_traceback_includes_user_procs_and_pure_functions ... ok 45ms
tests/xsh/run.xsh::test_run_builtin_unknown_name_returns_process_error ... ok 1ms
tests/xsh/run.xsh::test_pipeline_status_preserves_exec_failure_and_broken_pipe_segments ... ok 35ms
tests/xsh/run.xsh::test_run_builtin_forms_execute_like_plain_run_forms ... ok 70ms
tests/xsh/run.xsh::test_plain_run_updates_last_status_and_direct_binding ... ok 85ms
tests/xsh/run.xsh::test_run_capture_record_captures_status_stdout_and_stderr ... ok 85ms
tests/xsh/run.xsh::test_run_status_can_drive_conditions ... ok 56ms
tests/xsh/run.xsh::test_run_timeout_error ... ok 46ms
tests/xsh/run.xsh::test_script_stdout_can_emit_invalid_utf8_bytes ... ok 0ms
tests/xsh/run.xsh::test_legacy_test_and_getopt_spellings_are_not_command_aliases ... ok 189ms
tests/xsh/run.xsh::test_run_fixture_behaviors ... ok 138ms
tests/xsh/run.xsh::test_run_text_captures_stdout_and_inherits_stderr ... ok 80ms
tests/xsh/run.xsh::test_signaled_status_exposes_total_signal_helpers ... ok 60ms
tests/xsh/run.xsh::test_nul_run_targets_proc_splice_and_match_diagnostics ... ok 247ms
tests/xsh/run.xsh::test_redirection_paths_and_fd_duplication_use_typed_boundaries ... ok 223ms
tests/xsh/run.xsh::test_signaled_status_exit_code_is_structured_error ... ok 77ms
tests/xsh/stdlib/archive.xsh::test_archive_zip_error_contracts ... ok 3ms
tests/xsh/stdlib/args.xsh::test_args_parse_tokens_and_commands ... ok 2ms
tests/xsh/stdlib/args.xsh::test_cli_applet_last_scalar_occurrence_wins ... ok 2ms
tests/xsh/stdlib/args.xsh::test_cli_applet_parses_cp_compatibility_flags ... ok 2ms
tests/xsh/stdlib/args.xsh::test_cli_applet_parses_fd_clusters_and_repeated_values ... ok 4ms
tests/xsh/stdlib/args.xsh::test_cli_applet_parses_head_attached_value ... ok 1ms
tests/xsh/stdlib/args.xsh::test_cli_applet_parses_rg_long_assignment_and_attached_values ... ok 2ms
tests/xsh/stdlib/args.xsh::test_cli_applet_parses_sort_cluster_and_attached_values ... ok 2ms
tests/xsh/stdlib/args.xsh::test_cli_commands_accept_aliases_forms_and_options ... ok 2ms
tests/xsh/run.xsh::test_pipeline_failures_and_trace_are_visible ... ok 283ms
tests/xsh/stdlib/args.xsh::test_cli_parse_compact_forms ... ok 3ms
tests/xsh/stdlib/args.xsh::test_cli_parse_advanced_descriptors ... ok 13ms
tests/xsh/stdlib/auth.xsh::test_applet_mdev_scans_empty_roots ... skipped: mdev is Linux-only 3ms
tests/xsh/run.xsh::test_trace_output_covers_baseline_event_kinds ... ok 117ms
tests/xsh/run.xsh::test_whole_script_cli_usage_and_auto_main_errors ... ok 119ms
tests/xsh/stdlib/auth.xsh::test_auth_lib_passwd_and_shadow_parse_render ... ok 18ms
tests/xsh/stdlib/bytes.xsh::test_bytes_methods_and_decode_errors ... ok 3ms
tests/xsh/stdlib/cpu.xsh::test_cpu_count ... ok 3ms
tests/xsh/stdlib/bytes.xsh::test_bytes_construction_encoding_and_copy ... ok 13ms
tests/xsh/stdlib/dns.xsh::test_dns_module_with_mocks ... ok 3ms
tests/xsh/stdlib/diff.xsh::test_diff_unified ... ok 11ms
tests/xsh/run.xsh::test_whole_script_run_error_diagnostics ... ok 78ms
tests/xsh/stdlib/elf.xsh::test_elf_inspect ... ok 12ms
tests/xsh/stdlib/fs.xsh ... FAILED 0ms
tests/xsh/stdlib/archive.xsh::test_archive_tar_cpio_and_compression ... ok 80ms
tests/xsh/run.xsh::test_run_trace_reports_redirection_method_and_env_details ... ok 174ms
tests/xsh/stdlib/hash.xsh::test_hash_digests_checksums_and_digest_methods ... ok 11ms
tests/xsh/stdlib/ini.xsh::test_ini_decode_encode_and_files ... ok 6ms
tests/xsh/stdlib/json.xsh::test_json_decode_type_patterns_and_public_boundaries ... ok 2ms
tests/xsh/stdlib/json.xsh::test_json_path_helpers_report_invalid_paths ... ok 1ms
tests/xsh/stdlib/env.xsh::test_env_functions_and_path_list ... ok 32ms
tests/xsh/stdlib/json.xsh::test_json_read_write_lines_and_paths ... ok 6ms
tests/xsh/stdlib/env.xsh::test_path_literals_method_sugar_and_expr_env_blocks ... ok 36ms
tests/xsh/stdlib/map.xsh::test_map_module_and_methods ... ok 2ms
tests/xsh/stdlib/group.xsh::test_group_lookup_and_mutation_contracts ... ok 50ms
tests/xsh/stdlib/env.xsh::test_env_overlays_blocks_lookup_and_path_mutation_affect_children ... ok 59ms
tests/xsh/stdlib/mime.xsh::test_mime_lookup_and_parse ... ok 4ms
tests/xsh/stdlib/json.xsh::test_json_rejection_is_trace_visible ... ok 34ms
tests/xsh/stdlib/net.xsh::test_net_module_with_mocks ... ok 4ms
tests/xsh/stdlib/methods.xsh::test_collection_number_text_status_and_result_methods ... ok 23ms
tests/xsh/stdlib/module.xsh::test_module_load ... ok 10ms
tests/xsh/stdlib/path.xsh::test_membership_operator_supports_strings_lists_bytes_and_paths ... ok 2ms
tests/xsh/stdlib/path.xsh::test_path_absolute ... ok 3ms
tests/xsh/stdlib/patch.xsh::test_patch_apply ... ok 11ms
tests/xsh/run.xsh::test_whole_script_exit_status_and_abort_behavior ... ok 176ms
tests/xsh/stdlib/linux.xsh::test_linux_dry_run_covers_module_surface ... ok 73ms
tests/xsh/stdlib/path.xsh::test_absolute_glob_traverses_symlinked_literal_components ... ok 38ms
tests/xsh/stdlib/process.xsh::test_process_spawn_setup_errors ... ok 8ms
tests/xsh/stdlib/path.xsh::test_path_methods ... ok 42ms
tests/xsh/stdlib/process.xsh::test_process_timeout_errors ... ok 17ms
tests/xsh/stdlib/io.xsh::test_io_stdin_text_line_bytes_and_stdout ... ok 132ms
tests/xsh/stdlib/record.xsh::test_record_require_and_any_require ... ok 5ms
tests/xsh/stdlib/auth.xsh::test_applet_auth_helpers_and_sessions ... ok 208ms
tests/xsh/stdlib/record.xsh::test_schema_runtime_checks_unknown_values ... ok 35ms
tests/xsh/stdlib/regex.xsh::test_regex_module_and_methods ... ok 1ms
tests/xsh/stdlib/set.xsh::test_set_module ... ok 2ms
tests/xsh/stdlib/shlex.xsh::test_shlex_quote_and_join ... ok 1ms
tests/xsh/stdlib/path.xsh::test_path_edge_cases_and_standard_record_schema ... ok 129ms
tests/xsh/stdlib/record.xsh::test_standard_record_schemas_reject_bad_dynamic_records ... ok 38ms
tests/xsh/stdlib/process.xsh::test_process_command_redirections ... ok 142ms
tests/xsh/stdlib/streams.xsh::test_direct_collect_of_lazy_module_stream_is_a_list ... ok 20ms
tests/xsh/stdlib/streams.xsh::test_flat_map_consumes_live_streams_returned_by_blocks ... ok 20ms
tests/xsh/stdlib/streams.xsh::test_if_else_is_a_stream_stage_tail_value ... ok 1ms
tests/xsh/stdlib/streams.xsh::test_core_commands_and_byte_pipeline ... ok 54ms
tests/xsh/stdlib/streams.xsh::test_implicit_standard_read_helpers_and_pipe_shorthand ... ok 19ms
tests/xsh/stdlib/streams.xsh::test_flat_map_identity_reduce_by_matches_direct_rows ... ok 37ms
tests/xsh/stdlib/process.xsh::test_process_spawn_timeout_and_return_transfer ... ok 184ms
tests/xsh/stdlib/process.xsh::test_process_wait_and_handle_contracts ... ok 174ms
tests/xsh/stdlib/streams.xsh::test_line_methods_and_adapters_are_lazy_sources ... ok 67ms
tests/xsh/stdlib/streams.xsh::test_parallel_stream_preserves_filtered_order ... ok 36ms
tests/xsh/stdlib/streams.xsh::test_parallel_stream_stages_are_bounded_and_deterministic ... ok 17ms
tests/xsh/stdlib/streams.xsh::test_predicate_stage_blocks_bind_local_lets ... ok 11ms
tests/xsh/stdlib/streams.xsh::test_fs_files_lazy_folding_terminals_match_eager_results ... ok 115ms
tests/xsh/stdlib/streams.xsh::test_reduce_by_stream_aggregates ... ok 5ms
tests/xsh/stdlib/streams.xsh::test_sort_by_compound_record_keys_and_stability ... ok 4ms
tests/xsh/stdlib/streams.xsh::test_sort_by_desc_reverses_sort_order ... ok 4ms
tests/xsh/stdlib/streams.xsh::test_sort_by_map_accumulator_any_typed_fields ... ok 2ms
tests/xsh/stdlib/streams.xsh::test_stream_adapters_and_transform_stages ... ok 12ms
tests/xsh/stdlib/streams.xsh::test_sort_by_rejects_non_orderable_keys_at_runtime ... ok 44ms
tests/xsh/stdlib/streams.xsh::test_stream_adapters_bridge_text_bytes_and_json_lines ... ok 31ms
tests/xsh/stdlib/process.xsh::test_process_spawn_traces ... ok 281ms
tests/xsh/stdlib/streams.xsh::test_projected_reduce_by_sums_output_fields ... ok 86ms
tests/xsh/stdlib/streams.xsh::test_structured_stream_batch_count_and_argv_limits ... ok 22ms
tests/xsh/stdlib/streams.xsh::test_stream_producers_are_lazy_and_run_defers_on_stop ... ok 49ms
tests/xsh/stdlib/streams.xsh::test_structured_streams_walk_filter_map_collect_and_count ... ok 11ms
tests/xsh/stdlib/streams.xsh::test_terminal_newline_does_not_add_empty_line_for_round_trip ... ok 1ms
tests/xsh/stdlib/streams.xsh::test_stream_errors_include_trace_context ... ok 63ms
tests/xsh/stdlib/system.xsh::test_system_module ... ok 2ms
tests/xsh/stdlib/test.xsh::test_error_fail_constructs_validation_result ... ok 2ms
tests/xsh/stdlib/streams.xsh::test_table_print_wraps_cells_to_terminal_width ... ok 25ms
tests/xsh/stdlib/test.xsh::test_skip_function_is_covered ... skipped: covered skip 1ms
tests/xsh/stdlib/streams.xsh::test_stream_stages_are_trace_observable ... ok 72ms
tests/xsh/stdlib/test.xsh::test_test_helpers ... ok 2ms
tests/xsh/stdlib/text.xsh::test_text_fields_replacement_and_counts ... ok 1ms
tests/xsh/stdlib/time.xsh::test_time_module ... ok 24ms
tests/xsh/stdlib/tui.xsh::test_tui_helpers ... ok 3ms
tests/xsh/stdlib/time.xsh::test_time_module_formats_local_time_under_tz ... ok 46ms
tests/xsh/stdlib/tui.xsh::test_tui_read_secret_piped_lines ... ok 32ms
tests/xsh/stdlib/unix.xsh::test_wait_pid1_event_timeout_kind ... ok 2ms
tests/xsh/stdlib/test.xsh::test_run_script_captures_status_env_args_and_bytes ... ok 78ms
tests/xsh/stdlib/utils.xsh::test_utils_cache ... ok 1ms
tests/xsh/stdlib/test.xsh::test_run_xsht_trace_accepts_trace_flags_and_script_args ... ok 79ms
tests/xsh/stdlib/user.xsh::test_user_lookup_and_mutation_contracts ... ok 40ms
tests/xsh/stdlib/unix.xsh::test_unix_dry_run_covers_module_surface ... ok 133ms
tests/xsh/stdlib/process.xsh::test_process_module ... ok 1.2s
tests/xsh/stdlib/streams.xsh::test_parallel_count_and_group_by_match_serial ... ok 1.1s
tests/xsh/stdlib/streams.xsh::test_par_map_reduce_by_fuses_to_worker_aggregation ... ok 1.1s
tests/xsh/stdlib/streams.xsh::test_reduce_by_parallel_jobs_match_serial ... ok 2.7s

failures:

---- core/tests/test-ifdown.xsh ----
err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifdown.xsh:11:30
      pre-down echo "pre-down:$IFACE:$LOGICAL:$ADDRFAM:$METHOD" >> ${hook_log.display()}
                               ^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifdown.xsh:11:37
      pre-down echo "pre-down:$IFACE:$LOGICAL:$ADDRFAM:$METHOD" >> ${hook_log.display()}
                                      ^^^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifdown.xsh:11:46
      pre-down echo "pre-down:$IFACE:$LOGICAL:$ADDRFAM:$METHOD" >> ${hook_log.display()}
                                               ^^^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifdown.xsh:11:55
      pre-down echo "pre-down:$IFACE:$LOGICAL:$ADDRFAM:$METHOD" >> ${hook_log.display()}
                                                        ^^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifdown.xsh:12:22
      down echo "down:$IFACE:$IF_ADDRESS" >> ${hook_log.display()}
                       ^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifdown.xsh:12:29
      down echo "down:$IFACE:$IF_ADDRESS" >> ${hook_log.display()}
                              ^^^^^^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifdown.xsh:13:32
      post-down echo "post-down:$PHASE" >> ${hook_log.display()}
                                 ^^^^^ unresolved name

---- core/tests/test-ifup.xsh ----
err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifup.xsh:11:23
      pre-up echo "pre:$IFACE:$LOGICAL:$ADDRFAM:$METHOD" >> ${hook_log.display()}
                        ^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifup.xsh:11:30
      pre-up echo "pre:$IFACE:$LOGICAL:$ADDRFAM:$METHOD" >> ${hook_log.display()}
                               ^^^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifup.xsh:11:39
      pre-up echo "pre:$IFACE:$LOGICAL:$ADDRFAM:$METHOD" >> ${hook_log.display()}
                                        ^^^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifup.xsh:11:48
      pre-up echo "pre:$IFACE:$LOGICAL:$ADDRFAM:$METHOD" >> ${hook_log.display()}
                                                 ^^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifup.xsh:12:18
      up echo "up:$IFACE:$IF_ADDRESS:$IF_GATEWAY" >> ${hook_log.display()}
                   ^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifup.xsh:12:25
      up echo "up:$IFACE:$IF_ADDRESS:$IF_GATEWAY" >> ${hook_log.display()}
                          ^^^^^^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifup.xsh:12:37
      up echo "up:$IFACE:$IF_ADDRESS:$IF_GATEWAY" >> ${hook_log.display()}
                                      ^^^^^^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifup.xsh:13:25
      post-up echo "post:$PHASE" >> ${hook_log.display()}
                          ^^^^^ unresolved name

---- tests/xsh/stdlib/fs.xsh ----
err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/tests/xsh/stdlib/fs.xsh:53:8
  print $entry.size
         ^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/tests/xsh/stdlib/fs.xsh:417:8
  print $entry.size
         ^^^^^ unresolved name

test result: FAILED. 312 passed; 3 failed; 6 skipped

stderr:

note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace


failures:
    runtime::coverage::xsh_native_tests

test result: FAILED. 0 passed; 1 failed; 0 ignored; 0 measured; 496 filtered out; finished in 33.21s

error: test failed, to rerun pass `--test integration`


Command exited with code 101
  - Structured report: `workers/engineer/task-histogram-009/report.json`
- `engineer/task-histogram-009`, turn `47`, tool `bash`:    Compiling xsh-registry v0.0.1 (/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/crates/xsh-registry)
    Finished `test` profile [unoptimized] target(s) in 0.78s
     Running unittests src/lib.rs (target/debug/deps/xsh_registry-ba9b80b8ad461f45)

running 8 tests
test types::tests::core_builtin_symbol_table_matches_builtin_type_names ... ok
test types::tests::builtin_type_names_round_trip_through_parser ... ok
test signature::tests::record_and_language_registry_docs_are_complete ... ok
test signature::tests::public_api_items_have_complete_registry_docs ... ok
test symbols::tests::preloaded_symbols_start_with_fixed_core_symbols ... ok
test symbols::tests::semantic_symbols_cover_registry_surfaces ... ok
test symbols::tests::preloaded_symbols_cover_builtin_type_names ... ok
test symbols::tests::preloaded_symbols_are_unique_nonempty_ascii ... ok

test result: ok. 8 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.01s

   Compiling xsh v0.0.1 (/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009)
   Compiling xsht v0.0.1 (/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/crates/xsht)
    Finished `test` profile [unoptimized] target(s) in 5.93s
     Running tests/integration.rs (target/debug/deps/integration-0d8e0e4a2df73a3f)

running 1 test
   Compiling xshi v0.0.1 (/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/crates/xshi)
   Compiling xsht v0.0.1 (/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/crates/xsht)
    Finished `dev` profile [unoptimized] target(s) in 2.09s
test runtime::coverage::xsh_native_tests ... FAILED

failures:

---- runtime::coverage::xsh_native_tests stdout ----

thread 'runtime::coverage::xsh_native_tests' (17114561) panicked at tests/runtime/coverage.rs:1577:5:
xsh native tests
stdout:
running 321 tests
core/tests/test-basename.xsh::test_basename_runs_as_executable_shebang_script ... skipped: /bin/xsh is not installed 4ms
core/tests/test-basename.xsh::test_basename_basic ... ok 134ms
core/tests/test-basename.xsh::test_basename_suffix_and_multiple ... ok 135ms
core/tests/test-cut.xsh::test_cut_fields ... ok 137ms
core/tests/test-df.xsh::test_df_matches_alpine_kp ... skipped: Alpine-only df comparison 4ms
core/tests/test-df.xsh::test_df ... ok 52ms
core/tests/test-cat.xsh::test_cat_file_and_stdin ... ok 196ms
core/tests/test-chown.xsh::test_chown_current_user ... ok 201ms
core/tests/test-date.xsh::test_date_format ... ok 74ms
core/tests/test-chgrp.xsh::test_chgrp_current_group ... ok 209ms
core/tests/test-dirname.xsh::test_dirname ... ok 71ms
core/tests/test-env.xsh::test_env_uses_direct_xsh_shebang ... ok 5ms
core/tests/test-cp.xsh::test_cp_file_and_recursive_dir ... ok 223ms
core/tests/test-chmod.xsh::test_chmod_recursive ... ok 255ms
core/tests/test-fd.xsh::test_fd_finds_by_name_extension_and_type ... ok 44ms
core/tests/test-env.xsh::test_env_assignment_runs_command ... ok 67ms
core/tests/test-env.xsh::test_env_split_string_as_single_shebang_arg_runs_command ... ok 60ms
core/tests/test-env.xsh::test_env_split_string_runs_command ... ok 66ms
core/tests/test-du.xsh::test_du_recursive_all_and_total ... ok 80ms
core/tests/test-du.xsh::test_du ... ok 91ms
core/tests/test-fd.xsh::test_fd_multiple_roots_exclude_depth_and_executable ... ok 39ms
core/tests/test-fold.xsh::test_fold_width ... ok 27ms
core/tests/test-ifdown.xsh ... FAILED 0ms
core/tests/test-ifup.xsh ... FAILED 0ms
core/tests/test-head.xsh::test_head_lines ... ok 33ms
core/tests/test-host.xsh::test_host_localhost ... ok 30ms
core/tests/test-getty.xsh::test_getty_requires_baud_and_tty ... ok 44ms
core/tests/test-head.xsh::test_head_reads_stdin ... ok 38ms
core/tests/test-hostname.xsh::test_hostname_short ... ok 23ms
core/tests/test-fd.xsh::test_fd_hidden_and_glob ... ok 99ms
core/tests/test-ip.xsh::test_ip_addr_smoke ... ok 29ms
core/tests/test-link.xsh::test_link ... ok 28ms
core/tests/test-host.xsh::test_host_type_and_usage ... ok 59ms
core/tests/test-ln.xsh::test_ln_symbolic_force ... ok 32ms
core/tests/test-mdev.xsh::test_mdev_wrapper_preserves_platform_boundary ... ok 31ms
core/tests/test-mkdir.xsh::test_mkdir ... ok 34ms
core/tests/test-nproc.xsh::test_nproc ... ok 32ms
core/tests/test-mv.xsh::test_mv_file_and_target_directory ... ok 43ms
core/tests/test-passwd.xsh::test_passwd_rejects_extra_operands ... ok 55ms
core/tests/test-pstree.xsh::test_pstree_default_prints_visible_root ... skipped: macOS pstree is unavailable 7ms
core/tests/test-printenv.xsh::test_printenv_processes_all_names_before_missing_status ... ok 42ms
core/tests/test-paste.xsh::test_paste_parallel_serial_and_delimiters ... ok 74ms
core/tests/test-printenv.xsh::test_printenv_named ... ok 67ms
core/tests/test-paste.xsh::test_paste_reads_stdin_and_rejects_flags ... ok 96ms
core/tests/test-pwd.xsh::test_pwd ... ok 34ms
core/tests/test-printf.xsh::test_printf_escapes_and_usage ... ok 90ms
core/tests/test-ls.xsh::test_ls ... ok 145ms
core/tests/test-realpath.xsh::test_realpath ... ok 30ms
core/tests/test-printf.xsh::test_printf_strings_repeat_without_implicit_newline ... ok 102ms
core/tests/test-rev.xsh::test_rev_rejects_options ... ok 30ms
core/tests/test-rg.xsh::test_rg_reports_matches_with_line_numbers ... ok 33ms
core/tests/test-readlink.xsh::test_readlink ... ok 91ms
core/tests/test-rm.xsh::test_rm_force_recursive ... ok 35ms
core/tests/test-rev.xsh::test_rev_lines_files_and_stdin ... ok 75ms
core/tests/test-rmdir.xsh::test_rmdir_parents ... ok 33ms
core/tests/test-seq.xsh::test_seq_range ... ok 26ms
core/tests/test-rg.xsh::test_rg_count_and_filename ... ok 93ms
core/tests/test-seq.xsh::test_seq_rejects_zero_step ... ok 30ms
core/tests/test-shuf.xsh::test_shuf_head_count ... ok 43ms
core/tests/test-split.xsh::test_split_lines ... ok 46ms
core/tests/test-pstree.xsh::test_pstree_rejects_unknown_pid ... ok 208ms
core/tests/test-sort.xsh::test_sort_unique_reverse ... ok 68ms
core/tests/test-seq.xsh::test_seq_descending_negative_separator_and_width ... ok 109ms
core/tests/test-strings.xsh::test_strings_min_len ... ok 41ms
core/tests/test-tail.xsh::test_tail_lines ... ok 44ms
core/tests/test-rg.xsh::test_rg_word_line_pattern_and_globs ... ok 180ms
core/tests/test-tee.xsh::test_tee_input_file ... ok 44ms
core/tests/test-su.xsh::test_su_returns_failure_for_unknown_user ... ok 62ms
core/tests/test-tee.xsh::test_tee_reads_stdin_and_appends ... ok 50ms
core/tests/test-stat.xsh::test_stat ... ok 116ms
core/tests/test-tr.xsh::test_tr_rejects_bad_usage ... ok 38ms
core/tests/test-uname.xsh::test_uname_all ... ok 28ms
core/tests/test-touch.xsh::test_touch ... ok 67ms
core/tests/test-uniq.xsh::test_uniq_counts ... ok 34ms
core/tests/test-wc.xsh::test_wc_counts ... ok 32ms
core/tests/test-tree.xsh::test_tree_supports_multiple_roots_and_rejects_flags ... ok 74ms
core/tests/test-which.xsh::test_which_finds_shell ... ok 28ms
core/tests/test-wc.xsh::test_wc_reads_stdin ... ok 36ms
core/tests/test-which.xsh::test_which_processes_all_names_before_missing_status ... ok 52ms
core/tests/test-tree.xsh::test_tree_renders_sorted_branches_and_symlinks ... ok 129ms
showcase/tests/test-bump-version.xsh::test_bump_version_usage ... ok 34ms
showcase/tests/test-backup-rotate.xsh::test_backup_rotate ... ok 80ms
showcase/tests/test-bench.xsh::test_bench ... ok 58ms
showcase/tests/test-batch-rename.xsh::test_batch_rename ... ok 91ms
showcase/tests/test-archive-unpack.xsh::test_archive_unpack ... ok 100ms
showcase/tests/test-bytes-inspect.xsh::test_bytes_inspect ... ok 39ms
core/tests/test-tar.xsh::test_tar_create_list_extract ... ok 257ms
core/tests/test-tr.xsh::test_tr_translate_delete_squeeze_and_stdin ... ok 218ms
showcase/tests/test-csv-query.xsh::test_csv_query ... ok 47ms
showcase/tests/test-df.xsh::test_showcase_df_root ... ok 35ms
showcase/tests/test-df.xsh::test_showcase_df_kp_path ... ok 43ms
showcase/tests/test-dedup.xsh::test_dedup ... ok 52ms
showcase/tests/test-ecount.xsh::test_ecount_can_sum_sizes ... ok 50ms
showcase/tests/test-env-diff.xsh::test_env_diff ... ok 44ms
showcase/tests/test-ecount.xsh::test_ecount_counts_extensions ... ok 46ms
showcase/tests/test-dot-env-run.xsh::test_dot_env_run ... ok 66ms
showcase/tests/test-file-report.xsh::test_file_report ... ok 47ms
showcase/tests/test-flamegraph.xsh::test_flamegraph ... ok 40ms
showcase/tests/test-git-digest.xsh::test_git_digest_usage ... ok 28ms
showcase/tests/test-file-audit.xsh::test_file_audit_findings ... ok 68ms
showcase/tests/test-hosts-ping.xsh::test_hosts_ping_usage ... ok 26ms
showcase/tests/test-hyperfine.xsh::test_hyperfine_usage ... ok 34ms
showcase/tests/test-jq.xsh::test_jq_arith_stream ... ok 201ms
showcase/tests/test-jq.xsh::test_jq_construct ... ok 189ms
showcase/tests/test-jq.xsh::test_jq_identity ... ok 161ms
showcase/tests/test-jq.xsh::test_jq_alt_and_try ... ok 393ms
showcase/tests/test-jq.xsh::test_jq_number_roundtrip ... ok 184ms
showcase/tests/test-jq.xsh::test_jq_pipe_index ... ok 294ms
showcase/tests/test-jq.xsh::test_jq_assign ... ok 836ms
showcase/tests/test-jq.xsh::test_jq_stream ... ok 263ms
showcase/tests/test-json-diff.xsh::test_json_diff ... ok 65ms
showcase/tests/test-loc.xsh::test_loc ... ok 37ms
showcase/tests/test-jq.xsh::test_jq_bindings ... ok 1.0s
showcase/tests/test-parse-log.xsh::test_parse_log ... ok 30ms
showcase/tests/test-music-convert.xsh::test_music_convert ... ok 40ms
showcase/tests/test-perf-collapse.xsh::test_perf_collapse ... ok 43ms
showcase/tests/test-path-audit.xsh::test_path_audit_findings ... ok 56ms
showcase/tests/test-jq.xsh::test_jq_defs ... ok 1.1s
core/tests/test-pstree.xsh::test_pstree_renders_tree_with_pid_labels ... ok 1.7s
showcase/tests/test-px.xsh::test_px_kill_requires_a_filter ... ok 53ms
showcase/tests/test-px.xsh::test_px_kill_signal_is_parse_bounded ... ok 49ms
showcase/tests/test-jq.xsh::test_jq_builtins ... ok 1.4s
showcase/tests/test-jq.xsh::test_jq_paths ... ok 1.0s
showcase/tests/test-release-pack.xsh::test_release_pack ... ok 56ms
showcase/tests/test-rgrep.xsh::test_rgrep ... ok 55ms
showcase/tests/test-jq.xsh::test_jq_regex ... ok 1.2s
showcase/tests/test-secret-scan.xsh::test_secret_scan ... ok 40ms
showcase/tests/test-todo-scan.xsh::test_todo_scan ... ok 106ms
showcase/tests/test-px.xsh::test_px_finds_current_test_process ... ok 838ms
showcase/tests/test-tokei.xsh::test_tokei_json_shape_counts_and_ignores ... ok 241ms
showcase/tests/test-wait-for.xsh::test_wait_for_usage ... ok 23ms
showcase/tests/test-jq.xsh::test_jq_strings ... ok 1.2s
showcase/tests/test-run-retry.xsh::test_run_retry ... ok 549ms
showcase/tests/test-watch-run.xsh::test_watch_run_once ... ok 69ms
tests/xsh/basic.xsh::test_dns_mock ... ok 7ms
showcase/tests/test-px.xsh::test_px_kill_accepts_numeric_signal ... ok 927ms
tests/xsh/basic.xsh::test_net_mock ... ok 3ms
tests/xsh/basic.xsh::test_pass ... ok 3ms
showcase/tests/test-webp-dir.xsh::test_webp_dir_dry_run ... ok 88ms
tests/xsh/basic.xsh::test_language_sugar_edge_cases ... ok 15ms
tests/xsh/basic.xsh::test_skip ... skipped: later 3ms
showcase/tests/test-webp-dir.xsh::test_webp_dir_help ... ok 34ms
tests/xsh/basic.xsh::test_process_command_builder ... ok 15ms
tests/xsh/basic.xsh::test_temp ... ok 9ms
tests/xsh/collections.xsh::test_list_comprehension_basic_transform ... ok 2ms
showcase/tests/test-xfetch.xsh::test_xfetch_summary ... ok 35ms
tests/xsh/collections.xsh::test_list_comprehension_with_guard_filters_elements ... ok 3ms
tests/xsh/collections.xsh::test_list_comprehension_guard_can_produce_empty_list ... ok 4ms
tests/xsh/collections.xsh::test_list_comprehension_with_record_destructuring ... ok 5ms
tests/xsh/collections.xsh::test_local_accumulator_field_mutation ... ok 2ms
tests/xsh/collections.xsh::test_nominal_error_payload_and_facet_patterns ... ok 3ms
tests/xsh/collections.xsh::test_ergonomic_sugar_pass_forms ... ok 15ms
showcase/tests/test-px.xsh::test_px_kill_signals_default_matches ... ok 839ms
tests/xsh/collections.xsh::test_compact_sugar_forms ... ok 40ms
tests/xsh/effects.xsh::test_annotated_proc_not_flagged_by_linter ... ok 40ms
tests/xsh/effects.xsh::test_io_covers_net ... ok 40ms
tests/xsh/effects.xsh::test_correct_annotation_passes ... ok 49ms
tests/xsh/effects.xsh::test_io_does_not_cover_time ... ok 52ms
tests/xsh/effects.xsh::test_linter_infers_net ... ok 31ms
tests/xsh/effects.xsh::test_linter_infers_fs_error ... ok 35ms
tests/xsh/effects.xsh::test_linter_infers_process_from_run ... ok 32ms
tests/xsh/effects.xsh::test_module_call_blocked_by_annotation ... ok 34ms
tests/xsh/effects.xsh::test_print_requires_no_effect ... ok 31ms
tests/xsh/effects.xsh::test_proc_to_proc_subset_passes ... ok 30ms
tests/xsh/effects.xsh::test_question_mark_requires_error_effect ... ok 31ms
tests/xsh/effects.xsh::test_restricted_cannot_call_unrestricted_proc ... ok 32ms
tests/xsh/implicit-result-return.xsh::test_implicit_result_return_in_par_map ... ok 2ms
tests/xsh/implicit-result-return.xsh::test_nested_result_calls_in_par_map ... ok 2ms
tests/xsh/implicit-result-return.xsh::test_result_alias_return_shape ... ok 1ms
tests/xsh/implicit-result-return.xsh::test_result_return_shapes_agree ... ok 1ms
tests/xsh/effects.xsh::test_run_form_requires_process_effect ... ok 30ms
tests/xsh/par-map-result.xsh::test_par_map_all_ok ... ok 1ms
tests/xsh/effects.xsh::test_unrestricted_proc_unchecked ... ok 32ms
tests/xsh/par-map-result.xsh::test_par_map_collect_all ... ok 4ms
tests/xsh/implicit-result-return.xsh::test_explicit_result_return_shapes ... ok 22ms
tests/xsh/implicit-result-return.xsh::test_implicit_result_return_through_module ... ok 21ms
showcase/tests/test-px.xsh::test_px_default_search_matches_executable_substrings ... ok 1.1s
tests/xsh/retry.xsh::test_retry_attempt_defers_run_before_next_attempt ... ok 23ms
tests/xsh/retry.xsh::test_retry_attempts_are_traced ... ok 29ms
tests/xsh/run.xsh::test_boolean_operators_short_circuit ... ok 2ms
tests/xsh/implicit-result-return.xsh::test_value_returning_error_helper ... ok 43ms
tests/xsh/run.xsh::test_command_proc_args_resolve_bare_value_references ... ok 3ms
tests/xsh/retry.xsh::test_retry_exhaustion_returns_final_error ... ok 38ms
tests/xsh/run.xsh::test_function_tail_values_return_declared_values ... ok 2ms
tests/xsh/retry.xsh::test_retry_repeats_until_attempt_succeeds ... ok 36ms
tests/xsh/formatter.xsh::test_fmt_fixture ... ok 79ms
tests/xsh/retry.xsh::test_return_inside_retry_returns_from_enclosing_proc ... ok 33ms
tests/xsh/run.xsh::test_grouped_multiline_run_invocation_executes ... ok 21ms
tests/xsh/run.xsh::test_byte_pipeline_executes_without_shell_and_redirects_stdout ... ok 35ms
tests/xsh/run.xsh::test_acceptance_tar_gzip_pipeline_writes_archive ... ok 47ms
tests/xsh/run.xsh::test_invalid_utf8_text_capture_is_a_run_error ... ok 33ms
tests/xsh/run.xsh::test_path_absolute_uses_current_runtime_cwd_without_existing_path ... ok 2ms
tests/xsh/run.xsh::test_foundation_literals_defers_streams_and_builders ... ok 41ms
tests/xsh/run.xsh::test_modules_are_not_command_namespaces ... ok 24ms
tests/xsh/run.xsh::test_nested_traceback_includes_user_procs_and_pure_functions ... ok 25ms
tests/xsh/run.xsh::test_pipeline_status_preserves_exec_failure_and_broken_pipe_segments ... ok 23ms
tests/xsh/run.xsh::test_result_unit_statements_propagate_by_default ... ok 4ms
showcase/tests/test-px.xsh::test_px_returns_one_when_no_process_matches ... ok 940ms
tests/xsh/run.xsh::test_run_builtin_unknown_name_returns_process_error ... ok 1ms
tests/xsh/run.xsh::test_large_stdout_capture_drains_and_limit_is_error ... ok 65ms
tests/xsh/run.xsh::test_legacy_test_and_getopt_spellings_are_not_command_aliases ... ok 88ms
tests/xsh/run.xsh::test_plain_run_updates_last_status_and_direct_binding ... ok 60ms
tests/xsh/run.xsh::test_run_builtin_forms_execute_like_plain_run_forms ... ok 53ms
tests/xsh/run.xsh::test_run_capture_record_captures_status_stdout_and_stderr ... ok 79ms
tests/xsh/run.xsh::test_run_status_can_drive_conditions ... ok 57ms
tests/xsh/run.xsh::test_script_stdout_can_emit_invalid_utf8_bytes ... ok 1ms
tests/xsh/run.xsh::test_nul_run_targets_proc_splice_and_match_diagnostics ... ok 133ms
tests/xsh/run.xsh::test_run_timeout_error ... ok 47ms
tests/xsh/run.xsh::test_run_text_captures_stdout_and_inherits_stderr ... ok 86ms
tests/xsh/run.xsh::test_run_fixture_behaviors ... ok 129ms
tests/xsh/run.xsh::test_signaled_status_exposes_total_signal_helpers ... ok 54ms
tests/xsh/run.xsh::test_signaled_status_exit_code_is_structured_error ... ok 91ms
tests/xsh/run.xsh::test_pipeline_failures_and_trace_are_visible ... ok 214ms
tests/xsh/stdlib/archive.xsh::test_archive_zip_error_contracts ... ok 4ms
tests/xsh/stdlib/args.xsh::test_args_parse_tokens_and_commands ... ok 2ms
tests/xsh/run.xsh::test_redirection_paths_and_fd_duplication_use_typed_boundaries ... ok 206ms
tests/xsh/stdlib/args.xsh::test_cli_applet_last_scalar_occurrence_wins ... ok 3ms
tests/xsh/run.xsh::test_trace_output_covers_baseline_event_kinds ... ok 94ms
tests/xsh/stdlib/args.xsh::test_cli_applet_parses_cp_compatibility_flags ... ok 3ms
tests/xsh/stdlib/args.xsh::test_cli_applet_parses_head_attached_value ... ok 3ms
tests/xsh/stdlib/args.xsh::test_cli_applet_parses_fd_clusters_and_repeated_values ... ok 3ms
tests/xsh/stdlib/args.xsh::test_cli_applet_parses_rg_long_assignment_and_attached_values ... ok 3ms
tests/xsh/stdlib/args.xsh::test_cli_applet_parses_sort_cluster_and_attached_values ... ok 2ms
tests/xsh/stdlib/args.xsh::test_cli_commands_accept_aliases_forms_and_options ... ok 3ms
tests/xsh/stdlib/args.xsh::test_cli_parse_compact_forms ... ok 2ms
tests/xsh/stdlib/auth.xsh::test_applet_mdev_scans_empty_roots ... skipped: mdev is Linux-only 2ms
tests/xsh/stdlib/auth.xsh::test_auth_lib_passwd_and_shadow_parse_render ... ok 17ms
tests/xsh/run.xsh::test_whole_script_cli_usage_and_auto_main_errors ... ok 109ms
tests/xsh/stdlib/bytes.xsh::test_bytes_construction_encoding_and_copy ... ok 15ms
tests/xsh/run.xsh::test_whole_script_run_error_diagnostics ... ok 89ms
tests/xsh/stdlib/bytes.xsh::test_bytes_methods_and_decode_errors ... ok 5ms
tests/xsh/stdlib/cpu.xsh::test_cpu_count ... ok 3ms
tests/xsh/stdlib/dns.xsh::test_dns_module_with_mocks ... ok 3ms
tests/xsh/run.xsh::test_run_trace_reports_redirection_method_and_env_details ... ok 161ms
tests/xsh/stdlib/args.xsh::test_cli_parse_advanced_descriptors ... ok 49ms
tests/xsh/stdlib/diff.xsh::test_diff_unified ... ok 9ms
tests/xsh/stdlib/fs.xsh ... FAILED 0ms
tests/xsh/stdlib/elf.xsh::test_elf_inspect ... ok 16ms
tests/xsh/stdlib/hash.xsh::test_hash_digests_checksums_and_digest_methods ... ok 14ms
tests/xsh/stdlib/ini.xsh::test_ini_decode_encode_and_files ... ok 3ms
tests/xsh/stdlib/env.xsh::test_env_functions_and_path_list ... ok 39ms
tests/xsh/stdlib/archive.xsh::test_archive_tar_cpio_and_compression ... ok 102ms
tests/xsh/stdlib/json.xsh::test_json_path_helpers_report_invalid_paths ... ok 4ms
tests/xsh/stdlib/env.xsh::test_path_literals_method_sugar_and_expr_env_blocks ... ok 43ms
tests/xsh/stdlib/group.xsh::test_group_lookup_and_mutation_contracts ... ok 43ms
tests/xsh/stdlib/json.xsh::test_json_decode_type_patterns_and_public_boundaries ... ok 7ms
tests/xsh/run.xsh::test_whole_script_exit_status_and_abort_behavior ... ok 153ms
tests/xsh/stdlib/env.xsh::test_env_overlays_blocks_lookup_and_path_mutation_affect_children ... ok 44ms
tests/xsh/stdlib/map.xsh::test_map_module_and_methods ... ok 2ms
tests/xsh/stdlib/mime.xsh::test_mime_lookup_and_parse ... ok 4ms
tests/xsh/stdlib/json.xsh::test_json_read_write_lines_and_paths ... ok 11ms
tests/xsh/stdlib/net.xsh::test_net_module_with_mocks ... ok 6ms
tests/xsh/stdlib/module.xsh::test_module_load ... ok 12ms
tests/xsh/stdlib/path.xsh::test_membership_operator_supports_strings_lists_bytes_and_paths ... ok 2ms
tests/xsh/stdlib/patch.xsh::test_patch_apply ... ok 7ms
tests/xsh/stdlib/path.xsh::test_path_absolute ... ok 1ms
tests/xsh/stdlib/methods.xsh::test_collection_number_text_status_and_result_methods ... ok 19ms
tests/xsh/stdlib/json.xsh::test_json_rejection_is_trace_visible ... ok 28ms
tests/xsh/stdlib/path.xsh::test_absolute_glob_traverses_symlinked_literal_components ... ok 24ms
tests/xsh/stdlib/process.xsh::test_process_spawn_setup_errors ... ok 1ms
tests/xsh/stdlib/path.xsh::test_path_methods ... ok 28ms
tests/xsh/stdlib/linux.xsh::test_linux_dry_run_covers_module_surface ... ok 56ms
tests/xsh/stdlib/io.xsh::test_io_stdin_text_line_bytes_and_stdout ... ok 83ms
tests/xsh/stdlib/process.xsh::test_process_timeout_errors ... ok 16ms
tests/xsh/stdlib/record.xsh::test_record_require_and_any_require ... ok 1ms
tests/xsh/stdlib/auth.xsh::test_applet_auth_helpers_and_sessions ... ok 171ms
tests/xsh/stdlib/record.xsh::test_schema_runtime_checks_unknown_values ... ok 25ms
tests/xsh/stdlib/regex.xsh::test_regex_module_and_methods ... ok 1ms
tests/xsh/stdlib/set.xsh::test_set_module ... ok 1ms
tests/xsh/stdlib/shlex.xsh::test_shlex_quote_and_join ... ok 1ms
tests/xsh/stdlib/process.xsh::test_process_command_redirections ... ok 98ms
tests/xsh/stdlib/record.xsh::test_standard_record_schemas_reject_bad_dynamic_records ... ok 52ms
tests/xsh/stdlib/path.xsh::test_path_edge_cases_and_standard_record_schema ... ok 130ms
tests/xsh/stdlib/streams.xsh::test_core_commands_and_byte_pipeline ... ok 45ms
tests/xsh/stdlib/streams.xsh::test_flat_map_consumes_live_streams_returned_by_blocks ... ok 22ms
tests/xsh/stdlib/streams.xsh::test_direct_collect_of_lazy_module_stream_is_a_list ... ok 42ms
tests/xsh/stdlib/streams.xsh::test_if_else_is_a_stream_stage_tail_value ... ok 7ms
tests/xsh/stdlib/streams.xsh::test_implicit_standard_read_helpers_and_pipe_shorthand ... ok 20ms
tests/xsh/stdlib/streams.xsh::test_line_methods_and_adapters_are_lazy_sources ... ok 18ms
tests/xsh/stdlib/streams.xsh::test_flat_map_identity_reduce_by_matches_direct_rows ... ok 35ms
tests/xsh/stdlib/streams.xsh::test_parallel_stream_preserves_filtered_order ... ok 15ms
tests/xsh/stdlib/process.xsh::test_process_spawn_timeout_and_return_transfer ... ok 164ms
tests/xsh/stdlib/process.xsh::test_process_wait_and_handle_contracts ... ok 162ms
tests/xsh/stdlib/streams.xsh::test_parallel_stream_stages_are_bounded_and_deterministic ... ok 35ms
tests/xsh/stdlib/streams.xsh::test_predicate_stage_blocks_bind_local_lets ... ok 32ms
tests/xsh/stdlib/streams.xsh::test_reduce_by_stream_aggregates ... ok 2ms
tests/xsh/stdlib/streams.xsh::test_sort_by_compound_record_keys_and_stability ... ok 1ms
tests/xsh/stdlib/streams.xsh::test_sort_by_desc_reverses_sort_order ... ok 1ms
tests/xsh/stdlib/streams.xsh::test_fs_files_lazy_folding_terminals_match_eager_results ... ok 92ms
tests/xsh/stdlib/streams.xsh::test_sort_by_map_accumulator_any_typed_fields ... ok 2ms
tests/xsh/stdlib/streams.xsh::test_stream_adapters_and_transform_stages ... ok 4ms
tests/xsh/stdlib/streams.xsh::test_projected_reduce_by_sums_output_fields ... ok 28ms
tests/xsh/stdlib/process.xsh::test_process_spawn_traces ... ok 213ms
tests/xsh/stdlib/streams.xsh::test_stream_adapters_bridge_text_bytes_and_json_lines ... ok 16ms
tests/xsh/stdlib/streams.xsh::test_sort_by_rejects_non_orderable_keys_at_runtime ... ok 23ms
tests/xsh/stdlib/streams.xsh::test_structured_stream_batch_count_and_argv_limits ... ok 20ms
tests/xsh/stdlib/streams.xsh::test_stream_producers_are_lazy_and_run_defers_on_stop ... ok 34ms
tests/xsh/stdlib/streams.xsh::test_structured_streams_walk_filter_map_collect_and_count ... ok 23ms
tests/xsh/stdlib/streams.xsh::test_terminal_newline_does_not_add_empty_line_for_round_trip ... ok 4ms
tests/xsh/stdlib/system.xsh::test_system_module ... ok 5ms
tests/xsh/stdlib/test.xsh::test_error_fail_constructs_validation_result ... ok 1ms
tests/xsh/stdlib/streams.xsh::test_stream_errors_include_trace_context ... ok 63ms
tests/xsh/stdlib/streams.xsh::test_table_print_wraps_cells_to_terminal_width ... ok 27ms
tests/xsh/stdlib/test.xsh::test_skip_function_is_covered ... skipped: covered skip 1ms
tests/xsh/stdlib/test.xsh::test_test_helpers ... ok 1ms
tests/xsh/stdlib/text.xsh::test_text_fields_replacement_and_counts ... ok 2ms
tests/xsh/stdlib/time.xsh::test_time_module ... ok 23ms
tests/xsh/stdlib/test.xsh::test_run_xsht_trace_accepts_trace_flags_and_script_args ... ok 36ms
tests/xsh/stdlib/tui.xsh::test_tui_helpers ... ok 2ms
tests/xsh/stdlib/test.xsh::test_run_script_captures_status_env_args_and_bytes ... ok 50ms
tests/xsh/stdlib/streams.xsh::test_stream_stages_are_trace_observable ... ok 108ms
tests/xsh/stdlib/unix.xsh::test_wait_pid1_event_timeout_kind ... ok 2ms
tests/xsh/stdlib/time.xsh::test_time_module_formats_local_time_under_tz ... ok 40ms
tests/xsh/stdlib/utils.xsh::test_utils_cache ... ok 2ms
tests/xsh/stdlib/tui.xsh::test_tui_read_secret_piped_lines ... ok 46ms
tests/xsh/stdlib/user.xsh::test_user_lookup_and_mutation_contracts ... ok 42ms
tests/xsh/stdlib/unix.xsh::test_unix_dry_run_covers_module_surface ... ok 185ms
tests/xsh/stdlib/process.xsh::test_process_module ... ok 1.1s
tests/xsh/stdlib/streams.xsh::test_parallel_count_and_group_by_match_serial ... ok 1.1s
tests/xsh/stdlib/streams.xsh::test_par_map_reduce_by_fuses_to_worker_aggregation ... ok 1.2s
tests/xsh/stdlib/streams.xsh::test_reduce_by_parallel_jobs_match_serial ... ok 2.7s

failures:

---- core/tests/test-ifdown.xsh ----
err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifdown.xsh:11:30
      pre-down echo "pre-down:$IFACE:$LOGICAL:$ADDRFAM:$METHOD" >> ${hook_log.display()}
                               ^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifdown.xsh:11:37
      pre-down echo "pre-down:$IFACE:$LOGICAL:$ADDRFAM:$METHOD" >> ${hook_log.display()}
                                      ^^^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifdown.xsh:11:46
      pre-down echo "pre-down:$IFACE:$LOGICAL:$ADDRFAM:$METHOD" >> ${hook_log.display()}
                                               ^^^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifdown.xsh:11:55
      pre-down echo "pre-down:$IFACE:$LOGICAL:$ADDRFAM:$METHOD" >> ${hook_log.display()}
                                                        ^^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifdown.xsh:12:22
      down echo "down:$IFACE:$IF_ADDRESS" >> ${hook_log.display()}
                       ^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifdown.xsh:12:29
      down echo "down:$IFACE:$IF_ADDRESS" >> ${hook_log.display()}
                              ^^^^^^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifdown.xsh:13:32
      post-down echo "post-down:$PHASE" >> ${hook_log.display()}
                                 ^^^^^ unresolved name

---- core/tests/test-ifup.xsh ----
err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifup.xsh:11:23
      pre-up echo "pre:$IFACE:$LOGICAL:$ADDRFAM:$METHOD" >> ${hook_log.display()}
                        ^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifup.xsh:11:30
      pre-up echo "pre:$IFACE:$LOGICAL:$ADDRFAM:$METHOD" >> ${hook_log.display()}
                               ^^^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifup.xsh:11:39
      pre-up echo "pre:$IFACE:$LOGICAL:$ADDRFAM:$METHOD" >> ${hook_log.display()}
                                        ^^^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifup.xsh:11:48
      pre-up echo "pre:$IFACE:$LOGICAL:$ADDRFAM:$METHOD" >> ${hook_log.display()}
                                                 ^^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifup.xsh:12:18
      up echo "up:$IFACE:$IF_ADDRESS:$IF_GATEWAY" >> ${hook_log.display()}
                   ^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifup.xsh:12:25
      up echo "up:$IFACE:$IF_ADDRESS:$IF_GATEWAY" >> ${hook_log.display()}
                          ^^^^^^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifup.xsh:12:37
      up echo "up:$IFACE:$IF_ADDRESS:$IF_GATEWAY" >> ${hook_log.display()}
                                      ^^^^^^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/core/tests/test-ifup.xsh:13:25
      post-up echo "post:$PHASE" >> ${hook_log.display()}
                          ^^^^^ unresolved name

---- tests/xsh/stdlib/fs.xsh ----
err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/tests/xsh/stdlib/fs.xsh:53:8
  print $entry.size
         ^^^^^ unresolved name

err[check.unresolved-name]: unresolved name
  /Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009/tests/xsh/stdlib/fs.xsh:417:8
  print $entry.size
         ^^^^^ unresolved name

test result: FAILED. 312 passed; 3 failed; 6 skipped

stderr:

note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace


failures:
    runtime::coverage::xsh_native_tests

test result: FAILED. 0 passed; 1 failed; 0 ignored; 0 measured; 496 filtered out; finished in 33.22s

error: test failed, to rerun pass `--test integration`


Command exited with code 101
  - Structured report: `workers/engineer/task-histogram-009/report.json`


### Cycle total

- Workers: `2`
- Assistant turns: `64`
- Bucket tokens: `3860379`
- Cost (USD): `0.079366`
- Nonzero tool results: `5`
- Budget failures or unknown costs: `0`


## Employee decisions

### director/director

- Role: `director`
- Result: `pass`
- Report: `workers/director/director/REPORT.md`

#### Efficiency and evidence

Mode: `ticket-implementation`. One approved product ticket was admitted and
dispatched: `task-histogram-009` (Change target `product`). The controller
created the isolated worktree
`/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786218719345/task-histogram-009`
on the source branch `factory/task-histogram-009/1786218728914`, wrote the
immutable assignment manifest
`phases/01-ticket/dispatch/engineer-task-histogram-009.json`, and launched the
single engineer row through the shared runner
(`FACTORY_DIRECTOR_RECONCILE_ONLY=true`). No other child rows were requested.
The plan: implement the admitted ticket in the isolated worktree, capture its
branch and commit, and leave both pending CTO review (review-only phase; no
merge performed here).

#### Handbook or proposal decision

not reported

#### Ticket or product decision

not reported

#### Next action

- Engineer `REPORT.md` (required narrative): present and valid — result
  `ready-for-review`, branch and commit recorded.
- Engineer `report.json`: present and valid — `result: pass`, `state:
  completed`.
- Implementation branch: present in XSH repo —
  `factory/task-histogram-009/1786218728914` resolves to
  `0fe019e450adc63f59418f14806b8e6951abe6a4`.
- Implementation commit: present and is the branch head — worktree log shows
  `0fe019e Add typed positive unsigned integer parsing` on base `df60bdb`.
- Ticket scope: declared `product`, matches the implemented change.
- Worktree retained for CTO review
  (`FACTORY_RETAIN_WORKTREE=true`); the controller captures the portable patch
  in its own reconciliation.

#### North-star impact

This cycle produced a real, additive product improvement: `Str.parse_uint_positive()`
gives agents a typed, discoverable way to express a `> 0` (positive-exclusive)
integer contract. The ticket's hypothesis — that positive boundaries recur
across systems glue and were previously only expressible via a division-by-zero
SIGFPE abort — is directly addressed by a small additive parse-conversion
method, matching the handbook's "prefer a typed conversion" guidance without
changing existing parse behavior or adding a broader error-constructor
proposal. Native tests for the new surface pass.

Uncertainty: the cycle is review-only, so this branch is not merged and the
product change is not yet validated against its linked `task-histogram` replay
or the independent numeric-parse eval. The full native corpus still reports
pre-existing baseline failures in `core/tests/test-ifup.xsh`,
`core/tests/test-ifdown.xsh`, and `tests/xsh/stdlib/fs.xsh` (unrelated
unresolved-name fixtures), so corpus-wide green is not attributable to this
change. The next falsification replay (engineer branch merge, then linked
`task-histogram` replay) will determine whether the typed positive parser
actually removes the signal-abort path while keeping all nine cases byte-exact.

### engineer/task-histogram-009

- Role: `engineer`
- Result: `ready-for-review`
- Report: `workers/engineer/task-histogram-009/REPORT.md`

#### Efficiency and evidence

- `cargo test -p xsh-registry --lib` — passed (8 tests).
- `cargo test --test integration runtime::modules --no-default-features` — passed (34 passed, 2 ignored).
- `cargo test --test integration runtime::coverage::xsh_native_tests --no-default-features` — positive parser tests passed; suite has 3 pre-existing unrelated failures in `core/tests/test-ifup.xsh`, `core/tests/test-ifdown.xsh`, and `tests/xsh/stdlib/fs.xsh`.
- `cargo build -p xsh -p xsht --bin xsh --bin xsht` — passed.
- `target/debug/xsht api method:Str.parse_uint_positive` — exact discoverable API entry.
- Manual script check/run — valid input prints `42`; zero input exits nonzero with empty stdout and typed runtime traceback.
- `git diff --check` — passed; worktree clean after commit.

#### Handbook or proposal decision

not reported

#### Ticket or product decision

The full native corpus remains blocked by the three unrelated baseline fixture failures listed above. The new parser returns the existing `Int` representation for positive values and deliberately accepts only decimal digits without trimming or signs.

#### Next action

not reported

#### North-star impact

Adds a discoverable, typed `Str.parse_uint_positive()` conversion for strict `> 0` decimal contracts. Agents can reject zero and malformed or signed input through an explicit Result/error boundary instead of using a division-by-zero signal workaround, improving clarity, learnability, and reliability for widths, sizes, counts, ports, and durations while preserving existing parse behavior.



## Eval proposal review

No CTO eval review was recorded.

## Handbook lineage

Checked-in `runtime/handbook.md`: `9822e4305181e651c4a587b64afd487074216fae532c9a678f25a4d2f59fb3f8`
- approved snapshot: `factory-source/handbook-approved.md` sha256 `9822e4305181e651c4a587b64afd487074216fae532c9a678f25a4d2f59fb3f8` — promoted by CTO ledger; matches checked-in handbook
- approved snapshot: `lineage/handbook-approved.md` sha256 `9822e4305181e651c4a587b64afd487074216fae532c9a678f25a4d2f59fb3f8` — promoted by CTO ledger; matches checked-in handbook
- candidate: `lineage/handbook-candidate.md` sha256 `9822e4305181e651c4a587b64afd487074216fae532c9a678f25a4d2f59fb3f8` — promoted by CTO ledger; matches checked-in handbook


## Historical handbook backlog

Historical candidates: 115; differing: 90; ledger-dispositioned: 90; unresolved: 0.
No unresolved candidate content is present.

## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
