##! Package-owned evaluator for task-dupcheck.
use factory.control as control

type FixtureFile = {dir: Str, name: Str, data: Str}

type Case = {name: Str, dirs: List[Str], files: List[FixtureFile], missing: Bool}

type CaseResult = {
  name: Str,
  exact: Bool,
  candidate_exit: Int,
  oracle_exit: Int,
  candidate_wall_ns: Int,
  oracle_wall_ns: Int,
}

proc copy_results() [fs, error] {
  for name in ["dupcheck.xsh", "review.md"] {
    let source = fp"/work/${name}"
    if fs.exists(source)? {
      fs.copy(source, fp"/export/${name}", overwrite: true)?
    }
  }
}

proc review_ok() [fs, error] -> Result[Bool] {
  let review = /work/review.md
  if ! fs.exists(review)? or fs.metadata(review)?.size == 0 {
    return false
  }

  let text = review.read_text()?
  return text.contains("## XSH language proposals") and text.contains("## xsht friction") and ! ("{{" in text)
}

proc make_fixture(index: Int, case: Case) [fs, error] -> Result[Path] {
  let root = fp"/tmp/task-dupcheck-${index}"
  fs.mkdir(root)?
  for dir in case.dirs {
    fs.mkdir(fp"${root}/${dir}")?
  }

  for file in case.files {
    fs.write(fp"${root}/${file.dir}/${file.name}", file.data)?
  }

  return root
}

proc run_case(index: Int, case: Case, oracle: Path) [fs, process, time, error] -> Result[CaseResult] {
  let root = if case.missing {
    fp"/tmp/task-dupcheck-missing-${index}"
  } else {
    make_fixture(index, case)?
  }
  fs.remove(fp"/session/task-dupcheck-candidate-${index}.stdout", missing_ok: true)?
  fs.remove(fp"/session/task-dupcheck-oracle-${index}.stdout", missing_ok: true)?
  let candidate = time.measure(
    process.command_argv(
      "xsh",
      ["xsh", "/work/dupcheck.xsh", root.display()],
      stdout: fp"/session/task-dupcheck-candidate-${index}.stdout",
      stderr: fp"/session/task-dupcheck-candidate-${index}.stderr",
    ),
  )?
  let oracle_result = time.measure(
    process.command_argv(
      "sh",
      ["sh", oracle.display(), root.display()],
      stdout: fp"/session/task-dupcheck-oracle-${index}.stdout",
      stderr: fp"/session/task-dupcheck-oracle-${index}.stderr",
    ),
  )?
  let candidate_text = if fs.exists(fp"/session/task-dupcheck-candidate-${index}.stdout")? {
    fs.read_text(fp"/session/task-dupcheck-candidate-${index}.stdout")?
  } else {
    ""
  }
  let oracle_text = if fs.exists(fp"/session/task-dupcheck-oracle-${index}.stdout")? {
    fs.read_text(fp"/session/task-dupcheck-oracle-${index}.stdout")?
  } else {
    ""
  }
  let exact = if case.missing {
    ! candidate.status.ok and ! oracle_result.status.ok and candidate_text == ""
  } else {
    candidate.status.ok and oracle_result.status.ok and candidate_text == oracle_text
  }
  return {
    name: case.name,
    exact: exact,
    candidate_exit: candidate.status.exit_code() ?? -1,
    oracle_exit: oracle_result.status.exit_code() ?? -1,
    candidate_wall_ns: candidate.wall_ns,
    oracle_wall_ns: oracle_result.wall_ns,
  }
}

proc main() [fs, process, env, time, error, io] {
  defer copy_results()?
  let artifact = /work/dupcheck.xsh
  let artifact_present = fs.exists(artifact)?
  let oracle = /tmp/task-dupcheck-oracle.sh
  fs.write(
    oracle,
    r"""#!/bin/sh
set -o pipefail
find "$1" -type f -exec sha256sum {} + | sort | awk '
NR == 1 { prev = $1; out = $0; n = 1; next }
$1 == prev { out = out "\n" $0; n++; next }
{ if (n > 1) print out; prev = $1; out = $0; n = 1 }
END { if (n > 1) print out }'
""",
  )?
  fs.chmod(oracle, 0o755)?
  var all_exact = artifact_present
  var cases: List[CaseResult] = []
  if artifact_present {
    let inputs: List[Case] = [
      {
        name: "public",
        dirs: [
          "a",
          "sub",
        ],
        files: [
          {
            dir: "a",
            name: "one.txt",
            data: "hello world",
          },
          {
            dir: "a",
            name: "two.txt",
            data: "hello world",
          },
          {
            dir: "sub",
            name: "three.txt",
            data: "unique content",
          },
        ],
        missing: false,
      },
      {
        name: "hidden_empty",
        dirs: [
          "a",
        ],
        files: [
          {
            dir: "a",
            name: "u1.txt",
            data: "alpha",
          },
          {
            dir: "a",
            name: "u2.txt",
            data: "beta",
          },
        ],
        missing: false,
      },
      {
        name: "hidden_nested",
        dirs: [
          "a",
          "b",
          ".cfg",
        ],
        files: [
          {
            dir: "a",
            name: "one.txt",
            data: "dup-a",
          },
          {
            dir: "b",
            name: "two.txt",
            data: "dup-a",
          },
          {
            dir: ".cfg",
            name: "three.ini",
            data: "dup-a",
          },
          {
            dir: ".cfg",
            name: ".hidden.txt",
            data: "dup-b",
          },
          {
            dir: "a",
            name: "five.txt",
            data: "dup-b",
          },
        ],
        missing: false,
      },
      {
        name: "hidden_three",
        dirs: [
          "x",
        ],
        files: [
          {
            dir: "x",
            name: "a",
            data: "same",
          },
          {
            dir: "x",
            name: "b",
            data: "same",
          },
          {
            dir: "x",
            name: "c",
            data: "same",
          },
        ],
        missing: false,
      },
      {
        name: "hidden_spaces",
        dirs: [
          "my dir",
        ],
        files: [
          {
            dir: "my dir",
            name: "first file.txt",
            data: "hello",
          },
          {
            dir: "my dir",
            name: "second file.txt",
            data: "hello",
          },
          {
            dir: "my dir",
            name: "unique name.txt",
            data: "world",
          },
        ],
        missing: false,
      },
      {
        name: "hidden_many",
        dirs: [
          "g",
        ],
        files: [
          {
            dir: "g",
            name: "aaa.txt",
            data: "omega",
          },
          {
            dir: "g",
            name: "zzz1.txt",
            data: "omega",
          },
          {
            dir: "g",
            name: "bbb.txt",
            data: "alpha",
          },
          {
            dir: "g",
            name: "yyy.txt",
            data: "alpha",
          },
          {
            dir: "g",
            name: "ccc.txt",
            data: "mid",
          },
          {
            dir: "g",
            name: "xxx.txt",
            data: "mid",
          },
          {
            dir: "g",
            name: "ddd.txt",
            data: "unique",
          },
        ],
        missing: false,
      },
      {
        name: "hidden_none",
        dirs: [],
        files: [],
        missing: false,
      },
      {
        name: "hidden_missing",
        dirs: [],
        files: [],
        missing: true,
      },
    ]
    var index = 0
    for case in inputs {
      index += 1
      let result = run_case(index, case, oracle)?
      cases = cases.push(result)
      if ! result.exact {
        all_exact = false
      }
    }
  }

  let source = if artifact_present { artifact.read_text()? } else { "" }
  let restriction_ok = artifact_present and "hash." in source and ! control.source_has_forbidden_subprocess(source)
  let protocol_ok = review_ok()?
  let passed = all_exact and restriction_ok and protocol_ok
  json.write(
    /session/run.json,
    {
      image_id: env.get_or("FACTORY_IMAGE_ID", "unknown")?,
      platform: env.get_or("FACTORY_PLATFORM", "unknown")?,
      eval_id: env.get_or("FACTORY_EVAL_ID", "task-dupcheck")?,
      trial_id: env.get_or("FACTORY_TRIAL_ID", "1")?,
      result: if passed { "pass" } else { "fail" },
      classification: if ! artifact_present {
        "worker_missing_artifact"
      } else if ! protocol_ok {
        "protocol_failed"
      } else if ! restriction_ok {
        "restriction_failed"
      } else if ! all_exact {
        "candidate_failed"
      } else {
        "pass"
      },
      protocol: {
        artifact_present: artifact_present,
        review_ok: protocol_ok,
      },
      correctness: {
        cases: cases,
        all_exact: all_exact,
        passed: all_exact,
      },
      restrictions: {
        passed: restriction_ok,
      },
      timings: {
        passed: true,
      },
    },
    pretty: true,
  )?
  if ! passed {
    abort(1)
  }
}
