#!/bin/bash
# Checks: schema-migrate Job exists and owns its Pod (Job→Pod chain intact),
# and the cdr-rollup CronJob exists (CronJob→Job→Pod chain root present).
OWNER=$(kubectl get pod -n provisioning -l app=schema-migrate -o jsonpath='{.items[0].metadata.ownerReferences[0].kind}' 2>/dev/null)
[ "$OWNER" = "Job" ] || { echo "schema-migrate Pod owner is '$OWNER', expected 'Job' (owner chain not intact)" >&2; exit 1; }

kubectl get cronjob cdr-rollup -n cdr-storage >/dev/null 2>&1 || { echo "cdr-rollup CronJob not found in cdr-storage" >&2; exit 1; }

echo "✓ Batch owner chains intact: Job/schema-migrate → Pod, and CronJob/cdr-rollup present"
exit 0
