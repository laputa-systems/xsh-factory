##! Package-owned evaluator for task-treecmp.
##! This script owns the fixture, oracle, correctness, restriction, and
##! protocol checks; it must not delegate task logic to a legacy dispatcher.
type FixtureFile = {rel: Str, data: Str}

type Case = {
  name: Str,
  manifest: Str,
  files: List[FixtureFile],
  write_manifest: Bool,
  expect_fail: Bool,
}

type CaseResult = {
  name: Str,
  exact: Bool,
  candidate_exit: Int,
  oracle_exit: Int,
  candidate_wall_ns: Int,
  oracle_wall_ns: Int,
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

proc copy_results() [fs, error] {
  for name in ["treecmp.xsh", "review.md"] {
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

proc seed_fixture(root: Path, files: List[FixtureFile]) [fs, error] {
  fs.mkdir(root)?
  for file in files {
    let destination = fp"${root}/${file.rel}"
    let parent = destination.parent()
    if ! fs.exists(parent)? {
      fs.mkdir(parent)?
    }

    fs.write(destination, file.data)?
  }
}

proc run_case(index: Int, case: Case, oracle: Path) [fs, process, time, error] -> Result[CaseResult] {
  let root = fp"/tmp/task-treecmp-${index}"
  let manifest = fp"/tmp/task-treecmp-manifest-${index}"
  let candidate_out = fp"/session/task-treecmp-candidate-${index}.stdout"
  let candidate_err = fp"/session/task-treecmp-candidate-${index}.stderr"
  let oracle_out = fp"/session/task-treecmp-oracle-${index}.stdout"
  let oracle_err = fp"/session/task-treecmp-oracle-${index}.stderr"
  for cleanup in [candidate_out, candidate_err, oracle_out, oracle_err] {
    fs.remove(cleanup, missing_ok: true)?
  }

  seed_fixture(root, case.files)?
  if case.write_manifest {
    fs.write(manifest, case.manifest)?
  } else {
    fs.remove(manifest, missing_ok: true)?
  }

  let candidate_args = ["xsh", "/work/treecmp.xsh", root.display(), manifest.display()]
  let oracle_args = ["sh", oracle.display(), root.display(), manifest.display()]
  let candidate = time.measure(
    process.command_argv(
      "xsh",
      candidate_args,
      stdout: candidate_out,
      stderr: candidate_err,
    ),
  )?
  let oracle_result = time.measure(
    process.command_argv(
      "sh",
      oracle_args,
      stdout: oracle_out,
      stderr: oracle_err,
    ),
  )?
  let candidate_text = if fs.exists(candidate_out)? { candidate_out.read_text()? } else { "" }
  let oracle_text = if fs.exists(oracle_out)? { oracle_out.read_text()? } else { "" }
  let exact = if case.expect_fail {
    ! candidate.status.ok and ! oracle_result.status.ok and candidate_text == "" and oracle_text == ""
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
  let artifact = /work/treecmp.xsh
  let artifact_present = fs.exists(artifact)?
  let oracle = /tmp/task-treecmp-oracle.sh
  fs.write(
    oracle,
    r"""#!/bin/sh
set -o pipefail
root="$1"; manifest="$2"
if [ ! -f "$manifest" ]; then exit 1; fi
tmp=$(mktemp -d) || exit 1
awk -F '\t' '
  NF != 2 || $1 == "" || $2 !~ /^[0-9]+$/ { exit 1 }
  { print }
' "$manifest" > "$tmp/exp" || { rm -rf "$tmp"; exit 1; }
( cd "$root" && find . -type f ) | while IFS= read -r f; do
  rel=${f#./}
  size=$(wc -c < "$root/$rel") || exit 1
  printf '%s\t%s\n' "$rel" "$size"
done | sort -t$'\t' -k1,1 > "$tmp/live"
sort -t$'\t' -k1,1 "$tmp/exp" > "$tmp/exps"
awk -F '\t' -v f1="$tmp/exps" -v f2="$tmp/live" '
  BEGIN {
    while ((getline line < f1) > 0) { split(line, a, "\t"); want[a[1]] = a[2] }
    while ((getline line < f2) > 0) { split(line, a, "\t"); got[a[1]] = a[2] }
    for (p in want) {
      if (!(p in got)) print "missing\t" p
      else if (got[p] != want[p]) print "changed\t" p "\t" want[p] "\t" got[p]
    }
    for (p in got) if (!(p in want)) print "extra\t" p
  }
' | sort
rm -rf "$tmp"
""",
  )?
  fs.chmod(oracle, 0o755)?

  var all_exact = artifact_present
  var cases: List[CaseResult] = []
  if artifact_present {
    let inputs: List[Case] = [
      {
        name: "public",
        write_manifest: true,
        expect_fail: false,
        manifest: """a.txt	2
b.txt	99
d.txt	1
""",
        files: [
          {
            rel: "a.txt",
            data: "aa",
          },
          {
            rel: "b.txt",
            data: "bbb",
          },
          {
            rel: "c.txt",
            data: "cccc",
          },
        ],
      },
      {
        name: "hidden_all_ok",
        write_manifest: true,
        expect_fail: false,
        manifest: """f1	4
f2	3
f3	2
f4	1
""",
        files: [
          {
            rel: "f1",
            data: "aaaa",
          },
          {
            rel: "f2",
            data: "aaa",
          },
          {
            rel: "f3",
            data: "aa",
          },
          {
            rel: "f4",
            data: "a",
          },
        ],
      },
      {
        name: "hidden_missing",
        write_manifest: true,
        expect_fail: false,
        manifest: """present.txt	4
ghost.txt	7
""",
        files: [
          {
            rel: "present.txt",
            data: "data",
          },
        ],
      },
      {
        name: "hidden_changed",
        write_manifest: true,
        expect_fail: false,
        manifest: """account.log	1000
""",
        files: [
          {
            rel: "account.log",
            data: "srv",
          },
        ],
      },
      {
        name: "hidden_extra",
        write_manifest: true,
        expect_fail: false,
        manifest: """known	1
""",
        files: [
          {
            rel: "known",
            data: "x",
          },
          {
            rel: "rogue",
            data: "yy",
          },
        ],
      },
      {
        name: "hidden_combined",
        write_manifest: true,
        expect_fail: false,
        manifest: """dir/a	2
dir/b	50
gone	9
top	3
""",
        files: [
          {
            rel: "dir/a",
            data: "aa",
          },
          {
            rel: "dir/b",
            data: "b",
          },
          {
            rel: "top",
            data: "ttt",
          },
          {
            rel: "zed",
            data: "zzz",
          },
        ],
      },
      {
        name: "hidden_empty_tree",
        write_manifest: true,
        expect_fail: false,
        manifest: """some/file	3
""",
        files: [],
      },
      {
        name: "hidden_empty_manifest",
        write_manifest: true,
        expect_fail: false,
        manifest: "",
        files: [
          {
            rel: "a",
            data: "a",
          },
          {
            rel: "b",
            data: "bb",
          },
        ],
      },
      {
        name: "hidden_spaces",
        write_manifest: true,
        expect_fail: false,
        manifest: """dir with space/long file	6
dir with space/missing one	5
""",
        files: [
          {
            rel: "dir with space/long file",
            data: "longer",
          },
          {
            rel: "dir with space/short",
            data: "s",
          },
          {
            rel: "whitespace file",
            data: "w",
          },
        ],
      },
      {
        name: "hidden_utf8",
        write_manifest: true,
        expect_fail: false,
        manifest: """café.txt	999
note.txt	3
""",
        files: [
          {
            rel: "caf\u{e9}.txt",
            data: "caf\u{e9}",
          },
          {
            rel: "note.txt",
            data: "zzz",
          },
        ],
      },
      {
        name: "hidden_missing_manifest",
        write_manifest: false,
        expect_fail: true,
        manifest: """present	1
""",
        files: [
          {
            rel: "present",
            data: "p",
          },
        ],
      },
      {
        name: "hidden_bad_manifest",
        write_manifest: true,
        expect_fail: true,
        manifest: """ok	1
broken	not-a-number
""",
        files: [
          {
            rel: "a",
            data: "x",
          },
        ],
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
  let restriction_ok = artifact_present and ("fs.files" in source or "fs.walk" in source) and ("read_text" in source or "read(" in source) and ! source_has_forbidden_subprocess(
    source,
  )
  let protocol_ok = review_ok()?
  let passed = all_exact and restriction_ok and protocol_ok
  json.write(
    /session/run.json,
    {
      image_id: env.get_or("FACTORY_IMAGE_ID", "unknown")?,
      platform: env.get_or("FACTORY_PLATFORM", "unknown")?,
      eval_id: env.get_or("FACTORY_EVAL_ID", "task-treecmp")?,
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
