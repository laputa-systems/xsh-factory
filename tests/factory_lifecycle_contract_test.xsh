##! Behavior-level coverage for terminal lifecycle decisions.
use factory.lifecycle as lifecycle

proc test_lifecycle_reaches_terminal_state_only_with_valid_evidence() [error] {
  let digest = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  let events = [
    {event_id: "admit", run_id: "run-1", node_id: "node-a", attempt: 1, caused_by: "controller", previous: "created", next: "admitted", content_sha256: digest},
    {event_id: "start", run_id: "run-1", node_id: "node-a", attempt: 1, caused_by: "controller", previous: "admitted", next: "started", content_sha256: digest},
    {event_id: "complete", run_id: "run-1", node_id: "node-a", attempt: 1, caused_by: "runner", previous: "started", next: "completed", content_sha256: digest},
    {event_id: "validate", run_id: "run-1", node_id: "node-a", attempt: 1, caused_by: "audit", previous: "completed", next: "validated", content_sha256: digest},
  ]
  lifecycle.validate_events(events)?
  test.ok(lifecycle.transition_allowed("created", "created"))?
  test.ok(lifecycle.transition_allowed("created", "started"))?
  test.ok(lifecycle.transition_allowed("completed", "validated"))?
  test.ok(! lifecycle.transition_allowed("validated", "started"))?
  let transition = lifecycle.transition("node-a", "started", "completed", 1, "runner", true)?
  test.eq(transition.next, "completed")?
  test.eq(lifecycle.finalize({desired: "started", process: "exited", evidence: "valid"}, false, false)?.result, "pass")?
  test.eq(lifecycle.finalize({desired: "started", process: "exited", evidence: "invalid"}, false, false)?.state, "failed")?
  test.eq(lifecycle.finalize({desired: "started", process: "live", evidence: "valid"}, true, false)?.state, "cancelled")?
  test.eq(lifecycle.finalize({desired: "started", process: "live", evidence: "valid"}, false, true)?.state, "budget-breached")?

  match lifecycle.validate_events(events.push(events[2])) {
    Ok(_) => test.fail("duplicate lifecycle evidence was accepted")?
    Err(_) => {}
  }
  match lifecycle.validate_events([{event_id: "start", run_id: "run-1", node_id: "node-a", attempt: 1, caused_by: "controller", previous: "created", next: "started", content_sha256: "short"}]) {
    Ok(_) => test.fail("invalid lifecycle content hash was accepted")?
    Err(_) => {}
  }
}
