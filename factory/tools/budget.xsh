##! Canonical budget gates for graph execution.
## New paid work is allowed only below the aggregate cap with known cost.
export pure can_start(observed: Any, aggregate_limit: Float, requested: Float) -> Bool {
  match observed {
    value is Float => value >= 0.0 and requested >= 0.0 and value + requested <= aggregate_limit
    value is Int => value.float() + requested <= aggregate_limit
    _ => false
  }
}

## Unknown or breached cost stops all new paid nodes.
export pure stops_new_work(observed: Any, breached: Bool) -> Bool {
  return breached or observed == null or observed == "unknown"
}
