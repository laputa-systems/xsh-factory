#!/bin/sh
set -eu

session=
export_file=
next=
for arg in "$@"; do
  if [ "$next" = session ]; then
    session=$arg
    next=
    continue
  fi
  if [ "$next" = export ]; then
    export_file=$arg
    next=
    continue
  fi
  case "$arg" in
    --session)
      next=session
      ;;
    --export)
      next=export
      ;;
  esac
done

if [ -n "$export_file" ]; then
  printf '%s\n' '<html>fixture</html>' > "$export_file"
  exit 0
fi

printf '%s\n' '{"timestamp":"2026-08-01T12:00:00.000Z","type":"message","message":{"role":"assistant","content":[],"usage":{"input":1,"output":1,"reasoning":1,"totalTokens":2,"cost":{"total":0.30}}}}' > "$session"
exec sleep 10
