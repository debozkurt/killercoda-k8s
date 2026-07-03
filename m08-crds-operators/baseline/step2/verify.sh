#!/bin/bash
# Checks: both MediaTenant custom resources exist and the operator has written their
# .status to Ready (the observed half the controller owns). Defensive baseline check.
for t in orion lyra; do
  if ! kubectl get mediatenant "$t" -n media >/dev/null 2>&1; then
    echo "MediaTenant '$t' not found in namespace media. The cluster may still be coming up — wait and retry." >&2
    exit 1
  fi
done
PHASE=$(kubectl get mediatenant orion -n media -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$PHASE" != "Ready" ]; then
  echo "MediaTenant orion .status.phase is '$PHASE', not Ready — the operator may still be reconciling. Wait a few seconds and retry." >&2
  exit 1
fi
echo "✓ MediaTenants orion and lyra exist; orion .status.phase=Ready (operator-written)"
exit 0
