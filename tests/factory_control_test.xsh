##! Native tests for factory contracts and lifecycle state.

use factory.control as control
use factory.runtime as runtime
use factory.schema as schema

proc test_cycle_request_parsing() [error] {
  let request = "# Cycle\n\n## Mode\n\n- `organization`\n\n## Active evals\n\n- `task-tags`\n\n## Trial plan\n\n- Count: `1`\n\n## New eval proposals\n\n- Count: `1`\n\n## Approved tickets\n\n- `task-tags-001`\n- `task-tags-002`\n"
  test.eq(control.request_mode(request), "organization")?
  test.eq(control.request_eval(request), "task-tags")?
  test.eq(control.request_tickets(request), ["task-tags-001", "task-tags-002"])?
  test.eq(control.request_trial_count(request)?, 1)?
  test.eq(control.request_new_eval_count(request)?, 1)?
  test.ok(! control.request_allow_measured_eval(request))?
  test.ok(control.request_allow_measured_eval(request + "\n- Allow measured eval reuse: `yes`\n"))?
  test.eq(control.request_ticket_policy(request), "explicit")?
}

proc test_untried_eval_policy_is_explicit() [error] {
  test.ok(! control.request_allow_measured_eval("# Cycle\n"))?
  test.ok(control.request_allow_measured_eval("- Allow measured eval reuse: `yes`"))?
}

proc test_eval_difficulty_contract_gate() [error] {
  let valid = "## Eval task-rich\n\n## Difficulty justification\n\nThis task combines two independent data transformations and stateful aggregation, includes a meaningful failure control, and uses hidden cases that defeat a one-liner or hard-coded answer.\n"
  let weak = "## Eval task-trivial\n\n## Difficulty justification\n\nThis is a simple one-liner.\n"
  test.ok(control.eval_difficulty_contract_ok(valid))?
  test.ok(! control.eval_difficulty_contract_ok(weak))?
  test.ok(! control.eval_difficulty_contract_ok("## Eval task-missing\n"))?
}

proc test_eval_evaluator_package_ownership_gate() [error] {
  test.ok(control.eval_evaluator_package_owned("proc main() { json.write(...) }"))?
  test.ok(! control.eval_evaluator_package_owned(
    "let dispatcher = p\"/usr/local/lib/xsh-factory/factory/dispatcher.xsh\""))?
  test.ok(! control.eval_evaluator_package_owned(
    "let dispatcher = env.get_or(\"FACTORY_EVAL_EVALUATOR\", \"\")?"))?
}

proc test_forbidden_subprocess_scan_ignores_comments() [error] {
  test.ok(! control.source_has_forbidden_subprocess(
    "# run a command in prose\nlet note = \"safe\"\n"))?
  test.ok(control.source_has_forbidden_subprocess(
    "# harmless\nlet status = process.run(command)\n"))?
  test.ok(control.source_has_forbidden_subprocess(
    "let child = spawn process.command_argv(\"xsh\", args)\n"))?
}

proc test_organization_selects_two_approved_tickets(ctx: TestContext) [fs, error] {
  let root = test.temp_dir(ctx, name: "approved-ticket-selection")?
  let tickets = fp"${root}/tickets"
  fs.mkdir(tickets)?
  fs.write(fp"${tickets}/task-z.md", "# Ticket\n\n## Status\n\nOpen.\n")?
  fs.write(fp"${tickets}/task-b.md", "# Ticket\n\n## Status\n\nApproved.\n\n## Change target\n\n- `product`\n")?
  fs.write(fp"${tickets}/task-a.md", "# Ticket\n\n## Status\n\nApproved.\n\n## Change target\n\n- `product`\n")?
  fs.write(fp"${tickets}/task-factory.md", "# Ticket\n\n## Status\n\nApproved.\n\n## Change target\n\n- `factory`\n")?
  test.eq(runtime.first_approved_tickets(root, 2)?, ["task-a", "task-b"])?
  test.ok(! runtime.accepted_ticket(fp"${tickets}/task-factory.md")?)?
}

proc test_cto_inventory_surfaces_ticket_state() [error] {
  let markdown = runtime.cto_inventory_markdown([
    {id: "task-a", status: "Open.", change_target: "product", eval_id: "task-envcfg", cto_review: false, open_branch: "", path: "tickets/task-a.md"},
    {id: "task-b", status: "Approved.", change_target: "factory", eval_id: "task-ecount", cto_review: true, open_branch: "", path: "tickets/task-b.md"},
  ])
  test.contains(markdown, "Open tickets: 1")?
  test.contains(markdown, "Approved tickets: 1")?
  test.contains(markdown, "`task-a` | `Open.` | `product`")?
  test.contains(markdown, "`task-b` | `Approved.` | `factory`")?
  test.contains(markdown, "| present |")?
}

proc test_cto_gate_surfaces_unreviewed_open_tickets() [error] {
  let tickets = [
    {id: "task-open", status: "Open.", eval_id: "task-envcfg", cto_review: false, open_branch: "", path: "tickets/task-open.md"},
    {id: "task-reviewed", status: "Open.", eval_id: "task-ecount", cto_review: true, open_branch: "", path: "tickets/task-reviewed.md"},
    {id: "task-approved", status: "Approved.", eval_id: "task-tags", cto_review: false, open_branch: "", path: "tickets/task-approved.md"},
  ]
  test.eq(runtime.cto_unreviewed_open_tickets(tickets), ["task-open"])?
}

proc test_handbook_candidate_gate_requires_ledger_disposition(ctx: TestContext) [fs, error] {
  let root = test.temp_dir(ctx, name: "handbook-gate")?
  fs.mkdir(fp"${root}/runtime")?
  fs.mkdir(fp"${root}/runs/run-1/lineage")?
  fs.write(fp"${root}/runtime/handbook.md", "approved\n")?
  let candidate = fp"${root}/runs/run-1/lineage/handbook-candidate.md"
  fs.write(candidate, "candidate\n")?
  test.eq(runtime.unresolved_handbook_candidates(root)?, 1)?
  let candidate_sha = hash.sha256(candidate)?.hex()
  fs.write(fp"${root}/runtime/handbook-ledger.md", f"promoted ${candidate_sha}\n")?
  test.eq(runtime.unresolved_handbook_candidates(root)?, 0)?
}

proc test_organization_phase_request_preserves_multiple_tickets() [fs, error] {
  let template = fs.read_text(fp"${fs.cwd()?}/templates/ORGANIZATION-PHASE-REQUEST.md")?
  let request = control.fill_template(template, [
    {key: "MODE", value: "ticket-implementation"},
    {key: "EVAL_ID", value: "task-envcfg"},
    {key: "TRIAL_COUNT", value: "1"},
    {key: "NEW_EVAL_COUNT", value: "0"},
    {key: "TICKET_ID", value: "`task-a`\n- `task-b`"},
    {key: "OBJECTIVE", value: "fixture"},
  ])
  let tickets = control.request_tickets(request)
  test.eq(tickets.len(), 2)?
  test.eq(tickets[0], "task-a")?
  test.eq(tickets[1], "task-b")?
}

proc test_role_defaults_are_coded_and_capped() [env, error] {
  test.eq(control.default_cycle_budget(), "1.00")?
  test.eq(control.clamp_cycle_budget("2.00")?, "1.00")?
  test.eq(control.max_concurrent_engineers(), 2)?
  test.eq(control.max_concurrent_engineers(), 2)?
  test.eq(control.max_eval_contracts(), 30)?
  test.eq(control.max_eval_contracts(), 30)?
  for role in ["director", "eval-designer", "eval-manager", "eval-worker", "engineer"] {
    test.eq(control.default_provider(role), "openrouter")?
    if role == "engineer" {
      test.eq(control.default_model(role), "openai/gpt-5.6-luna")?
    } else {
      test.eq(control.default_model(role), "deepseek/deepseek-v4-flash-0731")?
    }
    test.eq(control.default_thinking(role), "high")?
    test.ok(control.default_budget(role) != "")?
    test.ok(control.default_max_turns(role) != "")?
  }
  test.eq(control.default_max_turns("eval-designer"), "64")?
  test.eq(control.default_budget("engineer"), "0.35")?
  test.eq(control.default_max_turns("engineer"), "220")?
  test.eq(control.default_max_wall_seconds("director"), "1800")?
  test.eq(control.default_max_wall_seconds("eval-designer"), "720")?
  test.eq(control.default_max_wall_seconds("eval-manager"), "900")?
  test.eq(control.default_max_wall_seconds("eval-worker"), "1800")?
  test.eq(control.default_max_wall_seconds("engineer"), "1800")?
  env FACTORY_ENGINEER_BUDGET_USD="2" {
    test.eq(control.configured_role_setting("engineer", "BUDGET_USD")?, control.default_budget("engineer"))?
  }
  env FACTORY_ENGINEER_BUDGET_USD="0.01" {
    test.eq(control.configured_role_setting("engineer", "BUDGET_USD")?, "0.01")?
  }
}

proc test_north_star_contains_rationale_without_factory_symlink() [fs, error] {
  let root = fs.cwd()?
  let north_star = fs.read_text(fp"${root}/NORTH-STAR.md")?
  test.contains(north_star, "## XSH rationale")?
  test.contains(north_star, "The Archaeological Site")?
  test.contains(north_star, "next century")?
  test.ok(! fs.exists(fp"${root}/docs/CHAPTER-01-why-xsh.md")?)?
}

proc test_ticket_api_surface_gate_rejects_unjustified_new_surface() [fs, error] {
  let ticket = "# Ticket\n\n## Status\n\nApproved.\n\n## Change target\n\n- `product`\n\n## Proposed XSH change\n\nAdd a new builtin primitive.\n"
  test.ok(! control.ticket_api_surface_gate_ok(ticket))?
  test.ok(control.ticket_api_surface_gate_ok(ticket.replace("## Proposed XSH change", "## API-surface justification\n\nThe existing operation is insufficient; semantic evidence is required.\n\n## Proposed XSH change")))?
}

proc test_ticket_api_surface_gate_is_documented() [fs, error] {
  let ticket = fs.read_text(fp"${fs.cwd()?}/templates/TICKET.md")?
  test.contains(ticket, "## API-surface justification")?
  test.contains(ticket, "semantic capability")?
  test.contains(ticket, "desugaring")?
  test.contains(ticket, "ergonomic shortcut")?
}

proc test_admission_and_report_contracts() [error] {
  test.ok(control.valid_eval_id("task-tags"))?
  test.eq(control.eval_id_from_contract("# Eval task-probe\n\n## Status\n\nDraft.\n"), "task-probe")?
  test.eq(control.eval_id_from_contract("# Proposal\n"), "")?
  test.ok(! control.valid_eval_id("../escape"))?
  test.ok(control.valid_ticket_id("task-tags-001"))?
  test.ok(! control.valid_ticket_id("task/tags"))?
  test.ok(control.ticket_is_accepted("# Ticket\n\n## Status\n\nApproved.\n\n## Change target\n\n- `product`\n"))?
  test.eq(control.ticket_change_target("# Ticket\n\n## Change target\n\n- `product`\n"), "product")?
  test.eq(control.ticket_change_target("# Ticket\n\n## Change target\n\n- `factory`\n"), "factory")?
  test.ok(control.ticket_change_target("# Ticket\n") != "product")?
  test.ok(! control.ticket_is_accepted("# Ticket\n\n## Status\n\nApproved.\n"))?
  test.ok(! control.ticket_is_accepted("# Ticket\n\n## Status\n\nApproved.\n\n## Change target\n\n- `factory`\n"))?
  test.ok(control.eval_is_disabled("# Eval\n\n## Status\n\nDisabled.\n"))?
  test.ok(! control.ticket_is_closed("# Ticket\n\n## Status\n\nApproved.\n"))?
  test.ok(control.report_contract_ok("# Report\n\n## Result\n\npass\n\n## Evidence\n\nready\n", ["Evidence"], "pass"))?
  test.ok(! control.report_contract_ok("# Report\n\n## Result\n\npass\n", ["Evidence"], "pass"))?
  test.ok(control.manager_tool_error_findings_contract_ok("## Tool-error findings\n\nreport.json\n"))?
  test.ok(control.manager_tool_error_findings_contract_ok("## Tool-error findings\n\nFour nonzero Pi tool results were accounted for.\n"))?
  test.ok(! control.manager_tool_error_findings_contract_ok("## Tool-error findings\n\nFill every current tool error.\n"))?
  let manager_report = "## Result\n\npass\n\n## Effort metrics\n\nfixture\n\n## Usage and cost\n\nfixture\n\n## Thinking evidence\n\nfixture\n\n## Tool-error findings\n\nFive nonzero Pi tool results were accounted for in `tool_errors`.\n\n## Timing evidence\n\nfixture\n\n## Observation classification\n\nfixture\n\n## Handbook decision\n\nunchanged\n\n## Tickets created\n\nNone.\n\n## Post-merge decisions\n\nNone.\n\n## Next replay\n\nNone.\n\n## North-star impact\n\nfixture\n"
  test.ok(control.manager_report_gate_ok(manager_report, true, false))?
  test.eq(control.report_section("# Report\n\n## Result\n\npass\n\nDetails.\n\n## Evidence\n\nready\n", "Result"), "pass\n\nDetails.")?
  test.eq(control.report_field("# Report\n\n## Result\n\npass\n\nDetails.\n\n## Evidence\n\nready\n", "Result"), "pass")?
}

proc test_eval_proposal_is_promoted_without_acceptance(ctx: TestContext) [fs, error] {
  let factory = test.temp_dir(ctx, name: "eval-promotion")?
  let proposal = fp"${factory}/runs/run-1/proposals/proposal-1"
  fs.mkdir(fp"${proposal}/runtime")?
  fs.mkdir(fp"${factory}/evals")?
  fs.write(fp"${proposal}/EVAL.md", "# Eval task-probe\n\n## Status\n\nDraft.\n")?
  for relative in ["executor.xsh", "evaluate.xsh", "evaluator.xsh", "runtime/task.md", "runtime/artifact.md"] {
    fs.write(fp"${proposal}/${relative}", f"${relative}\n")?
  }
  let run_dir = fp"${factory}/runs/run-1"
  test.ok(runtime.promote_eval_proposal(factory, proposal, run_dir, "rejected")?)?
  let promoted = fp"${factory}/evals/task-probe"
  test.ok(fs.exists(fp"${promoted}/evaluator.xsh")?)?
  let contract = fs.read_text(fp"${promoted}/EVAL.md")?
  test.contains(contract, "## CTO review")?
  test.contains(contract, "Result: `rejected`")?
  test.contains(contract, "Package: `complete`")?
  test.contains(contract, "Status: `Draft.`")?
  test.ok(! runtime.promote_eval_proposal(factory, proposal, run_dir, "accepted")?)?

  let partial = fp"${factory}/runs/run-2/proposals/proposal-1"
  fs.mkdir(fp"${partial}/runtime")?
  fs.write(fp"${partial}/EVAL.md", "# Eval task-legacy\n\n## Status\n\nDraft.\n")?
  for relative in ["executor.xsh", "evaluate.xsh", "runtime/task.md", "runtime/artifact.md"] {
    fs.write(fp"${partial}/${relative}", f"${relative}\n")?
  }
  test.ok(runtime.promote_eval_proposal(factory, partial, fp"${factory}/runs/run-2", "rejected")?)?
  let partial_contract = fs.read_text(fp"${factory}/evals/task-legacy/EVAL.md")?
  test.contains(partial_contract, "Package: `incomplete`")?
  test.contains(partial_contract, "evaluator.xsh")?

  let accepted = fp"${factory}/runs/run-3/proposals/proposal-1"
  fs.mkdir(fp"${accepted}/runtime")?
  fs.write(fp"${accepted}/EVAL.md", "# Eval task-accepted\n\n## Status\n\nDraft.\n")?
  for relative in ["executor.xsh", "evaluate.xsh", "evaluator.xsh", "runtime/task.md", "runtime/artifact.md"] {
    fs.write(fp"${accepted}/${relative}", f"${relative}\n")?
  }
  test.ok(runtime.promote_eval_proposal(factory, accepted, fp"${factory}/runs/run-3", "accepted")?)?
  test.eq(control.ticket_status(fs.read_text(fp"${factory}/evals/task-accepted/EVAL.md")?), "Approved.")?
}

proc test_role_report_skeletons_are_fail_closed() [fs, error] {
  let root = fs.cwd()?
  let manager = fs.read_text(fp"${root}/templates/EVAL-MANAGER-REPORT.md")?
  let director = fs.read_text(fp"${root}/templates/DIRECTOR-REPORT.md")?
  let engineer = fs.read_text(fp"${root}/templates/ENGINEER-REPORT.md")?
  for report in [manager, director, engineer] {
    test.contains(report, "## Result")?
    test.contains(report, "not-ready")?
  }
  test.contains(manager, "## Tool-error findings")?
  let assignment = fs.read_text(fp"${fs.cwd()?}/templates/EVAL-MANAGER-ASSIGNMENT.md")?
  test.contains(assignment, "exact absolute path")?
  test.contains(assignment, "construct a relative path")?
  test.contains(manager, "## Next replay")?
  test.contains(director, "## Required-output status")?
  test.contains(engineer, "## Commit")?
  let runner = fs.read_text(fp"${root}/factory/entrypoints/run-agent.xsh")?
  test.contains(runner, "EVAL-MANAGER-REPORT.md")?
  test.contains(runner, "DIRECTOR-REPORT.md")?
  test.contains(runner, "ENGINEER-REPORT.md")?
}

proc test_standard_cycle_uses_diverse_active_eval() [fs, error] {
  let request = fs.read_text(fp"${fs.cwd()?}/cycle-organization.md")?
  let improvement = fs.read_text(fp"${fs.cwd()?}/templates/CTO-IMPROVEMENT.md")?
  let productivity = fs.read_text(fp"${fs.cwd()?}/templates/CTO-PRODUCTIVITY-REPORT.md")?
  let ledger = fs.read_text(fp"${fs.cwd()?}/runtime/handbook-ledger.md")?
  let launcher = fs.read_text(fp"${fs.cwd()?}/run.xsh")?
  let organization = fs.read_text(fp"${fs.cwd()?}/factory/controllers/organization.xsh")?
  let runtime_source = fs.read_text(fp"${fs.cwd()?}/factory/runtime.xsh")?
  let cto_runner = fs.read_text(fp"${fs.cwd()?}/factory/tools/cto.xsh")?
  test.contains(request, "`task-bigfiles`")?
  test.contains(request, "Allow measured eval reuse")?
  test.contains(fs.read_text(fp"${fs.cwd()?}/factory/tools/eval-trends.xsh")?, "median_turns")?
  test.contains(request, "## Bottleneck review")?
  test.ok(! request.contains("`task-tags`"))?
  test.ok(! fs.exists(fp"${fs.cwd()?}/evals/task-tags/EVAL.md")?)
  test.contains(fs.read_text(fp"${fs.cwd()?}/evals/RETIREMENTS.md")?, "task-tags")?
  test.contains(improvement, "## Baseline metric")?
  test.contains(improvement, "## Revert condition")?
  test.contains(improvement, "not awaiting another approval")?
  test.contains(improvement, "before admitting")?
  test.contains(ledger, "One-time CTO consolidation")?
  test.contains(ledger, "Future candidates require a new explicit CTO disposition")?
  let cto = fs.read_text(fp"${fs.cwd()?}/CTO.md")?
  let factory = fs.read_text(fp"${fs.cwd()?}/FACTORY.md")?
  test.contains(cto, "not a request for approval")?
  test.contains(cto, "may finish the cycle with `pending-validation`")?
  test.contains(cto, "product merge is a CTO decision")?
  test.contains(cto, "Before declaring any cycle complete")?
  test.contains(cto, "cto: close <run-id>")?
  test.contains(cto, "unconditionally closes")?
  test.contains(cto, "regardless of")?
  test.contains(cto, "do not batch multiple runs")?
  test.contains(cto, "The CTO decides whether to merge or apply")?
  test.contains(cto, "Admission is an explicit CTO decision")?
  test.contains(cto, "Throughput invariant")?
  test.contains(cto, "Factory-efficiency gate")?
  test.contains(cto, "Assembly-line bottleneck gate")?
  test.contains(cto, "Eval-strength gate")?
  test.contains(cto, "CTO-PRODUCTIVITY-REPORT.md")?
  test.contains(improvement, "## Throughput requirement")?
  test.contains(productivity, "## Assembly-line bottleneck")?
  test.contains(request, "Throughput gate: when a quality-approved ticket is admitted")?
  test.contains(request, "Admission invariant: approve eligible Open tickets before invoking `run.xsh`")?
  let cycle_template = fs.read_text(fp"${fs.cwd()?}/templates/cycle-request.md")?
  test.contains(cycle_template, "Require at least one engineer implementation commit")?
  test.contains(cycle_template, "Approve eligible Open tickets before controller invocation")?
  test.contains(cycle_template, "Never leave an")?
  test.contains(cycle_template, "eligible ticket Open")?
  test.ok(! cto.contains("user authority"))?
  test.ok(! factory.contains("user authority"))?
  test.ok(! factory.contains("user approves"))?
  test.contains(launcher, "templates/CTO-IMPROVEMENT.md")?
  test.contains(launcher, "candidate_tickets")?
  test.contains(launcher, "first_approved_tickets")?
  test.contains(launcher, "cto_unreviewed_open_tickets")?
  test.contains(launcher, "unresolved_handbook_candidates")?
  test.contains(launcher, "factory/tools/cto.xsh")?
  test.contains(organization, "first_approved_tickets")?
  test.contains(fs.read_text(fp"${fs.cwd()?}/run.xsh")?, "next_untried_approved_eval")?
  test.contains(organization, "cto_unreviewed_open_tickets")?
  test.contains(organization, "write_cto_inventory")?
  test.contains(cto_runner, "cto_ticket_inventory")?
  test.contains(organization, "for ticket_id in selected_tickets")?
  test.contains(organization, "ticket_eval_available")?
  test.contains(organization, "eval_is_disabled")?
  test.contains(organization, "max_concurrent_engineers()")?
  test.ok(! organization.contains("admit at most one ticket"))?
  test.contains(runtime_source, "passing engineer report")?
  test.ok(! runtime_source.contains("git branch provenance"))?
}

proc test_agent_completion_is_report_bound() [error] {
  test.ok(control.agent_completion_ok(true, true, true, true))?
  test.ok(! control.agent_completion_ok(false, true, true, true))?
  test.ok(! control.agent_completion_ok(true, false, true, true))?
  test.ok(! control.agent_completion_ok(true, true, false, true))?
  test.ok(! control.agent_completion_ok(true, true, true, false))?
}

proc test_report_schema_is_single_machine_contract(ctx: TestContext) [fs, error] {
  let root = test.temp_dir(ctx, name: "report-schema")?
  let worker = fp"${root}/worker.json"
  json.write(worker, {
    schema_version: 1, kind: "worker", identity: {role: "engineer", worker_id: "fixture"},
    state: "completed", result: "pass", data: {usage: {assistant_turns: 1}},
    findings: [], artifacts: [{kind: "session", path: "session.jsonl"}]
  }, pretty: true)?
  let value = json.read(worker)?
  test.ok(schema.valid(value, "worker"))?
  test.ok(! schema.valid(value, "phase"))?
  test.eq(schema.value_text(json.get(value, ["result"], null)), "pass")?
}

proc test_lifecycle_rejects_improvised_transitions() [error] {
  test.ok(control.transition_allowed("created", "started"))?
  test.ok(control.transition_allowed("started", "completed"))?
  test.ok(control.transition_allowed("started", "failed"))?
  test.ok(control.transition_allowed("completed", "validated"))?
  test.ok(! control.transition_allowed("created", "validated"))?
  test.ok(! control.transition_allowed("completed", "started"))?
}

proc test_event_ledger_is_jsonl_and_stateful(ctx: TestContext) [fs, error] {
  let root = test.temp_dir(ctx, name: "event-ledger")?
  runtime.emit_event(root, root, "01-start", "worker", "started", 1, "controller", "assigned")?
  runtime.emit_event(root, root, "02-complete", "worker", "completed", 1, "worker", "returned")?
  let events = fp"${root}/events.jsonl"
  test.ok(fs.exists(events)?)?
  let text = fs.read_text(events)?
  test.contains(text, "\"kind\":\"event\"")?
  test.contains(text, "\"event_id\":\"02-complete\"")?
  test.eq(fs.read_text(fp"${root}/states/worker.state")?.trim(), "completed")?
  test.ok(! fs.exists(fp"${root}/events/02-complete.md")?)?
}

proc test_budget_consequences_are_durable(ctx: TestContext) [fs, error] {
  let factory = test.temp_dir(ctx, name: "budget-consequences")?
  fs.mkdir(fp"${factory}/tickets")?
  fs.mkdir(fp"${factory}/evals/task-tags")?
  fs.mkdir(fp"${factory}/templates")?
  fs.copy(fp"${fs.cwd()?}/templates/TICKET.md", fp"${factory}/templates/TICKET.md", overwrite: true)?
  fs.copy(fp"${fs.cwd()?}/templates/BUDGET-BREACH.md", fp"${factory}/templates/BUDGET-BREACH.md", overwrite: true)?
  fs.write(fp"${factory}/tickets/task-tags-002.md", "# Ticket\n\n## Status\n\nApproved.\n")?
  fs.write(fp"${factory}/evals/task-tags/EVAL.md", "# Eval\n\n## Status\n\nApproved.\n")?
  let engineer_report = fp"${factory}/runs/run-1/workers/engineer/task-tags-002/report.json"
  let eval_report = fp"${factory}/runs/run-2/workers/eval-worker/task-tags-1/report.json"
  fs.mkdir(engineer_report.parent())?
  fs.mkdir(eval_report.parent())?
  json.write(engineer_report, {schema_version: 1, kind: "worker", identity: {role: "engineer", worker_id: "task-tags-002"}, state: "completed", result: "fail", findings: [], artifacts: []}, pretty: true)?
  json.write(eval_report, {schema_version: 1, kind: "worker", identity: {role: "eval-worker", worker_id: "task-tags-1"}, state: "completed", result: "fail", findings: [], artifacts: []}, pretty: true)?
  test.ok(runtime.close_ticket_too_difficult(factory, "task-tags-002", engineer_report.parent())?)?
  let closed = fs.read_text(fp"${factory}/tickets/task-tags-002.md")?
  test.ok(control.ticket_is_closed(closed))?
  test.contains(closed, "Reason: too difficult")?
  test.contains(closed, "runs/run-1/workers/engineer/task-tags-002/report.json")?
  test.ok(runtime.disable_eval(factory, "task-tags", eval_report.parent())?)?
  let disabled = fs.read_text(fp"${factory}/evals/task-tags/EVAL.md")?
  test.ok(control.eval_is_disabled(disabled))?
  test.contains(disabled, "Reason: eval-worker budget exceeded")?
  test.contains(disabled, "runs/run-2/workers/eval-worker/task-tags-1/report.json")?
}

proc test_engineer_assignment_is_controller_bound() [error] {
  let assignment = "- Ticket ID: `task-tags-001`\n- Dedicated XSH worktree: `/tmp/work`\n<!-- CONTROLLER_TICKET_SNAPSHOT_BEGIN -->\nticket\n<!-- CONTROLLER_TICKET_SNAPSHOT_END -->\nDo not search for open tickets\n"
  test.ok(control.engineer_assignment_ok("/factory/runs/run-1", "task-tags-001",
    "/factory/runs/run-1/messages/task-tags-001.md", "/tmp/work", assignment))?
  test.ok(! control.engineer_assignment_ok("/factory/runs/run-1", "task-tags-002",
    "/factory/runs/run-1/messages/task-tags-002.md", "/tmp/work", assignment))?
}

proc test_eval_image_inputs_are_local() [fs, error] {
  let dockerfile = fs.read_text(fp"${fs.cwd()?}/evals/Dockerfile.base")?
  let controller = fs.read_text(fp"${fs.cwd()?}/factory/controllers/eval.xsh")?
  let executor = fs.read_text(fp"${fs.cwd()?}/factory/entrypoints/eval-executor.xsh")?
  test.contains(dockerfile, ".dist/xsh")?
  test.contains(dockerfile, ".dist/xsht")?
  test.contains(dockerfile, "pi-headless-bun-musl-static/releases/download/pi-3aeca83d-bun-1.4.0-linux-arm64-musl/pi")?
  test.contains(dockerfile, "443d39a4a2565e13edd70068ace8131baf71b3fd1edfa19a9d6b65a2ed7633ed")?
  test.contains(controller, "dist-Linux-docker")?
  test.contains(controller, "stage_xsht")?
  test.contains(executor, "--pids-limit")?
  test.contains(executor, "--memory")?
  test.contains(executor, "size=64m")?
}
