# Ticket task-tags-003

## Status

Open.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-tags` (`evals/task-tags/EVAL.md`)
- Shared handbook lineage: `runs/run-1785686080618/lineage/handbook-approved.md` (approved `c7c9dd9a…`; provisional candidate `5849fe64…`)
- Manager run: `runs/run-1785686080618/workers/eval-manager/task-tags/session.jsonl`
- Executor run: `runs/run-1785686080618/workers/eval-worker/task-tags-1` (trial 1) and `task-tags-2` (trial 2)
- XSH baseline commit: `defa805a18b4708efeecaa4da9de7d2096bcfb41`

## Observation

The `if` conditional — core control-flow syntax used by any branching XSH
script — is absent from the live `xsht api` reference. The task-tags worker
needed an `if` expression to handle the zero-argument case and spent four
consecutive tool rounds searching the reference for it; the reference cannot
resolve it:

```text
$ xsht api language:conditional
status: missing

$ xsht api language:control
status: missing

$ xsht api language:if
status: missing

$ xsht api search:conditional
status: missing

$ xsht api search:branch
status: missing

$ xsht api search:else
status: missing

$ xsht api search:if
status: matches   # only language.cli.xsht-fmt, language.core.run,
                  # language.core.streams — no control-flow entry

$ xsht api language:core   # complete name list has no conditional entry
```

The worker fell back to writing the smallest script and letting `xsht check`
parse feedback confirm the syntax, which worked but only after the wasted
search.

## Evidence

- Worker session (trial 1): `runs/run-1785686080618/workers/eval-worker/task-tags-1/session.jsonl`, tool calls at lines 19, 21, 23, 25 run `xsht api language:conditional`, `language:control`, `language:if`, `xsht api summary | grep -iE "if|cond|branch|else"`, and `language:core` greps; every result is missing or unrelated. The worker then wrote the conditional and let parse feedback confirm it (line 29→31).
- Thinking transcript (trial 1): `thinking.md`, blocks 6–7 explicitly search for if/else syntax ("Let me check the syntax for if/else... The greps for if/cond/branch produced nothing relevant").
- Host probe on the pinned image (`xsh-factory-base:latest`, image ID `sha256:93cc888baeb0c4f30d29ddcc4b921f0ff45be82847094fffa7394d870ed79e5b`, XSH commit `defa805a18b4708efeecaa4da9de7d2096bcfb41`): `search:conditional`, `search:branch`, `search:else` return `missing`; `search:if` returns only unrelated language.cli/language.core.run/language.core.streams matches; the full `language:core` name list contains bindings, captures, command-interpolation, comments, display-strings, fallback, glob-literals, native-tests, path-literals, postfix-question, print, procs, pure-functions, records, results, run, source-files, statements, streams — but no conditionals/control-flow entry. Deterministic.
- Contrast replay (trial 2): when the factory handbook candidate supplied the one-line `if` expression syntax (`let label = if argv.len() == 0 { "tags:" } else { "tags: " + joined }`), the same eval completed in 11 assistant turns with zero control-flow search and zero tool errors; the worker's thinking (block 8) states "the `if` expression syntax in handbook ... worked as given. Not much friction."
- The eval passed on correctness in both trials; the gap is diagnostic/discoverability, not a correctness blocker.

## Diagnosis or hypothesis

`xsht api` indexes language rules, module functions, and methods but not the
`if` conditional expression. The handbook explicitly directs agents to treat
`xsht api` as "the live reference" and "source of truth for a task," so an
agent or person who follows that instruction cannot confirm the syntax of the
most common branch construct through the reference. This mirrors the
previously accepted `print` discoverability gap (ticket task-tags-002), which
was fixed by indexing `language.core.print`; control flow is a
parallel language-core rule that belongs in the same index. This is a general
learnability/ergonomics gap: any script with branching, in any eval, is
affected, and it is not a task-tags recipe. The factory handbook can carry the
syntax (a provisional candidate now does), but the product reference should
itself answer the query the handbook tells agents to make.

## North-star impact

The north star asks for a concise handbook, fewer guesses and workarounds, and
explicit boundaries. A core language construct that the live reference cannot
find forces agents to either memorize syntax or burn tool rounds discovering
it, exactly the "repeated discoveries" the factory exists to remove. Indexing
`if` (syntax, expression form usable in `let`, branch semantics, example)
would let the reference answer the query the handbook directs agents to make.
Evidence of generalization: any eval whose worker queries the API for
conditionals would resolve it; a replay of `task-tags` should show the worker
confirming `if` through `xsht api` instead of relying only on the handbook.

## Proposed XSH change

Smallest candidate: add a language-core entry for the conditional expression
(for example `language:core.conditionals`) documenting the expression form
`if COND { A } else { B }`, that it is a value usable in `let` bindings, and a
working example; register it so `xsht api search:conditional` and
`search:if` surface it. No runtime semantics change.

## Acceptance criteria

- `xsht api search:conditional` (or a documented query such as `xsht api language:core.conditionals`) returns a `if` entry with the expression syntax, branch semantics, and a working example; `language:core` lists it.
- The entry documents the value/expression form usable in `let` bindings.
- A replay of `task-tags` shows the worker resolving the `if` contract through `xsht api` rather than only through the handbook example.
- `xsht api` continues to resolve existing language rules, module functions, and methods exactly as before.

## Scope and non-goals

- No change to `if` runtime semantics; reference/indexing only.
- Not a task-tags shortcut; the entry must describe the general conditional construct.
- No change to the shared handbook inside XSH; the factory lineage owns the agent-facing handbook.

## Post-merge evaluation

The `task-tags` eval-manager will run a controlled replay against the merged
XSH commit using the current approved handbook lineage, check that the worker
resolves `if` through `xsht api`, and record acceptance or rejection in that
run's manager report.
