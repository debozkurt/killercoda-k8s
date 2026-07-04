#!/bin/bash
# Checks: the HelmRelease dependsOn now names the real backing-store release
# (message-store), the release is Ready, and voicemail installed at 2 replicas.
DEP=$(kubectl get helmrelease voicemail -n flux-system -o jsonpath='{.spec.dependsOn[0].name}' 2>/dev/null)
[ "$DEP" = "message-store" ] || { echo "HelmRelease dependsOn is '${DEP:-none}', expected the real HelmRelease 'message-store'" >&2; exit 1; }

READY=$(kubectl get helmrelease voicemail -n flux-system \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
[ "$READY" = "True" ] || { echo "HelmRelease voicemail is not Ready yet (got: ${READY:-none}). Run: flux reconcile helmrelease voicemail" >&2; exit 1; }

RR=$(kubectl get deploy voicemail -n app-services -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
[ "$RR" = "2" ] || { echo "Expected voicemail Deployment at 2 ready replicas, got ${RR:-none}" >&2; exit 1; }

echo "✓ dependsOn corrected to message-store; HelmRelease Ready; voicemail Deployment at $RR ready replicas"
exit 0
