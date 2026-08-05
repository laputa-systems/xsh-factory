# Ticket task-envcfg-003

## Status

Merged.

## Change target

- `product`

## CTO review

- Review cycle: `run-1785787490432` (2026-08-03)
- Decision: Approved for the next ticket-implementation cycle.
- Basis: The misleading diagnostics for `||`, `&&`, and `then` reproduce in
  minimal programs, the defect is general parser behavior, and the acceptance
  criteria are narrow, testable, and replayable.
- Assignment boundary: improve token attribution and the constructive
  diagnostic for the unsupported forms; preserve valid `or`/`and` semantics
  and do not take on the separate envcfg tickets.

## Budget breach

None.

## Merge record

- Implementation branch: `factory/task-envcfg-003/1785789595996`
- Implementation commit: `71e7b84552a5a5614347c8c6faf064f76fd85317`
- Detected at XSH commit: `84fe556cb48feb747d6b575e4925dbdc5848ecdb`
- Implementation run: `runs/run-1785789595047`
- CTO merge verification: focused parser regression tests passed

## Source eval and manager

- Eval: `task-envcfg` (`evals/task-envcfg/EVAL.md`)
- Shared handbook lineage: `runs/run-1785731807794/phases/03-eval/lineage/handbook-approved.md` (approved `c7c9dd9a…`; candidate `6eecf5ed…` with one added condition-operator sentence)
- Manager run: `runs/run-1785731807794/phases/03-eval/workers/eval-manager/task-envcfg/REPORT.md`
- Executor run: `runs/run-1785731807794/phases/03-eval/workers/eval-worker/task-envcfg-1` (trial 1)
- XSH baseline commit: `ea7dea2f2b436cce34262d7a02105cbb029243dd`

## Observation

XSH's boolean operators are word forms (`or`, `and`), but the parser's
diagnostics for the unsupported C-style forms (`||`, `&&`) and the `then`
keyword misattribute the error to the block that follows, never naming the
offending token. The task-envcfg worker reproduced this four times in one
session:

```text
$ cat /tmp/t6.xsh            # initial validation branch
proc main() [env, fs, error] {
  let host = env.get_or("CFG_HOST", "localhost")?
  ...
  if port == "" || port.delete("0123456789") != "" {
    "".parse_int()?
  }
}
$ xsht check /tmp/t6.xsh
err[parse.expected-token]: expected `{` to start block
  /tmp/t6.xsh:5:17
    if port == "" || port.delete("0123456789") != "" {
                   ^ expected `{` to start block
err[parse.expected-expression]: expected expression
  /tmp/t6.xsh:10:1
  }

$ cat /tmp/if.xsh
proc main() { if true || false { print "y" } }
err[parse.expected-token]: expected `{` to start block
  /tmp/if.xsh:2:11
    if true || false { print "y" }
                  ^ expected `{` to start block

$ printf 'proc main() { if true then { print "y" } }'
err[parse.expected-token]: expected `{` to start block
  /tmp/if.xsh:2:11
    if true then { print "y" }

$ printf 'let a = %s if a == "x" || a != "y" { ... }'   # both || and &&
err[parse.expected-token]: expected `{` to start block
err[parse.expected-terminator]: expected statement terminator   # in let bindings
```

The caret points at the block brace that is actually present (`` expected `{`
to start block `` under the `{`), which sends the agent debugging `if`
statement syntax, the `then` keyword, and block layout instead of the real
problem: the operator spelling. The correct forms `if c1 or c2 { ... }` and
`and` were only found by probing seven operator candidates (`or`, `||`, `|`,
`and`, `&&`, `&`) at session turn 46.

## Evidence

- Worker session: `runs/run-1785731807794/phases/03-eval/workers/eval-worker/task-envcfg-1/session.jsonl` — turn 37 (first `||` misparse in the real validation branch), turns 44–45 (`if true then { }` and `if true || false { }` reproductions), turn 46 (operator probe that found `or`/`and`); the final `/work/envcfg.xsh` uses `or`.
- Worker review: `runs/run-1785731807794/phases/03-eval/workers/eval-worker/task-envcfg-1/review.md`, section `## xsht friction` — "Writing `if a == \"\" || b != \"\"` failed at parse time with a misleading `expected '{' to start block`, which pointed at the `{` rather than the operator; the correct spelling was only found by probing alternatives."
- Quantitative: trial passed 10/10 (`run.json` `correctness.all_exact: true`, `restrictions.passed: true`), so the eval was not blocked, but the discovery consumed session turns 37–46 (~10 turns / 8 bash probes) after the real logic was already written.
- Related but distinct: the approved handbook also never documents boolean operators or `if` syntax; that discoverability gap is tracked separately as the lineage candidate in this run (not this ticket).

## Diagnosis or hypothesis

`err[parse.expected-token]: expected '{' to start block` is emitted for
conditions containing an unsupported operator token and points at the already
present block brace. This is a general parser-diagnostic quality problem, not
an envcfg recipe: any agent writing `||` / `&&` / `then` in any eval or script
is routed to the wrong hypothesis (block syntax, `if` shape) and burns turns
before discovering the word-form operators. The north star asks for precise,
learnable boundaries; a diagnostic that names the unsupported token (e.g. "XSH
uses word-form boolean operators `or` / `and`, not `||` / `&&`") would turn a
~10-turn discovery into a one-line fix. Generalization evidence: after the
fix, a replay of any eval with a boolean condition should show the worker
writing `or`/`and` without hitting the misleading `expected '{' to start
block`.

## Proposed XSH change

Smallest candidate, one of:

1. When a condition contains `||`, `&&`, `|`, `&`, or `then`, emit a
   constructive diagnostic that names the unsupported token and the supported
   spelling, e.g. `unsupported operator '||': XSH boolean operators are the
   word forms 'or'/'and'`; or
2. At minimum, point the caret at the offending operator token instead of the
   block brace when the condition parse fails.

Prefer (1): a named-operator diagnostic converts the friction into a
learnable one-shot message. Keep word-form `or`/`and` semantics unchanged.

## Acceptance criteria

- `xsht check` on `proc main() { if a || b { } }` reports an error that names
  `||` (or the supported `or` spelling); the caret is not on the block brace.
- `xsht check` on `proc main() { if a or b { } }` still passes.
- A replay of `task-envcfg` on the merged change passes all 10 correctness
  cases, and the worker's validation branch uses `or`/`and` without a
  `expected '{' to start block` misparse during the session.

## Scope and non-goals

- No change to boolean-operator semantics or parsing of valid programs.
- Not an envcfg shortcut; the diagnostic must improve any condition parse.
- Does not cover the error-constructor gap (ticket `task-envcfg-001`) or the
  compact-runtime `main` parameter mismatch (ticket `task-envcfg-002`); those
  are separate triggers. The agent-facing discoverability of `or`/`and`/`if`
  is owned by the shared handbook lineage, not this ticket.

## Post-merge evaluation

The `task-envcfg` eval-manager will run a controlled replay against the merged
XSH commit using the current approved handbook lineage, verify the worker's
session contains no `expected '{' to start block` misparse for boolean
conditions, confirm all 10 oracle cases still pass, and record acceptance or
rejection in that run's manager report.
