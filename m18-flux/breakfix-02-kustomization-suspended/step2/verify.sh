#!/bin/bash
# Checks: apps is no longer suspended, it is Ready, and drift correction
# returned dialplan to the 2 replicas that git declares.
SUSPEND=$(kubectl get kustomization apps -n flux-system -o jsonpath='{.spec.suspend}' 2>/dev/null)
[ "$SUSPEND" = "true" ] && { echo "Kustomization apps is still suspended. Run:" >&2; echo "  flux resume kustomization apps" >&2; exit 1; }

READY=$(kubectl get kustomization apps -n flux-system \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
[ "$READY" = "True" ] || { echo "Kustomization apps is not Ready (got: ${READY:-none}). Run:" >&2; echo "  flux reconcile kustomization apps" >&2; exit 1; }

REPLICAS=$(kubectl get deploy dialplan -n app-services -o jsonpath='{.spec.replicas}' 2>/dev/null)
[ "$REPLICAS" = "2" ] || { echo "dialplan wants ${REPLICAS:-no} replicas, git declares 2. Run:" >&2; echo "  flux reconcile kustomization apps" >&2; exit 1; }

echo "✓ apps resumed and Ready; drift correction returned dialplan to 2 replicas"
exit 0
