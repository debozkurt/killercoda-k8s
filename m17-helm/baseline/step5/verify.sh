#!/bin/bash
# Checks: the hand edit is resolved through Helm. The latest revision is
# deployed, kubectl no longer owns .spec.replicas through the scale
# subresource, and the live replica count equals the stored manifest.
command -v helm >/dev/null 2>&1 || { echo "helm CLI not found on PATH" >&2; exit 1; }

STATUS=$(helm status voicemail -n app-services 2>/dev/null | awk '/^STATUS:/ {print $2}')
[ "$STATUS" = "deployed" ] || { echo "Latest voicemail revision is ${STATUS:-missing}, not deployed. Run helm upgrade ... --reuse-values --force-conflicts" >&2; exit 1; }

if kubectl get deployment voicemail -n app-services -o yaml --show-managed-fields 2>/dev/null | grep -q 'subresource: scale'; then
  echo "kubectl still owns .spec.replicas (scale subresource). Run helm upgrade ... --reuse-values --force-conflicts" >&2
  exit 1
fi

LIVE=$(kubectl get deployment voicemail -n app-services -o jsonpath='{.spec.replicas}' 2>/dev/null)
STORED=$(helm get manifest voicemail -n app-services 2>/dev/null | awk '/^  replicas:/ {print $2; exit}')
[ -n "$LIVE" ] && [ "$LIVE" = "$STORED" ] || { echo "Live replicas ${LIVE:-none} differ from the release manifest ${STORED:-none}" >&2; exit 1; }

echo "✓ Field taken back by Helm: revision deployed, live replicas $LIVE match the release manifest"
exit 0
