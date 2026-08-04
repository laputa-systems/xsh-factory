Create one file named `jsonfilter.xsh` in the task working directory.

The program accepts one output path argument and writes a JSON array to that
path. The input is a JSON document in the environment variable `CFG_DOC` with
this shape:

```json
{
  "records": [
    {"name": "alpha", "active": true, "count": 2},
    {"name": "beta",  "active": false, "count": 5}
  ]
}
```

The output must be the records whose `active` field is `true`, sorted by
`name` ascending, and projected to only the `name` and `count` fields. The
evaluator invokes the candidate equivalently to `xsh jsonfilter.xsh OUT` with
several different `CFG_DOC` values, so do not hard-code one result.

The behavior is defined by this oracle, run by the evaluator with the same
environment:

```sh
out="$1"
test -n "${CFG_DOC-}" || exit 1
rendered="$(printf '%s' "$CFG_DOC" | jq -cS '.records | map(select(.active == true)) | sort_by(.name) | map({name, count})')" || exit 1
printf '%s\n' "$rendered" > "$out"
```

Acceptance is a byte-for-byte match of the written file with the oracle's
output, including compact key-sorted JSON (object keys in alphabetical order),
the final newline, and integer count formatting. When `CFG_DOC` is absent,
empty, or not valid JSON, both the candidate and the oracle must exit nonzero
and must not create the output file.

The program must read the JSON document through the XSH `json` module and
perform the filtering, sorting, and projection with typed XSH values. It must
not start subprocesses, invoke an external command (including `jq`), or add
diagnostic text to stdout.

Use the handbook and the available `xsht` checks as the reference. A normal
development loop is:

    xsht check jsonfilter.xsh
    xsht fmt jsonfilter.xsh
    xsht lint jsonfilter.xsh
    CFG_DOC='{"records":[{"name":"beta","active":true,"count":3}]}' xsh jsonfilter.xsh out.json
