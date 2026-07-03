#!/bin/bash
# Checks: the operator is Running and it reconciled the tenants into child Deployments
# (orion-media, lyra-media). Proves the control loop turned spec into real resources.
OP=$(kubectl get pods -n platform -l app=tenant-operator \
  -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
if [ "$OP" != "Running" ]; then
  echo "tenant-operator Pod isn't Running (got '$OP'). The cluster may still be coming up — wait and retry." >&2
  exit 1
fi
for d in orion-media lyra-media; do
  if ! kubectl get deployment "$d" -n media >/dev/null 2>&1; then
    echo "Child Deployment '$d' not found — the operator hasn't reconciled it yet. Wait a few seconds and retry." >&2
    exit 1
  fi
done
echo "✓ tenant-operator is Running and created child Deployments orion-media and lyra-media"
exit 0
