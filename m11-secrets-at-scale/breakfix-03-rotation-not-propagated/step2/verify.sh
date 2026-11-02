#!/bin/bash
# Checks: the running billing-processor holds the store's current db-password, so the
# consumer was rolled and read the rotated Secret. Asserts the outcome, not the method.
STORE=$(kubectl get secret vault-backend -n secrets-source -o jsonpath='{.data.db-password}' 2>/dev/null | base64 -d)
LIVE=$(kubectl exec deploy/billing-processor -n provisioning -- printenv DB_PASSWORD 2>/dev/null)
if [ -z "$LIVE" ]; then
  echo "No running billing-processor container answered. It may be mid-rollout. Wait, then run:" >&2
  echo "  kubectl rollout status deployment/billing-processor -n provisioning" >&2
  exit 1
fi
if [ "$LIVE" != "$STORE" ]; then
  echo "The process holds '$LIVE', and the store holds '$STORE'. The Secret is correct. Roll the consumer:" >&2
  echo "  kubectl rollout restart deployment/billing-processor -n provisioning" >&2
  exit 1
fi
kubectl get pods -n provisioning -l app=billing-processor
echo "✓ billing-processor holds the rotated value ($STORE)"
exit 0
