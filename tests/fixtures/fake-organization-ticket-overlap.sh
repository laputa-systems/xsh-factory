#!/bin/sh
set -eu
printf 'start:%s\n' "$FACTORY_PHASE_DIR" >> "$FACTORY_TEST_LOG"
case "$FACTORY_PHASE_DIR" in
  */01-ticket)
    worktree="$FACTORY_PHASE_DIR/worktrees/task-overlap"
    mkdir -p "$FACTORY_PHASE_DIR/patches"
    git -C "$FACTORY_XSH_REPO" worktree add -b factory/fake-ticket "$worktree" "$FACTORY_XSH_COMMIT" >/dev/null
    printf 'changed\n' > "$worktree/README"
    git -C "$worktree" add README
    git -C "$worktree" commit -m change >/dev/null
    printf 'patch\n' > "$FACTORY_PHASE_DIR/patches/task-overlap.diff"
    ;;
esac
sleep 1
printf 'end:%s\n' "$FACTORY_PHASE_DIR" >> "$FACTORY_TEST_LOG"
cp "$FACTORY_TEST_REPORT" "$FACTORY_PHASE_DIR/RUN.md"
