#!/bin/bash
# Checks: cdr-rollup is no longer suspended, and at least one rollup Job now exists
# (scheduled or the manual recovery Job).
SUSPEND=$(kubectl get cronjob cdr-rollup -n cdr-storage -o jsonpath='{.spec.suspend}' 2>/dev/null)
if [ "$SUSPEND" = "true" ]; then
  echo "cdr-rollup is still suspended — it will create nothing. Un-suspend it:" >&2
  echo "  kubectl patch cronjob cdr-rollup -n cdr-storage -p '{\"spec\":{\"suspend\":false}}'" >&2
  exit 1
fi

JOBS=$(kubectl get jobs -n cdr-storage -l app=cdr-rollup --no-headers 2>/dev/null | wc -l)
[ "$JOBS" -ge 1 ] || { echo "No cdr-rollup Jobs yet. Trigger one to confirm the template, or wait for the next minute boundary: kubectl create job --from=cronjob/cdr-rollup cdr-rollup-recover -n cdr-storage" >&2; exit 1; }

echo "✓ CronJob un-suspended (suspend=${SUSPEND:-false}); $JOBS rollup Job(s) present — firing again"
exit 0
