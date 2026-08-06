##! Package-owned evaluator for task-ecount.
use factory.control as control

proc copy_results(artifact: Str) [fs, error] {
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
  return text.contains("## XSH language proposals") and text.contains("## xsht friction") and ! text.contains("""
### <title>
""") and """
**Rationale.** What fell short for this task.""" not in text and """
**Symptom.** What you queried or ran and what came back.""" not in text
}

proc run_task_ecount() [fs, process, env, time, error, io] -> Result[Int] {
  defer copy_results("ecount.xsh")?
  var eval_status = 0
  let artifact_present = fs.exists(/work/ecount.xsh)?
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
    let candidate = time.measure(
      process.command_argv(
        "xsh",
        ["xsh", "/work/ecount.xsh", "/usr/share"],
        stdout: /session/candidate.stdout,
      ),
    )?
    candidate_wall_ns = candidate.wall_ns
    candidate_user_ns = candidate.user_ns
    candidate_system_ns = candidate.system_ns
    let candidate_status = candidate.status
    if ! candidate_status.ok {
      eval_status = candidate_status.exit_code() ?? 1
    }

    let oracle_args = control.ecount_oracle_command()
    let oracle = time.measure(
      process.command_argv(
        oracle_args[0],
        oracle_args,
        stdout: /session/oracle.stdout,
      ),
    )?
    oracle_wall_ns = oracle.wall_ns
    oracle_user_ns = oracle.user_ns
    oracle_system_ns = oracle.system_ns
    let oracle_output = if fs.exists(/session/oracle.stdout)? {
      fs.read_text(/session/oracle.stdout)?
    } else {
      ""
    }
    oracle_ok = control.ecount_oracle_ok(oracle.status.ok, oracle_output)
    if ! oracle_ok {
      eprint "task-ecount oracle failed or produced empty output"
      eval_status = 1
    }

    let source = fs.read_text(/work/ecount.xsh)?
    forbidden_operations = ! control.source_has_forbidden_subprocess(source)
    if candidate_status.ok and oracle_ok {
      let candidate_output = fs.read_text(/session/candidate.stdout)?
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

  review_ok = check_review(/work)?
  if review_ok {
    print "task-ecount evaluation passed (review.md)"
  } else {
    eprint "task-ecount evaluation failed: review.md missing or incomplete"
    eval_status = 1
  }

  let correctness_ok = artifact_present and oracle_ok and exact_output
  let restriction_ok = artifact_present and forbidden_operations
  let timing_ratio = if oracle_wall_ns > 0 { candidate_wall_ns.float() / oracle_wall_ns.float() } else { 0.0 }
  let timing_ok = oracle_ok and oracle_wall_ns > 0 and timing_ratio >= 0.90 and timing_ratio <= 1.10
  if ! timing_ok {
    eval_status = 1
  }

  let classification = control.ecount_classification(
    artifact_present,
    review_ok,
    restriction_ok,
    oracle_ok,
    correctness_ok,
    timing_ok,
  )
  let agents_sha = hash.sha256(/work/agents.md)?.hex()
  let handbook_sha = hash.sha256(/work/handbook.md)?.hex()
  let task_sha = hash.sha256(/work/task.md)?.hex()
  let candidate_sha = if fs.exists(/session/candidate.stdout)? {
    hash.sha256(/session/candidate.stdout)?.hex()
  } else {
    ""
  }
  let oracle_sha = if fs.exists(/session/oracle.stdout)? { hash.sha256(/session/oracle.stdout)?.hex() } else { "" }
  let result = if eval_status == 0 { "pass" } else { "fail" }
  json.write(
    /session/run.json,
    {
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
    },
    pretty: true,
  )?
  eval_status
}

proc main(..._: List[Str]) [fs, process, env, time, error, io] {
  abort(run_task_ecount()?)
}
