#!/bin/bash
# Checks: the value the running consumer holds now matches the (rotated) store value —
# the consumer was rolled and re-read the Secret. Asserts the outcome, not the method.
STORE=$(kubectl get secret vault-backend -n secrets-source -o jsonpath='{.data.db-password}' 2>/dev/null | base64 -d)
LIVE=$(kubectl exec deploy/billing-processor -n provisioning -- printenv DB_PASSWORD 2>/dev/null)
if [ -z "$LIVE" ]; then
  echo "Couldn't read DB_PASSWORD from a running billing-processor Pod — it may be mid-rollout. Wait a few seconds and retry." >&2
  exit 1
fi
if [ "$LIVE" != "$STORE" ]; then
  echo "The running container still holds '$LIVE', but the store's current value is '$STORE'. The Secret is already correct — roll the consumer so it re-reads it: kubectl rollout restart deployment/billing-processor -n provisioning" >&2
  exit 1
fi
echo "✓ billing-processor now holds the rotated value ($STORE) — the rotation reached the process after the rollout"
exit 0
