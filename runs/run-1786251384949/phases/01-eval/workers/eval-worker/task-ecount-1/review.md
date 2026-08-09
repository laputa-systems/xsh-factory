## XSH language proposals

- `run` is a reserved word / parser token (the `run` subprocess form), so it
  cannot be used as a plain identifier. A `let run = ...` binding produced
  `expected binding name` plus `unknown run form` diagnostics. Renaming the
  binding resolved it. This is undocumented in the handbook's identifier rules
  and cost a parse round-trip; an explicit reserved-words note would help.
- No `Str`-repeat or integer-width formatter is exposed (padding is in
  `tui.*`), so producing a fixed-width right-aligned count (matching `uniq -c`
  `%7d`) requires composing `range(...) |> map { |_| " " } |> collect()` +
  `join`. A small `Str.repeat` or `fmt`/`sprintf` helper would make exact-layout
  tasks like this one much simpler and less error-prone.
- Multi-statement `if`/`else` bodies are not accepted in expression position;
  `let`-binding inside a then/else branch of an expression parses as
  `expected expression`. Side-effect-free helper functions needing local
  bindings must be factored into separate procs (which then also require an
  explicit `[]` effect list to be callable from an effects-declared proc).
  The `[]` requirement is discoverable only via the effect-violation
  diagnostic; a check note in the handbook would be useful.

## xsht friction

- The fixed-width `%7d` prefix of `uniq -c` (a stable 7-column field) is what
  makes the numeric-then-byte tie sort reducible; verifying that width and the
  sort tie-break behavior required empirical `uniq`/`sort` probes because the
  handbook does not document GNU sort's last-resort byte comparison for ties
  nor `uniq`'s padding width.
- `fs.walk`/`fs.files` default `hidden: false`, which aligns with `fd`'s
  default, and `kind == "file"` excludes symlinks exactly like `fd -t f`.
  These were confirmed empirically against `fd` output rather than documented
  as a contract on the file-set semantics relative to `fd`.