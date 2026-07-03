#!/bin/bash
# Checks: Kyverno is installed and the three policies are present. Proves the engine
# is up and reading policy objects (the admission webhooks depend on this).
ADM=$(kubectl get deploy kyverno-admission-controller -n kyverno -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ -z "$ADM" ] || [ "$ADM" -lt 1 ] 2>/dev/null; then
  echo "kyverno-admission-controller isn't Available yet — the Kyverno image pull can take a couple of minutes on first boot. Wait and retry." >&2
  exit 1
fi
POLS=$(kubectl get clusterpolicy -o name 2>/dev/null)
for p in require-resource-limits add-owner-label disallow-latest-tag; do
  echo "$POLS" | grep -q "$p" || { echo "ClusterPolicy '$p' not found yet — policies may still be applying. Wait and retry." >&2; exit 1; }
done
echo "✓ Kyverno is running and all three ClusterPolicies are present"
exit 0
