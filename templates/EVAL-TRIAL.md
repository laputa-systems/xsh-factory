## Trial 1

Use the approved shared-handbook snapshot:

```sh
FACTORY_EVAL_ID={{EVAL_ID}} FACTORY_TRIAL_ID=1 FACTORY_EVAL_WORKER_DIR="$FACTORY_RUN_DIR/workers/eval-worker/{{EVAL_ID}}-1" FACTORY_HANDBOOK_FILE="$FACTORY_RUN_DIR/lineage/handbook-approved.md" xsh "{{EVAL_DIR}}/executor.xsh"
```

Inspect the executor report, worker report, thinking transcript, evaluator
manifest, artifact, review, and quantitative session results. A one-trial
cycle must copy the approved snapshot unchanged to
`$FACTORY_RUN_DIR/lineage/handbook-candidate.md`. A two-trial cycle may write
a provisional candidate there after trial 1; otherwise copy the approved
snapshot unchanged. Never edit the approved snapshot or the checked-in
`runtime/handbook.md`.

## Trial 2

Run this only when the configured trial count is `2`, using the candidate
snapshot:

```sh
FACTORY_EVAL_ID={{EVAL_ID}} FACTORY_TRIAL_ID=2 FACTORY_EVAL_WORKER_DIR="$FACTORY_RUN_DIR/workers/eval-worker/{{EVAL_ID}}-2" FACTORY_HANDBOOK_FILE="$FACTORY_RUN_DIR/lineage/handbook-candidate.md" xsh "{{EVAL_DIR}}/executor.xsh"
```
