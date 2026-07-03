#!/bin/bash
# Checks: the partner-api SecretSync now reports Synced, the target Secret was
# materialized, and the consumer recovered from CreateContainerConfigError.
# Asserts the outcome, not the exact fix used.
REASON=$(kubectl get secretsync partner-api -n media -o jsonpath='{.status.reason}' 2>/dev/null)
if [ "$REASON" != "Synced" ]; then
  echo "partner-api SecretSync is still '$REASON', not 'Synced'. Correct its sourceKey to 'api-token' and re-apply; the operator reconciles every ~10s — wait and retry." >&2
  exit 1
fi
if ! kubectl get secret partner-api -n media >/dev/null 2>&1; then
  echo "The sync reads Synced but the partner-api Secret isn't visible yet — the operator is mid-reconcile. Wait a few seconds and retry." >&2
  exit 1
fi
READY=$(kubectl get deployment partner-connector -n media -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "$READY" != "1" ]; then
  echo "The Secret exists but partner-connector isn't Ready yet (readyReplicas='$READY'). The kubelet retries CreateContainerConfigError on a backoff — wait ~30s and retry." >&2
  exit 1
fi
echo "✓ partner-api Synced, its Secret materialized, and partner-connector recovered — the pipeline produces the Secret again"
exit 0
