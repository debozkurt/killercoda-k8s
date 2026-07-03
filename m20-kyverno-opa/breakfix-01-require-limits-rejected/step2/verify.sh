#!/bin/bash
# Checks: billing-api now rolls out — its Pod passes require-resource-limits because the
# workload declares limits. Asserts the outcome (a Ready Pod), not a specific fix command.
AVAIL=$(kubectl get deploy billing-api -n tenant-apps -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ "${AVAIL:-0}" -ge 1 ] 2>/dev/null; then
  LIM=$(kubectl get deploy billing-api -n tenant-apps \
    -o jsonpath='{.spec.template.spec.containers[0].resources.limits}' 2>/dev/null)
  if [ -n "$LIM" ]; then
    echo "✓ billing-api is Available with resource limits set — it now passes require-resource-limits"
    exit 0
  fi
fi
echo "billing-api isn't Available yet. Add resources.limits.{cpu,memory} to the container, then wait for the rollout and retry." >&2
exit 1
