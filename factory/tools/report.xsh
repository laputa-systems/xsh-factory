##! Controller-owned report construction for run and phase boundaries.

use factory.schema as schema

## Writes the common envelope and keeps boundary-specific facts under `data`.
export proc write(
  output: Path,
  kind: Str,
  identity: Any,
  state: Str,
  result: Str,
  data: Any,
  findings: List[Any],
  artifacts: List[Any],
) [fs, error] -> Result[Unit] {
  json.write(output, {
    schema_version: schema.SCHEMA_VERSION,
    kind: kind,
    identity: identity,
    state: state,
    result: result,
    data: data,
    findings: findings,
    artifacts: artifacts,
  }, pretty: true)?
  return Ok()
}

## Reads a report result without making Markdown parsing part of orchestration.
export proc result(report_path: Path) [fs, error] -> Result[Str] {
  if ! fs.exists(report_path)? { return "missing" }
  let value = json.read(report_path)?
  return schema.value_text(json.get(value, ["result"], "unknown"))
}

## Validates a report's common envelope and boundary kind.
export proc valid_report(report_path: Path, kind: Str) [fs, error] -> Result[Bool] {
  if ! fs.exists(report_path)? { return false }
  return schema.valid(json.read(report_path)?, kind)
}
