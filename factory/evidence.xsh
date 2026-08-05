##! Typed evidence references and identity/hash validation.

use factory.types as types
use factory.paths as paths

## One run-scoped machine evidence reference.
export type EvidenceRef = {
  run_id: Str,
  node_id: Str,
  kind: Str,
  path: Path,
  sha256: Str,
  required: Bool,
  state: Str,
}

## All references required to validate one node.
export type EvidenceSet = {
  refs: List[EvidenceRef],
  required_kinds: List[Str],
}

## A report/manifest/session identity expected by the audit.
export type ExpectedIdentity = {
  run_id: Str,
  node_id: Str,
  role: Str,
  worker_id: Str,
  dispatch_id: Str,
}

## Constructs one typed evidence reference under a run root.
export pure make_ref(
  run_id: Str,
  node_id: Str,
  kind: Str,
  run_root: Path,
  value_path: Path,
  sha256: Str,
  required: Bool,
  state: Str,
) -> Result[EvidenceRef] {
  if run_id == "" or node_id == "" or kind == "" or ! types.valid_hash_text(sha256) {
    return Err(types.DomainError.InvalidCombination(message: "evidence reference is incomplete"))
  }
  if ! paths.within(run_root, value_path)? {
    return Err(types.DomainError.NotContained(path: value_path.display(), root: run_root.display()))
  }
  if state != "present" and state != "missing" and state != "invalid" {
    return Err(types.DomainError.InvalidFormat(kind: "evidence-state", value: state))
  }
  return Ok({run_id: run_id, node_id: node_id, kind: kind, path: value_path, sha256: sha256, required: required, state: state})
}

## Validates a reference against one run and node identity.
export pure validate_ref(ref: EvidenceRef, run_id: Str, node_id: Str, run_root: Path) -> Result[Unit] {
  if ref.run_id != run_id or ref.node_id != node_id {
    return Err(types.DomainError.InvalidCombination(message: "evidence identity does not match its node"))
  }
  if ! paths.within(run_root, ref.path)? {
    return Err(types.DomainError.NotContained(path: ref.path.display(), root: run_root.display()))
  }
  if ref.required and ref.state != "present" {
    return Err(types.DomainError.Missing(value: f"${ref.kind}:${ref.path.display()}"))
  }
  return Ok()
}

pure duplicate_kind(refs: List[EvidenceRef]) -> Str {
  var seen: List[Str] = []
  for ref in refs {
    let key = f"${ref.node_id}:${ref.kind}"
    for prior in seen {
      if prior == key { return key }
    }
    seen = seen.push(key)
  }
  return ""
}

## Validates references and required evidence kinds without directory guessing.
export pure validate_set(evidence_set: EvidenceSet, run_id: Str, node_id: Str, run_root: Path) -> Result[Unit] {
  let duplicate = duplicate_kind(evidence_set.refs)
  if duplicate != "" { return Err(types.DomainError.Duplicate(value: f"evidence:${duplicate}")) }
  for ref in evidence_set.refs { validate_ref(ref, run_id, node_id, run_root)? }
  for kind in evidence_set.required_kinds {
    var found = false
    for ref in evidence_set.refs {
      if ref.kind == kind and ref.state == "present" { found = true }
    }
    if ! found { return Err(types.DomainError.Missing(value: f"evidence-kind:${kind}")) }
  }
  return Ok()
}

## Proves that a machine report is bound to its planned worker identity.
export pure report_identity_ok(report: Any, expected: ExpectedIdentity) -> Bool {
  let identity = json.get(report, ["identity"], null)
  return json.get(identity, ["run_id"], "") == expected.run_id and
    json.get(identity, ["node_id"], "") == expected.node_id and
    json.get(identity, ["role"], "") == expected.role and
    json.get(identity, ["worker_id"], "") == expected.worker_id and
    json.get(identity, ["dispatch_id"], "") == expected.dispatch_id
}

## Verifies content hash for a persisted evidence file.
export proc verify_file(ref: EvidenceRef) [fs, error] -> Result[Bool] {
  if ! fs.exists(ref.path)? { return Ok(false) }
  return Ok(hash.sha256(ref.path)?.hex() == ref.sha256)
}
