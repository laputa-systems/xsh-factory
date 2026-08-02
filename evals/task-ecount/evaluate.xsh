##! Evaluates the task-ecount run inside the eval container: runs the
##! candidate, compares it with the fd/awk oracle, checks review.md, and
##! writes the run manifest. Result files are copied to /export on exit.

proc copy_results() [fs, error] -> Result[Unit] {
  # /session and /export are two views of the same host worker directory.
  # Session, manifest, and oracle files are already in their final location;
  # only artifacts created in /work need copying into that directory.
  for name in ["ecount.xsh", "review.md"] {
    let src = fp"/work/${name}"
    if fs.exists(src)? {
      fs.copy(src, fp"/export/${name}", overwrite: true)?
    }
  }
}

proc main() [fs, process, env, time, error, io] {
  defer copy_results()?
  var eval_status = 0
  var artifact_present = fs.exists(p"/work/ecount.xsh")?
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
      "xsh",
      ["xsh", "/work/ecount.xsh", "/usr/share"],
      stdout: p"/session/candidate.stdout",
    ))?
    candidate_wall_ns = candidate.wall_ns
    candidate_user_ns = candidate.user_ns
    candidate_system_ns = candidate.system_ns
    let candidate_status = candidate.status
    if ! candidate_status.ok {
      eval_status = candidate_status.exit_code() ?? 1
    }
    # The oracle is the byte-exact sh pipeline; keep it as one command so its
    # semantics and output do not drift from the original harness.
    let oracle = time.measure(process.command_argv(
      "sh",
      ["sh", "-c", "fd --color=never -tf . /usr/share | awk -F. 'NF > 1 {print tolower(\$NF)}' | sort | uniq -c | sort -n"],
      stdout: p"/session/oracle.stdout",
    ))?
    oracle_wall_ns = oracle.wall_ns
    oracle_user_ns = oracle.user_ns
    oracle_system_ns = oracle.system_ns
    if ! oracle.status.ok {
      eval_status = 1
    } else {
      oracle_ok = true
    }
    let source = fs.read_text(p"/work/ecount.xsh")?
    forbidden_operations = ! source.contains("process.") and
      ! source.contains("spawn ") and ! source.contains("run ")
    if candidate_status.ok and oracle.status.ok {
      let candidate = fs.read_text(p"/session/candidate.stdout")?
      let oracle = fs.read_text(p"/session/oracle.stdout")?
      if candidate == oracle {
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
  let timing_ratio = if oracle_wall_ns > 0 {
    candidate_wall_ns.float() / oracle_wall_ns.float()
  } else {
    0.0
  }
  let timing_ok = oracle_wall_ns > 0 and timing_ratio >= 0.90 and timing_ratio <= 1.10
  if ! timing_ok {
    eval_status = 1
  }
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
  let candidate_sha = if fs.exists(p"/session/candidate.stdout")? {
    hash.sha256(p"/session/candidate.stdout")?.hex()
  } else {
    ""
  }
  let oracle_sha = if fs.exists(p"/session/oracle.stdout")? {
    hash.sha256(p"/session/oracle.stdout")?.hex()
  } else {
    ""
  }
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
    protocol: {
      artifact_present: artifact_present,
      review_ok: review_ok,
    },
    correctness: {
      oracle_ok: oracle_ok,
      exact_output: exact_output,
      passed: correctness_ok,
    },
    restrictions: {
      forbidden_operations: forbidden_operations,
      passed: restriction_ok,
    },
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
