# task-col2 dry-run evidence

## Host byte-match (reference col2.xsh vs BusyBox awk oracle)
- public: PASS
- hidden_single: PASS
- hidden_blank: PASS
- hidden_leading: PASS
- hidden_multi_ws: PASS
- hidden_trailing: PASS
- hidden_unicode: PASS
- hidden_no_newline: PASS
- hidden_empty: PASS
- hidden_missing (failure control): candidate exit=3 oracle exit=2, candidate stdout 0 bytes -> PASS

## Toolchain
- xsht check: OK; xsht lint: OK; xsht fmt: no-op (already formatted)

## Container smoke (xsh-factory-base:latest, /work mounted)
- xsh col2.xsh vs awk on all 9 content cases inside image: PASS x9
- missing-file failure control inside image: exit=3, stdout 0 bytes -> PASS

## Negative controls
- hard-coded output: matches public only, fails hidden_single byte-match -> rejected by correctness gate
- no read_text reference: restriction scan flags -> rejected
- subprocess token (process/run/spawn): restriction scan flags -> rejected
- missing review.md: evaluator check_review existence test fails -> rejected
- missing input file: candidate exits nonzero, stdout empty -> failure control PASS

## Not exercised in dry run
- live Pi worker session (requires paid auth); inherited unchanged from approved base image
- controller-owned evaluate_common.xsh dispatch branch for task-col2 (merged on approval)
