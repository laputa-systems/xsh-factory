##! task-safepath self-contained package evaluator (no legacy/common controller
##! dependency). Runs in the read-only eval container with:
##!   /work      mounted read-only: candidate safepath.xsh, task.md, handbook.md
##!   /session   mounted rw: candidate/oracle stdout + run.json manifest
##!   /export    mounted rw (same worker dir): artifact + review.md copies
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

type Safecase = {name: Str, root: Str, rel: Str}

type SafecaseResult = {exact: Bool, candidate_wall_ns: Int, oracle_wall_ns: Int}

proc run_safecase(index: Int, case: Safecase) [fs, process, time, error] -> Result[SafecaseResult] {
  let candidate = time.measure(
    process.command_argv(
      "xsh",
      ["xsh", "/work/safepath.xsh", case.root, case.rel],
      stdout: fp"/session/candidate.${index}.stdout",
      stderr: fp"/session/candidate.${index}.stderr",
    ),
  )?
  let oracle = time.measure(
    process.command_argv(
      "sh",
      ["sh", "/tmp/safepath-oracle.sh", case.root, case.rel],
      stdout: fp"/session/oracle.${index}.stdout",
      stderr: fp"/session/oracle.${index}.stderr",
    ),
  )?
  let cand_ok = candidate.status.ok
  let orcl_ok = oracle.status.ok
  let out_eq = fs.read_text(fp"/session/candidate.${index}.stdout")? == fs.read_text(
    fp"/session/oracle.${index}.stdout",
  )?
  return {exact: cand_ok == orcl_ok and out_eq, candidate_wall_ns: candidate.wall_ns, oracle_wall_ns: oracle.wall_ns}
}

proc run_task_safepath() [fs, process, env, time, error, io] -> Result[Int] {
  defer copy_results("safepath.xsh")?
  var eval_status = 0
  let artifact_present = fs.exists(/work/safepath.xsh)?
  var review_ok = false
  var forbidden_operations = false
  var all_exact = false

  let cases: List[Safecase] = [
    {
      name: "public",
      root: "/srv/app",
      rel: "a/b/c",
    },
    {
      name: "hidden_collapse",
      root: "/srv/app",
      rel: "a/../b",
    },
    {
      name: "hidden_dot_slash",
      root: "/srv/app",
      rel: "a/./b//c",
    },
    {
      name: "hidden_empty",
      root: "/srv/app",
      rel: "",
    },
    {
      name: "hidden_leading_dotdot",
      root: "/srv/app",
      rel: "..",
    },
    {
      name: "hidden_midescape",
      root: "/srv/app",
      rel: "a/../../etc",
    },
    {
      name: "hidden_absolute",
      root: "/srv/app",
      rel: "/etc/passwd",
    },
    {
      name: "hidden_deep_escape",
      root: "/srv/app",
      rel: "x/../../../y",
    },
  ]

  var public_exact = false
  var public_candidate_wall_ns = 0
  var public_oracle_wall_ns = 0
  var hidden_collapse_exact = false
  var hidden_collapse_candidate_wall_ns = 0
  var hidden_collapse_oracle_wall_ns = 0
  var hidden_dot_slash_exact = false
  var hidden_dot_slash_candidate_wall_ns = 0
  var hidden_dot_slash_oracle_wall_ns = 0
  var hidden_empty_exact = false
  var hidden_empty_candidate_wall_ns = 0
  var hidden_empty_oracle_wall_ns = 0
  var hidden_leading_dotdot_exact = false
  var hidden_leading_dotdot_candidate_wall_ns = 0
  var hidden_leading_dotdot_oracle_wall_ns = 0
  var hidden_midescape_exact = false
  var hidden_midescape_candidate_wall_ns = 0
  var hidden_midescape_oracle_wall_ns = 0
  var hidden_absolute_exact = false
  var hidden_absolute_candidate_wall_ns = 0
  var hidden_absolute_oracle_wall_ns = 0
  var hidden_deep_escape_exact = false
  var hidden_deep_escape_candidate_wall_ns = 0
  var hidden_deep_escape_oracle_wall_ns = 0

  if artifact_present {
    fs.write(
      /tmp/safepath-oracle.sh,
      r"""#!/bin/sh
root="$1"; rel="$2"
case "$rel" in
  /*) echo "escape: $rel"; exit 1 ;;
esac
stack=""
old="$IFS"; IFS="/"
for seg in $rel; do
  case "$seg" in
    ""|".") : ;;
    "..")
      if [ -z "$stack" ]; then echo "escape: $rel"; exit 1; fi
      case "$stack" in
        */*) stack="${stack%/*}" ;;
        *)   stack="" ;;
      esac
      ;;
    *) stack="${stack}${stack:+/}${seg}" ;;
  esac
done
IFS="$old"
if [ -z "$stack" ]; then echo "$root"; else echo "$root/$stack"; fi
exit 0
""",
    )?
    var index = 0
    for case in cases {
      index += 1
      let result = run_safecase(index, case)?
      if case.name == "public" {
        public_exact = result.exact
        public_candidate_wall_ns = result.candidate_wall_ns
        public_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_collapse" {
        hidden_collapse_exact = result.exact
        hidden_collapse_candidate_wall_ns = result.candidate_wall_ns
        hidden_collapse_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_dot_slash" {
        hidden_dot_slash_exact = result.exact
        hidden_dot_slash_candidate_wall_ns = result.candidate_wall_ns
        hidden_dot_slash_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_empty" {
        hidden_empty_exact = result.exact
        hidden_empty_candidate_wall_ns = result.candidate_wall_ns
        hidden_empty_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_leading_dotdot" {
        hidden_leading_dotdot_exact = result.exact
        hidden_leading_dotdot_candidate_wall_ns = result.candidate_wall_ns
        hidden_leading_dotdot_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_midescape" {
        hidden_midescape_exact = result.exact
        hidden_midescape_candidate_wall_ns = result.candidate_wall_ns
        hidden_midescape_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_absolute" {
        hidden_absolute_exact = result.exact
        hidden_absolute_candidate_wall_ns = result.candidate_wall_ns
        hidden_absolute_oracle_wall_ns = result.oracle_wall_ns
      } else if case.name == "hidden_deep_escape" {
        hidden_deep_escape_exact = result.exact
        hidden_deep_escape_candidate_wall_ns = result.candidate_wall_ns
        hidden_deep_escape_oracle_wall_ns = result.oracle_wall_ns
      }
    }

    all_exact = public_exact and hidden_collapse_exact and hidden_dot_slash_exact and hidden_empty_exact and hidden_leading_dotdot_exact and hidden_midescape_exact and hidden_absolute_exact and hidden_deep_escape_exact
    let source = fs.read_text(/work/safepath.xsh)?
    forbidden_operations = ! source_has_forbidden_subprocess(source)
    if ! all_exact or ! forbidden_operations {
      eval_status = 1
    }

    if all_exact and forbidden_operations {
      print "task-safepath evaluation passed"
    } else {
      eprint "task-safepath evaluation failed"
    }
  } else {
    eprint "pi completed without creating /work/safepath.xsh"
    eval_status = 1
  }

  review_ok = check_review(/work)?
  if ! review_ok {
    eprint "task-safepath evaluation failed: review.md missing or incomplete"
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
      eval_id: env.get_or("FACTORY_EVAL_ID", "task-safepath")?,
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
        hidden_collapse_exact: hidden_collapse_exact,
        hidden_dot_slash_exact: hidden_dot_slash_exact,
        hidden_empty_exact: hidden_empty_exact,
        hidden_leading_dotdot_exact: hidden_leading_dotdot_exact,
        hidden_midescape_exact: hidden_midescape_exact,
        hidden_absolute_exact: hidden_absolute_exact,
        hidden_deep_escape_exact: hidden_deep_escape_exact,
        all_exact: all_exact,
      },
      restrictions: {
        forbidden_operations: forbidden_operations,
        passed: restriction_ok,
      },
      timings: {
        public_candidate_wall_ns: public_candidate_wall_ns,
        public_oracle_wall_ns: public_oracle_wall_ns,
        hidden_collapse_candidate_wall_ns: hidden_collapse_candidate_wall_ns,
        hidden_collapse_oracle_wall_ns: hidden_collapse_oracle_wall_ns,
        hidden_dot_slash_candidate_wall_ns: hidden_dot_slash_candidate_wall_ns,
        hidden_dot_slash_oracle_wall_ns: hidden_dot_slash_oracle_wall_ns,
        hidden_empty_candidate_wall_ns: hidden_empty_candidate_wall_ns,
        hidden_empty_oracle_wall_ns: hidden_empty_oracle_wall_ns,
        hidden_leading_dotdot_candidate_wall_ns: hidden_leading_dotdot_candidate_wall_ns,
        hidden_leading_dotdot_oracle_wall_ns: hidden_leading_dotdot_oracle_wall_ns,
        hidden_midescape_candidate_wall_ns: hidden_midescape_candidate_wall_ns,
        hidden_midescape_oracle_wall_ns: hidden_midescape_oracle_wall_ns,
        hidden_absolute_candidate_wall_ns: hidden_absolute_candidate_wall_ns,
        hidden_absolute_oracle_wall_ns: hidden_absolute_oracle_wall_ns,
        hidden_deep_escape_candidate_wall_ns: hidden_deep_escape_candidate_wall_ns,
        hidden_deep_escape_oracle_wall_ns: hidden_deep_escape_oracle_wall_ns,
      },
    },
    pretty: true,
  )?
  eval_status
}

proc main(...argv: List[Str]) [fs, process, env, time, error, io] {
  let eval_id = if argv.len() > 0 { argv[0] } else { env.get_or("FACTORY_EVAL_ID", "task-safepath")? }
  var status = 2
  if eval_id == "task-safepath" {
    status = run_task_safepath()?
  } else {
    eprint f"unknown eval id: ${eval_id}"
  }

  abort(status)
}
