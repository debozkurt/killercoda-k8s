#!/bin/bash
# Checks: the webhook backend is up again (>=1 ready) AND billing-api rolled out — its Pods
# pass admission now that the webhook call completes. Asserts the outcome, not a fix command.
BAVAIL=$(kubectl get deploy admission-guard -n admission -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ "${BAVAIL:-0}" -lt 1 ] 2>/dev/null; then
  echo "admission-guard isn't Available yet — scale it to 1 and wait for its Pod to be Ready (the image pulls on first start)." >&2
  exit 1
fi
AVAIL=$(kubectl get deploy billing-api -n tenant-apps -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ "${AVAIL:-0}" -ge 1 ] 2>/dev/null; then
  echo "✓ admission-guard is back up and billing-api is Available — admission calls complete again"
  exit 0
fi
echo "billing-api isn't Available yet. With the backend up, trigger a fresh admission attempt (e.g. kubectl rollout restart deployment/billing-api -n tenant-apps), then wait and retry." >&2
exit 1
