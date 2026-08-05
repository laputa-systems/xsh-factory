##! Canonical repository, run, phase, worker, and worktree boundaries.

use factory.types as types

## Canonicalizes an absolute path and rejects traversal syntax.
export pure canonical_absolute(path_value: Path) -> Result[Path] {
  let value = path_value.display()
  if value == "" or ! value.starts_with("/") {
    return Err(types.DomainError.InvalidFormat(kind: "absolute-path", value: value))
  }
  if value.contains("/../") or value.ends_with("/..") or value.contains("/./") or value.ends_with("/.") {
    return Err(types.DomainError.InvalidFormat(kind: "normalized-path", value: value))
  }
  var normalized = value
  while normalized.contains("//") {
    normalized = normalized.replace("//", "/")
  }
  if normalized.byte_len() > 1 and normalized.ends_with("/") {
    normalized = normalized.byte_slice(0, normalized.byte_len() - 1)
  }
  return Ok(Path(normalized))
}

## Proves lexical containment with a separator-aware boundary.
export pure within(root: Path, candidate: Path) -> Result[Bool] {
  let canonical_root = canonical_absolute(root)?
  let canonical_candidate = canonical_absolute(candidate)?
  let root_text = canonical_root.display()
  let candidate_text = canonical_candidate.display()
  if root_text == "/" { return Ok(candidate_text.starts_with("/")) }
  return Ok(candidate_text == root_text or candidate_text.starts_with(root_text + "/"))
}

## Resolves symlinks before applying the same separator-aware boundary.
export proc real_within(root: Path, candidate: Path) [fs, error] -> Result[Bool] {
  let resolved_root = root.resolve()?
  let resolved_candidate = candidate.resolve()?
  return within(resolved_root, resolved_candidate)
}

## Constructs the factory repository root.
export pure make_factory_root(path_value: Path) -> Result[types.FactoryRoot] {
  let canonical = canonical_absolute(path_value)?
  return Ok({root_path: canonical, canonical: canonical.display()})
}

## Constructs a product root outside the factory checkout.
export pure make_product_root(path_value: Path, factory: types.FactoryRoot) -> Result[types.ProductRoot] {
  let canonical = canonical_absolute(path_value)?
  if canonical.display() == factory.canonical or (within(factory.root_path, canonical)?) {
    return Err(types.DomainError.InvalidCombination(message: "product root must not be inside the factory root"))
  }
  return Ok({root_path: canonical, canonical: canonical.display()})
}

## Constructs a path proven to belong to the factory checkout.
export pure make_factory_path(root: types.FactoryRoot, path_value: Path) -> Result[types.FactoryPath] {
  let canonical = canonical_absolute(path_value)?
  if ! within(root.root_path, canonical)? {
    return Err(types.DomainError.NotContained(path: canonical.display(), root: root.canonical))
  }
  return Ok({value: canonical, root: root})
}

## Constructs a product worktree and rejects factory paths.
export pure make_product_worktree(
  product: types.ProductRoot,
  factory: types.FactoryRoot,
  worktree_value: Path,
  branch: Str,
  base_commit: Str,
) -> Result[types.ProductWorktree] {
  let canonical = canonical_absolute(worktree_value)?
  if ! within(product.root_path, canonical)? or within(factory.root_path, canonical)? {
    return Err(types.DomainError.NotContained(path: canonical.display(), root: product.canonical))
  }
  if ! types.valid_identifier(branch) or base_commit == "" {
    return Err(types.DomainError.InvalidCombination(message: "worktree requires a safe branch and base commit"))
  }
  return Ok({worktree_path: canonical, branch: branch, base_commit: base_commit})
}

## Constructs a run root below the factory runs directory.
export pure make_run_root(factory: types.FactoryRoot, path_value: Path) -> Result[types.RunRoot] {
  let canonical = canonical_absolute(path_value)?
  let runs = fp"${factory.canonical}/runs"
  let run_name = canonical.name()
  if ! within(runs, canonical)? or ! run_name.starts_with("run-") {
    return Err(types.DomainError.NotContained(path: canonical.display(), root: runs.display()))
  }
  let run_id = types.make_run_id(run_name)?
  return Ok({root_path: canonical, run_id: run_id.value})
}

## Constructs a phase root below a run root.
export pure make_phase_root(run_root: types.RunRoot, phase_id: Str, path_value: Path) -> Result[types.PhaseRoot] {
  let canonical = canonical_absolute(path_value)?
  let phase = types.make_phase_id(phase_id)?
  let run_path = run_root.root_path
  let run_text = run_path.display()
  if ! within(run_path, canonical)? {
    return Err(types.DomainError.NotContained(path: canonical.display(), root: run_text))
  }
  return Ok({root_path: canonical, run_id: run_root.run_id, phase_id: phase.value})
}

## Constructs a worker root below a phase root.
export pure make_worker_root(phase: types.PhaseRoot, worker_id: Str, path_value: Path) -> Result[types.WorkerRoot] {
  let canonical = canonical_absolute(path_value)?
  let worker = types.make_worker_id(worker_id)?
  let phase_path = phase.root_path
  let phase_text = phase_path.display()
  if ! within(phase_path, canonical)? {
    return Err(types.DomainError.NotContained(path: canonical.display(), root: phase_text))
  }
  return Ok({root_path: canonical, run_id: phase.run_id, phase_id: phase.phase_id, worker_id: worker.value})
}

## Constructs a run-scoped evidence path.
export pure make_run_path(root: types.RunRoot, path_value: Path) -> Result[types.RunPath] {
  let canonical = canonical_absolute(path_value)?
  if ! within(root.root_path, canonical)? {
    let root_text = root.root_path.display()
    return Err(types.DomainError.NotContained(path: canonical.display(), root: root_text))
  }
  return Ok({value: canonical, root: root})
}

## Constructs a phase-scoped evidence path.
export pure make_phase_path(root: types.PhaseRoot, path_value: Path) -> Result[types.PhasePath] {
  let canonical = canonical_absolute(path_value)?
  if ! within(root.root_path, canonical)? {
    let root_text = root.root_path.display()
    return Err(types.DomainError.NotContained(path: canonical.display(), root: root_text))
  }
  return Ok({value: canonical, root: root})
}

## Constructs a worker-scoped evidence path.
export pure make_worker_path(root: types.WorkerRoot, path_value: Path) -> Result[types.WorkerPath] {
  let canonical = canonical_absolute(path_value)?
  if ! within(root.root_path, canonical)? {
    let root_text = root.root_path.display()
    return Err(types.DomainError.NotContained(path: canonical.display(), root: root_text))
  }
  return Ok({value: canonical, root: root})
}
