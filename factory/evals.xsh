##! Eval portfolio admission and package ownership policy.
use factory.control as legacy
use factory.types as types

## Parsed checked-in eval facts.
export type EvalRecord = {
  id: Any,
  status: Any,
  package_owned: Bool,
  difficulty_ok: Bool,
}

## Parses one EVAL.md and its package evaluator source.
export pure parse(eval_id: Str, contract: Str, evaluator: Str) -> Result[EvalRecord] {
  let id = types.make_eval_id(eval_id)?
  let status = types.parse_eval_status(legacy.ticket_status(contract))?
  return Ok({
    id: id,
    status: status,
    package_owned: legacy.eval_evaluator_package_owned(evaluator),
    difficulty_ok: legacy.eval_difficulty_contract_ok(contract),
  })
}

## A package is eligible only when status and package boundaries agree.
export pure dispatchable(eval: EvalRecord) -> Bool {
  return eval.status.value == "Approved." and eval.package_owned and eval.difficulty_ok
}

## Enforces the hard checked-in portfolio cap.
export pure under_cap(eval_count: Int) -> Bool {
  return eval_count <= 30
}

## A proposal remains Draft until all package gates pass.
export pure promoted_status(review_pass: Bool) -> types.EvalStatus {
  return if review_pass { {value: "Approved."} } else { {value: "Draft."} }
}
