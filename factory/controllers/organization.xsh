##! Organization controller plan construction; execution stays shared.

use factory.graph as graph

## Constructs and validates the complete organization graph before spawning.
export pure build(run_id: Str, mode: Str, nodes: List[Any], edges: List[Any], required_outputs: List[Str], aggregate_budget: Float) -> Result[Any] {
  let plan = {run_id: run_id, mode: mode, nodes: nodes, edges: edges, source_hashes: [], required_outputs: required_outputs, aggregate_budget: aggregate_budget}
  graph.validate(plan)?
  return Ok(plan)
}
