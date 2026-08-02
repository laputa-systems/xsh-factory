## Trial 1

Use the approved shared-handbook snapshot:

```sh
FACTORY_EVAL_ID={{EVAL_ID}} FACTORY_TRIAL_ID=1 FACTORY_EVAL_WORKER_DIR="$FACTORY_RUN_DIR/workers/eval-worker/{{EVAL_ID}}-1" FACTORY_HANDBOOK_FILE="$FACTORY_RUN_DIR/lineage/handbook-approved.md" xsh "{{EVAL_DIR}}/executor.xsh"
```

Inspect the executor report, worker report, thinking transcript, evaluator
manifest, artifact, review, and quantitative session results. Copy the
approved snapshot unchanged to `$FACTORY_RUN_DIR/lineage/handbook-candidate.md`;
a one-trial cycle does not trust a new handbook change. Do not edit the
approved snapshot or the checked-in `runtime/handbook.md`.
