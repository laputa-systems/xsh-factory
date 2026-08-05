##! Canonical audit helpers for plan membership and evidence completeness.

use factory.graph as graph
use factory.reports as reports

## Audits the exact admitted node set.
export pure plan(plan_value: Any, observed: List[reports.NodeEvidence]) -> reports.AuditResult {
  return reports.audit_plan(plan_value, observed)
}
