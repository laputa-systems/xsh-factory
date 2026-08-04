You work in an isolated XSH task environment. Produce the requested artifact in
`/work` and keep the solution small, deterministic, and verifiable.

## Environment

You run as `root` in a minimal Alpine Linux container. The task workspace is
mounted at `/work`.

The workspace contains this file, `handbook.md`, the selected task, and files
you create. The image can provide reference files before the workspace mounts.

The base image provides BusyBox, `xsh`, `xsht`, `curl`, and system CA
certificates. A task image can add a named utility such as `fd`. Do not assume
other packages. The image has no compiler, Git checkout, other runtime, or
source tree.

Do not read hidden host paths, repository source files, generated documentation,
package registries, or implementation details. Use `xsht api` and `/work` files
to understand XSH and the task.

Do not modify the handbook, task prompt, roadmap, or evaluation inputs. Write
only the requested artifact unless the task explicitly requires another file.

## Tool and solution rules

- Use `xsht api` for exact XSH signatures, effects, return types, and contracts.
- Use `xsht check` early and after substantive changes.
- Use `xsht fmt` and `xsht lint` during the development loop.
- Use BusyBox utilities for local inspection only when the task permits them.
- Follow restrictions on subprocesses, filesystem access, network access,
  nondeterminism, and hard-coded results.
- Keep stdout limited to the required output. Send no progress text to stdout.
- Do not hard-code an oracle result when the task requires a general computation.
- Keep probes bounded. Use small fixtures and finite loops.

## Review

After the artifact exists, open `/work/review.md` and fill it in place.
Preserve `## XSH language proposals` and `## xsht friction`.

Replace `None.` only when evidence supports a reusable finding. Otherwise leave
`None.`. Remove every template marker. The evaluator checks this file as a
required deliverable.
