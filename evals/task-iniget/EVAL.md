# Eval task-iniget

## Status

Approved.

## Budget breach

None.

## Purpose

Measure a practical systems-administration / config-glue workflow that no
approved eval covers: reading a typed INI configuration document with the
`ini` module, navigating its nested record shape (global scalars and section
records), looking up a key inside a named section, and propagating a
missing/malformed lookup as a clean nonzero exit instead of a guess. Existing
evals read JSON (`task-jsonfilter`), environment scalars (`task-envcfg`),
plain key/value files (`task-propsort`, `task-render`), and line-oriented text
(`task-total`, `task-grep`, `task-setdiff`); none exercises the typed `ini`
module or a nested-record lookup.

## North-star hypothesis

An agent that has read the handbook should be able to turn "read a config and
print one value" into a short, typed XSH program that calls `ini.decode`, does
a dynamic record lookup with `Record.get`, and lets a missing key or section
fail through `?`. The eval probes whether the handbook and `xsht api` make the
`ini` module discoverable, whether dynamic record access (`row.get(name)`) is
ergonomic, and whether the Result/`?` failure path is the instinctive way to
handle "not found". A successful run teaches the factory that the typed INI
API and records compose cleanly into real config tools; a missed run reveals
whether navigation of a nested record or the exact `ini` signature is still
unclear. The design resists task-specific hacks: the evaluator generates hidden
fixture files and passing section/key names at runtime, and it requires the
source to reference `ini.`, so a hand-written INI parser or a hard-coded value
is not a valid win.

## Task

Create one file named `iniget.xsh` in the task working directory.

The program accepts exactly three command-line arguments: a path to an INI
file, the name of a section, and the name of a key. It reads the INI file with
the typed `ini` module and prints the value of `key` in `section`, followed by
a newline.

Rules:

- Read the file through the `ini` module (for example `ini.decode(text)`); do
  not parse the INI by hand.
- Section and key names are the exact strings given as arguments. Every
  evaluator fixture writes section headers and keys in lowercase, so a direct
  lookup matches.
- The file is a normal INI document: `[section]` headers, `key = value` lines
  (whitespace around the `=` is optional), `#` and `;` comment lines, and blank
  lines. Values are trimmed of surrounding whitespace.
- Print the value on its own line (the value followed by a newline) and nothing
  else on stdout.
- If the section or the key does not exist, the program must exit nonzero and
  print nothing to stdout.
- If the file is malformed (for example a key repeated in the same section) or
  cannot be read, the program must exit nonzero and print nothing to stdout.

The program must use XSH typed values and the `ini` module. It must not start
subprocesses, invoke an external command, or add diagnostics to stdout. The
evaluator supplies several hidden INI files and argument triples, so do not
hard-code a value.

Complete `review.md` using the supplied headings.

Use the handbook and the available `xsht` checks as the reference. A normal
development loop is:

    xsht check iniget.xsh
    xsht fmt iniget.xsh
    xsht lint iniget.xsh
    xsh iniget.xsh config.ini server host

## Agent boundary

The worker runs as root in a minimal Alpine container with `/work` as its task
workspace. The image provides BusyBox, `xsh`, `xsht`, `curl`, CA certificates,
and the XSH standard modules including `ini`. It has no compiler, repository
checkout, or implementation source. The submitted program may not start
subprocesses or invoke an external command and must keep diagnostics off
stdout.

## Oracle and evaluator

The package-owned evaluator runs in a separate read-only container boundary so
the worker cannot inspect fixtures or the oracle harness. It writes a set of
hidden INI fixture files, invokes the candidate as
`xsh /work/iniget.xsh <file> <section> <key>` for each case, and compares the
candidate's stdout byte-for-byte with an independent oracle:

- success cases: an external `printf` oracle emits the expected
  `value\n`; the case passes only when the candidate exits 0 and its stdout
  matches the oracle byte-for-byte;
- failure cases: an external `sh -c 'exit 1'` oracle emits nothing with a
  nonzero exit; the case passes only when the candidate also exits nonzero and
  prints nothing to stdout.

The evaluator then checks that the source references the `ini` module, that it
contains no forbidden subprocess boundary, and that `review.md` preserves the
required headings. It writes a JSON run manifest to `/session/run.json`.

The hidden cases are:

- `public`: two-section file, `server`/`host` -> `example.test`;
- `hidden_port`: `server`/`port` -> `8080`;
- `hidden_spaces`: `app`/`name` -> `hello world`;
- `hidden_trim`: `alpha`/`path` -> `/usr/local/bin` (value has trailing spaces
  in the file that the parser must trim);
- `hidden_global`: a file with a leading global key plus `[service]`,
  `service`/`name` -> `api`;
- `hidden_missing_key`: `server`/`absent` -> nonzero, empty stdout;
- `hidden_missing_section`: `nosuch`/`host` -> nonzero, empty stdout;
- `hidden_malformed`: a duplicate key in one section -> nonzero, empty stdout.

Timing (candidate vs oracle wall ns) is recorded per case but is diagnostic
only; there is no strict runtime envelope.

## Metrics

Record correctness for all cases (success byte-exactness and failure
exit/empty-stdout semantics), restriction compliance (`ini.` reference and no
forbidden subprocess), worker turns, thinking blocks and reasoning tokens,
token buckets, provider cost, tool calls and errors, session wall span,
candidate/oracle timing, and protocol completion (`review.md` rows). This eval
has no strict candidate/oracle timing gate; timing is diagnostic until a
stable envelope is established.

## Manager policy

Use one trial by default; the controller-owned `## Trial plan` in the cycle
request may explicitly raise this to two. Classify repeated friction as
handbook guidance or a product issue only when it generalizes (for example, a
recurring misunderstanding of `ini` module discovery or dynamic `Record.get`
access); do not create a ticket for an ordinary short-task miss or evaluator
noise. A handbook change must name the concept it teaches and be replayed
before it is trusted. The no-subprocess and `ini.`-reference checks keep a
hand-rolled parser out of the accepted set, so a pass is evidence about the
typed module, not about a workaround.

## Staged dry run

See `REPORT.md` under the run directory. The dry run exercised the reference
candidate across all eight hidden cases plus the three failure controls on the
local build, and ran the package-owned evaluator's decision logic against a
correct candidate (pass) and a wrong-output candidate (fail) to prove the
evaluator contract, isolation checks, and `run.json` manifest. The remaining
unproven surface is a live container trial of the exact `/work`/`/session`
paths and a real agent session.

## CTO review

- Result: `accepted`
- Promotion: `promoted`
- Package: `complete`
- Missing package files: `None.`
- Status: `Approved.`
- Source run: `runs/run-1785821597944/phases/04-eval-design`
