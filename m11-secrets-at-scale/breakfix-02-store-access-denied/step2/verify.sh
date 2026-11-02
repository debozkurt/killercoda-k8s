#!/bin/bash
# Checks: the operator SA can read secrets in secrets-source but NOT cluster-wide, both
# syncs are Synced, and both consumers are Ready.
SA=system:serviceaccount:secrets-system:secret-operator
if [ "$(kubectl auth can-i get secrets -n secrets-source --as=$SA 2>/dev/null)" != "yes" ]; then
  echo "secret-operator still cannot read secrets in secrets-source. Fix the RoleBinding subject:" >&2
  echo "  kubectl patch rolebinding secret-operator-store -n secrets-source --type=json -p '[{\"op\":\"replace\",\"path\":\"/subjects/0/name\",\"value\":\"secret-operator\"}]'" >&2
  exit 1
fi
if [ "$(kubectl auth can-i get secrets -n kube-system --as=$SA 2>/dev/null)" = "yes" ]; then
  echo "secret-operator can read secrets in kube-system. The fix granted too much. Remove the wide binding and grant only in secrets-source:" >&2
  echo "  kubectl get clusterrolebindings -o wide | grep secret-operator" >&2
  exit 1
fi
DB=$(kubectl get secretsync db-credentials -n provisioning -o jsonpath='{.status.reason}' 2>/dev/null)
PA=$(kubectl get secretsync partner-api -n media -o jsonpath='{.status.reason}' 2>/dev/null)
BR=$(kubectl get deployment billing-processor -n provisioning -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
PR=$(kubectl get deployment partner-connector -n media -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "$DB" != "Synced" ] || [ "$PA" != "Synced" ] || [ "$BR" != "1" ] || [ "$PR" != "1" ]; then
  echo "Access works, but the pipeline has not recovered (syncs: '$DB'/'$PA', ready: '$BR'/'$PR'). The operator runs every 10 seconds and the kubelet retries on a backoff. Wait 30 seconds, then run:" >&2
  echo "  kubectl get secretsync -A" >&2
  exit 1
fi
kubectl get secretsync -A
echo "✓ The operator reads the store again, both syncs are Synced, and both consumers are Ready"
exit 0
