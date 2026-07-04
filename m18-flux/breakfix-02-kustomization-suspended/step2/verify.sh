#!/bin/bash
# Checks: the apps Kustomization is resumed (not suspended) and Ready, and drift
# correction brought dialplan back to its git-declared 2 replicas.
SUSPEND=$(kubectl get kustomization apps -n flux-system -o jsonpath='{.spec.suspend}' 2>/dev/null)
[ "$SUSPEND" = "true" ] && { echo "Kustomization apps is still suspended — run: flux resume kustomization apps" >&2; exit 1; }

READY=$(kubectl get kustomization apps -n flux-system \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
[ "$READY" = "True" ] || { echo "Kustomization apps is not Ready yet (got: ${READY:-none})" >&2; exit 1; }

REPLICAS=$(kubectl get deploy dialplan -n app-services -o jsonpath='{.spec.replicas}' 2>/dev/null)
[ "$REPLICAS" = "2" ] || { echo "Expected dialplan reverted to 2 replicas, got ${REPLICAS:-none}" >&2; exit 1; }

echo "✓ apps resumed and Ready; drift corrected — dialplan back to $REPLICAS replicas"
exit 0
