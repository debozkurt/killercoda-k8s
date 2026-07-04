#!/bin/bash
# Checks: the apps Kustomization is Ready and applied the dialplan Deployment at
# its git-declared 2 replicas. Read-only tour step.
READY=$(kubectl get kustomization apps -n flux-system \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
[ "$READY" = "True" ] || { echo "Kustomization apps is not Ready (got: ${READY:-none})" >&2; exit 1; }

REPLICAS=$(kubectl get deploy dialplan -n app-services -o jsonpath='{.spec.replicas}' 2>/dev/null)
[ "$REPLICAS" = "2" ] || { echo "Expected dialplan at 2 replicas, got ${REPLICAS:-none}" >&2; exit 1; }

echo "✓ Kustomization apps Ready; dialplan applied at $REPLICAS replicas"
exit 0
