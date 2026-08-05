##! Native tests for lifecycle, ownership, and run-scoped cleanup.

use factory.types as types
use factory.lifecycle as lifecycle
use factory.process as owned_process
use factory.cleanup as cleanup

proc test_lifecycle_rejects_illegal_and_evidence_free_completion() [error] {
  match lifecycle.transition("node-a", "created", "completed", 1, "controller", false) {
    Ok(_) => test.fail("evidence-free completion was accepted")?,
    Err(_) => {},
  }
  match lifecycle.transition("node-a", "completed", "started", 1, "controller", true) {
    Ok(_) => test.fail("backward lifecycle transition was accepted")?,
    Err(_) => {},
  }
  let _admitted = lifecycle.transition("node-a", "created", "admitted", 1, "controller", false)?
  let _started = lifecycle.transition("node-a", "admitted", "started", 1, "controller", false)?
  let _completed = lifecycle.transition("node-a", "started", "completed", 1, "controller", true)?
}

proc test_event_ledger_rejects_duplicates_and_impossible_attempts() [error] {
  let events = [
    {event_id: "admit", run_id: "run-1", node_id: "node-a", attempt: 1, caused_by: "controller", previous: "created", next: "admitted", content_sha256: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"},
    {event_id: "start", run_id: "run-1", node_id: "node-a", attempt: 1, caused_by: "controller", previous: "admitted", next: "started", content_sha256: "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"},
    {event_id: "complete", run_id: "run-1", node_id: "node-a", attempt: 1, caused_by: "runner", previous: "started", next: "completed", content_sha256: "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"},
  ]
  lifecycle.validate_events(events)?
  let duplicate = events.push(events[2])
  match lifecycle.validate_events(duplicate) {
    Ok(_) => test.fail("duplicate event ID was accepted")?,
    Err(_) => {},
  }
  let bad_attempt = events.push({event_id: "retry", run_id: "run-1", node_id: "node-a", attempt: 3, caused_by: "controller", previous: "completed", next: "started", content_sha256: "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"})
  match lifecycle.validate_events(bad_attempt) {
    Ok(_) => test.fail("non-monotonic event attempt was accepted")?,
    Err(_) => {},
  }
}

proc test_finalization_keeps_process_and_evidence_distinct() [error] {
  let pass = lifecycle.finalize({desired: "started", process: "exited", evidence: "valid"}, false, false)?
  test.eq(pass.state, "completed")?
  let missing = lifecycle.finalize({desired: "started", process: "exited", evidence: "missing"}, false, false)?
  test.eq(missing.state, "failed")?
  let cancelled = lifecycle.finalize({desired: "started", process: "live", evidence: "missing"}, true, false)?
  test.eq(cancelled.state, "cancelled")?
  let breached = lifecycle.finalize({desired: "started", process: "live", evidence: "missing"}, false, true)?
  test.eq(breached.state, "budget-breached")?
}

proc test_process_ownership_is_run_and_node_scoped(ctx: TestContext) [fs, error] {
  let root = test.temp_dir(ctx, name: "process-owner")?
  let owner = {run_id: "run-1", node_id: "node-a", controller_pid: 42, pid: 43, container_id: "", start_marker: "start-a", claim_token: "claim-a"}
  owned_process.register(root, owner)?
  match owned_process.register(root, owner) {
    Ok(_) => test.fail("duplicate process ownership was accepted")?,
    Err(_) => {},
  }
  owned_process.mark(root, types.make_node_id("node-a")?, "exited")?
  let owner_record = json.read(fp"${root}/processes/node-a.json")?
  test.eq(json.get(owner_record, ["state"], ""), "exited")?
}

proc test_cleanup_preserves_durable_evidence(ctx: TestContext) [fs, error] {
  let root = test.temp_dir(ctx, name: "cleanup-contract")?
  fs.write(fp"${root}/events.jsonl", "durable\n")?
  fs.write(fp"${root}/report.json", "durable\n")?
  fs.write(fp"${root}/worker.stdout", "transient\n")?
  fs.write(fp"${root}/node.pids", "42\n")?
  fs.write(fp"${root}/factory.lock", "lock\n")?
  test.ok(! cleanup.removable(root, Path("/outside/report.json"), "report.json")?)
  cleanup.run_scoped(root)?
  test.ok(fs.exists(fp"${root}/events.jsonl")?)
  test.ok(fs.exists(fp"${root}/report.json")?)
  test.ok(! fs.exists(fp"${root}/worker.stdout")?)
  test.ok(! fs.exists(fp"${root}/node.pids")?)
  test.ok(! fs.exists(fp"${root}/factory.lock")?)
}
