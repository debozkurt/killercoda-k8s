#!/bin/bash
# Checks: the derived db-credentials Secret holds the store's value again after the
# hand edit, which proves the operator reconciles it back to the source.
STORE=$(kubectl get secret vault-backend -n secrets-source -o jsonpath='{.data.db-password}' 2>/dev/null | base64 -d)
SYNC=$(kubectl get secret db-credentials -n provisioning -o jsonpath='{.data.DB_PASSWORD}' 2>/dev/null | base64 -d)
if [ -z "$SYNC" ] || [ "$SYNC" != "$STORE" ]; then
  echo "db-credentials holds '$SYNC', not the store value. The operator reverts it within 10 seconds. Wait, then read it again:" >&2
  echo "  kubectl get secret db-credentials -n provisioning -o jsonpath='{.data.DB_PASSWORD}' | base64 -d; echo" >&2
  exit 1
fi
kubectl get secretsync db-credentials -n provisioning
echo "✓ db-credentials matches the store again: the operator reverted the hand edit"
exit 0
