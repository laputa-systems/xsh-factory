##! Canonical domain vocabulary for the factory control plane.
##! These records are intentionally nominal: a ticket identifier, a digest, and
##! a path are not interchangeable merely because they are represented by text.

## Structured construction and boundary errors.
export error DomainError = InvalidFormat(kind: Str, value: Str) : InvalidData | NotContained(path: Str, root: Str) : InvalidData | InvalidCombination(message: Str) : InvalidData | InvalidTransition(subject: Str, current: Str, next: Str) : InvalidData | Duplicate(value: Str) : InvalidData | Missing(value: Str) : InvalidData

## Repository root owned by the factory.
export type FactoryRoot = {root_path: Path, canonical: Str}
## Product checkout root, always outside the factory root.
export type ProductRoot = {root_path: Path, canonical: Str}
## A validated run directory and its stable identity.
export type RunRoot = {root_path: Path, run_id: Str}
## A validated phase directory within a run.
export type PhaseRoot = {root_path: Path, run_id: Str, phase_id: Str}
## A validated worker directory within a phase.
export type WorkerRoot = {root_path: Path, run_id: Str, phase_id: Str, worker_id: Str}
## An isolated product worktree with its provenance base.
export type ProductWorktree = {worktree_path: Path, branch: Str, base_commit: Str}
## A path proven to be inside the factory root.
export type FactoryPath = {value: Path, root: Any}
## A path proven to be inside one run.
export type RunPath = {value: Path, root: Any}
## A path proven to be inside one phase.
export type PhasePath = {value: Path, root: Any}
## A path proven to be inside one worker directory.
export type WorkerPath = {value: Path, root: Any}

## Immutable ticket identity.
export type TicketId = {value: Str}
## Immutable eval identity.
export type EvalId = {value: Str}
## Immutable worker identity component.
export type WorkerId = {value: Str}
## Immutable run identity component.
export type RunId = {value: Str}
## Immutable phase identity component.
export type PhaseId = {value: Str}
## Immutable graph node identity.
export type NodeId = {value: Str}
## Immutable dispatch claim identity.
export type DispatchId = {value: Str}
## Hash of the rendered assignment.
export type AssignmentHash = {value: Str}
## Hash of the system prompt.
export type PromptHash = {value: Str}
## Generic content hash used only where a narrower hash is unavailable.
export type ContentHash = {value: Str}
## Hash of checked-in ticket content.
export type TicketHash = {value: Str}
## Hash of approved handbook content.
export type HandbookHash = {value: Str}
## Hash of the evaluator source.
export type EvaluatorHash = {value: Str}
## Hash of a portable patch.
export type PatchHash = {value: Str}
## Hash of the canonical session archive.
export type SessionHash = {value: Str}
## Hash of the evaluator image identity.
export type ImageHash = {value: Str}
## Hash of a Git commit.
export type CommitHash = {value: Str}

## Controller-owned Pi roles.
export type Role = {value: Str}

## Controller-owned cycle modes.
export type CycleMode = {value: Str}

## Repository ownership for a ticket.
export type ChangeTarget = {value: Str}
## Checked-in ticket lifecycle.
export type TicketStatus = {value: Str}
## Checked-in eval lifecycle.
export type EvalStatus = {value: Str}
## Shared lifecycle state.
export type LifecycleState = {value: Str}

## Dependency relationship between graph nodes.
export type EdgeKind = {value: Str}
## Consequence of a predecessor failure.
export type FailurePolicy = {value: Str}
## Validated node outcome.
export type NodeResult = {value: Str}
## Observed cost is explicit; unknown is not zero.
export type CostState = {kind: Str, amount: Float}

## Per-role and aggregate budget with observed cost state.
export type Budget = {
  role_limit: Float,
  aggregate_limit: Float,
  observed: Any,
}

## Bounded trial count.
export type TrialCount = {value: Int}
## Ownership record for a descendant process or container.
export type ProcessOwner = {
  run_id: Str,
  node_id: Str,
  controller_pid: Int,
  pid: Int,
  container_id: Str,
  start_marker: Str,
  claim_token: Str,
}

## Full worker identity bound into reports and dispatch claims.
export type WorkerIdentity = {
  run_id: RunId,
  phase_id: PhaseId,
  role: Role,
  worker_id: WorkerId,
  dispatch_id: DispatchId,
}

## Checks the identifier alphabet and traversal boundary.
export pure valid_identifier(value: Str) -> Bool {
  return value != "" and ! value.contains("/") and ! value.contains("\\") and
    ! value.contains("..") and ! value.contains(" ") and ! value.contains("\n")
}

## Checks whether a persisted SHA-256 identity has its complete textual form.
export pure valid_hash_text(value: Str) -> Bool {
  return value.byte_len() == 64 and ! value.contains(" ") and ! value.contains("\n")
}

## Constructs a validated ticket identifier.
export pure make_ticket_id(value: Str) -> Result[TicketId] {
  if ! valid_identifier(value) { return Err(DomainError.InvalidFormat(kind: "ticket-id", value: value)) }
  return Ok({value: value})
}

## Constructs a validated eval identifier.
export pure make_eval_id(value: Str) -> Result[EvalId] {
  if ! valid_identifier(value) { return Err(DomainError.InvalidFormat(kind: "eval-id", value: value)) }
  return Ok({value: value})
}

## Constructs a validated worker identifier.
export pure make_worker_id(value: Str) -> Result[WorkerId] {
  if ! valid_identifier(value) { return Err(DomainError.InvalidFormat(kind: "worker-id", value: value)) }
  return Ok({value: value})
}

## Constructs a validated run identifier.
export pure make_run_id(value: Str) -> Result[RunId] {
  if ! valid_identifier(value) or ! value.starts_with("run-") {
    return Err(DomainError.InvalidFormat(kind: "run-id", value: value))
  }
  return Ok({value: value})
}

## Constructs a validated phase identifier.
export pure make_phase_id(value: Str) -> Result[PhaseId] {
  if ! valid_identifier(value) { return Err(DomainError.InvalidFormat(kind: "phase-id", value: value)) }
  return Ok({value: value})
}

## Constructs a validated graph node identifier.
export pure make_node_id(value: Str) -> Result[NodeId] {
  if ! valid_identifier(value) { return Err(DomainError.InvalidFormat(kind: "node-id", value: value)) }
  return Ok({value: value})
}

## Constructs a validated dispatch identifier.
export pure make_dispatch_id(value: Str) -> Result[DispatchId] {
  if ! valid_identifier(value) { return Err(DomainError.InvalidFormat(kind: "dispatch-id", value: value)) }
  return Ok({value: value})
}

## Constructs a content hash with a caller-supplied label.
export pure make_content_hash(kind: Str, value: Str) -> Result[ContentHash] {
  if ! valid_hash_text(value) { return Err(DomainError.InvalidFormat(kind: kind, value: value)) }
  return Ok({value: value})
}

## Constructs a validated assignment hash.
export pure make_assignment_hash(value: Str) -> Result[AssignmentHash] {
  if ! valid_hash_text(value) { return Err(DomainError.InvalidFormat(kind: "assignment-hash", value: value)) }
  return Ok({value: value})
}

## Constructs a validated prompt hash.
export pure make_prompt_hash(value: Str) -> Result[PromptHash] {
  if ! valid_hash_text(value) { return Err(DomainError.InvalidFormat(kind: "prompt-hash", value: value)) }
  return Ok({value: value})
}

## Constructs a validated commit hash.
export pure make_commit_hash(value: Str) -> Result[CommitHash] {
  if ! valid_hash_text(value) { return Err(DomainError.InvalidFormat(kind: "commit-hash", value: value)) }
  return Ok({value: value})
}

## Constructs a trial count within the paid-cycle bound.
export pure make_trial_count(value: Int) -> Result[TrialCount] {
  if value < 1 or value > 2 { return Err(DomainError.InvalidFormat(kind: "trial-count", value: f"${value}")) }
  return Ok({value: value})
}

## Constructs a budget whose role limit fits inside the aggregate limit.
export pure make_budget(role_limit: Float, aggregate_limit: Float) -> Result[Budget] {
  if role_limit < 0.0 or aggregate_limit <= 0.0 or role_limit > aggregate_limit {
    return Err(DomainError.InvalidCombination(message: "role and aggregate budget limits are inconsistent"))
  }
  return Ok({role_limit: role_limit, aggregate_limit: aggregate_limit, observed: {kind: "unknown", amount: 0.0}})
}

## Returns the stable external spelling of a role.
export pure role_name(role: Role) -> Str {
  return role.value
}

## Constructs a controller-owned role.
export pure make_role(value: Str) -> Result[Role] {
  if value == "CTO" or value == "director" or value == "eval-designer" or
    value == "eval-manager" or value == "eval-worker" or value == "engineer" {
    return Ok({value: value})
  }
  return Err(DomainError.InvalidFormat(kind: "role", value: value))
}

## Parses a role only from the controller's role vocabulary.
export pure parse_role(value: Str) -> Result[Role] {
  return make_role(value)
}

## Returns the stable external spelling of a cycle mode.
export pure mode_name(mode: CycleMode) -> Str {
  return mode.value
}

## Constructs a controller-owned cycle mode.
export pure make_mode(value: Str) -> Result[CycleMode] {
  if value == "eval" or value == "ticket-implementation" or value == "eval-design" or
    value == "organization" or value == "ticket-reuse" {
    return Ok({value: value})
  }
  return Err(DomainError.InvalidFormat(kind: "cycle-mode", value: value))
}

## Parses a cycle mode only from the controller's vocabulary.
export pure parse_mode(value: Str) -> Result[CycleMode] {
  return make_mode(value)
}

## Returns the stable external spelling of a change target.
export pure change_target_name(target: ChangeTarget) -> Str {
  return target.value
}

## Constructs a repository ownership target.
export pure make_change_target(value: Str) -> Result[ChangeTarget] {
  if value == "product" or value == "factory" { return Ok({value: value}) }
  return Err(DomainError.InvalidFormat(kind: "change-target", value: value))
}

## Parses a repository ownership target.
export pure parse_change_target(value: Str) -> Result[ChangeTarget] {
  return make_change_target(value)
}

## Returns the checked-in ticket status spelling.
export pure ticket_status_name(status: TicketStatus) -> Str {
  return status.value
}

## Constructs a checked-in ticket status.
export pure make_ticket_status(value: Str) -> Result[TicketStatus] {
  if value == "Open." or value == "Approved." or value == "Accepted." or
    value == "Merged." or value == "Closed." or value == "too difficult" {
    return Ok({value: value})
  }
  return Err(DomainError.InvalidFormat(kind: "ticket-status", value: value))
}

## Parses a checked-in ticket status.
export pure parse_ticket_status(value: Str) -> Result[TicketStatus] {
  return make_ticket_status(value)
}

## Returns the checked-in eval status spelling.
export pure eval_status_name(status: EvalStatus) -> Str {
  return status.value
}

## Constructs a checked-in eval status.
export pure make_eval_status(value: Str) -> Result[EvalStatus] {
  if value == "Draft." or value == "Approved." or value == "Disabled." { return Ok({value: value}) }
  return Err(DomainError.InvalidFormat(kind: "eval-status", value: value))
}

## Parses a checked-in eval status.
export pure parse_eval_status(value: Str) -> Result[EvalStatus] {
  return make_eval_status(value)
}

## Returns the stable external spelling of a lifecycle state.
export pure lifecycle_name(state: LifecycleState) -> Str {
  return state.value
}
