# Ticket task-tags-002

## Status

Open.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-tags` (`evals/task-tags/EVAL.md`)
- Shared handbook lineage: `runs/run-1785648492744/lineage/handbook-approved.md` (approved `c7c9dd9a…`; provisional candidate `20f9ee79…`)
- Manager run: `runs/run-1785648492744/workers/eval-manager/task-tags/session.jsonl`
- Executor run: `runs/run-1785648492744/workers/eval-worker/task-tags-1` (trial 1) and `task-tags-2` (trial 2)
- XSH baseline commit: `a66ade8218aacb38a2d1247db192f0c550cbb5cd`

## Observation

The `print` builtin — the core output command taught by the handbook and used
by nearly every practical XSH script — is absent from the live `xsht api`
reference. The eval-worker queried it directly and the pinned build cannot
resolve it:

```text
$ xsht api api:print
xsht api: invalid API query 'api:print'; expected NAME.MEMBER

$ xsht api search:print
status: matches   # only language.cli.xsht-api, language.cli.xsht-ast,
                  # language.stream.table-print, method.Bytes.strings

$ xsht api search:builtin
status: missing

$ xsht api language:core   # complete name list has no print entry
```

`module:io` indexes `write_stdout` and `write_stdout_bytes`, but not `print`.

## Evidence

- Worker session (trial 1): `runs/run-1785648492744/workers/eval-worker/task-tags-1/session.jsonl` — assistant turn 5 runs `xsht api api:print`, `xsht api search:print`, `xsht api language:main`; the tool result returns the invalid-query error and unrelated search matches.
- Worker review: `runs/run-1785648492744/workers/eval-worker/task-tags-1/review.md`, section `## xsht friction`, entry `print is not discoverable via api:print` — states the exact symptom and expectation, and notes the worker "worked around it by following the handbook's onboarding example, which used `pred main(...)` with `[io]`."
- Host probe on the pinned image (`xsh-factory-base:latest`, image ID `sha256:7a6336538e58da48343871ba96cf3d372c1eb9d1a27a76ca02ae87302c19e65d`, XSH commit `a66ade8218aacb38a2d1247db192f0c550cbb5cd`): `api:print`, `search:print`, `search:output`, `search:builtin`, `language:builtins`, and the full `language:core` name list reproduce the observation deterministically. No API entry describes the print builtin's signature, `[io]` effect, single-space separator behavior, or command-word interpolation.
- The eval still passed on correctness in both trials; the gap is diagnostic/discoverability, not a correctness blocker.

## Diagnosis or hypothesis

`print` is a language builtin command, and the API reference indexes module
functions, methods, and language rules but not builtin commands. The handbook
teaches `print "count" $count` by example, so the worker could proceed, but
the handbook also tells agents to treat `xsht api` as "the live reference"
and "source of truth for a task." An agent or person learning XSH who follows
that instruction cannot confirm the print contract, its required `[io]`
effect, or its value-separation behavior through the reference. This is a
general learnability/ergonomics gap: it affects any script that prints, in any
eval, and it is not a task-tags recipe.

## North-star impact

The north star asks for a concise handbook, fewer guesses and workarounds, and
explicit boundaries. A core builtin that the live reference cannot find forces
agents to rely on memory, examples, or trial-and-error instead of the
documented contract. Indexing `print` (signature, effects, single-space
separator, command-word interpolation, `f"..."` note) would make the most
common output operation discoverable exactly where the handbook directs agents
to look. Evidence of generalization: any eval whose worker queries the API for
print would resolve it; a replay of `task-tags` should show the worker
confirming print through `xsht api` instead of falling back to the handbook
example.

## Proposed XSH change

Smallest candidate: add a builtin/language entry for `print` (for example
`language:core.print` or a `builtin:` category) that documents the signature,
the required `[io]` effect, that print inserts a single space between values,
that command-word position interpolates while expression strings never
interpolate, and that `f"..."` is the expression-string interpolation path;
register it so `xsht api search:print` (and `search:output`) surface it. No
runtime semantics change.

## Acceptance criteria

- `xsht api search:print` (or a documented query such as `xsht api language:core.print`) returns a `print` entry with signature, effects, and a working example.
- The entry states the single-space separator behavior and that expression strings never interpolate.
- A replay of `task-tags` shows the worker resolving print's contract through `xsht api` rather than only through the handbook example.
- `xsht api` continues to resolve module functions and methods exactly as before.

## Scope and non-goals

- No change to `print` runtime behavior; documentation/indexing only.
- Not a task-tags shortcut; the entry must describe the general builtin.
- No change to the shared handbook inside XSH; the factory lineage owns the agent-facing handbook.

## Post-merge evaluation

The `task-tags` eval-manager will run a controlled replay against the merged
XSH commit using the current approved handbook lineage, check that the worker
resolves `print` through `xsht api`, and record acceptance or rejection in
that run's manager report.
