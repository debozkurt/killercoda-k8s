#!/bin/bash
# Checks: voicemail depends on an existing HelmRelease, it is Ready, and its
# Deployment runs 2 ready replicas.
DEP=$(kubectl get helmrelease voicemail -n flux-system -o jsonpath='{.spec.dependsOn[*].name}' 2>/dev/null)
for d in $DEP; do
  kubectl get helmrelease "$d" -n flux-system >/dev/null 2>&1 \
    || { echo "voicemail depends on HelmRelease '$d', which does not exist. Run:" >&2; echo "  kubectl patch helmrelease voicemail -n flux-system --type=merge -p '{\"spec\":{\"dependsOn\":[{\"name\":\"message-store\"}]}}'" >&2; exit 1; }
done
echo " $DEP " | grep -q " message-store " || { echo "voicemail no longer waits for message-store (dependsOn: ${DEP:-empty}). Keep the order gate:" >&2; echo "  kubectl patch helmrelease voicemail -n flux-system --type=merge -p '{\"spec\":{\"dependsOn\":[{\"name\":\"message-store\"}]}}'" >&2; exit 1; }

READY=$(kubectl get helmrelease voicemail -n flux-system \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
[ "$READY" = "True" ] || { echo "HelmRelease voicemail is not Ready (got: ${READY:-none}). Run:" >&2; echo "  flux reconcile helmrelease voicemail" >&2; exit 1; }

RR=$(kubectl get deploy voicemail -n app-services -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
[ "$RR" = "2" ] || { echo "voicemail has ${RR:-0} ready replicas, expected 2. Wait for the rollout, then run:" >&2; echo "  kubectl get deploy voicemail -n app-services" >&2; exit 1; }

echo "✓ voicemail waits for message-store, installed, and runs $RR ready replicas"
exit 0
