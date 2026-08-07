##! Behavior-level coverage for the Markdown cycle request boundary.
use factory.request as request
use factory.types as types

proc test_request_and_scalar_accessors_preserve_operator_intent() [error] {
  let text = """# Cycle

## Mode

- `organization`

## Active evals

- `task-ecount`

## Trial plan

- Count: `2`

## New eval proposals

- Count: 1

## Approved tickets

- `task-a`

## Allow measured eval reuse

- Allow measured eval reuse: `yes`

## Aggregate budget

- USD: `0.75`
"""
  test.eq(request.parse_ticket_ids(text)?[0].value, "task-a")?
  test.eq(request.parse_eval_ids(text)?[0].value, "task-ecount")?
  test.eq(request.mode_value(text)?, "organization")?
  let parsed = request.parse(text)?
  test.eq(types.mode_name(parsed.mode), "organization")?
  test.eq(parsed.tickets[0].value, "task-a")?
  test.eq(parsed.active_evals[0].value, "task-ecount")?
  test.eq(parsed.trial_count.value, 2)?
  test.eq(parsed.design_count, 1)?
  test.ok(parsed.allow_measured_reuse)?
  let facts = request.facts(text)?
  test.eq(facts.mode, "organization")?
  test.eq(request.mode_value(text)?, "organization")?
  test.eq(request.ticket_values(text)?[0], "task-a")?
  test.eq(request.ticket_policy_value(text)?, "explicit")?
  test.eq(request.eval_values(text)?[0], "task-ecount")?
  test.eq(request.trial_value(text)?, 2)?
  test.eq(request.design_value(text)?, 1)?
  test.ok(request.measured_reuse_value(text)?)?
  test.eq(request.parse_aggregate_budget(text)?, 0.75)?

  let paired_discovery = text.replace("- `task-ecount`", "- `task-ecount`\n- `task-envcfg`")
  test.eq(request.eval_values(paired_discovery)?, ["task-ecount", "task-envcfg"])?

  let no_tickets = """# Cycle

## Mode

- `eval`

## Approved tickets

- None.
"""
  test.eq(request.ticket_policy_value(no_tickets)?, "none")?
  test.eq(request.parse_trial_count(no_tickets)?.value, 1)?
  match request.parse("# Cycle\n\n## Approved tickets\n\n- None.\n") {
    Ok(_) => test.fail("a request without a mode was accepted")?
    Err(_) => {}
  }
}
