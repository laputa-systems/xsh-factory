# North star

The factory exists to improve XSH as a product, not to maximize agent activity
or win an isolated benchmark.

Our goal is to make XSH the practical, general-purpose **systems glue**
language: a clear, typed, composable way to connect processes, files, paths,
streams, JSON, and system state. It should be easy for a person to learn and
for a coding agent to understand, use correctly, and explain. The end state is
an XSH language and handbook that let an agent ramp up quickly, solve useful
administration and programming tasks, and avoid the shell sludge that motivated
XSH in the first place.

The canonical product rationale is
[`docs/CHAPTER-01-why-xsh.md`](docs/CHAPTER-01-why-xsh.md).
That chapter is the source for the ethos below; this document turns it into an
operating objective for factory employees.

## What the factory should improve

- **Ergonomics:** fewer guesses, workarounds, tool errors, and repeated
  discoveries when writing real XSH.
- **Learnability:** a concise handbook that teaches reusable concepts and
  idioms, rather than accumulating task-specific recipes.
- **Practicality:** reliable solutions to small systems-administration and
  programming tasks, with ecount as the current upper bound on difficulty.
- **AI efficiency:** agents reach a correct, clear solution with less
  unnecessary exploration, turns, and thinking. Lower token use is evidence of
  fluency only when correctness and clarity remain intact.
- **Trust:** reproducible bug reports, focused fixes, regression coverage, and
  eval replays that show whether a change actually helped.

The factory should preserve XSH's Unix strengths—processes, files, pipes,
environment, working directories, and statuses—while making boundaries,
types, errors, and data flow explicit. It should not reward hidden evaluation,
implicit word splitting, opaque text conventions, or a task-specific trick that
would make the language harder to understand elsewhere.

## Evidence loop

Every cycle should connect a capability hypothesis to evidence:

1. An eval-designer chooses a small, practical behavior worth probing.
2. The eval-executor measures correctness, protocol completion, candidate versus
   oracle timing where applicable, and the coding session that produced it.
3. The eval-manager separates reusable handbook guidance and product defects
   from task confusion, harness failures, and noise.
4. A handbook update or ticket states the general lesson, links its evidence,
   and names the next replay that could falsify it.
5. An XSH SWE implements an approved ticket with product tests and canonical
   documentation; the user decides whether to merge it.
6. The linked eval-manager replays the merged change and accepts or rejects the
   result. A handbook claim becomes trusted only after repeated evidence across
   the relevant eval lineage.

## Alignment test

Before acting, every role should be able to answer:

- What XSH capability or agent behavior does this work improve?
- What evidence will distinguish a general improvement from a task-specific
  workaround or noise?
- How does the work honor the clarity, explicit-boundary, and composability
  ethos in the canonical chapter?
- What is the next review, replay, or human decision that can validate it?

Every narrative role report must include `## North-star impact`. It may say
that a run is infrastructure-only or produced no product signal, but it must
not leave the connection implicit. The factory optimizes for durable product
improvement, not for producing a ticket, handbook edit, or lower token count by
itself.
