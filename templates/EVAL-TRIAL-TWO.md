## Trial 1

Use the approved shared-handbook snapshot:

```sh
FACTORY_EVAL_ID={{EVAL_ID}} FACTORY_TRIAL_ID=1 FACTORY_EVAL_WORKER_DIR="$FACTORY_RUN_DIR/workers/eval-worker/{{EVAL_ID}}-1" FACTORY_HANDBOOK_FILE="$FACTORY_RUN_DIR/lineage/handbook-approved.md" xsh "{{EVAL_DIR}}/executor.xsh"
```

Inspect the executor report, worker report, thinking transcript, evaluator
manifest, artifact, review, and quantitative session results. If a handbook
change is justified, write it to `$FACTORY_RUN_DIR/lineage/handbook-candidate.md`;
otherwise copy the approved snapshot there unchanged. Do not edit the approved
snapshot or the checked-in `runtime/handbook.md`.

## Trial 2

Run a fresh worker with the shared-handbook candidate:

```sh
FACTORY_EVAL_ID={{EVAL_ID}} FACTORY_TRIAL_ID=2 FACTORY_EVAL_WORKER_DIR="$FACTORY_RUN_DIR/workers/eval-worker/{{EVAL_ID}}-2" FACTORY_HANDBOOK_FILE="$FACTORY_RUN_DIR/lineage/handbook-candidate.md" xsh "{{EVAL_DIR}}/executor.xsh"
```
