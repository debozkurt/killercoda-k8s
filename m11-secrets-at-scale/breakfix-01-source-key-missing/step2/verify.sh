#!/bin/bash
# Checks: partner-api names the store's real key (api-token), reports Synced, its Secret
# exists, and partner-connector is Ready. Adding a typo'd key to the store is not a fix.
SRC=$(kubectl get secretsync partner-api -n media -o jsonpath='{.spec.data[0].sourceKey}' 2>/dev/null)
if [ "$SRC" != "api-token" ]; then
  echo "partner-api still names sourceKey '$SRC'. Fix the reference, not the store:" >&2
  echo "  kubectl patch secretsync partner-api -n media --type=json -p '[{\"op\":\"replace\",\"path\":\"/spec/data/0/sourceKey\",\"value\":\"api-token\"}]'" >&2
  exit 1
fi
REASON=$(kubectl get secretsync partner-api -n media -o jsonpath='{.status.reason}' 2>/dev/null)
if [ "$REASON" != "Synced" ] || ! kubectl get secret partner-api -n media >/dev/null 2>&1; then
  echo "The reference is correct, but partner-api reads '$REASON' and its Secret may not exist yet. The operator runs every 10 seconds. Wait, then run:" >&2
  echo "  kubectl get secretsync -A" >&2
  exit 1
fi
READY=$(kubectl get deployment partner-connector -n media -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "$READY" != "1" ]; then
  echo "The Secret exists, but partner-connector is not Ready (readyReplicas='$READY'). The kubelet retries on a backoff. Wait 30 seconds, then run:" >&2
  echo "  kubectl get pods -n media -l app=partner-connector" >&2
  exit 1
fi
kubectl get pods -n media -l app=partner-connector
echo "✓ partner-api is Synced, its Secret exists, and partner-connector is Ready"
exit 0
