#!/bin/bash
# Checks: the validating webhook is scoped back to admission-guard=enabled (tenant-apps only)
# AND sip-canary in signaling rolled out — proof the webhook no longer intercepts that namespace.
SEL=$(kubectl get validatingwebhookconfiguration admission-guard \
  -o jsonpath='{.webhooks[0].namespaceSelector.matchLabels.admission-guard}' 2>/dev/null)
if [ "$SEL" != "enabled" ]; then
  echo "The validating webhook's namespaceSelector isn't scoped to admission-guard=enabled yet (still matching more than tenant-apps). Narrow it and retry." >&2
  exit 1
fi
AVAIL=$(kubectl get deploy sip-canary -n signaling -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ "${AVAIL:-0}" -ge 1 ] 2>/dev/null; then
  echo "✓ webhook scoped back to tenant-apps; sip-canary in signaling is Available (no longer intercepted)"
  exit 0
fi
echo "sip-canary isn't Available yet. After narrowing the namespaceSelector, re-admit it (e.g. kubectl rollout restart deployment/sip-canary -n signaling), then wait and retry." >&2
exit 1
