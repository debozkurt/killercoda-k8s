#!/bin/bash
# Checks: the operator's ServiceAccount can read the store again, both SecretSyncs are
# Synced, and both consumers recovered. Asserts the outcome, not the exact fix used.
CANI=$(kubectl auth can-i get secrets -n secrets-source \
  --as=system:serviceaccount:secrets-system:secret-operator 2>/dev/null)
if [ "$CANI" != "yes" ]; then
  echo "The secret-operator ServiceAccount still can't read secrets in secrets-source. Fix the secret-operator-store RoleBinding subject to name 'secret-operator' and re-apply." >&2
  exit 1
fi
DB=$(kubectl get secretsync db-credentials -n provisioning -o jsonpath='{.status.reason}' 2>/dev/null)
PA=$(kubectl get secretsync partner-api -n media -o jsonpath='{.status.reason}' 2>/dev/null)
if [ "$DB" != "Synced" ] || [ "$PA" != "Synced" ]; then
  echo "Access is restored but the syncs aren't both Synced yet (db-credentials='$DB', partner-api='$PA'). The operator reconciles every ~10s — wait and retry." >&2
  exit 1
fi
BR=$(kubectl get deployment billing-processor -n provisioning -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
PR=$(kubectl get deployment partner-connector -n media -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "$BR" != "1" ] || [ "$PR" != "1" ]; then
  echo "Secrets are materialized but a consumer isn't Ready yet (billing='$BR', partner='$PR'). The kubelet retries CreateContainerConfigError on a backoff — wait ~30s and retry." >&2
  exit 1
fi
echo "✓ Operator can read the store again; both syncs Synced and both consumers recovered — one binding, whole pipeline back"
exit 0
