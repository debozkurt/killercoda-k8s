#!/bin/bash
# Checks two things: the durable guardrail (activeDeadlineSeconds) is now on the
# cdr-rollup jobTemplate, and the originally-stuck run has been cleared so the
# schedule can move again.

ADS=$(kubectl get cronjob cdr-rollup -n cdr-storage -o jsonpath='{.spec.jobTemplate.spec.activeDeadlineSeconds}' 2>/dev/null)
if [ -z "$ADS" ]; then
  echo "No activeDeadlineSeconds on the cdr-rollup jobTemplate — a future hang can still wedge the whole schedule under Forbid. Add the guardrail (a CronJob is patchable):" >&2
  echo "  kubectl patch cronjob cdr-rollup -n cdr-storage --type merge -p '{\"spec\":{\"jobTemplate\":{\"spec\":{\"activeDeadlineSeconds\":30}}}}'" >&2
  exit 1
fi

if kubectl get job cdr-rollup-29014200 -n cdr-storage >/dev/null 2>&1; then
  echo "The stuck run (cdr-rollup-29014200) is still Active and holding the one slot Forbid allows — the schedule stays frozen until you clear it:" >&2
  echo "  kubectl delete job cdr-rollup-29014200 -n cdr-storage" >&2
  exit 1
fi

echo "✓ Guardrail in place (activeDeadlineSeconds=${ADS}s) and the stuck run cleared — cdr-rollup can fire on schedule again, and a future hang will fail fast instead of freezing it"
exit 0
