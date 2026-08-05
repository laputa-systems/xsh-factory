##! Task-wordfreq evaluator package implementation.
##! Self-contained: the generic the shared evaluator dispatcher runs this script by path,
##! so it owns all task-specific case logic, oracle, and run.json emission.
##! It deliberately does not `use` factory_control: the eval container mounts
##! this script at /run/evaluator.xsh without XSH_MODULE_PATH, so any module
##! dependency is inlined.

## Detect forbidden subprocess syntax without treating prose in `#` comments as code.
pure source_has_forbidden_subprocess(source: Str) -> Bool {
  for line in source.lines() {
    let code = line.split("#").get(0, "")
    if code.contains("process.") or code.contains("spawn ") or code.contains("run ") {
      return true
    }
  }
  return false
}

## Detect a real (non-comment) reference to the file-text Read API; a comment that
## merely mentions `read_text` must not satisfy the anti-hard-code restriction.
pure code_references_read_text(source: Str) -> Bool {
  for line in source.lines() {
    let code = line.split("#").get(0, "")
    if code.contains("read_text") {
      return true
    }
  }
  return false
}

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

type WordfreqCase = {name: Str, content: Str}

type WordfreqCaseResult = {exact: Bool, candidate_wall_ns: Int, oracle_wall_ns: Int}

proc run_wordfreq_case(index: Int, case: WordfreqCase) [fs, process, time, error] -> Result[WordfreqCaseResult] {
  let input_path = fp"/tmp/wordfreq-in.${index}.txt"
  fs.write(input_path, case.content)?
  let candidate = time.measure(process.command_argv(
    "xsh", ["xsh", "/work/wordfreq.xsh", input_path.display()],
    stdout: fp"/session/candidate.${index}.stdout", stderr: fp"/session/candidate.${index}.stderr",
  ))?
  let oracle = time.measure(process.command_argv(
    "sh", ["sh", "/tmp/wordfreq-oracle.sh", input_path.display()],
    stdout: fp"/session/oracle.${index}.stdout", stderr: fp"/session/oracle.${index}.stderr",
  ))?
  let candidate_out = if fs.exists(fp"/session/candidate.${index}.stdout")? {
    fs.read_text(fp"/session/candidate.${index}.stdout")?
  } else {
    ""
  }
  let oracle_out = if fs.exists(fp"/session/oracle.${index}.stdout")? {
    fs.read_text(fp"/session/oracle.${index}.stdout")?
  } else {
    ""
  }
  let exact = candidate.status.ok and oracle.status.ok and candidate_out == oracle_out
  return {exact: exact, candidate_wall_ns: candidate.wall_ns, oracle_wall_ns: oracle.wall_ns}
}

proc run_task_wordfreq() [fs, process, env, time, error, io] -> Result[Int] {
  defer copy_results("wordfreq.xsh")?
  var eval_status = 0
  let artifact_present = fs.exists(p"/work/wordfreq.xsh")?
  var review_ok = false
  var forbidden_operations = false
  var reads_file = false
  var all_exact = false
  var public_exact = false
  var hidden_mixed_digits_exact = false
  var hidden_whitespace_exact = false
  var hidden_case_exact = false
  var hidden_utf8_exact = false
  var hidden_empty_exact = false
  var hidden_nowords_exact = false
  var public_candidate_wall_ns = 0
  var public_oracle_wall_ns = 0
  var hidden_mixed_digits_candidate_wall_ns = 0
  var hidden_mixed_digits_oracle_wall_ns = 0
  var hidden_whitespace_candidate_wall_ns = 0
  var hidden_whitespace_oracle_wall_ns = 0
  var hidden_case_candidate_wall_ns = 0
  var hidden_case_oracle_wall_ns = 0
  var hidden_utf8_candidate_wall_ns = 0
  var hidden_utf8_oracle_wall_ns = 0
  var hidden_empty_candidate_wall_ns = 0
  var hidden_empty_oracle_wall_ns = 0
  var hidden_nowords_candidate_wall_ns = 0
  var hidden_nowords_oracle_wall_ns = 0

  if artifact_present {
    fs.write(p"/tmp/wordfreq-oracle.sh", r"""#!/bin/sh
tr 'A-Z' 'a-z' < "$1" | tr -cs 'a-z' '\n' | sed '/^$/d' | sort | uniq -c | sed 's/^[[:space:]]*//'
""")?
    fs.chmod(p"/tmp/wordfreq-oracle.sh", 0o755)?
    let cases: List[WordfreqCase] = [
      {name: "public", content: "The quick brown fox. The fox jumps over the lazy dog!"},
      {name: "hidden_mixed_digits", content: "foo2bar baz-BAT 3qux qux QUX mix9"},
      {name: "hidden_whitespace", content: "  alpha\t beta \n alpha  beta  gamma\t\n"},
      {name: "hidden_case", content: "Apple APPLE apple Banana banana"},
      {name: "hidden_utf8", content: "café münchen NAÏVE"},
      {name: "hidden_empty", content: ""},
      {name: "hidden_nowords", content: "123 !!! --- ###"},
    ]
    var index = 0
    for case in cases {
      index += 1
      let result = run_wordfreq_case(index, case)?
      if case.name == "public" {
        public_exact = result.exact
        public_candidate_wall_ns = result.candidate_wall_ns
        public_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_mixed_digits" {
        hidden_mixed_digits_exact = result.exact
        hidden_mixed_digits_candidate_wall_ns = result.candidate_wall_ns
        hidden_mixed_digits_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_whitespace" {
        hidden_whitespace_exact = result.exact
        hidden_whitespace_candidate_wall_ns = result.candidate_wall_ns
        hidden_whitespace_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_case" {
        hidden_case_exact = result.exact
        hidden_case_candidate_wall_ns = result.candidate_wall_ns
        hidden_case_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_utf8" {
        hidden_utf8_exact = result.exact
        hidden_utf8_candidate_wall_ns = result.candidate_wall_ns
        hidden_utf8_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_empty" {
        hidden_empty_exact = result.exact
        hidden_empty_candidate_wall_ns = result.candidate_wall_ns
        hidden_empty_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_nowords" {
        hidden_nowords_exact = result.exact
        hidden_nowords_candidate_wall_ns = result.candidate_wall_ns
        hidden_nowords_oracle_wall_ns = result.oracle_wall_ns
      }
    }
    all_exact = public_exact and hidden_mixed_digits_exact and hidden_whitespace_exact and
      hidden_case_exact and hidden_utf8_exact and hidden_empty_exact and hidden_nowords_exact
    let source = fs.read_text(p"/work/wordfreq.xsh")?
    forbidden_operations = ! source_has_forbidden_subprocess(source)
    reads_file = code_references_read_text(source)
    if ! all_exact or ! forbidden_operations or ! reads_file {
      eval_status = 1
    }
    if all_exact and forbidden_operations and reads_file {
      print "task-wordfreq evaluation passed"
    } else {
      eprint "task-wordfreq evaluation failed"
    }
  } else {
    eprint "pi completed without creating /work/wordfreq.xsh"
    eval_status = 1
  }

  review_ok = check_review(p"/work")?
  if ! review_ok {
    eprint "task-wordfreq evaluation failed: review.md missing or incomplete"
    eval_status = 1
  }
  let correctness_ok = artifact_present and all_exact
  let restriction_ok = artifact_present and forbidden_operations and reads_file
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
    eval_id: env.get_or("FACTORY_EVAL_ID", "task-wordfreq")?,
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
      hidden_mixed_digits_exact: hidden_mixed_digits_exact,
      hidden_whitespace_exact: hidden_whitespace_exact,
      hidden_case_exact: hidden_case_exact,
      hidden_utf8_exact: hidden_utf8_exact,
      hidden_empty_exact: hidden_empty_exact,
      hidden_nowords_exact: hidden_nowords_exact,
      all_exact: all_exact,
    },
    restrictions: {forbidden_operations: forbidden_operations, reads_file: reads_file, passed: restriction_ok},
    timings: {
      public_candidate_wall_ns: public_candidate_wall_ns,
      public_oracle_wall_ns: public_oracle_wall_ns,
      hidden_mixed_digits_candidate_wall_ns: hidden_mixed_digits_candidate_wall_ns,
      hidden_mixed_digits_oracle_wall_ns: hidden_mixed_digits_oracle_wall_ns,
      hidden_whitespace_candidate_wall_ns: hidden_whitespace_candidate_wall_ns,
      hidden_whitespace_oracle_wall_ns: hidden_whitespace_oracle_wall_ns,
      hidden_case_candidate_wall_ns: hidden_case_candidate_wall_ns,
      hidden_case_oracle_wall_ns: hidden_case_oracle_wall_ns,
      hidden_utf8_candidate_wall_ns: hidden_utf8_candidate_wall_ns,
      hidden_utf8_oracle_wall_ns: hidden_utf8_oracle_wall_ns,
      hidden_empty_candidate_wall_ns: hidden_empty_candidate_wall_ns,
      hidden_empty_oracle_wall_ns: hidden_empty_oracle_wall_ns,
      hidden_nowords_candidate_wall_ns: hidden_nowords_candidate_wall_ns,
      hidden_nowords_oracle_wall_ns: hidden_nowords_oracle_wall_ns,
    },
  }, pretty: true)?
  return Ok(eval_status)
}

proc main(...argv: List[Str]) [fs, process, env, time, error, io] {
  let status = run_task_wordfreq()?
  abort(status)
}
