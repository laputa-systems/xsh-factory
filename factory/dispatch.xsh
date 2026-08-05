##! Pure dispatch identity, manifest, and claim validation.

use factory.types as types
use factory.paths as paths
use factory.graph as graph

## The immutable facts a runner must receive from a controller.
export type DispatchSpec = {
  run_id: types.RunId,
  phase_id: types.PhaseId,
  node_id: types.NodeId,
  dispatch_id: types.DispatchId,
  role: types.Role,
  worker_id: types.WorkerId,
  mode: types.CycleMode,
  ticket_id: Str,
  eval_id: Str,
  change_target: Str,
  system_prompt_path: Path,
  system_prompt_sha256: Str,
  message_path: Path,
  message_sha256: Str,
  workdir: Path,
  factory_root: Path,
  product_root: Path,
  handbook_path: Path,
  handbook_sha256: Str,
  north_star_path: Path,
  north_star_sha256: Str,
  source_commit: Str,
  image_id: Str,
  budget: types.Budget,
  max_turns: Int,
  max_wall_seconds: Int,
  parent_controller: Str,
  state: Str,
  claim_token: Str,
}

## A run-wide planned dispatch set and its controller authority.
export type DispatchPlan = {
  run_id: types.RunId,
  controller_identity: Str,
  controller_token: Str,
  specs: List[DispatchSpec],
}

## One immutable claim recorded by the runner.
export type ClaimRecord = {
  dispatch_id: types.DispatchId,
  claim_token: Str,
  claimed_by: Str,
  state: Str,
}

## Exact invocation values supplied by the host runner.
export type Invocation = {
  run_id: types.RunId,
  phase_id: types.PhaseId,
  node_id: types.NodeId,
  dispatch_id: types.DispatchId,
  role: types.Role,
  worker_id: types.WorkerId,
  mode: types.CycleMode,
  ticket_id: Str,
  eval_id: Str,
  change_target: Str,
  system_prompt_path: Path,
  system_prompt_sha256: Str,
  message_path: Path,
  message_sha256: Str,
  workdir: Path,
  parent_controller: Str,
}

pure spec_for(specs: List[DispatchSpec], dispatch_id: Str) -> DispatchSpec {
  for spec in specs {
    if spec.dispatch_id.value == dispatch_id { return spec }
  }
  return missing_spec()
}

pure missing_spec() -> DispatchSpec {
  return {
    run_id: {value: ""}, phase_id: {value: ""}, node_id: {value: ""}, dispatch_id: {value: ""},
    role: {value: ""}, worker_id: {value: ""}, mode: {value: ""}, ticket_id: "", eval_id: "", change_target: "",
    system_prompt_path: Path("/"), system_prompt_sha256: "", message_path: Path("/"), message_sha256: "",
    workdir: Path("/"), factory_root: Path("/"), product_root: Path("/"), handbook_path: Path("/"), handbook_sha256: "",
    north_star_path: Path("/"), north_star_sha256: "", source_commit: "", image_id: "",
    budget: {role_limit: 0.0, aggregate_limit: 0.0, observed: {kind: "unknown", amount: 0.0}},
    max_turns: 0, max_wall_seconds: 0, parent_controller: "", state: "missing", claim_token: "",
  }
}

## Serializes the complete immutable dispatch identity for durable evidence.
export pure manifest_value(spec: DispatchSpec) -> Any {
  return {
    schema_version: 2,
    state: spec.state,
    run_id: spec.run_id.value,
    phase_id: spec.phase_id.value,
    node_id: spec.node_id.value,
    dispatch_id: spec.dispatch_id.value,
    role: spec.role.value,
    worker_id: spec.worker_id.value,
    mode: spec.mode.value,
    ticket_id: spec.ticket_id,
    eval_id: spec.eval_id,
    change_target: spec.change_target,
    system_prompt_file: spec.system_prompt_path.display(),
    system_prompt_sha256: spec.system_prompt_sha256,
    message_file: spec.message_path.display(),
    message_sha256: spec.message_sha256,
    workdir: spec.workdir.display(),
    factory_root: spec.factory_root.display(),
    product_root: spec.product_root.display(),
    handbook_file: spec.handbook_path.display(),
    handbook_sha256: spec.handbook_sha256,
    north_star_file: spec.north_star_path.display(),
    north_star_sha256: spec.north_star_sha256,
    source_commit: spec.source_commit,
    image_id: spec.image_id,
    budget: spec.budget.role_limit,
    aggregate_budget: spec.budget.aggregate_limit,
    max_turns: spec.max_turns,
    max_wall_seconds: spec.max_wall_seconds,
    parent_controller: spec.parent_controller,
    claim_token: spec.claim_token,
  }
}

## Persists one planned manifest atomically before a child starts.
export proc persist_spec(run_dir: Path, spec: DispatchSpec) [fs, error] -> Result[Unit] {
  validate_spec(spec)?
  fs.mkdir(fp"${run_dir}/dispatch")?
  let target = fp"${run_dir}/dispatch/${spec.dispatch_id.value}.json"
  if fs.exists(target)? { return Err(types.DomainError.Duplicate(value: spec.dispatch_id.value)) }
  fs.write_atomic(target, json.encode(manifest_value(spec))? + "\n")?
  return Ok()
}

## Persists the complete dispatch set and controller authority before launch.
export proc persist_plan(run_dir: Path, plan: DispatchPlan) [fs, error] -> Result[Unit] {
  validate_plan(plan)?
  fs.mkdir(fp"${run_dir}/dispatch")?
  for spec in plan.specs { persist_spec(run_dir, spec)? }
  let plan_value = {schema_version: 2, state: "planned", run_id: plan.run_id.value, controller_identity: plan.controller_identity, controller_token: plan.controller_token, dispatch_ids: [spec.dispatch_id.value for spec in plan.specs]}
  fs.write_atomic(fp"${run_dir}/dispatch/PLAN.json", json.encode(plan_value)? + "\n")?
  return Ok()
}

## Creates a separate claim record; the immutable manifest is never rewritten.
export proc claim_once(run_dir: Path, spec: DispatchSpec, claimed_by: Str) [fs, error] -> Result[ClaimRecord] {
  let locks = fp"${run_dir}/locks"
  fs.mkdir(locks)?
  let _lock = fs.lock(fp"${locks}/${spec.dispatch_id.value}.lock", nonblocking: true)?
  let claim_path = fp"${run_dir}/dispatch/${spec.dispatch_id.value}.claim.json"
  if fs.exists(claim_path)? { return Err(types.DomainError.Duplicate(value: spec.dispatch_id.value)) }
  let claim = claim(spec, spec.claim_token, claimed_by, "planned")?
  fs.write_atomic(claim_path, json.encode({dispatch_id: claim.dispatch_id.value, claim_token: claim.claim_token, claimed_by: claim.claimed_by, state: claim.state})? + "\n")?
  return Ok(claim)
}

## Claims a persisted manifest without reconstructing a weaker ad hoc identity.
## This is the effectful bridge used by the stable host-agent entrypoint.
export proc claim_persisted_once(run_dir: Path, dispatch_id: Str, claim_token: Str, claimed_by: Str) [fs, error] -> Result[Unit] {
  let id = types.make_dispatch_id(dispatch_id)?
  if claim_token == "" or claimed_by == "" {
    return Err(types.DomainError.InvalidCombination(message: "persisted dispatch claim is incomplete"))
  }
  let manifest_path = fp"${run_dir}/dispatch/${id.value}.json"
  if ! fs.exists(manifest_path)? { return Err(types.DomainError.Missing(value: f"dispatch:${id.value}")) }
  let manifest = json.read(manifest_path)?
  let state = match json.get(manifest, ["state"], "") { value is Str => value, _ => "" }
  let manifest_id = match json.get(manifest, ["dispatch_id"], "") { value is Str => value, _ => "" }
  let manifest_token = match json.get(manifest, ["claim_token"], "") { value is Str => value, _ => "" }
  if state != "planned" or manifest_id != id.value or manifest_token != claim_token {
    return Err(types.DomainError.InvalidCombination(message: "persisted dispatch identity is not claimable"))
  }
  fs.mkdir(fp"${run_dir}/locks")?
  let _lock = fs.lock(fp"${run_dir}/locks/${id.value}.lock", nonblocking: true)?
  let claim_path = fp"${run_dir}/dispatch/${id.value}.claim.json"
  if fs.exists(claim_path)? { return Err(types.DomainError.Duplicate(value: id.value)) }
  fs.write_atomic(claim_path, json.encode({schema_version: 2, dispatch_id: id.value, claim_token: claim_token, claimed_by: claimed_by, state: "claimed"})? + "\n")?
  return Ok()
}

pure duplicate_dispatch_id(specs: List[DispatchSpec]) -> Str {
  var seen: List[Str] = []
  for spec in specs {
    for previous in seen {
      if previous == spec.dispatch_id.value { return previous }
    }
    seen = seen.push(spec.dispatch_id.value)
  }
  return ""
}

## Validates a manifest before it is persisted as a planned dispatch.
export pure validate_spec(spec: DispatchSpec) -> Result[Unit] {
  if spec.state != "planned" { return Err(types.DomainError.InvalidCombination(message: "dispatch is not in planned state")) }
  if spec.claim_token == "" or spec.parent_controller == "" or spec.source_commit == "" {
    return Err(types.DomainError.InvalidCombination(message: "dispatch is missing controller authority"))
  }
  if ! types.valid_hash_text(spec.system_prompt_sha256) or
    ! types.valid_hash_text(spec.message_sha256) or
    ! types.valid_hash_text(spec.handbook_sha256) or
    ! types.valid_hash_text(spec.north_star_sha256) {
    return Err(types.DomainError.InvalidCombination(message: "dispatch is missing content identity"))
  }
  if spec.max_turns <= 0 or spec.max_wall_seconds <= 0 or spec.budget.aggregate_limit <= 0.0 {
    return Err(types.DomainError.InvalidCombination(message: "dispatch is missing a bounded budget"))
  }
  if spec.role.value == "engineer" and spec.change_target != "product" {
    return Err(types.DomainError.InvalidCombination(message: "factory change cannot enter engineer dispatch"))
  }
  if ! paths.within(spec.factory_root, spec.system_prompt_path)? or
    ! paths.within(spec.factory_root, spec.message_path)? or
    ! paths.within(spec.factory_root, spec.handbook_path)? or
    ! paths.within(spec.factory_root, spec.north_star_path)? {
    return Err(types.DomainError.NotContained(path: spec.message_path.display(), root: spec.factory_root.display()))
  }
  if spec.role.value == "engineer" and ! paths.within(spec.product_root, spec.workdir)? {
    return Err(types.DomainError.NotContained(path: spec.workdir.display(), root: spec.product_root.display()))
  }
  return Ok()
}

## Validates the exact planned dispatch set for one run.
export pure validate_plan(plan: DispatchPlan) -> Result[Unit] {
  if plan.controller_identity == "" or plan.controller_token == "" or plan.specs.len() == 0 {
    return Err(types.DomainError.InvalidCombination(message: "dispatch plan has no controller authority or specs"))
  }
  let duplicate = duplicate_dispatch_id(plan.specs)
  if duplicate != "" { return Err(types.DomainError.Duplicate(value: f"dispatch:${duplicate}")) }
  for spec in plan.specs {
    if spec.run_id.value != plan.run_id.value { return Err(types.DomainError.InvalidCombination(message: "dispatch crosses run boundary")) }
    validate_spec(spec)?
  }
  return Ok()
}

## Proves that the invocation is exactly the controller-planned identity.
export pure invocation_authorized(plan: DispatchPlan, invocation: Invocation) -> Bool {
  let spec = spec_for(plan.specs, invocation.dispatch_id.value)
  if spec.dispatch_id.value == "" or spec.state != "planned" { return false }
  return spec.run_id.value == invocation.run_id.value and
    spec.phase_id.value == invocation.phase_id.value and
    spec.node_id.value == invocation.node_id.value and
    spec.dispatch_id.value == invocation.dispatch_id.value and
    spec.role.value == invocation.role.value and
    spec.worker_id.value == invocation.worker_id.value and
    spec.mode.value == invocation.mode.value and
    spec.ticket_id == invocation.ticket_id and spec.eval_id == invocation.eval_id and
    spec.change_target == invocation.change_target and
    spec.system_prompt_path.display() == invocation.system_prompt_path.display() and
    spec.system_prompt_sha256 == invocation.system_prompt_sha256 and
    spec.message_path.display() == invocation.message_path.display() and
    spec.message_sha256 == invocation.message_sha256 and
    spec.workdir.display() == invocation.workdir.display() and
    spec.parent_controller == invocation.parent_controller
}

## Claims a planned dispatch exactly once.
export pure claim(spec: DispatchSpec, claim_token: Str, claimed_by: Str, prior_state: Str) -> Result[ClaimRecord] {
  if spec.state != "planned" or prior_state != "planned" {
    return Err(types.DomainError.InvalidCombination(message: "dispatch was already claimed or is not planned"))
  }
  if claim_token == "" or claim_token != spec.claim_token or claimed_by == "" {
    return Err(types.DomainError.InvalidCombination(message: "dispatch claim token is invalid"))
  }
  return Ok({dispatch_id: spec.dispatch_id, claim_token: claim_token, claimed_by: claimed_by, state: "claimed"})
}
