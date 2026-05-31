#!/bin/bash
# Checks: cdr-rollup CronJob is not suspended and has produced at least one Job.
SUSPEND=$(kubectl get cronjob cdr-rollup -n cdr-storage -o jsonpath='{.spec.suspend}' 2>/dev/null)
case "$SUSPEND" in
  ""|false) : ;;
  *) echo "cdr-rollup suspend=$SUSPEND — a suspended CronJob fires nothing" >&2; exit 1 ;;
esac

JOBS=$(kubectl get jobs -n cdr-storage -l app=cdr-rollup --no-headers 2>/dev/null | wc -l)
[ "$JOBS" -ge 1 ] || { echo "cdr-rollup has created $JOBS Jobs; wait for the next minute boundary, or trigger one with: kubectl create job --from=cronjob/cdr-rollup cdr-rollup-manual -n cdr-storage" >&2; exit 1; }

echo "✓ CronJob healthy: cdr-rollup not suspended, $JOBS scheduled Job(s) created"
exit 0
