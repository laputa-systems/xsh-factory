##! Pure workflow graph construction, validation, and readiness rules.

use factory.types as types

## One controller-assigned graph node.
export type GraphNode = {
  node_id: Str,
  role: Str,
  worker_id: Str,
  dispatch_id: Str,
  assignment: Str,
  inputs: List[Str],
  outputs: List[Str],
  budget: Any,
  terminal_states: List[Str],
  result: Str,
}

## One typed dependency between two graph nodes.
export type GraphEdge = {
  predecessor: Str,
  successor: Str,
  kind: Str,
  failure_policy: Str,
}

## The complete immutable graph admitted for one run.
export type WorkflowPlan = {
  run_id: Str,
  mode: Str,
  nodes: List[GraphNode],
  edges: List[GraphEdge],
  source_hashes: List[Any],
  required_outputs: List[Str],
  aggregate_budget: Float,
}

## Constructs one node and rejects missing assignment or terminal rules.
export pure make_node(
  node_id: types.NodeId,
  role: types.Role,
  worker_id: types.WorkerId,
  dispatch_id: types.DispatchId,
  assignment: Str,
  inputs: List[Str],
  outputs: List[Str],
  budget: types.Budget,
  terminal_states: List[Str],
) -> Result[GraphNode] {
  if assignment == "" or outputs.len() == 0 or terminal_states.len() == 0 {
    return Err(types.DomainError.InvalidCombination(message: f"node ${node_id.value} is missing assignment, outputs, or terminal states"))
  }
  return Ok({node_id: node_id.value, role: role.value, worker_id: worker_id.value, dispatch_id: dispatch_id.value, assignment: assignment, inputs: inputs, outputs: outputs, budget: budget, terminal_states: terminal_states, result: "pending"})
}

## Constructs one dependency edge.
export pure make_edge(predecessor: types.NodeId, successor: types.NodeId, kind: Str, failure_policy: Str) -> Result[GraphEdge] {
  if predecessor.value == successor.value or kind == "" or failure_policy == "" {
    return Err(types.DomainError.InvalidCombination(message: "graph edge has invalid endpoints or policy"))
  }
  return Ok({predecessor: predecessor.value, successor: successor.value, kind: kind, failure_policy: failure_policy})
}

pure has_node(nodes: List[GraphNode], node_id: Str) -> Bool {
  for node in nodes {
    if node.node_id == node_id { return true }
  }
  return false
}

pure node_for(nodes: List[GraphNode], node_id: Str) -> GraphNode {
  for node in nodes {
    if node.node_id == node_id { return node }
  }
  return {node_id: "", role: "", worker_id: "", dispatch_id: "", assignment: "", inputs: [], outputs: [], budget: {role_limit: 0.0, aggregate_limit: 0.0, observed: {kind: "unknown", amount: 0.0}}, terminal_states: [], result: "missing"}
}

pure duplicate_node_id(nodes: List[GraphNode]) -> Str {
  var seen: List[Str] = []
  for node in nodes {
    for prior in seen {
      if prior == node.node_id { return prior }
    }
    seen = seen.push(node.node_id)
  }
  return ""
}

pure duplicate_worker_identity(nodes: List[GraphNode]) -> Str {
  var seen: List[Str] = []
  for node in nodes {
    let identity = f"${node.role}:${node.worker_id}:${node.dispatch_id}"
    for prior in seen {
      if prior == identity { return identity }
    }
    seen = seen.push(identity)
  }
  return ""
}

pure path_exists(edges: List[GraphEdge], start: Str, target: Str, visited: List[Str]) -> Bool {
  if start == target { return true }
  for edge in edges {
    if edge.predecessor == start {
      var already_seen = false
      for value in visited {
        if value == edge.successor { already_seen = true }
      }
      if ! already_seen and path_exists(edges, edge.successor, target, visited.push(edge.successor)) {
        return true
      }
    }
  }
  return false
}

## Validates a complete graph before any child process is spawned.
export pure validate(plan: WorkflowPlan) -> Result[Unit] {
  if plan.nodes.len() == 0 { return Err(types.DomainError.InvalidCombination(message: "workflow has no nodes")) }
  if plan.nodes.len() > 64 { return Err(types.DomainError.InvalidCombination(message: "workflow fan-out exceeds hard bound")) }
  let duplicate = duplicate_node_id(plan.nodes)
  if duplicate != "" { return Err(types.DomainError.Duplicate(value: f"node:${duplicate}")) }
  let duplicate_worker = duplicate_worker_identity(plan.nodes)
  if duplicate_worker != "" { return Err(types.DomainError.Duplicate(value: f"worker:${duplicate_worker}")) }
  for node in plan.nodes {
    if node.assignment == "" or node.outputs.len() == 0 or node.terminal_states.len() == 0 {
      return Err(types.DomainError.InvalidCombination(message: f"node is missing terminal contract: ${node.node_id}"))
    }
  }
  for edge in plan.edges {
    if ! has_node(plan.nodes, edge.predecessor) or ! has_node(plan.nodes, edge.successor) {
      return Err(types.DomainError.Missing(value: f"edge:${edge.predecessor}->${edge.successor}"))
    }
    if path_exists(plan.edges, edge.successor, edge.predecessor, [edge.successor]) {
      return Err(types.DomainError.InvalidCombination(message: "workflow graph contains a cycle"))
    }
  }
  for node in plan.nodes {
    var has_relationship = false
    for edge in plan.edges {
      if edge.predecessor == node.node_id or edge.successor == node.node_id {
        has_relationship = true
      }
    }
    if plan.nodes.len() > 1 and ! has_relationship {
      return Err(types.DomainError.InvalidCombination(message: f"orphan graph node: ${node.node_id}"))
    }
  }
  if plan.aggregate_budget <= 0.0 { return Err(types.DomainError.InvalidFormat(kind: "aggregate-budget", value: f"${plan.aggregate_budget}")) }
  return Ok()
}

pure predecessor_edges(plan: WorkflowPlan, node_id: Str) -> List[GraphEdge] {
  var edges: List[GraphEdge] = []
  for edge in plan.edges {
    if edge.successor == node_id { edges = edges.push(edge) }
  }
  return edges
}

## Returns whether a node may start under the observed lifecycle states.
export pure startable(plan: WorkflowPlan, node_id: Str, states: List[Any]) -> Bool {
  let node = node_for(plan.nodes, node_id)
  if node.node_id == "" or node.result != "pending" { return false }
  for state in states {
    if state.node_id == node_id and state.state != "ready" and state.state != "admitted" { return false }
  }
  for edge in predecessor_edges(plan, node_id) {
    var predecessor_state = "missing"
    for state in states {
      if state.node_id == edge.predecessor { predecessor_state = state.state }
    }
    if edge.kind == "hard" or edge.kind == "replay" {
      if predecessor_state == "failed" or predecessor_state == "cancelled" or predecessor_state == "budget-breached" {
        if edge.failure_policy != "continue-on-failure" { return false }
      } else if predecessor_state != "completed" and predecessor_state != "validated" {
        return false
      }
    }
  }
  return true
}

## Derives the root result only from node results and required outputs.
export pure root_result(plan: WorkflowPlan, states: List[Any], outputs_present: List[Str]) -> Str {
  for node in plan.nodes {
    var observed = "missing"
    for state in states {
      if state.node_id == node.node_id { observed = state.state }
    }
    if observed == "failed" or observed == "cancelled" or observed == "budget-breached" or observed == "missing" {
      return "fail"
    }
  }
  for required in plan.required_outputs {
    var present = false
    for output in outputs_present {
      if output == required { present = true }
    }
    if ! present { return "fail" }
  }
  return "pass"
}
