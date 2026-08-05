##! Canonical session-evidence predicates.

## Unknown cost is a failure of evidence, not zero spend.
export pure cost_known(cost: Any) -> Bool {
  return cost != null and cost != "unknown"
}

## A session is complete only when the archive and normalized report exist.
export pure complete(session_present: Bool, report_present: Bool) -> Bool {
  return session_present and report_present
}
