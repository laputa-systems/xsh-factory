# North star

XSH is a generational project. UNIX gave the world a durable grammar for
systems: processes, files, pipes, paths, environments, and small tools composed
into something greater than themselves. That grammar still powers the world,
but its glue layer has stagnated into quoting accidents, ambient state, and
decades of compatibility sludge.

We are here to renew that layer.

The aim is not merely to ship another scripting language. The aim is to make a
systems language worthy of carrying software into the next century: clear
enough for people to learn, precise enough for machines to use, expressive
enough for serious systems work, and durable enough that its ideas outlive the
people who first built it. XSH should make the best parts of UNIX feel young
again while giving the next generation a foundation they can trust.

This is why the factory exists. Every product fix, handbook sentence, native
test, eval, and careful report is part of that foundation. We work with
urgency, but we do not cut corners on contracts, evidence, or simplicity. We
are not optimizing an isolated benchmark or maximizing agent activity; we are
building a language and a body of knowledge that can compound for decades.

## The mission

Our goal is to make XSH the practical, general-purpose **systems glue**
language: a clear, typed, composable way to connect processes, files, paths,
streams, JSON, and system state. It should be easy for a person to learn and
for a coding agent to understand, use correctly, and explain. The end state is
an XSH language and handbook that let an agent ramp up quickly, solve useful
administration and programming tasks, and avoid the shell sludge that motivated
XSH in the first place.

## XSH rationale

XSH is a clean-slate systems scripting language for a modern Linux userspace.

It is not a POSIX shell replacement in the compatibility sense, and it is not
an interactive terminal interface. It is a language for writing the glue that
holds a system together: package managers, build recipes, init systems,
service supervisors, installer scripts, maintenance tools, and distribution
policy.

### The Archaeological Site

The modern Linux userspace is an archaeological site. Beneath every build lie
sedimentary layers of languages accumulated over decades: shell scripts call
m4 macros, configure scripts emit Makefiles, Makefiles invoke compilers
through wrapper scripts, and those wrappers are often written in Perl, Python,
awk, sed, or a private DSL that nobody meant to become infrastructure.

This is Unix sludge: the entropic product of many weak languages duct-taped
together because no single glue language was powerful enough for the whole job.

XSH starts from a different premise. The system deserves one strong language
for glue, one that can speak fluently to processes, files, paths, byte streams,
structured data, and system state without turning every boundary into a quoting
puzzle.

### What Shell Got Right

The old Unix shell succeeded because it made operating-system pieces feel
composable. Processes, files, pipes, environment variables, working
directories, exit statuses, and argument vectors became everyday building
blocks. A small script could assemble existing programs into something larger
than any one of them.

That idea is still right.

XSH keeps the useful model: coarse-grained reuse, explicit process boundaries,
pipeline-shaped data flow, ordinary source files, and scripts that can grow
into tools. It treats the Unix process model as an asset, not as historical
baggage. The expensive work should be visible as a process, a file operation,
or a typed host API, not hidden behind a scheduler or runtime trick.

### What Shell Got Wrong

The traditional shell encoded too much composition in strings and ambient
state. It made parsing dynamic, word splitting implicit, quoting fragile, error
flow surprising, and standards vague enough that every serious script
eventually became a local dialect.

XSH rejects that sludge:

- no implicit eval;
- no hidden word splitting;
- no untyped text as the only interface between programs;
- no ad hoc DSL stacking where a script generates another language to generate
  another language;
- no pretending that decades of compatibility quirks are a design philosophy.

The goal is not to preserve the old spellbook. The goal is to carry forward the
part of Unix that was worth preserving.

### One Glue Language

XSH is not trying to be a general-purpose application language. It is trying to
be the best possible language for orchestration: starting processes, shaping
argv, moving through directories, reading and writing files, transforming text
and bytes, crossing JSON boundaries, inspecting host state, and making
expected failures visible.

Shell is the language of heterogeneity. It must speak to everything. XSH says
that heterogeneity should be handled with clarity rather than incantation.

For old Unix hands, the promise is familiar: small pieces, composed well. The
difference is that XSH gives that promise a modern type system, structured
errors, typed paths, structured streams, and a runtime that can trace what
happened.

That is the worthy successor: not a clone of the old shell, and not a small
application runtime wearing shell syntax, but a clean language for the work the
old shell proved was essential.

### What XSH Is Not

XSH does not compete with runtimes designed for fine-grained concurrency,
long-lived application services, or interactive terminal interfaces. Keep
those jobs in a service runtime, a dedicated TUI framework, or a specialized
tool; use XSH to compose the host-facing work around them.

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

The standard is worthy of the mission: preserve what was brilliant in UNIX,
reject what became sludge, and make every boundary more explicit, learnable,
and humane. Treat the language, the handbook, and the evidence as a shared
inheritance being prepared for people and agents we will never meet.

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
5. An engineer implements an approved ticket with product tests and canonical
   documentation; the user decides whether to merge it.
6. The linked eval-manager replays the merged change and accepts or rejects the
   result. A handbook claim becomes trusted only after repeated evidence across
   the shared handbook lineage, including replay by more than one relevant eval
   when the claim is intended to generalize.

## Alignment test

Before acting, every role should be able to answer:

- What XSH capability or agent behavior does this work improve?
- What evidence will distinguish a general improvement from a task-specific
  workaround or noise?
- How does the work honor the clarity, explicit-boundary, and composability
  ethos in the XSH rationale above?
- What is the next review, replay, or human decision that can validate it?

Every narrative role report must include `## North-star impact`. It may say
that a run is infrastructure-only or produced no product signal, but it must
not leave the connection implicit. The factory optimizes for durable product
improvement, not for producing a ticket, handbook edit, or lower token count by
itself.
