# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

`json.write` and `json.encode` emit compact, key-sorted JSON but append no trailing newline, so matching an oracle that requires a final newline (`printf '%s\n'`) is not possible through the JSON module alone; I had to serialize with `json.encode` and write `out + "\n"` via `fs.write`. Documenting (or providing) newline behavior on `json.write` would make exact-file-output contracts less surprising.
