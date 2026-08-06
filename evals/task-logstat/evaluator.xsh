##! Task-logstat self-contained package evaluator (no legacy/common controller
##! dependency). Runs in the read-only eval container with:
##!   /work     mounted read-only: candidate logstat.xsh, task.md, handbook.md
##!   /session  mounted rw: candidate/oracle stdout + run.json manifest
##!   /export   mounted rw (same worker dir): artifact + review.md copies
##!   /tmp      rw tmpfs: fixture log files and the oracle script
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

type LogCase = {name: Str, lines: List[Str]}

type LogCaseResult = {exact: Bool, candidate_wall_ns: Int, oracle_wall_ns: Int}

proc run_log_case(index: Int, fixture: Path) [fs, process, time, error] -> Result[LogCaseResult] {
  let candidate = time.measure(
    process.command_argv(
      "xsh",
      ["xsh", "/work/logstat.xsh", fixture.display()],
      stdout: fp"/session/candidate.${index}.stdout",
      stderr: fp"/session/candidate.${index}.stderr",
    ),
  )?
  let oracle = time.measure(
    process.command_argv(
      "sh",
      ["sh", "/tmp/logstat-oracle.sh", fixture.display()],
      stdout: fp"/session/oracle.${index}.stdout",
      stderr: fp"/session/oracle.${index}.stderr",
    ),
  )?
  let exact = candidate.status.ok and oracle.status.ok and fs.read_text(fp"/session/candidate.${index}.stdout")? == fs.read_text(
    fp"/session/oracle.${index}.stdout",
  )?
  return {exact: exact, candidate_wall_ns: candidate.wall_ns, oracle_wall_ns: oracle.wall_ns}
}

proc run_task_logstat() [fs, process, env, time, error, io] -> Result[Int] {
  defer copy_results("logstat.xsh")?
  var eval_status = 0
  let artifact_present = fs.exists(/work/logstat.xsh)?
  var review_ok = false
  var forbidden_operations = false
  var all_exact = false

  let cases: List[LogCase] = [
    {
      name: "public",
      lines: [
        "10.0.0.1 - - [10/Oct/2000:13:55:36 -0700] \"GET /index.html HTTP/1.0\" 200 2326",
        "10.0.0.2 - - [10/Oct/2000:13:55:37 -0700] \"GET /a.css HTTP/1.0\" 200 120",
        "10.0.0.3 - - [10/Oct/2000:13:55:38 -0700] \"POST /api HTTP/1.0\" 404 57",
        "10.0.0.1 - - [10/Oct/2000:13:55:39 -0700] \"GET /b.png HTTP/1.0\" 200 800",
        "10.0.0.9 - - [10/Oct/2000:13:55:40 -0700] \"GET /c HTTP/1.0\" 503 12",
        "10.0.0.4 - - [10/Oct/2000:13:55:41 -0700] \"GET /d HTTP/1.0\" 500 99",
        "10.0.0.5 - - [10/Oct/2000:13:55:42 -0700] \"GET /e HTTP/1.0\" 404 1",
      ],
    },
    {
      name: "hidden_order",
      lines: [
        "1.1.1.1 - - [01/Jan/2020:01:01:01 +0000] \"GET /a HTTP/1.1\" 503 1",
        "2.2.2.2 - - [01/Jan/2020:01:01:02 +0000] \"GET /b HTTP/1.1\" 200 1",
        "3.3.3.3 - - [01/Jan/2020:01:01:03 +0000] \"GET /c HTTP/1.1\" 404 1",
        "4.4.4.4 - - [01/Jan/2020:01:01:04 +0000] \"GET /d HTTP/1.1\" 301 1",
        "1.1.1.1 - - [01/Jan/2020:01:01:05 +0000] \"GET /e HTTP/1.1\" 503 1",
        "5.5.5.5 - - [01/Jan/2020:01:01:06 +0000] \"GET /f HTTP/1.1\" 500 1",
      ],
    },
    {
      name: "hidden_single",
      lines: [
        "9.9.9.9 - - [02/Feb/2020:02:02:02 +0000] \"GET /x HTTP/1.1\" 204 0",
        "8.8.8.8 - - [02/Feb/2020:02:02:03 +0000] \"GET /y HTTP/1.1\" 204 0",
        "7.7.7.7 - - [02/Feb/2020:02:02:04 +0000] \"GET /z HTTP/1.1\" 204 0",
      ],
    },
    {
      name: "hidden_many",
      lines: [
        "1.1.1.1 - - [03/Mar/2020:03:03:01 +0000] \"GET /a HTTP/1.1\" 200 1",
        "2.2.2.2 - - [03/Mar/2020:03:03:02 +0000] \"GET /b HTTP/1.1\" 301 1",
        "3.3.3.3 - - [03/Mar/2020:03:03:03 +0000] \"GET /c HTTP/1.1\" 400 1",
        "4.4.4.4 - - [03/Mar/2020:03:03:04 +0000] \"GET /d HTTP/1.1\" 201 1",
        "1.1.1.1 - - [03/Mar/2020:03:03:05 +0000] \"GET /e HTTP/1.1\" 200 1",
        "5.5.5.5 - - [03/Mar/2020:03:03:06 +0000] \"GET /f HTTP/1.1\" 503 1",
        "6.6.6.6 - - [03/Mar/2020:03:03:07 +0000] \"GET /g HTTP/1.1\" 200 1",
        "7.7.7.7 - - [03/Mar/2020:03:03:08 +0000] \"GET /h HTTP/1.1\" 502 1",
        "8.8.8.8 - - [03/Mar/2020:03:03:09 +0000] \"GET /i HTTP/1.1\" 301 1",
        "9.9.9.9 - - [03/Mar/2020:03:03:10 +0000] \"GET /j HTTP/1.1\" 500 1",
      ],
    },
    {
      name: "hidden_empty",
      lines: [],
    },
    {
      name: "hidden_noise",
      lines: [
        "1.1.1.1 - - [04/Apr/2020:04:04:01 +0000] \"GET /a HTTP/1.1\" 200 5",
        "2.2.2.2 - - [04/Apr/2020:04:04:02 +0000] \"GET /b HTTP/1.1\" 4xx 0",
        "3.3.3.3 - - [04/Apr/2020:04:04:03 +0000] \"GET /c HTTP/1.1\" 404 1",
        "4.4.4.4 - - [04/Apr/2020:04:04:04 +0000] \"GET /d HTTP/1.1\" 500 7",
        "5.5.5.5 - - [04/Apr/2020:04:04:05 +0000] \"GET /e HTTP/1.1\" xx 0",
      ],
    },
    {
      name: "hidden_nomatch",
      lines: [
        "1.1.1.1 - - [05/May/2020:05:05:01 +0000] \"GET /a HTTP/1.1\" 4xx 0",
        "2.2.2.2 - - [05/May/2020:05:05:02 +0000] \"GET /b HTTP/1.1\" abc 0",
      ],
    },
    {
      name: "hidden_dupheavy",
      lines: [
        "1.1.1.1 - - [06/Jun/2020:06:06:01 +0000] \"GET /a HTTP/1.1\" 200 1",
        "2.2.2.2 - - [06/Jun/2020:06:06:02 +0000] \"GET /b HTTP/1.1\" 200 1",
        "3.3.3.3 - - [06/Jun/2020:06:06:03 +0000] \"GET /c HTTP/1.1\" 404 1",
        "4.4.4.4 - - [06/Jun/2020:06:06:04 +0000] \"GET /d HTTP/1.1\" 200 1",
        "5.5.5.5 - - [06/Jun/2020:06:06:05 +0000] \"GET /e HTTP/1.1\" 404 1",
        "1.1.1.1 - - [06/Jun/2020:06:06:06 +0000] \"GET /f HTTP/1.1\" 200 1",
        "2.2.2.2 - - [06/Jun/2020:06:06:07 +0000] \"GET /g HTTP/1.1\" 200 1",
      ],
    },
  ]

  var public_exact = false
  var public_candidate_wall_ns = 0
  var public_oracle_wall_ns = 0
  var hidden_order_exact = false
  var hidden_order_candidate_wall_ns = 0
  var hidden_order_oracle_wall_ns = 0
  var hidden_single_exact = false
  var hidden_single_candidate_wall_ns = 0
  var hidden_single_oracle_wall_ns = 0
  var hidden_many_exact = false
  var hidden_many_candidate_wall_ns = 0
  var hidden_many_oracle_wall_ns = 0
  var hidden_empty_exact = false
  var hidden_empty_candidate_wall_ns = 0
  var hidden_empty_oracle_wall_ns = 0
  var hidden_noise_exact = false
  var hidden_noise_candidate_wall_ns = 0
  var hidden_noise_oracle_wall_ns = 0
  var hidden_nomatch_exact = false
  var hidden_nomatch_candidate_wall_ns = 0
  var hidden_nomatch_oracle_wall_ns = 0
  var hidden_dupheavy_exact = false
  var hidden_dupheavy_candidate_wall_ns = 0
  var hidden_dupheavy_oracle_wall_ns = 0

  if artifact_present {
    fs.write(
      /tmp/logstat-oracle.sh,
      """#!/bin/sh
awk '{print $9}' "$1" | grep -E '^[0-9]+$' | sort -n | uniq -c | awk '{printf "%d %d\\n", $2, $1}'
""",
    )?
    var index = 0
    for case in cases {
      index += 1
      let fixture = fp"/tmp/logstat-case.${index}.log"
      if case.lines.len() == 0 {
        fs.write(fixture, "")?
      } else {
        fs.write(fixture, case.lines.join("\n") + "\n")?
      }

      let result = run_log_case(index, fixture)?
      if case.name == "public" {
        public_exact = result.exact
        public_candidate_wall_ns = result.candidate_wall_ns
        public_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_order" {
        hidden_order_exact = result.exact
        hidden_order_candidate_wall_ns = result.candidate_wall_ns
        hidden_order_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_single" {
        hidden_single_exact = result.exact
        hidden_single_candidate_wall_ns = result.candidate_wall_ns
        hidden_single_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_many" {
        hidden_many_exact = result.exact
        hidden_many_candidate_wall_ns = result.candidate_wall_ns
        hidden_many_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_empty" {
        hidden_empty_exact = result.exact
        hidden_empty_candidate_wall_ns = result.candidate_wall_ns
        hidden_empty_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_noise" {
        hidden_noise_exact = result.exact
        hidden_noise_candidate_wall_ns = result.candidate_wall_ns
        hidden_noise_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_nomatch" {
        hidden_nomatch_exact = result.exact
        hidden_nomatch_candidate_wall_ns = result.candidate_wall_ns
        hidden_nomatch_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_dupheavy" {
        hidden_dupheavy_exact = result.exact
        hidden_dupheavy_candidate_wall_ns = result.candidate_wall_ns
        hidden_dupheavy_oracle_wall_ns = result.oracle_wall_ns
      }
    }

    all_exact = public_exact and hidden_order_exact and hidden_single_exact and hidden_many_exact and hidden_empty_exact and hidden_noise_exact and hidden_nomatch_exact and hidden_dupheavy_exact
    let source = fs.read_text(/work/logstat.xsh)?
    forbidden_operations = ! source_has_forbidden_subprocess(source)
    if ! all_exact or ! forbidden_operations {
      eval_status = 1
    }

    if all_exact and forbidden_operations {
      print "task-logstat evaluation passed"
    } else {
      eprint "task-logstat evaluation failed"
    }
  } else {
    eprint "pi completed without creating /work/logstat.xsh"
    eval_status = 1
  }

  review_ok = check_review(/work)?
  if ! review_ok {
    eprint "task-logstat evaluation failed: review.md missing or incomplete"
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
      eval_id: env.get_or("FACTORY_EVAL_ID", "task-logstat")?,
      trial_id: env.get_or("FACTORY_TRIAL_ID", "1")?,
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
        hidden_order_exact: hidden_order_exact,
        hidden_single_exact: hidden_single_exact,
        hidden_many_exact: hidden_many_exact,
        hidden_empty_exact: hidden_empty_exact,
        hidden_noise_exact: hidden_noise_exact,
        hidden_nomatch_exact: hidden_nomatch_exact,
        hidden_dupheavy_exact: hidden_dupheavy_exact,
        all_exact: all_exact,
      },
      restrictions: {
        forbidden_operations: forbidden_operations,
        passed: restriction_ok,
      },
      timings: {
        public_candidate_wall_ns: public_candidate_wall_ns,
        public_oracle_wall_ns: public_oracle_wall_ns,
        hidden_order_candidate_wall_ns: hidden_order_candidate_wall_ns,
        hidden_order_oracle_wall_ns: hidden_order_oracle_wall_ns,
        hidden_single_candidate_wall_ns: hidden_single_candidate_wall_ns,
        hidden_single_oracle_wall_ns: hidden_single_oracle_wall_ns,
        hidden_many_candidate_wall_ns: hidden_many_candidate_wall_ns,
        hidden_many_oracle_wall_ns: hidden_many_oracle_wall_ns,
        hidden_empty_candidate_wall_ns: hidden_empty_candidate_wall_ns,
        hidden_empty_oracle_wall_ns: hidden_empty_oracle_wall_ns,
        hidden_noise_candidate_wall_ns: hidden_noise_candidate_wall_ns,
        hidden_noise_oracle_wall_ns: hidden_noise_oracle_wall_ns,
        hidden_nomatch_candidate_wall_ns: hidden_nomatch_candidate_wall_ns,
        hidden_nomatch_oracle_wall_ns: hidden_nomatch_oracle_wall_ns,
        hidden_dupheavy_candidate_wall_ns: hidden_dupheavy_candidate_wall_ns,
        hidden_dupheavy_oracle_wall_ns: hidden_dupheavy_oracle_wall_ns,
      },
    },
    pretty: true,
  )?
  eval_status
}

proc main(...argv: List[Str]) [fs, process, env, time, error, io] {
  let eval_id = if argv.len() > 0 { argv[0] } else { env.get_or("FACTORY_EVAL_ID", "task-logstat")? }
  var status = 2
  if eval_id == "task-logstat" {
    status = run_task_logstat()?
  } else {
    eprint f"unknown eval id: ${eval_id}"
  }

  abort(status)
}
