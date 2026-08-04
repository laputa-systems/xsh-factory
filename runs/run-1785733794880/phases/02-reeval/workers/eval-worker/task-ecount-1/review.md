# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

- `xsht api language:stream.group-by` and `language:stream.fold` return only a
  purpose/contract with an empty `signatures` array (confirmed via
  `--format jsonl`), so the result shape is not documented. The grouped value
  had to be discovered by probing: it is a `List[{key, items}]` rather than a
  Map. Emit signatures for language stages the way exact `method:`/`api:`
  items do.
- There is no way to enumerate a type's methods (`xsht api method:Path` is
  rejected; a bare `method:Path` query is not supported). Discovery for a
  fresh type like `Path` required guessing candidate names until one
  (`Path.display`, `Path.name`, `Path.ext`, `Path.bytes_len`) matched.
- Converting an `Int` to `Str` has no dedicated method; the working idiom is
  the formatted string `f"${n}"`, and `Str(n)` is rejected as an unresolved
  call. A named conversion would reduce round-tripping through f-strings for
  length/padding arithmetic.
