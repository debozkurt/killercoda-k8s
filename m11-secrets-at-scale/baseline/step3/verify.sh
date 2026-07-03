#!/bin/bash
# Checks: the operator is Running and the db-credentials SecretSync status reads
# reason=Synced — the controller reconciled the object, not just started.
POD=$(kubectl get pods -n secrets-system -l app=secret-operator -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
if [ "$POD" != "Running" ]; then
  echo "The secret-operator Pod isn't Running yet (got '$POD'). Wait for the cluster to finish coming up and retry." >&2
  exit 1
fi
REASON=$(kubectl get secretsync db-credentials -n provisioning -o jsonpath='{.status.reason}' 2>/dev/null)
if [ "$REASON" != "Synced" ]; then
  echo "db-credentials .status.reason is '$REASON', not 'Synced'. The operator may be mid-reconcile — wait a few seconds and retry." >&2
  exit 1
fi
echo "✓ Operator Running and db-credentials reports reason=Synced — reconciliation is healthy"
exit 0
