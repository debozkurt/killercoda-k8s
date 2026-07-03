#!/bin/bash
# Checks: the corrected upgrade set replicaCount, so the Deployment now runs 3
# replicas and the rendered manifest agrees. Accepts any fix path that lands 3.
command -v helm >/dev/null 2>&1 || { echo "helm CLI not found on PATH" >&2; exit 1; }

DESIRED=$(kubectl get deployment voicemail -n app-services -o jsonpath='{.spec.replicas}' 2>/dev/null)
[ "$DESIRED" = "3" ] || { echo "Expected voicemail Deployment at 3 replicas, got ${DESIRED:-none}" >&2; exit 1; }

READY=$(kubectl get pods -n app-services -l app=voicemail --no-headers 2>/dev/null | awk '$3 == "Running"' | wc -l)
[ "$READY" -ge 3 ] || { echo "Expected 3 voicemail pods Running, got $READY" >&2; exit 1; }

# The rendered manifest must reflect the corrected key (proves the value flowed,
# not that someone hand-scaled the Deployment out of band).
helm get manifest voicemail -n app-services 2>/dev/null | grep -qE "replicas: 3" \
  || { echo "voicemail release manifest does not render replicas: 3 — was replicaCount set via helm?" >&2; exit 1; }

echo "✓ Override corrected: replicaCount reached the manifest, voicemail at $READY/3 Running"
exit 0
