##! Task-uniqcat evaluator package implementation (self-contained; new evals
##! must not edit the shared the retired evaluator fallback compatibility module).
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

type UniqCase = {name: Str, files: List[Str], expect_fail: Bool}

type UniqCaseResult = {exact: Bool, candidate_wall_ns: Int, oracle_wall_ns: Int}

proc run_uniq_case(index: Int, case: UniqCase) [fs, process, time, error] -> Result[UniqCaseResult] {
  let cand_out = fp"/session/candidate.${index}.stdout"
  let ora_out = fp"/session/oracle.${index}.stdout"
  let cand_args = ["xsh", "/work/uniqcat.xsh"].extend(case.files)
  let candidate = time.measure(
    process.command_argv(
      "xsh",
      cand_args,
      stdout: cand_out,
      stderr: fp"/session/candidate.${index}.stderr",
    ),
  )?
  let ora_args = ["awk", "!seen[$0]++"].extend(case.files)
  let oracle = time.measure(
    process.command_argv(
      "awk",
      ora_args,
      stdout: ora_out,
      stderr: fp"/session/oracle.${index}.stderr",
    ),
  )?
  let candidate_text = if fs.exists(cand_out)? { fs.read_text(cand_out)? } else { "" }
  let oracle_text = if fs.exists(ora_out)? { fs.read_text(ora_out)? } else { "" }
  let exact = if case.expect_fail {
    ! candidate.status.ok and ! oracle.status.ok and candidate_text == ""
  } else {
    candidate.status.ok and oracle.status.ok and candidate_text == oracle_text
  }
  return {exact: exact, candidate_wall_ns: candidate.wall_ns, oracle_wall_ns: oracle.wall_ns}
}

proc run_task_uniqcat() [fs, process, env, time, error, io] -> Result[Int] {
  defer copy_results("uniqcat.xsh")?
  var eval_status = 0
  let artifact_present = fs.exists(/work/uniqcat.xsh)?
  var review_ok = false
  var forbidden_operations = false
  var read_referenced = false
  var all_exact = false
  var public_exact = false
  var hidden_single_exact = false
  var hidden_three_exact = false
  var hidden_blank_exact = false
  var hidden_utf8_exact = false
  var hidden_space_exact = false
  var hidden_all_empty_exact = false
  var hidden_missing_exact = false
  var public_candidate_wall_ns = 0
  var public_oracle_wall_ns = 0
  var hidden_single_candidate_wall_ns = 0
  var hidden_single_oracle_wall_ns = 0
  var hidden_three_candidate_wall_ns = 0
  var hidden_three_oracle_wall_ns = 0
  var hidden_blank_candidate_wall_ns = 0
  var hidden_blank_oracle_wall_ns = 0
  var hidden_utf8_candidate_wall_ns = 0
  var hidden_utf8_oracle_wall_ns = 0
  var hidden_space_candidate_wall_ns = 0
  var hidden_space_oracle_wall_ns = 0
  var hidden_all_empty_candidate_wall_ns = 0
  var hidden_all_empty_oracle_wall_ns = 0
  var hidden_missing_candidate_wall_ns = 0
  var hidden_missing_oracle_wall_ns = 0

  if artifact_present {
    # Fixture files under the evaluator's writable /tmp.
    fs.write(
      /tmp/uc-A.txt,
      """alpha
beta
gamma
""",
    )?
    fs.write(
      /tmp/uc-B.txt,
      """beta
delta
""",
    )?
    fs.write(
      /tmp/uc-one.txt,
      """x
y
x
y
""",
    )?
    fs.write(
      /tmp/uc-f1.txt,
      """p
q
""",
    )?
    fs.write(
      /tmp/uc-f2.txt,
      """q
r
""",
    )?
    fs.write(
      /tmp/uc-f3.txt,
      """r
s
""",
    )?
    fs.write(
      /tmp/uc-blank.txt,
      """a

b""",
    )?
    fs.write(
      /tmp/uc-utf8.txt,
      """héllo
wörld
héllo
""",
    )?
    fs.write(
      /tmp/uc-space.txt,
      f"""  lead
trail${"  "}
mid dle
  lead
""",
    )?
    fs.write(/tmp/uc-e1.txt, "")?
    fs.write(/tmp/uc-e2.txt, "")?

    # The unreadable-file case places the missing path first so both sides
    # fail before emitting any stdout, honoring the "exit nonzero and print
    # nothing" contract.
    let cases: List[UniqCase] = [
      {
        name: "public",
        files: [
          "/tmp/uc-A.txt",
          "/tmp/uc-B.txt",
        ],
        expect_fail: false,
      },
      {
        name: "hidden_single",
        files: [
          "/tmp/uc-one.txt",
        ],
        expect_fail: false,
      },
      {
        name: "hidden_three",
        files: [
          "/tmp/uc-f1.txt",
          "/tmp/uc-f2.txt",
          "/tmp/uc-f3.txt",
        ],
        expect_fail: false,
      },
      {
        name: "hidden_blank",
        files: [
          "/tmp/uc-blank.txt",
        ],
        expect_fail: false,
      },
      {
        name: "hidden_utf8",
        files: [
          "/tmp/uc-utf8.txt",
        ],
        expect_fail: false,
      },
      {
        name: "hidden_space",
        files: [
          "/tmp/uc-space.txt",
        ],
        expect_fail: false,
      },
      {
        name: "hidden_all_empty",
        files: [
          "/tmp/uc-e1.txt",
          "/tmp/uc-e2.txt",
        ],
        expect_fail: false,
      },
      {
        name: "hidden_missing",
        files: [
          "/tmp/uc-missing.txt",
          "/tmp/uc-A.txt",
        ],
        expect_fail: true,
      },
    ]
    var index = 0
    for case in cases {
      index += 1
      let result = run_uniq_case(index, case)?
      if case.name == "public" {
        public_exact = result.exact
        public_candidate_wall_ns = result.candidate_wall_ns
        public_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_single" {
        hidden_single_exact = result.exact
        hidden_single_candidate_wall_ns = result.candidate_wall_ns
        hidden_single_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_three" {
        hidden_three_exact = result.exact
        hidden_three_candidate_wall_ns = result.candidate_wall_ns
        hidden_three_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_blank" {
        hidden_blank_exact = result.exact
        hidden_blank_candidate_wall_ns = result.candidate_wall_ns
        hidden_blank_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_utf8" {
        hidden_utf8_exact = result.exact
        hidden_utf8_candidate_wall_ns = result.candidate_wall_ns
        hidden_utf8_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_space" {
        hidden_space_exact = result.exact
        hidden_space_candidate_wall_ns = result.candidate_wall_ns
        hidden_space_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_all_empty" {
        hidden_all_empty_exact = result.exact
        hidden_all_empty_candidate_wall_ns = result.candidate_wall_ns
        hidden_all_empty_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_missing" {
        hidden_missing_exact = result.exact
        hidden_missing_candidate_wall_ns = result.candidate_wall_ns
        hidden_missing_oracle_wall_ns = result.oracle_wall_ns
      }
    }

    all_exact = public_exact and hidden_single_exact and hidden_three_exact and hidden_blank_exact and hidden_utf8_exact and hidden_space_exact and hidden_all_empty_exact and hidden_missing_exact
    let source = fs.read_text(/work/uniqcat.xsh)?
    forbidden_operations = ! control.source_has_forbidden_subprocess(source)
    read_referenced = "read_text" in source
    if ! all_exact or ! forbidden_operations or ! read_referenced {
      eval_status = 1
    }

    if all_exact and forbidden_operations and read_referenced {
      print "task-uniqcat evaluation passed"
    } else {
      eprint "task-uniqcat evaluation failed"
    }
  } else {
    eprint "pi completed without creating /work/uniqcat.xsh"
    eval_status = 1
  }

  review_ok = check_review(/work)?
  if ! review_ok {
    eprint "task-uniqcat evaluation failed: review.md missing or incomplete"
    eval_status = 1
  }

  let correctness_ok = artifact_present and all_exact
  let restriction_ok = artifact_present and forbidden_operations and read_referenced
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
  let handbook_sha = if fs.exists(/work/handbook.md)? { hash.sha256(/work/handbook.md)?.hex() } else { "" }
  let agents_sha = if fs.exists(/work/agents.md)? { hash.sha256(/work/agents.md)?.hex() } else { "" }
  let task_sha = if fs.exists(/work/task.md)? { hash.sha256(/work/task.md)?.hex() } else { "" }
  let candidate_sha = if fs.exists(/session/candidate.1.stdout)? {
    hash.sha256(/session/candidate.1.stdout)?.hex()
  } else {
    ""
  }
  let oracle_sha = if fs.exists(/session/oracle.1.stdout)? { hash.sha256(/session/oracle.1.stdout)?.hex() } else { "" }
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
        hidden_single_exact: hidden_single_exact,
        hidden_three_exact: hidden_three_exact,
        hidden_blank_exact: hidden_blank_exact,
        hidden_utf8_exact: hidden_utf8_exact,
        hidden_space_exact: hidden_space_exact,
        hidden_all_empty_exact: hidden_all_empty_exact,
        hidden_missing_exact: hidden_missing_exact,
        all_exact: all_exact,
      },
      restrictions: {
        forbidden_operations: forbidden_operations,
        read_referenced: read_referenced,
        passed: restriction_ok,
      },
      timings: {
        public_candidate_wall_ns: public_candidate_wall_ns,
        public_oracle_wall_ns: public_oracle_wall_ns,
        hidden_single_candidate_wall_ns: hidden_single_candidate_wall_ns,
        hidden_single_oracle_wall_ns: hidden_single_oracle_wall_ns,
        hidden_three_candidate_wall_ns: hidden_three_candidate_wall_ns,
        hidden_three_oracle_wall_ns: hidden_three_oracle_wall_ns,
        hidden_blank_candidate_wall_ns: hidden_blank_candidate_wall_ns,
        hidden_blank_oracle_wall_ns: hidden_blank_oracle_wall_ns,
        hidden_utf8_candidate_wall_ns: hidden_utf8_candidate_wall_ns,
        hidden_utf8_oracle_wall_ns: hidden_utf8_oracle_wall_ns,
        hidden_space_candidate_wall_ns: hidden_space_candidate_wall_ns,
        hidden_space_oracle_wall_ns: hidden_space_oracle_wall_ns,
        hidden_all_empty_candidate_wall_ns: hidden_all_empty_candidate_wall_ns,
        hidden_all_empty_oracle_wall_ns: hidden_all_empty_oracle_wall_ns,
        hidden_missing_candidate_wall_ns: hidden_missing_candidate_wall_ns,
        hidden_missing_oracle_wall_ns: hidden_missing_oracle_wall_ns,
      },
    },
    pretty: true,
  )?
  eval_status
}

proc main(..._: List[Str]) [fs, process, env, time, error, io] {
  var status = run_task_uniqcat()?
  abort(status)
}
