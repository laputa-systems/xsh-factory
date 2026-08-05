##! Eval-design controller plan construction.

use factory.graph as graph

## Constructs the single bounded designer graph.
export pure build(run_id: Str, nodes: List[Any], edges: List[Any], required_outputs: List[Str], aggregate_budget: Float) -> Result[Any] {
  let plan = {run_id: run_id, mode: "eval-design", nodes: nodes, edges: edges, source_hashes: [], required_outputs: required_outputs, aggregate_budget: aggregate_budget}
  graph.validate(plan)?
  return Ok(plan)
}
