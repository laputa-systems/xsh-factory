# task-intsum dry-run evidence

## Package syntax / reference checks (xsht check, checkout binary)
- evaluator.xsh -> pass (0)
- executor.xsh  -> pass (0)
- evaluate.xsh  -> pass (0)
Two focused scaffold errors were fixed (missing `pure` modifier; incorrect
`proc pure` spelling) before these pass.

## Reference candidate: dryrun/intsum-candidate.xsh
```
proc main(...argv: List[Str]) [error] {
  var total = 0
  for a in argv {
    total = total + (a.parse_int()?)
  }
  print $total
}
```
Verified outputs/exit codes with the checkout xsh:
- `4 9 2`                       -> 15   (0)
- (no args)                     -> 0    (0)
- `-3 7 -1`                     -> 3    (0)
- `2147483647 1`                -> 2147483648 (0)
- `0 10 20`                     -> 30   (0)
- `5 abc 2` (malformed)         -> no stdout, exit 3 (nonzero) -> expect_fail satisfied

## External oracle: dryrun/intsum-oracle.sh (portable sh)
- `4 9 2`        -> 15  (0)
- (no args)      -> 0   (0)
- `-3 7 -1`      -> 3   (0)
- `2147483647 1` -> 2147483648 (0)
- `0 10 20`      -> 30  (0)
- `5 abc 2`      -> exit 1 (nonzero) -> expect_fail satisfied

## Byte-for-byte candidate vs oracle (numeric cases): all MATCH

## Not exercised here (remains for the CTO's post-promotion gate)
- Full isolated container run: agent produces /work/intsum.xsh + review.md,
  evaluator container runs evaluator.xsh end-to-end, run.json manifest.
