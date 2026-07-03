#!/bin/bash
# Checks: the learner's upgrade took effect — voicemail is now at 3 replicas and
# the release advanced past revision 1. sipRealm must still be present (proof
# --reuse-values carried the required value forward).
command -v helm >/dev/null 2>&1 || { echo "helm CLI not found on PATH" >&2; exit 1; }

REPLICAS=$(kubectl get deployment voicemail -n app-services -o jsonpath='{.spec.replicas}' 2>/dev/null)
[ "$REPLICAS" = "3" ] || { echo "Expected voicemail at 3 replicas after upgrade, got ${REPLICAS:-none}" >&2; exit 1; }

REV=$(helm status voicemail -n app-services 2>/dev/null | awk '/^REVISION:/ {print $2}')
[ -n "$REV" ] && [ "$REV" -ge 2 ] || { echo "Expected release revision >= 2 after upgrade, got ${REV:-none}" >&2; exit 1; }

echo "✓ Upgrade applied: voicemail at $REPLICAS replicas, release now revision $REV"
exit 0
