##! Canonical run-scoped cleanup tool helpers.
use factory.cleanup as cleanup

## Exposes the shared durable-evidence boundary to operators and tests.
export pure can_remove(run_root: Path, candidate: Path, name: Str) -> Result[Bool] {
  return cleanup.removable(run_root, candidate, name)
}
