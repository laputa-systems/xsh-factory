# task-histogram dry run

The external oracle was exercised on the host against the exact fixture data
embedded in `evaluator.xsh`, across the public case, the six hidden passing
cases, and the two failure controls. The oracle script (`hist_oracle.sh` in this
directory) is byte-for-byte the `#!/bin/sh` block embedded in the evaluator. A
candidate XSH implementation was deliberately **not** authored this cycle; the
oracle is the acceptance contract and the evaluator's correctness gate, and the
proposal's difficulty hinge is on the oracle discriminating composition from a
one-liner. `xsht check` passes on `evaluator.xsh`, `executor.xsh`, and
`evaluate.xsh`; `xsht lint` returns warnings consistent with the approved
scaffold (rc 0).

## Cases exercised (host shell)

- `public` (width=2, data `0 1 2 3 4`): exit 0
  ```
  0 2 2
  1 2 4
  2 1 5
  ```
- `hidden_width` (width=3, same data): exit 0
  ```
  0 3 3
  1 2 5
  ```
- `hidden_many` (width=10, `5 9 10 15 19 20 25 29 30`): exit 0
  ```
  0 2 2
  1 3 5
  2 3 8
  3 1 9
  ```
- `hidden_sparse` (width=10, `0 1000 100000`): exit 0
  ```
  0 1 1
  100 1 2
  10000 1 3
  ```
- `hidden_single` (width=3, `7`): exit 0
  ```
  2 1 1
  ```
- `hidden_ties` (width=2, `0 1 2 3`): exit 0
  ```
  0 2 2
  1 2 4
  ```
- `hidden_empty` (empty file, width=5): exit 0, no output
- `hidden_bad_width` (width=0): exit 1, stdout empty (failure control)
- `hidden_bad_value` (line `12x`, width=5): exit 2, stdout empty (failure control)

## Remaining unproven

The package-owned `evaluator.xsh` wiring, the container isolation, and the
shared `/usr/local/lib/xsh-factory` evaluator boundary are inherited unchanged
from the approved scaffold and were not re-run end-to-end in a container this
cycle (that path is a container-only surface). No candidate XSH solution was
built or timed, so candidate/oracle timing remains unmeasured until the first
worker trial.
