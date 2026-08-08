# Eval-manager report

## Result

pass

## Effort metrics

1 worker (`task-histogram-1`), 1 controller-run fresh trial. Worker session:
35 assistant turns, 49 tool calls (42 bash, 2 edit, 3 read, 2 write), 49 tool
results, 1 tool error, 27 thinking blocks. Session span 179,046 ms
(`session_span_ms`), agent wall 180,343 ms. Stop reasons: 1 `stop`, 34
`toolUse`; normal completion. No repeated exploration beyond the normal
check/run/lint loop; the worker correctly recovered its one failed probe.

## Usage and cost

Single worker, provider `openrouter/deepseek/deepseek-v4-flash-0731`.
Input 67,933; output 10,235; cacheRead 461,312; cacheWrite 0;
provider_totalTokens 539,480 = bucket total. Provider-reported reasoning
tokens 4,943 (subset of output). Cost: input $0.006114, output $0.001842,
cacheRead $0.008304, cacheWrite $0, total $0.016260. Budget $0.50, no breach.
Aggregate across the phase is the same single-worker total.

## Thinking evidence

27 provider-reported thinking blocks; reasoning tokens 4,943 were reported.
Thinking is qualitative, not a token estimate. The worker reasoned explicitly
toward `parse_uint` as the non-negative validated parser
(`query: search:parse_uint` → `status: exact`, contract "Signs, radix
prefixes, malformed text, and out-of-range values return an error"), verified
integer division is `/` for Int (`7 / 2` → 3) after `//` is a parse error
(consistent with handbook), used `Str.lines()` + `trim` + `where` for
non-blank lines, verified `List.extend` for fold accumulator output, and
checked empty/bad-width/bad-value/negative cases locally before submission.
Diagnostics were kept off stdout (only stderr tracebacks in error cases).

## Tool-error findings

Structured `tool_errors` has exactly 1 entry: at turn 7 a `bash` probe
`ls -la /usr/share/hist-data.txt` failed (file not found via
`/usr/share/hist-data.txt: No such file or directory`), exit code 1. Root
cause: the task's suggested dev-loop command references
`/usr/share/hist-data.txt`, which is not present in this image's `/usr/share`
(only `apk`, `ca-certificates`, `misc`, `udhcpc`). The worker immediately
recovered by creating its own fixture and continued to a correct result. This
is harness/task noise, not a product defect.

No invalid `xsht api` query produced a failed tool result. Several discovery
queries returned `status: missing` (`search:int_div`, `search:division`,
`language:core.int`, `search://`), but those were valid, non-error query
results (`isError: false`), not tool errors; they are ordinary discovery
probes and are not counted in `tool_errors`.

## Timing evidence

No strict candidate/oracle ratio gate for this eval (both sides finish in
milliseconds). Candidate 11.8–15.8 ms per case; oracle 11.0–15.5 ms.
Candidate and oracle are comparable throughout; timing is diagnostic only.

## Observation classification

- **Worker friction (minor / ordinary noise):** the `ls /usr/share/hist-data.txt`
  probe failed because the suggested example path is absent from the image.
  Recovered cleanly in one turn; not a repeatable agent inefficiency.
- **Reusable handbook guidance:** a strict non-negative/unsigned decimal
  contract is now expressible with one discoverable typed operation,
  `Str.parse_uint()?`, which rejects any sign/radix prefix/malformed/out-of-range
  text. The worker found it with zero friction (`xsht api` status `exact`) and
  used it directly, dropping the old `regex + "".parse_int()?` workaround. This
  removes an ergonomics gap for the recurring numeric field (ports, counts,
  sizes, measurements) and replaces the prior opaque forced-failure idiom.
- **Product signal (correctness/tooling):** `parse_uint` is present and
  discoverable in the image under test and its contract matches the ticket's
  proposed surface; all nine cases byte-exact.
- **Evaluator/harness:** none; all cases passed including both failure
  controls.

## Handbook decision

Provisional candidate staged at
`lineage/handbook-candidate.md`. General lesson: for a strict non-negative /
unsigned decimal contract, prefer the typed `Str.parse_uint()?` (rejects any
sign, radix prefix, malformed, or out-of-range text) instead of layering
`regex.compile("^[0-9]+$")` over `parse_int` and forcing failure via an opaque
empty-string parse; reserve `Str.parse_int()` for signed integers. Replay
scope: promote only after a fresh `task-histogram` replay and at least one other
numeric-parsing eval confirm the `parse_uint` spelling is discovered and all
cases stay byte-exact. The approved snapshot and the checked-in
`runtime/handbook.md` are unchanged.

## Tickets created

Zero. The candidate being validated is the pre-existing open ticket
`tickets/task-histogram-005.md`; no new ticket identity was needed.

## Post-merge decisions

None. The reconciler reported `none` merged tickets for this phase.
`task-histogram-005` is a pre-merge candidate validation, not a post-merge
acceptance assignment (its `## Merge record` placeholders remain unfilled).

## Next replay

Replay `task-histogram` against the merged `parse_uint` commit plus at least
one other numeric-parsing eval (the ticket's falsification / no-regression
gate) to confirm the typed non-negative spelling is discovered and the whole
suite stays byte-exact before promoting the handbook candidate to
`runtime/handbook.md`.

## North-star impact

This run exercises the ticket's core hypothesis end-to-end: an agent with the
handbook and `xsht api` discovered `parse_uint`, the additive typed
unsigned parser that makes a strict non-negative integer contract a first-class
operation instead of a regex-plus-`"".parse_int()?` hack. That directly serves
XSH's trust and ergonomics goals — clearer boundaries and typed conversions for
a recurring systems-glue validation (counts, sizes, ports, measurements) — with
no silent sign acceptance and no obscure forced-failure idiom. The exact,
byte-for-byte result across all nine cases (including both failure controls)
confirms the surface is correct and composable, a durable improvement ready for
a numeric cross-eval replay.

---

## Observed decision — candidate re-evaluation of task-histogram-005

Candidate XSH commit under test: `2d255aa8297671339564f1f93587ec69c5f96cb5`
(phase `report.json` also records baseline `xsh_commit` `e6d3fd96...`).

Acceptance criteria:
1. `parse_uint` discoverable via `xsht api` — PASS. Worker ran
   `xsht api search:parse_uint` (`status: exact`) and
   `xsht api method:Str.parse_uint` (`signature: Str.parse_uint() ->
   Result[Int, Error]`, contract: "Signs, radix prefixes, malformed text, and
   out-of-range values return an error").
2. `task-histogram` passes all nine cases byte-exact using the new spelling,
   sign-rejection and non-positive-width expressed directly rather than via
   `"".parse_int()?` — PASS. Artifact `histogram.xsh` uses `parse_uint()?` for
   both width and value parsing, `width == 0` uses `abort(1)`, and there is no
   `regex.compile` and no `"".parse_int()?` forced-failure hack. `run.json`:
   `all_exact: true`; failure controls `hidden_bad_width` (exit 1) and
   `hidden_bad_value` (exit 3) both nonzero with empty stdout.
3. No regression in the rest of the suite — the worker exercised the exact
   `parse_uint` surface the ticket proposes and this eval passes all cases;
   the additive surface is minimal. Cross-eval no-regression is recorded as a
   required future replay (no other eval ran in this phase).

The worker actually exercised the ticket's proposed surface (no workaround).
`Candidate acceptance: pass.`
