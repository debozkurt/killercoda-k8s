#!/bin/bash
# Checks: reconciliation resumed once the operator got create permission — the child
# Deployments now exist and at least one tenant reached Ready. Asserts the outcome,
# not the exact fix used.
CANI=$(kubectl auth can-i create deployments -n media \
  --as=system:serviceaccount:platform:tenant-operator 2>/dev/null)
if [ "$CANI" != "yes" ]; then
  echo "The tenant-operator ServiceAccount still can't create Deployments. Add create/update/patch/delete on deployments to the tenant-operator ClusterRole and re-apply it." >&2
  exit 1
fi
if ! kubectl get deployment orion-media -n media >/dev/null 2>&1; then
  echo "Permission looks granted, but orion-media isn't created yet — the operator retries every ~10s. Wait a few seconds and retry." >&2
  exit 1
fi
PHASE=$(kubectl get mediatenant orion -n media -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$PHASE" != "Ready" ]; then
  echo "orion-media exists but orion .status.phase is '$PHASE' — the operator is mid-reconcile. Wait a few seconds and retry." >&2
  exit 1
fi
echo "✓ Operator can create Deployments again; orion-media reconciled and orion is Ready — the stall was RBAC, not the operator process"
exit 0
