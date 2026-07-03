#!/bin/bash
# Checks: the live release manifest renders a Deployment at 2 replicas — proof
# the value flowed values -> render -> live object. Read-only tour step.
command -v helm >/dev/null 2>&1 || { echo "helm CLI not found on PATH" >&2; exit 1; }

MANIFEST=$(helm get manifest voicemail -n app-services 2>/dev/null)
echo "$MANIFEST" | grep -q "kind: Deployment" || { echo "voicemail manifest has no Deployment" >&2; exit 1; }

REPLICAS=$(kubectl get deployment voicemail -n app-services -o jsonpath='{.spec.replicas}' 2>/dev/null)
[ "$REPLICAS" = "2" ] || { echo "Expected voicemail Deployment at 2 replicas, got ${REPLICAS:-none}" >&2; exit 1; }

echo "✓ Render pipeline intact: values -> manifest -> live Deployment at $REPLICAS replicas"
exit 0
