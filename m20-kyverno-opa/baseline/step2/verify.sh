#!/bin/bash
# Checks both sides of validation: the compliant workload was admitted (tenant-web up),
# AND a non-compliant Pod is rejected by the Enforce policy (server dry-run, nothing persisted).
AVAIL=$(kubectl get deploy tenant-web -n tenant-apps -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ -z "$AVAIL" ] || [ "$AVAIL" -lt 1 ] 2>/dev/null; then
  echo "tenant-web isn't Available yet — the fleet or Kyverno may still be settling. Wait and retry." >&2
  exit 1
fi
OUT=$(kubectl run bad-verify --image=nginx:1.25 -n tenant-apps --restart=Never --dry-run=server 2>&1)
if echo "$OUT" | grep -qi "denied the request\|require-resource-limits\|validation error"; then
  echo "✓ compliant tenant-web admitted; a no-limits Pod is denied by require-resource-limits"
  exit 0
fi
echo "The no-limits Pod was not denied — Kyverno's webhook may not be registered yet (policy READY?). Wait a few seconds and retry." >&2
exit 1
