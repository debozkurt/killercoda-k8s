#!/bin/bash
# Checks: the operator materialized the db-credentials Secret with the DB_PASSWORD key,
# carrying the managed-by=secret-operator label, and its value matches the store.
MB=$(kubectl get secret db-credentials -n provisioning -o jsonpath='{.metadata.labels.managed-by}' 2>/dev/null)
if [ "$MB" != "secret-operator" ]; then
  echo "The db-credentials Secret isn't present with the managed-by=secret-operator label yet (got '$MB'). Wait for the operator to reconcile and retry." >&2
  exit 1
fi
STORE=$(kubectl get secret vault-backend -n secrets-source -o jsonpath='{.data.db-password}' 2>/dev/null | base64 -d)
SYNC=$(kubectl get secret db-credentials -n provisioning -o jsonpath='{.data.DB_PASSWORD}' 2>/dev/null | base64 -d)
if [ -z "$SYNC" ] || [ "$STORE" != "$SYNC" ]; then
  echo "The materialized DB_PASSWORD doesn't match the store's db-password. The operator may be mid-reconcile — wait a few seconds and retry." >&2
  exit 1
fi
echo "✓ db-credentials materialized with DB_PASSWORD, labeled managed-by=secret-operator, value matches the store"
exit 0
