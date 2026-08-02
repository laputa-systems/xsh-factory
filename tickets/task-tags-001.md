# Ticket task-tags-001

## Status

Merged.

## Merge record

- Implementation branch: `factory/task-tags-001/1785640252827`
- Implementation commit: `e17fc1cd9538a4357460657b3f030caa0c1c7474`
- Detected at XSH commit: `a66ade8218aacb38a2d1247db192f0c550cbb5cd`
- Implementation run: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785640252827`

## Source eval and manager

- Eval: `task-tags` (`evals/task-tags/EVAL.md`)
- Shared handbook lineage: `runs/run-1785638563480/lineage/task-tags` (historical per-eval run; approved `f1cc95ab…`, provisional `6a4b8867…`; current shared source is `runtime/handbook.md`)
- Manager run: `runs/run-1785638563480/workers/eval-manager/task-tags/session.jsonl`
- Executor run: `runs/run-1785638563480/workers/eval-worker/task-tags-1` (trial 1 evidence) and `task-tags-2`
- XSH baseline commit: `3bc22853824fa554e0ca5cb318a4d452a97b2557`

## Observation

An expression string literal that contains `$name` (no braces) silently keeps
`$name` as literal text with **no diagnostic from `xsht check`, `xsht fmt`, or
`xsht lint`**, so an agent can write a program whose output is wrong in a way
the type-checker accepts. The same literal with `${name}` fails loudly with
`err[parse.expr-string-interpolation]`. The task-tags worker hit exactly this:
its second draft printed `tags: $body` (literal `$body` on stdout) and the
session transcript shows four to five tool rounds of experimental discovery
before it found that `f"..."` display strings, command-word interpolation, or
`+` concatenation are the working paths.

Contrast, reproduced on the pinned build:

```xsh
let line = "tags: $body"      # check/fmt/lint accept; prints literal "tags: $body"
let line = "tags: ${body}"    # loud parse error with actionable message
print "tags: $body"           # print argument position interpolates (command word)
```

The context dependence is the trap: a `"..."` literal interpolates in print
argument position but never in expression position, and only the braced form
is diagnosed.

## Evidence

- Worker session (trial 1): `runs/run-1785638563480/workers/eval-worker/task-tags-1/session.jsonl`, turn 19–29; tool result at line 22 shows `---RUN---\ntags: $body` after `xsht check`/`xsht fmt`/`xsht lint` had already been exercised.
- Thinking transcript: `runs/run-1785638563480/workers/eval-worker/task-tags-1/thinking.md`, blocks 7–9 explicitly reconsider string interpolation.
- Worker review (`review.md` in trial 1 work dir) reports the same friction independently with the exact reproduction: `"tags: $body"` silently literal; `"tags: ${body}"` parse error; request for a loud diagnostic.
- Evaluator manifest: `run.json` in trial 1 – pass, all exact, no timing gate hit; the defect is diagnostic, not a correctness blocker.
- Host probes on the same staged build: `xsht check`/`fmt`/`lint` accept `"tags: $body"` with only unrelated `unused-local` warnings; `xsh` prints literal `tags: $body`; the `${body}` form errors.
- API reference gap: `xsht api language:core.display-strings` returns only the two-line contract "Display strings are presentation text…" with no syntax or interpolation example, and there is no `language:core.*` entry that states ordinary expression strings never interpolate.

## Diagnosis or hypothesis

XSH intentionally makes expression strings non-interpolating (SPEC: "Expression
string literals do not interpolate"), and `${…}` is rejected with an excellent
message. The ergonomics defect is the uncovered middle: `$name` without braces
still looks like shell interpolation to humans and coding agents, parses
silently, and produces a wrong value. The existing linter already targets
lookalike ambiguity (`lint.bare-print-ident` for `print`), so a symmetric lint
for interpolate-lookalike `$` in expression strings fits the design. This is a
general language/tooling issue, not a task-tags recipe: any agent or person
building output strings can hit it, and the same lack of documentation
(handbook taught `print "count" $count` without explaining that expression
strings never interpolate) left no discoverable contract in `xsht api`.

## North-star impact

The north star asks for explicit boundaries and fewer silent failures: XSH
should be easy to learn and use correctly. A `$name` in an expression string
that is silently literal is exactly the kind of opaque text convention the
factory should not reward. A diagnostic or an API/handbook contract that says
"expression strings never interpolate; use `f"..."` or concatenation" turns a
silent wrong output into a one-line teachable correction. Evidence of
generalization: the warning fires on any script containing interpolate-lookalike
`$` in an expression string, independent of task, and would have removed all
four-plus discovery rounds from this eval without touching its solution space.

## Proposed XSH change

Smallest candidate: add a lint rule (e.g. `lint.dollar-in-expression-string`)
that warns when an expression string literal contains `$` immediately followed
by an identifier that is in scope (or looks like a binding), suggesting
`f"..."`/`+`/command-word interpolation instead; the `${…}` parse error already
exists and stays. Alternatively, if a lint is not desired, extend
`language:core.display-strings` (and any core string API entry) with an
explicit contract and example stating that ordinary expression string literals
never interpolate and `$name` is literal text. The factory handbook candidate
for this cycle already teaches the working idiom; the product change should
make the same lesson discoverable without the handbook.

## Acceptance criteria

- A script containing `"tags: $body"` in expression position produces a
  warning (not silent acceptance) on `xsht lint`, or the API reference states
  the non-interpolation rule with a working example; `xsht check` may still pass.
- `print "tags: $body"` (command-word position) and `f"..."` continue to
  interpolate; raw strings `r"..."` remain literal.
- A replay of `task-tags` with the merged change shows the worker reaching the
  final solution without the `"tags: $body"` literal-output discovery loop, and
  still passes all three argument cases byte-for-byte.

## Scope and non-goals

- No change to expression-string runtime semantics: expression strings remain
  non-interpolating. This ticket is about diagnostics/discoverability only.
- No handbook edit inside XSH; the factory lineage already owns the
  agent-facing handbook candidate.
- Not a task-specific shortcut; the change must apply to any script.

## Post-merge evaluation

The `task-tags` eval-manager will run a controlled replay against the merged
XSH commit using the current approved handbook lineage, comparing worker turns,
tool errors, and the presence of the interpolation trap in the session
transcript, and will record acceptance or rejection in that run's manager
report.
