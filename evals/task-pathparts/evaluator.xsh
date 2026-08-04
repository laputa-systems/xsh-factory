##! Task-pathparts evaluator package implementation (self-contained).
##! Runs inside the evaluator container: /work is the readonly candidate
##! workspace, /session and /export are writable views of the same host dir.

type PathCase = {name: Str, path: Str}

type CaseResult = {exact: Bool, candidate_wall_ns: Int, oracle_wall_ns: Int}

pure forbidden_source(source: Str) -> Bool {
  for line in source.lines() {
    let code = line.split("#").get(0, "")
    if code.contains("process.") or code.contains("spawn ") or code.contains("run ") {
      return true
    }
  }
  return false
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

proc copy_results(artifact: Str) [fs, error] -> Result[Unit] {
  for name in [artifact, "review.md"] {
    let src = fp"/work/${name}"
    if fs.exists(src)? {
      fs.copy(src, fp"/export/${name}", overwrite: true)?
    }
  }
}

proc run_case(index: Int, c: PathCase) [fs, process, time, error] -> Result[CaseResult] {
  let candidate = time.measure(process.command_argv(
    "xsh", ["xsh", "/work/pathparts.xsh", c.path],
    stdout: fp"/session/candidate.${index}.stdout", stderr: fp"/session/candidate.${index}.stderr",
  ))?
  let oracle = time.measure(process.command_argv(
    "sh", ["sh", "/tmp/pathparts-oracle.sh", c.path],
    stdout: fp"/session/oracle.${index}.stdout", stderr: fp"/session/oracle.${index}.stderr",
  ))?
  let exact = candidate.status.ok and oracle.status.ok and
    fs.read_text(fp"/session/candidate.${index}.stdout")? == fs.read_text(fp"/session/oracle.${index}.stdout")?
  return {exact: exact, candidate_wall_ns: candidate.wall_ns, oracle_wall_ns: oracle.wall_ns}
}

proc main() [fs, process, env, time, error, io] {
  defer copy_results("pathparts.xsh")?
  var eval_status = 0
  let artifact_present = fs.exists(p"/work/pathparts.xsh")?
  var review_ok = false
  var all_exact = false
  var no_forbidden = false
  var path_referenced = false
  var exact_map: Map[Bool] = {}
  var timing_map: Map[Int] = {}

  if artifact_present {
    fs.write(p"/tmp/pathparts-oracle.sh", r"""#!/bin/sh
dir=$(dirname "$1")
name=$(basename "$1")
case "$name" in
  ?*.*) ext="${name##*.}" ;;
  *) ext="none" ;;
esac
printf 'dir=%s\nname=%s\next=%s\n' "$dir" "$name" "$ext"
""")?
    let cases: List[PathCase] = [
      {name: "public", path: "/srv/app/server.cfg"},
      {name: "hidden_deep", path: "/var/log/app/archive/2024-01-01.txt.gz"},
      {name: "hidden_plain", path: "notes"},
      {name: "hidden_rel", path: "conf/nginx.conf"},
      {name: "hidden_dotdir", path: "/home/u/.config/app.yaml"},
      {name: "hidden_dotfile", path: "/root/.profile"},
      {name: "hidden_targz", path: "report.tar.gz"},
    ]
    var index = 0
    for c in cases {
      index += 1
      let result = run_case(index, c)?
      exact_map = exact_map.set(c.name, result.exact)
      timing_map = timing_map.set(c.name + "_candidate_wall_ns", result.candidate_wall_ns)
      timing_map = timing_map.set(c.name + "_oracle_wall_ns", result.oracle_wall_ns)
    }
    all_exact = true
    for c in cases {
      all_exact = all_exact and exact_map.get(c.name, false)
    }
    let source = fs.read_text(p"/work/pathparts.xsh")?
    no_forbidden = ! forbidden_source(source)
    path_referenced = source.contains("Path(")
    if ! all_exact or ! no_forbidden or ! path_referenced {
      eval_status = 1
    }
    if all_exact and no_forbidden and path_referenced {
      print "task-pathparts evaluation passed"
    } else {
      eprint "task-pathparts evaluation failed"
    }
  } else {
    eprint "pi completed without creating /work/pathparts.xsh"
    eval_status = 1
  }

  review_ok = check_review(p"/work")?
  if ! review_ok {
    eprint "task-pathparts evaluation failed: review.md missing or incomplete"
    eval_status = 1
  }
  let correctness_ok = artifact_present and all_exact
  let restriction_ok = artifact_present and no_forbidden and path_referenced
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
    correctness: exact_map,
    restrictions: {no_forbidden: no_forbidden, path_referenced: path_referenced, passed: restriction_ok},
    timings: timing_map,
  }, pretty: true)?
  abort(eval_status)
}
