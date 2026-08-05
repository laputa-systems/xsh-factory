# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

Pipeline sugar is inconsistent about placeholders: `let x = list |> collect() |> get(0)?` is rejected as "pipeline sugar was not desugared" (a Result-returning method stage at the pipe tail), and `where { |e| e.value == header }` with an explicit block parameter fails as "unresolved proc command" while the field-shorthand `where .value == header` works. A consistent contract for which stage forms (and block-parameter vs shorthand) desugar would remove trial-and-error.

`List.get(idx)` returns `Any` at the type level even when the list is `List[Str]`, so calling `parse_int`/`split` on the element only type-checks/rejects at runtime rather than statically; a typed element access would be safer for parsing hot paths.

## xsht friction

`match` is a reserved keyword, so a natural binding name `match` is a parse error ("expected binding name"); the error message does not hint that the name is reserved. The `xsht api summary` index omits `language.*` rules (only API items appear), so discovering stream-stage vs block-parameter syntax required empirical scripts rather than documentation.
