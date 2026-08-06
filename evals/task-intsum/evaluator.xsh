##! Task-intsum evaluator package implementation.
proc copy_results(artifact: Str) [fs, error] {
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
""") and ! ("""
**Rationale.** What fell short for this task.""" in text) and ! ("""
**Symptom.** What you queried or ran and what came back.""" in text)
}

pure source_has_forbidden_subprocess(source: Str) -> Bool {
  for line in source.lines() {
    let code = line.split("#").get(0, "")
    if "process." in code or "spawn " in code or "run " in code {
      return true
    }
  }

  return false
}

type IntsumCase = {name: Str, args: List[Str], expect_fail: Bool}

type IntsumCaseResult = {exact: Bool, candidate_wall_ns: Int, oracle_wall_ns: Int}

proc run_case(index: Int, case: IntsumCase) [fs, process, time, error] -> Result[IntsumCaseResult] {
  let candidate = time.measure(
    process.command_argv(
      "xsh",
      ["xsh", "/work/intsum.xsh"].extend(case.args),
      stdout: fp"/session/candidate.${index}.stdout",
      stderr: fp"/session/candidate.${index}.stderr",
    ),
  )?
  let oracle = time.measure(
    process.command_argv(
      "sh",
      ["sh", "/tmp/intsum-oracle.sh"].extend(case.args),
      stdout: fp"/session/oracle.${index}.stdout",
      stderr: fp"/session/oracle.${index}.stderr",
    ),
  )?
  let exact = if case.expect_fail {
    ! candidate.status.ok and ! oracle.status.ok
  } else {
    candidate.status.ok and oracle.status.ok and fs.read_text(fp"/session/candidate.${index}.stdout")? == fs.read_text(
      fp"/session/oracle.${index}.stdout",
    )?
  }
  return {exact: exact, candidate_wall_ns: candidate.wall_ns, oracle_wall_ns: oracle.wall_ns}
}

proc main() [fs, process, env, time, error, io] {
  defer copy_results("intsum.xsh")?
  var eval_status = 0
  let artifact_present = fs.exists(/work/intsum.xsh)?
  var review_ok = false
  var forbidden_operations = false
  var all_exact = false
  var public_exact = false
  var hidden_zero_exact = false
  var hidden_neg_exact = false
  var hidden_large_exact = false
  var hidden_mixed_exact = false
  var hidden_malformed_exact = false
  var public_candidate_wall_ns = 0
  var public_oracle_wall_ns = 0
  var hidden_zero_candidate_wall_ns = 0
  var hidden_zero_oracle_wall_ns = 0
  var hidden_neg_candidate_wall_ns = 0
  var hidden_neg_oracle_wall_ns = 0
  var hidden_large_candidate_wall_ns = 0
  var hidden_large_oracle_wall_ns = 0
  var hidden_mixed_candidate_wall_ns = 0
  var hidden_mixed_oracle_wall_ns = 0
  var hidden_malformed_candidate_wall_ns = 0
  var hidden_malformed_oracle_wall_ns = 0

  if artifact_present {
    fs.write(
      /tmp/intsum-oracle.sh,
      r"""#!/bin/sh
total=0
for n in "$@"; do
  case "$n" in
    ''|*[!0-9-]*) exit 1 ;;
  esac
  total=$((total + n))
done
printf '%d\n' "$total"
""",
    )?
    let cases: List[IntsumCase] = [
      {
        name: "public",
        args: [
          "4",
          "9",
          "2",
        ],
        expect_fail: false,
      },
      {
        name: "hidden_zero",
        args: [],
        expect_fail: false,
      },
      {
        name: "hidden_neg",
        args: [
          "-3",
          "7",
          "-1",
        ],
        expect_fail: false,
      },
      {
        name: "hidden_large",
        args: [
          "2147483647",
          "1",
        ],
        expect_fail: false,
      },
      {
        name: "hidden_mixed",
        args: [
          "0",
          "10",
          "20",
        ],
        expect_fail: false,
      },
      {
        name: "hidden_malformed",
        args: [
          "5",
          "abc",
          "2",
        ],
        expect_fail: true,
      },
    ]
    var index = 0
    for case in cases {
      index += 1
      let result = run_case(index, case)?
      if case.name == "public" {
        public_exact = result.exact
        public_candidate_wall_ns = result.candidate_wall_ns
        public_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_zero" {
        hidden_zero_exact = result.exact
        hidden_zero_candidate_wall_ns = result.candidate_wall_ns
        hidden_zero_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_neg" {
        hidden_neg_exact = result.exact
        hidden_neg_candidate_wall_ns = result.candidate_wall_ns
        hidden_neg_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_large" {
        hidden_large_exact = result.exact
        hidden_large_candidate_wall_ns = result.candidate_wall_ns
        hidden_large_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_mixed" {
        hidden_mixed_exact = result.exact
        hidden_mixed_candidate_wall_ns = result.candidate_wall_ns
        hidden_mixed_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_malformed" {
        hidden_malformed_exact = result.exact
        hidden_malformed_candidate_wall_ns = result.candidate_wall_ns
        hidden_malformed_oracle_wall_ns = result.oracle_wall_ns
      }
    }

    all_exact = public_exact and hidden_zero_exact and hidden_neg_exact and hidden_large_exact and hidden_mixed_exact and hidden_malformed_exact
    let source = fs.read_text(/work/intsum.xsh)?
    forbidden_operations = ! source_has_forbidden_subprocess(source)
    if ! all_exact or ! forbidden_operations {
      eval_status = 1
    }

    if all_exact and forbidden_operations {
      print "task-intsum evaluation passed"
    } else {
      eprint "task-intsum evaluation failed"
    }
  } else {
    eprint "pi completed without creating /work/intsum.xsh"
    eval_status = 1
  }

  review_ok = check_review(/work)?
  if ! review_ok {
    eprint "task-intsum evaluation failed: review.md missing or incomplete"
    eval_status = 1
  }

  let correctness_ok = artifact_present and all_exact
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
      eval_id: env.get_or("FACTORY_EVAL_ID", "task-intsum")?,
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
        hidden_zero_exact: hidden_zero_exact,
        hidden_neg_exact: hidden_neg_exact,
        hidden_large_exact: hidden_large_exact,
        hidden_mixed_exact: hidden_mixed_exact,
        hidden_malformed_exact: hidden_malformed_exact,
        all_exact: all_exact,
      },
      restrictions: {
        forbidden_operations: forbidden_operations,
        passed: restriction_ok,
      },
      timings: {
        public_candidate_wall_ns: public_candidate_wall_ns,
        public_oracle_wall_ns: public_oracle_wall_ns,
        hidden_zero_candidate_wall_ns: hidden_zero_candidate_wall_ns,
        hidden_zero_oracle_wall_ns: hidden_zero_oracle_wall_ns,
        hidden_neg_candidate_wall_ns: hidden_neg_candidate_wall_ns,
        hidden_neg_oracle_wall_ns: hidden_neg_oracle_wall_ns,
        hidden_large_candidate_wall_ns: hidden_large_candidate_wall_ns,
        hidden_large_oracle_wall_ns: hidden_large_oracle_wall_ns,
        hidden_mixed_candidate_wall_ns: hidden_mixed_candidate_wall_ns,
        hidden_mixed_oracle_wall_ns: hidden_mixed_oracle_wall_ns,
        hidden_malformed_candidate_wall_ns: hidden_malformed_candidate_wall_ns,
        hidden_malformed_oracle_wall_ns: hidden_malformed_oracle_wall_ns,
      },
    },
    pretty: true,
  )?
  abort(if eval_status == 0 { 0 } else { 1 })
}
