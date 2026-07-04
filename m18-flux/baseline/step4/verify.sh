#!/bin/bash
# Checks: the voicemail HelmRelease is Ready and its Deployment is up at 2
# replicas — the dependsOn-ordered release installed cleanly. Read-only tour step.
command -v flux >/dev/null 2>&1 || { echo "flux CLI not found on PATH" >&2; exit 1; }

READY=$(kubectl get helmrelease voicemail -n flux-system \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
[ "$READY" = "True" ] || { echo "HelmRelease voicemail is not Ready (got: ${READY:-none})" >&2; exit 1; }

RR=$(kubectl get deploy voicemail -n app-services -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
[ "$RR" = "2" ] || { echo "Expected voicemail Deployment 2 ready replicas, got ${RR:-none}" >&2; exit 1; }

echo "✓ HelmRelease voicemail Ready; voicemail Deployment at $RR ready replicas"
exit 0
