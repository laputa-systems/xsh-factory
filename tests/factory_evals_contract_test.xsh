##! Behavior-level coverage for eval package admission.
use factory.evals as evals
use factory.types as types

proc test_eval_package_status_and_boundaries_are_admission_ready(ctx: TestContext) [fs, error] {
  let contract = fs.read_text(fp"${fs.cwd()?}/evals/task-ecount/EVAL.md")? + """

## Difficulty justification

This combines two independent data transformations with stateful aggregation,
an explicit failure control, hidden cases, and cases that punish a one-liner or
hard-coded answer.
"""
  let evaluator = fs.read_text(fp"${fs.cwd()?}/evals/task-ecount/evaluator.xsh")?
  let parsed_eval = evals.parse("task-ecount", contract, evaluator)?
  test.ok(evals.dispatchable(parsed_eval))?
  test.ok(evals.under_cap(30))?
  test.ok(! evals.under_cap(31))?
  test.eq(types.eval_status_name(evals.promoted_status(true)), "Approved.")?
  test.eq(types.eval_status_name(evals.promoted_status(false)), "Draft.")?
}
