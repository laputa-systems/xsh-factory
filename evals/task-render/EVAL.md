# Eval task-render

## Status

Approved.

## Budget breach

None.

## Purpose

Measure a practical systems-administration / devops-glue workflow that no
current eval covers: reading a template file and a `KEY=value` values file,
building a typed substitution map, and rendering a byte-exact output file by
replacing `@KEY@` placeholders. `task-envcfg` renders a fixed three-field
config from scalar environment variables, `task-propsort` cleans and sorts an
allowlist, and `task-jsonfilter` crosses a JSON boundary; none builds a data
structure from a parsed text file and uses it to substitute placeholders in a
separate template. `task-render` fills that gap with the classic
configuration-templating shape "render `app.conf` from `values`" — the XSH
analogue of a `sed`-substitution / `envsubst`-style pipeline, performed
entirely through typed XSH values without a subprocess.

## North-star hypothesis

An agent that has internalized the handbook's typed-value and stream lessons
should solve this task with a short program that reads two files, folds parsed
`KEY=value` lines into a `Map[Str]`, iterates `Map.keys()` in deterministic
order, and substitutes each literal `@KEY@` through `Str.replace`. A
successful run is evidence about real ergonomics: map construction from text,
deterministic key iteration, literal string replacement, and a byte-exact
write contract. Because the values are read from a file the agent has never
seen and the hidden cases vary key order, empty values, unknown placeholders,
and punctuation inside values, no hard-coded substitution or one-example
special case can pass. The design deliberately exposes any friction in
`Map`/`Str` transitions, which the manager can generalise into handbook
guidance rather than a task-specific recipe.

## Task

Create `render.xsh`. It accepts exactly three path arguments — TEMPLATE,
VALUES, and OUTPUT:

    xsh render.xsh TEMPLATE VALUES OUTPUT

The VALUES file holds one `KEY=value` pair per line. A line is split on its
first `=` into KEY and value; the value is everything after that first `=`
(and may itself contain `=` or spaces, and may be empty). Lines with no `=`
or with an empty KEY are ignored. The program reads TEMPLATE and replaces
every literal occurrence of `@KEY@` with that KEY's value, for every KEY
defined in VALUES. A placeholder whose KEY is not defined is left exactly as
written. The substituted text is written byte-for-byte to OUTPUT. When
TEMPLATE or VALUES does not exist, the program must exit nonzero and must not
create OUTPUT. Values never contain `@`, so substitution is unambiguous and
independent of iteration order.

The behavior is defined by this oracle command, run by the evaluator on the
same inputs:

```sh
awk 'NR==FNR{i=index($0,"="); if(i>0){k=substr($0,1,i-1); v[k]=substr($0,i+1)}}
     NR>FNR{line=$0; for(k in v) gsub("@"k"@", v[k], line); print line}' VALUES TEMPLATE
```

The evaluator invokes the candidate equivalently to
`xsh render.xsh TEMPLATE VALUES OUTPUT` and compares the written OUTPUT
byte-for-byte with the oracle's stdout. Complete `review.md` using the
supplied headings.

## Agent boundary

The worker runs as root in a minimal Alpine container with `/work` as its task
workspace. The image provides BusyBox, `xsh`, `xsht`, `curl`, and CA
certificates. It has no compiler, repository checkout, or implementation
source. The submitted program must read both inputs and write the output
through XSH `fs`/text APIs; it must not start subprocesses, invoke an external
command, add diagnostic text to stdout, or modify the inputs. Keep stdout
silent; the file at OUTPUT is the only deliverable.

## Oracle and evaluator

The evaluator runs in a separate read-only container boundary. It invokes the
candidate for public and hidden cases and compares each written OUTPUT
byte-for-byte with the external `awk` oracle above. Hidden cases exercise:
multiple and adjacent placeholders; keys defined out of insertion order
(deterministic, order-independent substitution); a KEY whose value is empty;
a value containing `=` or spaces; an unknown placeholder left intact; and a
missing TEMPLATE or VALUES file (must exit nonzero and create no OUTPUT). The
evaluator also checks that the source does not start subprocesses and that
`review.md` preserves both required headings.

## Metrics

Record correctness for all cases, restriction compliance, worker turns,
thinking blocks and reasoning tokens, token buckets, provider cost, tool calls
and errors, session wall span, candidate/oracle timing, and protocol
completion. This eval has no strict candidate/oracle timing gate; timing is
diagnostic until a stable envelope is established.

## Manager policy

Use one trial by default; the controller-owned `## Trial plan` in the cycle
request may explicitly raise this to two. Classify repeated friction as
handbook guidance or a product issue only when it is generalizable; do not
create a ticket for an ordinary short-task miss or evaluator noise. A handbook
change must name the concept it teaches and be replayed before it is trusted.

## Staged dry run

See `dry-run/run-log.txt` in the proposal. The reference `render.xsh` passes
`xsht check` and matches the `awk` oracle byte-for-byte on five representative
fixtures (basic substitution, multiple/adjacent placeholders, unknown
placeholder + empty value, reversed key order, and values containing `=` and
spaces). The missing-file failure control exits nonzero without creating the
output. What remains unproven by the dry run is a full agent coding session,
the containerized `evaluate_legacy.xsh` wiring, and lint cleanliness of the
agent's own solution.

## CTO review

- Result: `accepted`
- Promotion: `promoted`
- Package: `complete`
- Missing package files: `None.`
- Status: `Approved.`
- Source run: `runs/run-1785813921392/phases/04-eval-design`
