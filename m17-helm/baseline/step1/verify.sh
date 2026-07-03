#!/bin/bash
# Checks: helm is installed and the voicemail release is deployed with its
# workload up (2 pods Running). Read-only tour step — nothing to fix.
command -v helm >/dev/null 2>&1 || { echo "helm CLI not found on PATH" >&2; exit 1; }

helm status voicemail -n app-services 2>/dev/null | grep -q '^STATUS: deployed' \
  || { echo "voicemail release is not in status 'deployed'" >&2; exit 1; }

READY=$(kubectl get pods -n app-services -l app=voicemail --no-headers 2>/dev/null | awk '$3 == "Running"' | wc -l)
[ "$READY" -ge 2 ] || { echo "Expected 2 voicemail pods Running, got $READY" >&2; exit 1; }

echo "✓ Helm installed; voicemail release deployed with $READY pods Running"
exit 0
