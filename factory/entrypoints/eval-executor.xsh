##! Stable evaluator entrypoint contract.

use factory.evals as evals

## Package-owned evaluator selection is a pure gate.
export pure package_allowed(eval: evals.EvalRecord) -> Bool { return evals.dispatchable(eval) }
