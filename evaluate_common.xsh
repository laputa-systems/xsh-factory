##! Shared evaluator implementation. Thin eval wrappers select the task; this
##! file owns result copying, review protocol, manifests, and timing evidence.

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

proc run_task_tags() [fs, process, env, time, error, io] -> Result[Int] {
  defer copy_results("tag.xsh")?
  var eval_status = 0
  let artifact_present = fs.exists(p"/work/tag.xsh")?
  var review_ok = false
  var public_exact = false
  var hidden_exact = false
  var empty_exact = false
  var forbidden_operations = false
  var public_candidate_wall_ns = 0
  var public_oracle_wall_ns = 0
  var hidden_candidate_wall_ns = 0
  var hidden_oracle_wall_ns = 0
  var empty_candidate_wall_ns = 0
  var empty_oracle_wall_ns = 0

  if artifact_present {
    let public_candidate = time.measure(process.command_argv(
      "xsh", ["xsh", "/work/tag.xsh", "Alpha", "Two Words", "BETA"],
      stdout: p"/session/candidate.1.stdout", stderr: p"/session/candidate.1.stderr",
    ))?
    let public_oracle = time.measure(process.command_argv(
      "printf", ["printf", "tags: alpha, two words, beta\\n"],
      stdout: p"/session/oracle.1.stdout", stderr: p"/session/oracle.1.stderr",
    ))?
    public_candidate_wall_ns = public_candidate.wall_ns
    public_oracle_wall_ns = public_oracle.wall_ns

    let hidden_candidate = time.measure(process.command_argv(
      "xsh", ["xsh", "/work/tag.xsh", "MiXeD", "", "Three Words"],
      stdout: p"/session/candidate.2.stdout", stderr: p"/session/candidate.2.stderr",
    ))?
    let hidden_oracle = time.measure(process.command_argv(
      "printf", ["printf", "tags: mixed, , three words\\n"],
      stdout: p"/session/oracle.2.stdout", stderr: p"/session/oracle.2.stderr",
    ))?
    hidden_candidate_wall_ns = hidden_candidate.wall_ns
    hidden_oracle_wall_ns = hidden_oracle.wall_ns

    let empty_candidate = time.measure(process.command_argv(
      "xsh", ["xsh", "/work/tag.xsh"],
      stdout: p"/session/candidate.3.stdout", stderr: p"/session/candidate.3.stderr",
    ))?
    let empty_oracle = time.measure(process.command_argv(
      "printf", ["printf", "tags:\\n"],
      stdout: p"/session/oracle.3.stdout", stderr: p"/session/oracle.3.stderr",
    ))?
    empty_candidate_wall_ns = empty_candidate.wall_ns
    empty_oracle_wall_ns = empty_oracle.wall_ns

    public_exact = public_candidate.status.ok and public_oracle.status.ok and
      fs.read_text(p"/session/candidate.1.stdout")? == fs.read_text(p"/session/oracle.1.stdout")?
    hidden_exact = hidden_candidate.status.ok and hidden_oracle.status.ok and
      fs.read_text(p"/session/candidate.2.stdout")? == fs.read_text(p"/session/oracle.2.stdout")?
    empty_exact = empty_candidate.status.ok and empty_oracle.status.ok and
      fs.read_text(p"/session/candidate.3.stdout")? == fs.read_text(p"/session/oracle.3.stdout")?
    let source = fs.read_text(p"/work/tag.xsh")?
    forbidden_operations = ! source.contains("process.") and
      ! source.contains("spawn ") and ! source.contains("run ")
    if ! public_exact or ! hidden_exact or ! empty_exact or ! forbidden_operations {
      eval_status = 1
    }
  } else {
    eprint "pi completed without creating /work/tag.xsh"
    eval_status = 1
  }

  review_ok = check_review(p"/work")?
  if ! review_ok {
    eprint "task-tags evaluation failed: review.md missing or incomplete"
    eval_status = 1
  }
  let correctness_ok = artifact_present and public_exact and hidden_exact and empty_exact
  let restriction_ok = artifact_present and forbidden_operations
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
  let task_sha = if fs.exists(p"/work/task-tags.md")? { hash.sha256(p"/work/task-tags.md")?.hex() } else { "" }
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
    correctness: {public_exact: public_exact, hidden_exact: hidden_exact, empty_exact: empty_exact, all_exact: correctness_ok},
    restrictions: {forbidden_operations: forbidden_operations, passed: restriction_ok},
    timings: {
      public_candidate_wall_ns: public_candidate_wall_ns,
      public_oracle_wall_ns: public_oracle_wall_ns,
      hidden_candidate_wall_ns: hidden_candidate_wall_ns,
      hidden_oracle_wall_ns: hidden_oracle_wall_ns,
      empty_candidate_wall_ns: empty_candidate_wall_ns,
      empty_oracle_wall_ns: empty_oracle_wall_ns,
    },
  }, pretty: true)?
  return Ok(eval_status)
}

proc run_task_ecount() [fs, process, env, time, error, io] -> Result[Int] {
  defer copy_results("ecount.xsh")?
  var eval_status = 0
  let artifact_present = fs.exists(p"/work/ecount.xsh")?
  var review_ok = false
  var exact_output = false
  var oracle_ok = false
  var forbidden_operations = false
  var candidate_wall_ns = 0
  var candidate_user_ns = 0
  var candidate_system_ns = 0
  var oracle_wall_ns = 0
  var oracle_user_ns = 0
  var oracle_system_ns = 0

  if artifact_present {
    let candidate = time.measure(process.command_argv(
      "xsh", ["xsh", "/work/ecount.xsh", "/usr/share"], stdout: p"/session/candidate.stdout",
    ))?
    candidate_wall_ns = candidate.wall_ns
    candidate_user_ns = candidate.user_ns
    candidate_system_ns = candidate.system_ns
    let candidate_status = candidate.status
    if ! candidate_status.ok { eval_status = candidate_status.exit_code() ?? 1 }
    let oracle = time.measure(process.command_argv(
      "sh", ["sh", "-c", "fd --color=never -tf . /usr/share | awk -F. 'NF > 1 {print tolower(\\$NF)}' | sort | uniq -c | sort -n"],
      stdout: p"/session/oracle.stdout",
    ))?
    oracle_wall_ns = oracle.wall_ns
    oracle_user_ns = oracle.user_ns
    oracle_system_ns = oracle.system_ns
    if ! oracle.status.ok { eval_status = 1 } else { oracle_ok = true }
    let source = fs.read_text(p"/work/ecount.xsh")?
    forbidden_operations = ! source.contains("process.") and
      ! source.contains("spawn ") and ! source.contains("run ")
    if candidate_status.ok and oracle.status.ok {
      let candidate_output = fs.read_text(p"/session/candidate.stdout")?
      let oracle_output = fs.read_text(p"/session/oracle.stdout")?
      if candidate_output == oracle_output {
        exact_output = true
        print "task-ecount evaluation passed"
      } else {
        eprint "task-ecount evaluation failed"
        eval_status = 1
      }
    }
  } else {
    eprint "pi completed without creating /work/ecount.xsh"
    eval_status = 1
  }

  review_ok = check_review(p"/work")?
  if review_ok {
    print "task-ecount evaluation passed (review.md)"
  } else {
    eprint "task-ecount evaluation failed: review.md missing or incomplete"
    eval_status = 1
  }
  let correctness_ok = artifact_present and oracle_ok and exact_output
  let restriction_ok = artifact_present and forbidden_operations
  let timing_ratio = if oracle_wall_ns > 0 { candidate_wall_ns.float() / oracle_wall_ns.float() } else { 0.0 }
  let timing_ok = oracle_wall_ns > 0 and timing_ratio >= 0.90 and timing_ratio <= 1.10
  if ! timing_ok { eval_status = 1 }
  let classification = if ! artifact_present {
    "worker_missing_artifact"
  } else if ! review_ok {
    "protocol_failed"
  } else if ! restriction_ok {
    "restriction_failed"
  } else if ! correctness_ok {
    "candidate_failed"
  } else if ! timing_ok {
    "timing_failed"
  } else {
    "pass"
  }
  let agents_sha = hash.sha256(p"/work/agents.md")?.hex()
  let handbook_sha = hash.sha256(p"/work/handbook.md")?.hex()
  let task_sha = hash.sha256(p"/work/task-ecount.md")?.hex()
  let candidate_sha = if fs.exists(p"/session/candidate.stdout")? { hash.sha256(p"/session/candidate.stdout")?.hex() } else { "" }
  let oracle_sha = if fs.exists(p"/session/oracle.stdout")? { hash.sha256(p"/session/oracle.stdout")?.hex() } else { "" }
  let result = if eval_status == 0 { "pass" } else { "fail" }
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
    result: result,
    classification: classification,
    session: "/session/session.jsonl",
    inputs: {agents_sha256: agents_sha, handbook_sha256: handbook_sha, task_sha256: task_sha},
    outputs: {candidate_sha256: candidate_sha, oracle_sha256: oracle_sha},
    protocol: {artifact_present: artifact_present, review_ok: review_ok},
    correctness: {oracle_ok: oracle_ok, exact_output: exact_output, passed: correctness_ok},
    restrictions: {forbidden_operations: forbidden_operations, passed: restriction_ok},
    timings: {
      candidate_wall_ns: candidate_wall_ns,
      candidate_user_ns: candidate_user_ns,
      candidate_system_ns: candidate_system_ns,
      oracle_wall_ns: oracle_wall_ns,
      oracle_user_ns: oracle_user_ns,
      oracle_system_ns: oracle_system_ns,
      ratio: timing_ratio,
      passed: timing_ok,
    },
  }, pretty: true)?
  return Ok(eval_status)
}

proc main(...argv: List[Str]) [fs, process, env, time, error, io] {
  let eval_id = if argv.len() > 0 { argv[0] } else { env.get_or("FACTORY_EVAL_ID", "")? }
  var status = 2
  if eval_id == "task-tags" {
    status = run_task_tags()?
  } else if eval_id == "task-ecount" {
    status = run_task_ecount()?
  } else {
    eprint f"unknown eval id: ${eval_id}"
  }
  abort(status)
}
