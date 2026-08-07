##! Native tests for factory contracts and lifecycle state.
use factory.control as control
use factory.runtime as runtime
use factory.schema as schema

proc test_cycle_request_parsing() [error] {
  let request = """# Cycle

## Mode

- `organization`

## Active evals

- `task-tags`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `1`

## Approved tickets

- `task-tags-001`
- `task-tags-002`
"""
  test.eq(control.request_mode(request), "organization")?
  test.eq(control.request_eval(request), "task-tags")?
  test.eq(control.request_tickets(request), ["task-tags-001", "task-tags-002"])?
  test.eq(control.request_trial_count(request)?, 1)?
  test.eq(control.request_new_eval_count(request)?, 1)?
  test.ok(! control.request_allow_measured_eval(request))?
  test.ok(
    control.request_allow_measured_eval(
  request + """
- Allow measured eval reuse: `yes`
""",
),
  )?
  test.eq(control.request_ticket_policy(request), "explicit")?
}

proc test_untried_eval_policy_is_explicit() [error] {
  test.ok(
    ! control.request_allow_measured_eval("""# Cycle
"""),
  )?
  test.ok(control.request_allow_measured_eval("- Allow measured eval reuse: `yes`"))?
}

proc test_eval_difficulty_contract_gate() [error] {
  let valid = """## Eval task-rich

## Difficulty justification

This task combines two independent data transformations and stateful aggregation, includes a meaningful failure control, and uses hidden cases that defeat a one-liner or hard-coded answer.
"""
  let weak = """## Eval task-trivial

## Difficulty justification

This is a simple one-liner.
"""
  test.ok(control.eval_difficulty_contract_ok(valid))?
  test.ok(! control.eval_difficulty_contract_ok(weak))?
  test.ok(
    ! control.eval_difficulty_contract_ok("""## Eval task-missing
"""),
  )?
}

proc test_eval_evaluator_package_ownership_gate() [error] {
  test.ok(control.eval_evaluator_package_owned("proc main() { json.write(...) }"))?
  test.ok(
    ! control.eval_evaluator_package_owned(
      "let dispatcher = p\"/usr/local/lib/xsh-factory/factory/dispatcher.xsh\"",
    ),
  )?
  test.ok(
    ! control.eval_evaluator_package_owned(
      "let dispatcher = env.get_or(\"FACTORY_EVAL_EVALUATOR\", \"\")?",
    ),
  )?
}

proc test_forbidden_subprocess_scan_ignores_comments() [error] {
  test.ok(
    ! control.source_has_forbidden_subprocess("""# run a command in prose
let note = "safe"
"""),
  )?
  test.ok(
    control.source_has_forbidden_subprocess("""# harmless
let status = process.run(command)
"""),
  )?
  test.ok(
    control.source_has_forbidden_subprocess("""let child = spawn process.command_argv("xsh", args)
"""),
  )?
}

proc test_organization_selects_two_approved_tickets(ctx: TestContext) [fs, error] {
  let root = test.temp_dir(ctx, name: "approved-ticket-selection")?
  let tickets = fp"${root}/tickets"
  fs.mkdir(tickets)?
  fs.write(
    fp"${tickets}/task-z.md",
    """# Ticket

## Status

Open.
""",
  )?
  fs.write(
    fp"${tickets}/task-b.md",
    """# Ticket

## Status

Approved.

## Change target

- `product`
""",
  )?
  fs.write(
    fp"${tickets}/task-a.md",
    """# Ticket

## Status

Approved.

## Change target

- `product`
""",
  )?
  fs.write(
    fp"${tickets}/task-factory.md",
    """# Ticket

## Status

Approved.

## Change target

- `factory`
""",
  )?
  test.eq(runtime.first_approved_tickets(root, 2)?, ["task-a", "task-b"])?
  test.ok(! runtime.accepted_ticket(fp"${tickets}/task-factory.md")?)?
}

proc test_cto_inventory_surfaces_ticket_state() [error] {
  let markdown = runtime.cto_inventory_markdown(
    [
      {
        id: "task-a",
        status: "Open.",
        change_target: "product",
        eval_id: "task-envcfg",
        cto_review: false,
        open_branch: "",
        path: "tickets/task-a.md",
      },
      {
        id: "task-b",
        status: "Approved.",
        change_target: "factory",
        eval_id: "task-ecount",
        cto_review: true,
        open_branch: "",
        path: "tickets/task-b.md",
      },
    ],
  )
  test.contains(markdown, "Open tickets: 1")?
  test.contains(markdown, "Approved tickets: 1")?
  test.contains(markdown, "`task-a` | `Open.` | `product`")?
  test.contains(markdown, "`task-b` | `Approved.` | `factory`")?
  test.contains(markdown, "| present |")?
}

proc test_cto_gate_surfaces_unreviewed_open_tickets() [error] {
  let tickets = [
    {
      id: "task-open",
      status: "Open.",
      eval_id: "task-envcfg",
      cto_review: false,
      open_branch: "",
      path: "tickets/task-open.md",
    },
    {
      id: "task-reviewed",
      status: "Open.",
      eval_id: "task-ecount",
      cto_review: true,
      open_branch: "",
      path: "tickets/task-reviewed.md",
    },
    {
      id: "task-approved",
      status: "Approved.",
      eval_id: "task-tags",
      cto_review: false,
      open_branch: "",
      path: "tickets/task-approved.md",
    },
  ]
  test.eq(runtime.cto_unreviewed_open_tickets(tickets), ["task-open"])?
}

proc test_handbook_candidate_gate_requires_ledger_disposition(ctx: TestContext) [fs, error] {
  let root = test.temp_dir(ctx, name: "handbook-gate")?
  fs.mkdir(fp"${root}/runtime")?
  fs.mkdir(fp"${root}/runs/run-1/lineage")?
  fs.write(
    fp"${root}/runtime/handbook.md",
    """approved
""",
  )?
  let candidate = fp"${root}/runs/run-1/lineage/handbook-candidate.md"
  fs.write(
    candidate,
    """candidate
""",
  )?
  test.eq(runtime.unresolved_handbook_candidates(root)?, 1)?
  let candidate_sha = hash.sha256(candidate)?.hex()
  fs.write(
    fp"${root}/runtime/handbook-ledger.md",
    f"""promoted ${candidate_sha}
""",
  )?
  test.eq(runtime.unresolved_handbook_candidates(root)?, 0)?
}

proc test_organization_phase_request_preserves_multiple_tickets() [fs, error] {
  let template = fs.read_text(fp"${fs.cwd()?}/templates/ORGANIZATION-PHASE-REQUEST.md")?
  let request = control.fill_template(
    template,
    [
  {
    key: "MODE",
    value: "ticket-implementation",
  },
  {
    key: "EVAL_ID",
    value: "task-envcfg",
  },
  {
    key: "TRIAL_COUNT",
    value: "1",
  },
  {
    key: "NEW_EVAL_COUNT",
    value: "0",
  },
  {
    key: "TICKET_ID",
    value: """`task-a`
- `task-b`""",
  },
  {
    key: "OBJECTIVE",
    value: "fixture",
  },
],
  )
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
  let ticket = """# Ticket

## Status

Approved.

## Change target

- `product`

## Proposed XSH change

Add a new builtin primitive.
"""
  test.ok(! control.ticket_api_surface_gate_ok(ticket))?
  test.ok(
    control.ticket_api_surface_gate_ok(
  ticket.replace(
  "## Proposed XSH change",
  """## API-surface justification

The existing operation is insufficient; semantic evidence is required.

## Proposed XSH change""",
),
),
  )?
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
  test.eq(
    control.eval_id_from_contract("""# Eval task-probe

## Status

Draft.
"""),
    "task-probe",
  )?
  test.eq(
    control.eval_id_from_contract("""# Proposal
"""),
    "",
  )?
  test.ok(! control.valid_eval_id("../escape"))?
  test.ok(control.valid_ticket_id("task-tags-001"))?
  test.ok(! control.valid_ticket_id("task/tags"))?
  test.ok(
    control.ticket_is_accepted("""# Ticket

## Status

Approved.

## Change target

- `product`
"""),
  )?
  test.eq(
    control.ticket_change_target("""# Ticket

## Change target

- `product`
"""),
    "product",
  )?
  test.eq(
    control.ticket_change_target("""# Ticket

## Change target

- `factory`
"""),
    "factory",
  )?
  test.ok(
    control.ticket_change_target("""# Ticket
""") != "product",
  )?
  test.ok(
    ! control.ticket_is_accepted("""# Ticket

## Status

Approved.
"""),
  )?
  test.ok(
    ! control.ticket_is_accepted("""# Ticket

## Status

Approved.

## Change target

- `factory`
"""),
  )?
  test.ok(
    control.eval_is_disabled("""# Eval

## Status

Disabled.
"""),
  )?
  test.ok(
    ! control.ticket_is_closed("""# Ticket

## Status

Approved.
"""),
  )?
  test.ok(
    control.report_contract_ok(
  """# Report

## Result

pass

## Evidence

ready
""",
  ["Evidence"],
  "pass",
),
  )?
  test.ok(
    ! control.report_contract_ok(
  """# Report

## Result

pass
""",
  ["Evidence"],
  "pass",
),
  )?
  test.ok(
    control.manager_tool_error_findings_contract_ok("""## Tool-error findings

report.json
"""),
  )?
  test.ok(
    control.manager_tool_error_findings_contract_ok("""## Tool-error findings

Four nonzero Pi tool results were accounted for.
"""),
  )?
  test.ok(
    ! control.manager_tool_error_findings_contract_ok("""## Tool-error findings

Fill every current tool error.
"""),
  )?
  let manager_report = """## Result

pass

## Effort metrics

fixture

## Usage and cost

fixture

## Thinking evidence

fixture

## Tool-error findings

Five nonzero Pi tool results were accounted for in `tool_errors`.

## Timing evidence

fixture

## Observation classification

fixture

## Handbook decision

unchanged

## Tickets created

None.

## Post-merge decisions

None.

## Next replay

None.

## North-star impact

fixture
"""
  test.ok(control.manager_report_gate_ok(manager_report, true, false))?
  test.eq(
    control.report_section(
  """# Report

## Result

pass

Details.

## Evidence

ready
""",
  "Result",
),
    """pass

Details.""",
  )?
  test.eq(
    control.report_field(
  """# Report

## Result

pass

Details.

## Evidence

ready
""",
  "Result",
),
    "pass",
  )?
}

proc test_control_text_contracts_cover_fallbacks_and_transitions() [error] {
  let ticket = """# Ticket

## Status

Approved.

## Change target

- product

## Source eval and manager

- Eval: `task-envcfg`

## Body

content
"""
  test.eq(control.ticket_status(ticket), "Approved.")?
  test.eq(control.ticket_change_target(ticket), "product")?
  test.eq(control.ticket_eval(ticket), "task-envcfg")?
  test.ok(control.ticket_is_accepted(ticket))?
  test.ok(! control.ticket_is_merged(ticket))?
  test.eq(
    control.ticket_status("""# Ticket

## Status

## Next
"""),
    "",
  )?
  test.eq(
    control.ticket_change_target("""## Change target

- factory
"""),
    "factory",
  )?
  test.eq(
    control.ticket_eval("""## Source eval and manager

- Eval: task-plain
"""),
    "task-plain",
  )?
  test.eq(control.role_prefix("unknown"), "")?
  test.eq(control.default_provider("unknown"), "")?
  test.eq(control.default_model("unknown"), "")?
  test.eq(control.default_tools("eval-worker"), "read,write,edit,bash")?
  test.eq(control.default_tools("unknown"), "")?
  test.eq(control.clamp_session_limit("engineer", "MAX_TURNS", "999")?, "220")?
  test.eq(control.clamp_session_limit("engineer", "MAX_TURNS", "20")?, "20")?
  test.eq(control.clamp_session_limit("unknown", "MAX_TURNS", "20")?, "20")?
  test.eq(control.clamp_budget("engineer", "2.0")?, "0.35")?
  test.eq(control.clamp_budget("engineer", "0.10")?, "0.10")?
  test.eq(control.clamp_budget("unknown", "2.0")?, "2.0")?
  test.eq(control.clamp_cycle_budget("0.25")?, "0.25")?
  test.ok(control.ecount_oracle_ok(true, "data"))?
  test.ok(! control.ecount_oracle_ok(false, "data"))?
  test.eq(control.ecount_classification(false, true, true, true, true, true), "worker_missing_artifact")?
  test.eq(control.ecount_classification(true, false, true, true, true, true), "protocol_failed")?
  test.eq(control.ecount_classification(true, true, false, true, true, true), "restriction_failed")?
  test.eq(control.ecount_classification(true, true, true, false, true, true), "evaluator_failed")?
  test.eq(control.ecount_classification(true, true, true, true, false, true), "candidate_failed")?
  test.eq(control.ecount_classification(true, true, true, true, true, false), "timing_failed")?
  test.eq(control.ecount_classification(true, true, true, true, true, true), "pass")?
  let replaced = control.replace_ticket_status(ticket, "Merged.")
  test.ok(control.ticket_is_merged(replaced))?
  test.contains(control.replace_section(ticket, "Body", "replacement"), "replacement")?
  test.contains(
    control.replace_section(
  """# Ticket
""",
  "Body",
  "appended",
),
    "appended",
  )?
  test.eq(control.factory_relative_path("/factory", /factory/runs/run-1/report.json), "runs/run-1/report.json")?
  test.eq(control.factory_relative_path("/factory/", /outside/report.json), "/outside/report.json")?
  test.ok(control.transition_allowed("validated", "ready-for-review"))?
  test.ok(control.transition_allowed("ready-for-review", "accepted"))?
  test.ok(control.transition_allowed("accepted", "reverted"))?
  test.ok(! control.transition_allowed("accepted", "failed"))?
  test.ok(control.retry_allowed("transient-harness", 1, 2))?
  test.ok(! control.retry_allowed("permanent", 1, 2))?
  test.ok(! control.retry_allowed("worker-failed", 2, 2))?
  test.contains(control.fill_template("Hello {{NAME}}", [{key: "NAME", value: "factory"}]), "Hello factory")?
}

proc test_control_build_identity_and_report_helpers() [env, error] {
  let ticket = """# Ticket

## Status

Open.
"""
  let args = control.eval_overlay_build_args(
    "xsh-base",
    "build-1",
    "factory:latest",
    "linux/amd64",
    /factory/Dockerfile,
    /factory,
    true,
  )
  test.eq(args[0], "build")?
  test.ok("--no-cache" in args)?
  let cached = control.eval_overlay_build_args(
    "xsh-base",
    "build-1",
    "factory:latest",
    "linux/amd64",
    /factory/Dockerfile,
    /factory,
  )
  test.ok("--no-cache" not in cached)?
  test.ok(control.toolchain_cache_valid(false, true, "key", "key", true))?
  test.ok(! control.toolchain_cache_valid(true, true, "key", "key", true))?
  test.ok(! control.toolchain_cache_valid(false, true, "old", "key", true))?
  test.ok(! control.toolchain_cache_valid(false, true, "key", "key", false))?
  test.ok(control.toolchain_image_platform_matches("linux/arm64\n", "linux/arm64"))?
  test.ok(! control.toolchain_image_platform_matches("linux/amd64", "linux/arm64"))?
  test.ok(
    control.factory_image_tag(
      "xsh",
      "control",
      "runtime",
      "schema",
      "worker",
      "base",
      "toolchain",
      "make",
      "linux",
      "amd64",
    ) != "",
  )?
  test.eq(control.ecount_oracle_command()[0], "sh")?
  env FACTORY_ENGINEER_PROVIDER="fixture" {
    test.eq(control.configured_role_setting("engineer", "PROVIDER")?, "fixture")?
  }
  env FACTORY_ENGINEER_MAX_TURNS="999" {
    test.eq(control.configured_role_setting("engineer", "MAX_TURNS")?, "220")?
  }
  test.eq(control.configured_role_setting("unknown", "MODEL")?, "")?
  test.eq(control.configured_role_setting("engineer", "UNKNOWN")?, "")?
  let report = """## Result

ready-for-review. Details

Branch: `factory/task-a`

## Merge record

branch
commit
run
"""
  test.eq(control.report_line_value(report, "Branch:"), "factory/task-a")?
  test.ok(control.report_result_is(report, "ready-for-review"))?
  test.contains(control.section_text(report, "Merge record"), "commit")?
  test.ok(control.ticket_merge_record_complete(report))?
  test.ok(
    ! control.ticket_merge_record_complete("""## Merge record

{{IMPLEMENTATION_BRANCH}}
"""),
  )?
  test.eq(control.replace_status(report, "ready-for-review"), report)?
  test.eq(
    control.replace_status(
  """# Empty
""",
  "Closed.",
),
    """# Empty
""",
  )?
  test.contains(control.replace_eval_status(ticket, "Approved."), "Approved.")?
  test.contains(
    control.replace_ticket_section(
  """# Ticket
""",
  "Status",
  """## Status

Open.""",
),
    "Open.",
  )?
  test.ok(
    ! control.report_contract_ok(
  """## Result

pass
{{pending}}""",
  [],
  "pass",
),
  )?
}

proc test_eval_proposal_is_promoted_without_acceptance(ctx: TestContext) [fs, error] {
  let factory = test.temp_dir(ctx, name: "eval-promotion")?
  let proposal = fp"${factory}/runs/run-1/proposals/proposal-1"
  fs.mkdir(fp"${proposal}/runtime")?
  fs.mkdir(fp"${factory}/evals")?
  fs.write(
    fp"${proposal}/EVAL.md",
    """# Eval task-probe

## Status

Draft.
""",
  )?
  for relative in ["executor.xsh", "evaluate.xsh", "evaluator.xsh", "runtime/task.md", "runtime/artifact.md"] {
    fs.write(
      fp"${proposal}/${relative}",
      f"""${relative}
""",
    )?
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
  fs.write(
    fp"${partial}/EVAL.md",
    """# Eval task-legacy

## Status

Draft.
""",
  )?
  for relative in ["executor.xsh", "evaluate.xsh", "runtime/task.md", "runtime/artifact.md"] {
    fs.write(
      fp"${partial}/${relative}",
      f"""${relative}
""",
    )?
  }

  test.ok(runtime.promote_eval_proposal(factory, partial, fp"${factory}/runs/run-2", "rejected")?)?
  let partial_contract = fs.read_text(fp"${factory}/evals/task-legacy/EVAL.md")?
  test.contains(partial_contract, "Package: `incomplete`")?
  test.contains(partial_contract, "evaluator.xsh")?

  let accepted = fp"${factory}/runs/run-3/proposals/proposal-1"
  fs.mkdir(fp"${accepted}/runtime")?
  fs.write(
    fp"${accepted}/EVAL.md",
    """# Eval task-accepted

## Status

Draft.
""",
  )?
  for relative in ["executor.xsh", "evaluate.xsh", "evaluator.xsh", "runtime/task.md", "runtime/artifact.md"] {
    fs.write(
      fp"${accepted}/${relative}",
      f"""${relative}
""",
    )?
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
  let request = fs.read_text(fp"${fs.cwd()?}/templates/ORGANIZATION-REQUEST.md")?
  let improvement = fs.read_text(fp"${fs.cwd()?}/templates/CTO-IMPROVEMENT.md")?
  let productivity = fs.read_text(fp"${fs.cwd()?}/templates/CTO-PRODUCTIVITY-REPORT.md")?
  let ledger = fs.read_text(fp"${fs.cwd()?}/runtime/handbook-ledger.md")?
  let launcher = fs.read_text(fp"${fs.cwd()?}/run.xsh")?
  let readme = fs.read_text(fp"${fs.cwd()?}/README.md")?
  let organization = fs.read_text(fp"${fs.cwd()?}/factory/controllers/organization.xsh")?
  let runtime_source = fs.read_text(fp"${fs.cwd()?}/factory/runtime.xsh")?
  let cto_runner = fs.read_text(fp"${fs.cwd()?}/factory/tools/cto.xsh")?
  test.contains(
    request,
    """## Active evals

- `task-bigfiles`""",
  )?
  test.contains(request, "Allow measured eval reuse")?
  test.contains(request, "- None.")?
  test.contains(fs.read_text(fp"${fs.cwd()?}/factory/tools/eval-trends.xsh")?, "median_turns")?
  test.contains(request, "## Bottleneck review")?
  test.ok("`task-tags`" not in request)?
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
  test.contains(cto, "Before declaring a user-requested cycle complete")?
  test.contains(cto, "cto: close <run-id>")?
  test.contains(cto, "regardless of")?
  test.contains(cto, "do not manufacture a")?
  test.contains(cto, "The CTO decides whether to merge or apply")?
  test.contains(cto, "Admission is an explicit CTO decision")?
  test.contains(cto, "Throughput invariant")?
  test.contains(cto, "Factory-efficiency gate")?
  test.contains(cto, "Assembly-line bottleneck gate")?
  test.contains(cto, "Eval-strength gate")?
  test.contains(cto, "CTO-PRODUCTIVITY-REPORT.md")?
  test.contains(improvement, "## Throughput requirement")?
  test.contains(productivity, "## Assembly-line bottleneck")?
  test.contains(request, "No `cycle-*.md` files are kept")?
  test.contains(request, "Admission invariant: approve eligible Open tickets before invoking `run.xsh`")?
  let cycle_template = fs.read_text(fp"${fs.cwd()?}/templates/cycle-request.md")?
  test.contains(cycle_template, "Require at least one engineer implementation commit")?
  test.contains(cycle_template, "Approve eligible Open tickets before controller invocation")?
  test.contains(cycle_template, "Never leave an")?
  test.contains(cycle_template, "eligible ticket Open")?
  test.ok("user authority" not in cto)?
  test.ok("user authority" not in factory)?
  test.ok("user approves" not in factory)?
  test.contains(launcher, "templates/CTO-IMPROVEMENT.md")?
  test.contains(readme, "one paid `run.xsh` invocation")?
  test.contains(launcher, "paths.real_within")?
  test.contains(launcher, "cycle request must be a template")?
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
  test.ok("admit at most one ticket" not in organization)?
  test.contains(runtime_source, "passing engineer report")?
  test.ok("git branch provenance" not in runtime_source)?
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
  json.write(
    worker,
    {
      schema_version: 1,
      kind: "worker",
      identity: {
        role: "engineer",
        worker_id: "fixture",
      },
      state: "completed",
      result: "pass",
      data: {
        usage: {
          assistant_turns: 1,
        },
      },
      findings: [],
      artifacts: [
        {
          kind: "session",
          path: "session.jsonl",
        },
      ],
    },
    pretty: true,
  )?
  let value = json.read(worker)?
  test.ok(schema.valid(value, "worker"))?
  test.ok(! schema.valid(value, "phase"))?
  test.eq(schema.value_text(json.get(value, ["result"], null)), "pass")?
}

proc test_report_schema_preserves_outcome_and_scalar_contracts() [error] {
  let identity = {run_id: "run-1"}
  let envelope = schema.envelope("worker", identity, "completed", "pass")
  test.ok(schema.valid(envelope, "worker"))?
  test.ok(! schema.valid(envelope, "phase"))?
  let outcome = schema.outcome(true, false, true)
  test.eq(json.get(outcome, ["product"], ""), "pass")?
  test.eq(json.get(outcome, ["evaluator"], ""), "fail")?
  test.eq(json.get(outcome, ["cycle"], ""), "fail")?
  test.eq(schema.value_text("text"), "text")?
  test.eq(schema.value_text(7), "7")?
  test.eq(schema.value_text(0.5), "0.500000")?
  test.eq(schema.value_text(true), "true")?
  test.eq(schema.value_text([]), "")?
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
  fs.write(
    fp"${factory}/tickets/task-tags-002.md",
    """# Ticket

## Status

Approved.
""",
  )?
  fs.write(
    fp"${factory}/evals/task-tags/EVAL.md",
    """# Eval

## Status

Approved.
""",
  )?
  let engineer_report = fp"${factory}/runs/run-1/workers/engineer/task-tags-002/report.json"
  let eval_report = fp"${factory}/runs/run-2/workers/eval-worker/task-tags-1/report.json"
  fs.mkdir(engineer_report.parent())?
  fs.mkdir(eval_report.parent())?
  json.write(
    engineer_report,
    {
      schema_version: 1,
      kind: "worker",
      identity: {
        role: "engineer",
        worker_id: "task-tags-002",
      },
      state: "completed",
      result: "fail",
      findings: [],
      artifacts: [],
    },
    pretty: true,
  )?
  json.write(
    eval_report,
    {
      schema_version: 1,
      kind: "worker",
      identity: {
        role: "eval-worker",
        worker_id: "task-tags-1",
      },
      state: "completed",
      result: "fail",
      findings: [],
      artifacts: [],
    },
    pretty: true,
  )?
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
  let assignment = """- Ticket ID: `task-tags-001`
- Dedicated XSH worktree: `/tmp/work`
<!-- CONTROLLER_TICKET_SNAPSHOT_BEGIN -->
ticket
<!-- CONTROLLER_TICKET_SNAPSHOT_END -->
Do not search for open tickets
"""
  test.ok(
    control.engineer_assignment_ok(
      "/factory/runs/run-1",
      "task-tags-001",
      "/factory/runs/run-1/messages/task-tags-001.md",
      "/tmp/work",
      assignment,
    ),
  )?
  test.ok(
    ! control.engineer_assignment_ok(
      "/factory/runs/run-1",
      "task-tags-002",
      "/factory/runs/run-1/messages/task-tags-002.md",
      "/tmp/work",
      assignment,
    ),
  )?
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
  test.contains(controller, "valid_staged_binary")?
  test.contains(controller, "implausibly small")?
  test.ok(control.eval_binary_size_ok(1024))?
  test.ok(! control.eval_binary_size_ok(17))?
  test.contains(executor, "--pids-limit")?
  test.contains(executor, "--memory")?
  test.contains(executor, "size=64m")?
}
