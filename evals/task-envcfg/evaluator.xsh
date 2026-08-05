##! Package-owned evaluator for task-envcfg.

use factory.control as control

proc copy_results(artifact: Str) [fs, error] -> Result[Unit] {
  # /session and /export are two views of the same host worker directory.
  for name in [artifact, "review.md"] {
    let src = fp"/work/${name}"
    if fs.exists(src)? {
      fs.copy(src, fp"/export/${name}", overwrite: true)?
    }
  }
}

proc check_review(work_dir: Path) [fs, error] -> Result[Bool] {
  let review_file = fp"${work_dir}/review.md"
  if ! fs.exists(review_file)? {
    return false
  }
  let meta = fs.metadata(review_file)?
  if meta.size == 0 {
    return false
  }
  let text = fs.read_text(review_file)?
  return text.contains("## XSH language proposals") and text.contains("## xsht friction") and
    ! text.contains("\n### <title>\n") and
    ! text.contains("\n**Rationale.** What fell short for this task.") and
    ! text.contains("\n**Symptom.** What you queried or ran and what came back.")
}
type EnvcfgCase = {name: Str, env: Record, expect_fail: Bool}

type EnvcfgCaseResult = {exact: Bool, candidate_wall_ns: Int, oracle_wall_ns: Int}

proc run_envcfg_case(index: Int, case: EnvcfgCase) [fs, process, time, error] -> Result[EnvcfgCaseResult] {
  let out_path = fp"/tmp/envcfg-out.${index}"
  fs.remove(out_path, missing_ok: true)?
  let candidate = time.measure(process.command_argv(
    "xsh", ["xsh", "/work/envcfg.xsh", out_path.display()],
    env: case.env,
    stdout: fp"/session/candidate.${index}.stdout", stderr: fp"/session/candidate.${index}.stderr",
  ))?
  let oracle = time.measure(process.command_argv(
    "sh", ["sh", "/tmp/envcfg-oracle.sh"],
    env: case.env,
    stdout: fp"/session/oracle.${index}.stdout", stderr: fp"/session/oracle.${index}.stderr",
  ))?
  let exact = if case.expect_fail {
    ! candidate.status.ok and ! oracle.status.ok and ! fs.exists(out_path)?
  } else {
    candidate.status.ok and oracle.status.ok and fs.exists(out_path)? and
      fs.read_text(out_path)? == fs.read_text(fp"/session/oracle.${index}.stdout")?
  }
  return {exact: exact, candidate_wall_ns: candidate.wall_ns, oracle_wall_ns: oracle.wall_ns}
}

proc run_task_envcfg() [fs, process, env, time, error, io] -> Result[Int] {
  defer copy_results("envcfg.xsh")?
  var eval_status = 0
  let artifact_present = fs.exists(p"/work/envcfg.xsh")?
  var review_ok = false
  var forbidden_operations = false
  var env_referenced = false
  var all_exact = false
  var public_exact = false
  var hidden_defaults_exact = false
  var hidden_partial_exact = false
  var hidden_empty_exact = false
  var hidden_spaces_exact = false
  var hidden_zero_exact = false
  var hidden_utf8_exact = false
  var hidden_debug_false_exact = false
  var hidden_malformed_exact = false
  var hidden_empty_port_exact = false
  var public_candidate_wall_ns = 0
  var public_oracle_wall_ns = 0
  var hidden_defaults_candidate_wall_ns = 0
  var hidden_defaults_oracle_wall_ns = 0
  var hidden_partial_candidate_wall_ns = 0
  var hidden_partial_oracle_wall_ns = 0
  var hidden_empty_candidate_wall_ns = 0
  var hidden_empty_oracle_wall_ns = 0
  var hidden_spaces_candidate_wall_ns = 0
  var hidden_spaces_oracle_wall_ns = 0
  var hidden_zero_candidate_wall_ns = 0
  var hidden_zero_oracle_wall_ns = 0
  var hidden_utf8_candidate_wall_ns = 0
  var hidden_utf8_oracle_wall_ns = 0
  var hidden_debug_false_candidate_wall_ns = 0
  var hidden_debug_false_oracle_wall_ns = 0
  var hidden_malformed_candidate_wall_ns = 0
  var hidden_malformed_oracle_wall_ns = 0
  var hidden_empty_port_candidate_wall_ns = 0
  var hidden_empty_port_oracle_wall_ns = 0

  if artifact_present {
    fs.write(p"/tmp/envcfg-oracle.sh", r"""#!/bin/sh
case "${CFG_PORT-8080}" in
  *[!0-9]*|"") exit 1 ;;
esac
printf 'host=%s\nport=%s\ndebug=%s\n' "${CFG_HOST-localhost}" "${CFG_PORT-8080}" "${CFG_DEBUG-false}"
""")?
    let cases: List[EnvcfgCase] = [
      {name: "public", env: {CFG_HOST: "node-a", CFG_PORT: "9001", CFG_DEBUG: "true"}, expect_fail: false},
      {name: "hidden_defaults", env: {}, expect_fail: false},
      {name: "hidden_partial", env: {CFG_HOST: "api"}, expect_fail: false},
      {name: "hidden_empty", env: {CFG_HOST: ""}, expect_fail: false},
      {name: "hidden_spaces", env: {CFG_HOST: "us east 1", CFG_DEBUG: "true"}, expect_fail: false},
      {name: "hidden_zero", env: {CFG_PORT: "0"}, expect_fail: false},
      {name: "hidden_utf8", env: {CFG_HOST: "héllo wörld"}, expect_fail: false},
      {name: "hidden_debug_false", env: {CFG_DEBUG: "false"}, expect_fail: false},
      {name: "hidden_malformed", env: {CFG_PORT: "abc"}, expect_fail: true},
      {name: "hidden_empty_port", env: {CFG_PORT: ""}, expect_fail: true},
    ]
    var index = 0
    for case in cases {
      index += 1
      let result = run_envcfg_case(index, case)?
      if case.name == "public" {
        public_exact = result.exact
        public_candidate_wall_ns = result.candidate_wall_ns
        public_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_defaults" {
        hidden_defaults_exact = result.exact
        hidden_defaults_candidate_wall_ns = result.candidate_wall_ns
        hidden_defaults_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_partial" {
        hidden_partial_exact = result.exact
        hidden_partial_candidate_wall_ns = result.candidate_wall_ns
        hidden_partial_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_empty" {
        hidden_empty_exact = result.exact
        hidden_empty_candidate_wall_ns = result.candidate_wall_ns
        hidden_empty_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_spaces" {
        hidden_spaces_exact = result.exact
        hidden_spaces_candidate_wall_ns = result.candidate_wall_ns
        hidden_spaces_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_zero" {
        hidden_zero_exact = result.exact
        hidden_zero_candidate_wall_ns = result.candidate_wall_ns
        hidden_zero_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_utf8" {
        hidden_utf8_exact = result.exact
        hidden_utf8_candidate_wall_ns = result.candidate_wall_ns
        hidden_utf8_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_debug_false" {
        hidden_debug_false_exact = result.exact
        hidden_debug_false_candidate_wall_ns = result.candidate_wall_ns
        hidden_debug_false_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_malformed" {
        hidden_malformed_exact = result.exact
        hidden_malformed_candidate_wall_ns = result.candidate_wall_ns
        hidden_malformed_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_empty_port" {
        hidden_empty_port_exact = result.exact
        hidden_empty_port_candidate_wall_ns = result.candidate_wall_ns
        hidden_empty_port_oracle_wall_ns = result.oracle_wall_ns
      }
    }
    all_exact = public_exact and hidden_defaults_exact and hidden_partial_exact and
      hidden_empty_exact and hidden_spaces_exact and hidden_zero_exact and
      hidden_utf8_exact and hidden_debug_false_exact and hidden_malformed_exact and
      hidden_empty_port_exact
    let source = fs.read_text(p"/work/envcfg.xsh")?
    forbidden_operations = ! control.source_has_forbidden_subprocess(source)
    env_referenced = source.contains("env.")
    if ! all_exact or ! forbidden_operations or ! env_referenced {
      eval_status = 1
    }
    if all_exact and forbidden_operations and env_referenced {
      print "task-envcfg evaluation passed"
    } else {
      eprint "task-envcfg evaluation failed"
    }
  } else {
    eprint "pi completed without creating /work/envcfg.xsh"
    eval_status = 1
  }

  review_ok = check_review(p"/work")?
  if ! review_ok {
    eprint "task-envcfg evaluation failed: review.md missing or incomplete"
    eval_status = 1
  }
  let correctness_ok = artifact_present and all_exact
  let restriction_ok = artifact_present and forbidden_operations and env_referenced
  let classification = if ! artifact_present {
    "worker_missing_artifact"
  } else if ! review_ok {
    "protocol_failed"
  } else if ! restriction_ok {
    "restriction_failed"
  } else if ! correctness_ok {
    "candidate_failed"
  } else {
    "pass"
  }
  let handbook_sha = if fs.exists(p"/work/handbook.md")? { hash.sha256(p"/work/handbook.md")?.hex() } else { "" }
  let agents_sha = if fs.exists(p"/work/agents.md")? { hash.sha256(p"/work/agents.md")?.hex() } else { "" }
  let task_sha = if fs.exists(p"/work/task.md")? { hash.sha256(p"/work/task.md")?.hex() } else { "" }
  let candidate_sha = if fs.exists(p"/session/candidate.1.stdout")? { hash.sha256(p"/session/candidate.1.stdout")?.hex() } else { "" }
  let oracle_sha = if fs.exists(p"/session/oracle.1.stdout")? { hash.sha256(p"/session/oracle.1.stdout")?.hex() } else { "" }
  json.write(p"/session/run.json", {
    image_id: env.get_or("FACTORY_IMAGE_ID", "unknown")?,
    platform: env.get_or("FACTORY_PLATFORM", "unknown")?,
    provider: env.get_or("FACTORY_EVAL_WORKER_PROVIDER", "unknown")?,
    model: env.get_or("FACTORY_EVAL_WORKER_MODEL", "unknown")?,
    thinking: env.get_or("FACTORY_EVAL_WORKER_THINKING", "unknown")?,
    telemetry: env.get_or("FACTORY_TELEMETRY", "unknown")?,
    offline: env.get_or("FACTORY_OFFLINE", "unknown")?,
    eval_id: env.get_or("FACTORY_EVAL_ID", "unknown")?,
    trial_id: env.get_or("FACTORY_TRIAL_ID", "unknown")?,
    xsh_commit: env.get_or("FACTORY_XSH_COMMIT", "unknown")?,
    result: if eval_status == 0 { "pass" } else { "fail" },
    classification: classification,
    session: "/session/session.jsonl",
    inputs: {agents_sha256: agents_sha, handbook_sha256: handbook_sha, task_sha256: task_sha},
    outputs: {candidate_sha256: candidate_sha, oracle_sha256: oracle_sha},
    protocol: {artifact_present: artifact_present, review_ok: review_ok},
    correctness: {
      public_exact: public_exact,
      hidden_defaults_exact: hidden_defaults_exact,
      hidden_partial_exact: hidden_partial_exact,
      hidden_empty_exact: hidden_empty_exact,
      hidden_spaces_exact: hidden_spaces_exact,
      hidden_zero_exact: hidden_zero_exact,
      hidden_utf8_exact: hidden_utf8_exact,
      hidden_debug_false_exact: hidden_debug_false_exact,
      hidden_malformed_exact: hidden_malformed_exact,
      hidden_empty_port_exact: hidden_empty_port_exact,
      all_exact: all_exact,
    },
    restrictions: {forbidden_operations: forbidden_operations, env_referenced: env_referenced, passed: restriction_ok},
    timings: {
      public_candidate_wall_ns: public_candidate_wall_ns,
      public_oracle_wall_ns: public_oracle_wall_ns,
      hidden_defaults_candidate_wall_ns: hidden_defaults_candidate_wall_ns,
      hidden_defaults_oracle_wall_ns: hidden_defaults_oracle_wall_ns,
      hidden_partial_candidate_wall_ns: hidden_partial_candidate_wall_ns,
      hidden_partial_oracle_wall_ns: hidden_partial_oracle_wall_ns,
      hidden_empty_candidate_wall_ns: hidden_empty_candidate_wall_ns,
      hidden_empty_oracle_wall_ns: hidden_empty_oracle_wall_ns,
      hidden_spaces_candidate_wall_ns: hidden_spaces_candidate_wall_ns,
      hidden_spaces_oracle_wall_ns: hidden_spaces_oracle_wall_ns,
      hidden_zero_candidate_wall_ns: hidden_zero_candidate_wall_ns,
      hidden_zero_oracle_wall_ns: hidden_zero_oracle_wall_ns,
      hidden_utf8_candidate_wall_ns: hidden_utf8_candidate_wall_ns,
      hidden_utf8_oracle_wall_ns: hidden_utf8_oracle_wall_ns,
      hidden_debug_false_candidate_wall_ns: hidden_debug_false_candidate_wall_ns,
      hidden_debug_false_oracle_wall_ns: hidden_debug_false_oracle_wall_ns,
      hidden_malformed_candidate_wall_ns: hidden_malformed_candidate_wall_ns,
      hidden_malformed_oracle_wall_ns: hidden_malformed_oracle_wall_ns,
      hidden_empty_port_candidate_wall_ns: hidden_empty_port_candidate_wall_ns,
      hidden_empty_port_oracle_wall_ns: hidden_empty_port_oracle_wall_ns,
    },
  }, pretty: true)?
  return Ok(eval_status)
}

proc main(...argv: List[Str]) [fs, process, env, time, error, io] {
  abort(run_task_envcfg()?)
}
