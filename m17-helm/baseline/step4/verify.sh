#!/bin/bash
# Checks: the rollback demo worked — release advanced to revision >= 3, is
# deployed, and the Deployment is back to 2 replicas (revision 1's value).
command -v helm >/dev/null 2>&1 || { echo "helm CLI not found on PATH" >&2; exit 1; }

REV=$(helm status voicemail -n app-services 2>/dev/null | awk '/^REVISION:/ {print $2}')
[ -n "$REV" ] && [ "$REV" -ge 3 ] || { echo "Expected revision >= 3 after rollback, got ${REV:-none}" >&2; exit 1; }

helm status voicemail -n app-services 2>/dev/null | grep -q '^STATUS: deployed' \
  || { echo "release not in status 'deployed' after rollback" >&2; exit 1; }

REPLICAS=$(kubectl get deployment voicemail -n app-services -o jsonpath='{.spec.replicas}' 2>/dev/null)
[ "$REPLICAS" = "2" ] || { echo "Expected 2 replicas after rollback to rev 1, got ${REPLICAS:-none}" >&2; exit 1; }

SECRETS=$(kubectl get secret -n app-services -l owner=helm --no-headers 2>/dev/null | grep -c 'voicemail')
[ "$SECRETS" -ge 3 ] || { echo "Expected >= 3 helm release secrets for voicemail, got $SECRETS" >&2; exit 1; }

echo "✓ History walked: revision $REV deployed, back to $REPLICAS replicas, $SECRETS release secrets stored"
exit 0
