##! Evaluates task-tags in the eval container: runs the candidate against
##! three argument cases, compares each result with an external printf oracle,
##! checks the review and subprocess boundary, and writes the run manifest.

proc copy_results() [fs, error] -> Result[Unit] {
  # /session and /export are two views of the same host worker directory.
  # Session, manifest, and oracle files are already in their final location;
  # only artifacts created in /work need copying into that directory.
  for name in ["tag.xsh", "review.md"] {
    let src = fp"/work/${name}"
    if fs.exists(src)? {
      fs.copy(src, fp"/export/${name}", overwrite: true)?
    }
  }
}

proc main() [fs, process, env, time, error, io] {
  defer copy_results()?
  var eval_status = 0
  var artifact_present = fs.exists(p"/work/tag.xsh")?
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
      "xsh",
      ["xsh", "/work/tag.xsh", "Alpha", "Two Words", "BETA"],
      stdout: p"/session/candidate.1.stdout",
      stderr: p"/session/candidate.1.stderr",
    ))?
    let public_oracle = time.measure(process.command_argv(
      "printf",
      ["printf", "tags: alpha, two words, beta\\n"],
      stdout: p"/session/oracle.1.stdout",
      stderr: p"/session/oracle.1.stderr",
    ))?
    public_candidate_wall_ns = public_candidate.wall_ns
    public_oracle_wall_ns = public_oracle.wall_ns

    let hidden_candidate = time.measure(process.command_argv(
      "xsh",
      ["xsh", "/work/tag.xsh", "MiXeD", "", "Three Words"],
      stdout: p"/session/candidate.2.stdout",
      stderr: p"/session/candidate.2.stderr",
    ))?
    let hidden_oracle = time.measure(process.command_argv(
      "printf",
      ["printf", "tags: mixed, , three words\\n"],
      stdout: p"/session/oracle.2.stdout",
      stderr: p"/session/oracle.2.stderr",
    ))?
    hidden_candidate_wall_ns = hidden_candidate.wall_ns
    hidden_oracle_wall_ns = hidden_oracle.wall_ns

    let empty_candidate = time.measure(process.command_argv(
      "xsh",
      ["xsh", "/work/tag.xsh"],
      stdout: p"/session/candidate.3.stdout",
      stderr: p"/session/candidate.3.stderr",
    ))?
    let empty_oracle = time.measure(process.command_argv(
      "printf",
      ["printf", "tags:\\n"],
      stdout: p"/session/oracle.3.stdout",
      stderr: p"/session/oracle.3.stderr",
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
  let candidate_sha = if fs.exists(p"/session/candidate.1.stdout")? {
    hash.sha256(p"/session/candidate.1.stdout")?.hex()
  } else {
    ""
  }
  let oracle_sha = if fs.exists(p"/session/oracle.1.stdout")? {
    hash.sha256(p"/session/oracle.1.stdout")?.hex()
  } else {
    ""
  }
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
    xsh_bin_sha256: env.get_or("FACTORY_XSH_BIN_SHA256", "unknown")?,
    xsht_bin_sha256: env.get_or("FACTORY_XSHT_BIN_SHA256", "unknown")?,
    result: if eval_status == 0 { "pass" } else { "fail" },
    classification: classification,
    session: "/session/session.jsonl",
    inputs: {
      agents_sha256: agents_sha,
      handbook_sha256: handbook_sha,
      task_sha256: task_sha,
    },
    outputs: {
      candidate_sha256: candidate_sha,
      oracle_sha256: oracle_sha,
    },
    protocol: {
      artifact_present: artifact_present,
      review_ok: review_ok,
    },
    correctness: {
      public_exact: public_exact,
      hidden_exact: hidden_exact,
      empty_exact: empty_exact,
      all_exact: correctness_ok,
    },
    restrictions: {
      forbidden_operations: forbidden_operations,
      passed: restriction_ok,
    },
    timings: {
      public_candidate_wall_ns: public_candidate_wall_ns,
      public_oracle_wall_ns: public_oracle_wall_ns,
      hidden_candidate_wall_ns: hidden_candidate_wall_ns,
      hidden_oracle_wall_ns: hidden_oracle_wall_ns,
      empty_candidate_wall_ns: empty_candidate_wall_ns,
      empty_oracle_wall_ns: empty_oracle_wall_ns,
    },
  }, pretty: true)?

  abort(eval_status)
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
