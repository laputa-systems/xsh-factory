## XSH language proposals

- `Str.parse_int` accepts a leading `+` sign (`"+5"` parses to 5), which is broader than several task grammars ("decimal integer, optionally preceded by a single `-`"). Because of that, `parse_int` cannot be used as the sole validator; a task that needs a restricted integer grammar must add its own sign/digit checks before calling it.
- `Str.parse_int_decimal` rejects leading zeros (`"007"` is an error), so it is unsuitable when a task allows `007`. Similarly there is no built-in "signed integer allowing leading zeros" parser; a manual body check (`s.delete("-")` + digit-only test) plus `parse_int()?` is the workable route.
- Reference/`Result` values cannot be interpolated into `print` directly; collection accessors like `List.get(i)` / `Map.get(k)` return `Result` and must use the fallback overload (`get(i, default)`) before display. This is easy to hit when validations guarantee the index/key is present.
- Negation in expressions is `!expr` (`not` is a parse error), and boolean composition uses `and`/`or`; the `!` spelling is not called out in the handbook.

## xsht friction

None.
