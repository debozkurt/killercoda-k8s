#!/bin/bash
# Checks: the apps Kustomization is Ready and dialplan runs at its git-declared 2 replicas.
READY=$(kubectl get kustomization apps -n flux-system \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
[ "$READY" = "True" ] || { echo "Kustomization apps is not Ready (got: ${READY:-none}). Run:" >&2; echo "  flux reconcile kustomization apps --with-source" >&2; exit 1; }

REPLICAS=$(kubectl get deploy dialplan -n app-services -o jsonpath='{.spec.replicas}' 2>/dev/null)
[ "$REPLICAS" = "2" ] || { echo "dialplan wants ${REPLICAS:-no} replicas, git declares 2. Run:" >&2; echo "  flux reconcile kustomization apps" >&2; exit 1; }

echo "✓ Kustomization apps is Ready; dialplan runs at 2 replicas"
exit 0
