##! Run-scoped process and container ownership.
use factory.types as types

## A registry row binds a process to one graph node and one claim token.
export type ProcessClaim = {
  owner: types.ProcessOwner,
  state: Str,
}

## Writes one ownership record before a child is allowed to run.
export proc register(run_dir: Path, owner: types.ProcessOwner) [fs, error] -> Result[Unit] {
  if owner.run_id == "" or owner.node_id == "" or owner.pid <= 0 or owner.claim_token == "" {
    return Err(types.DomainError.InvalidCombination(message: "process owner is incomplete"))
  }

  let registry = fp"${run_dir}/processes"
  fs.mkdir(registry)?
  let record_path = fp"${registry}/${owner.node_id}.json"
  if fs.exists(record_path)? {
    return Err(types.DomainError.Duplicate(value: owner.node_id))
  }

  json.write(
    record_path,
    {
      run_id: owner.run_id,
      node_id: owner.node_id,
      controller_pid: owner.controller_pid,
      pid: owner.pid,
      container_id: owner.container_id,
      start_marker: owner.start_marker,
      claim_token: owner.claim_token,
      state: "owned",
    },
    pretty: true,
  )?
}

## Records a terminal observation without changing the ownership identity.
export proc mark(run_dir: Path, node_id: types.NodeId, state: Str) [fs, error] -> Result[Unit] {
  let record_path = fp"${run_dir}/processes/${node_id.value}.json"
  if ! fs.exists(record_path)? {
    return Err(types.DomainError.Missing(value: f"process:${node_id.value}"))
  }

  let value = json.read(record_path)?
  json.write(
    record_path,
    {
      run_id: json.get(value, ["run_id"], ""),
      node_id: json.get(value, ["node_id"], ""),
      controller_pid: json.get(value, ["controller_pid"], 0),
      pid: json.get(value, ["pid"], 0),
      container_id: json.get(value, ["container_id"], ""),
      start_marker: json.get(value, ["start_marker"], ""),
      claim_token: json.get(value, ["claim_token"], ""),
      state: state,
    },
    pretty: true,
  )?
}

## Cancels only descendants whose ownership records belong to this run.
export proc cancel_owned(run_dir: Path, signal: Str, excluded_pid: Int) [fs, process, error] -> Result[Unit] {
  let registry = fp"${run_dir}/processes"
  if ! fs.exists(registry)? {
    return
  }

  for entry in fs.walk(registry, gitignore: false, hidden: true)? |> where .kind == "file" {
    continue unless entry.name.ends_with(".json")
    let value = json.read(entry.path)?
    let pid = match json.get(value, ["pid"], 0) { i is Int => i, _ => 0 }
    if pid > 0 and pid != excluded_pid {
      match unix.kill_process_group(pid, signal) {
        Ok(_) => {}
        Err(_) => let _ = process.kill(pid, signal)
      }
    }
  }
}
