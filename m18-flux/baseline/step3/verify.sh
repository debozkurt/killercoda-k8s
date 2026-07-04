#!/bin/bash
# Checks: after the drift demo, Flux reconciled dialplan back to its git-declared
# 2 replicas. Accepts the reverted end state (the point of the step).
REPLICAS=$(kubectl get deploy dialplan -n app-services -o jsonpath='{.spec.replicas}' 2>/dev/null)
[ "$REPLICAS" = "2" ] || { echo "Expected dialplan reverted to 2 replicas, got ${REPLICAS:-none}. Run: flux reconcile kustomization apps --with-source" >&2; exit 1; }

READY=$(kubectl get kustomization apps -n flux-system \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
[ "$READY" = "True" ] || { echo "Kustomization apps is not Ready (got: ${READY:-none})" >&2; exit 1; }

echo "✓ Drift corrected: dialplan back to $REPLICAS replicas, Kustomization Ready"
exit 0
