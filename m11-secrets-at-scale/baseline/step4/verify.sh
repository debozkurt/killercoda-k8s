#!/bin/bash
# Checks: the consumer is Ready and the DB_PASSWORD it actually holds in its
# environment matches the store's db-password — the full chain resolved end to end.
READY=$(kubectl get deployment billing-processor -n provisioning -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "$READY" != "1" ]; then
  echo "billing-processor isn't Ready yet (readyReplicas='$READY'). It waits on the materialized Secret — give the operator a few seconds and retry." >&2
  exit 1
fi
STORE=$(kubectl get secret vault-backend -n secrets-source -o jsonpath='{.data.db-password}' 2>/dev/null | base64 -d)
LIVE=$(kubectl exec deploy/billing-processor -n provisioning -- printenv DB_PASSWORD 2>/dev/null)
if [ -z "$LIVE" ] || [ "$STORE" != "$LIVE" ]; then
  echo "The DB_PASSWORD in the running container ('$LIVE') doesn't match the store. Wait for the pipeline to settle and retry." >&2
  exit 1
fi
echo "✓ billing-processor is Ready and its DB_PASSWORD matches the store — the chain holds store → Secret → process"
exit 0
