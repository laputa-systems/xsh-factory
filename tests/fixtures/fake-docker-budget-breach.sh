#!/bin/sh
set -eu

session_src=
work_src=
is_eval=false
for arg in "$@"; do
  case "$arg" in
    type=bind,src=*,dst=/session)
      session_src=${arg#type=bind,src=}
      session_src=${session_src%,dst=/session}
      ;;
    type=bind,src=*,dst=/work)
      work_src=${arg#type=bind,src=}
      work_src=${work_src%,dst=/work}
      ;;
    /run/evaluate.xsh)
      is_eval=true
      ;;
  esac
done

if [ "$is_eval" = true ]; then
  printf '%s\n' '{"eval_id":"task-tags","trial_id":"1","result":"pass"}' > "$session_src/run.json"
  printf '%s\n' artifact > "$work_src/artifact.txt"
  printf '%s\n' review > "$work_src/review.md"
  exit 0
fi

printf '%s\n' '{"timestamp":"2026-08-01T12:00:00.000Z","type":"message","message":{"role":"assistant","content":[],"usage":{"input":1,"output":1,"reasoning":1,"totalTokens":2,"cost":{"total":0.60}}}}' > "$session_src/session.jsonl"
exec sleep 10
