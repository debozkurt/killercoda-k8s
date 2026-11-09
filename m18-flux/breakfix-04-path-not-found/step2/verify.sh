#!/bin/bash
# Checks: apps builds again, it applied the newest source revision, and the
# commit's change (dialplan at 3 replicas) reached the cluster.
READY=$(kubectl get kustomization apps -n flux-system \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
[ "$READY" = "True" ] || { echo "Kustomization apps is not Ready (got: ${READY:-none}). Point it at the moved directory:" >&2; echo "  kubectl patch kustomization apps -n flux-system --type=merge -p '{\"spec\":{\"path\":\"./deploy/apps\"}}'" >&2; exit 1; }

SRC=$(kubectl get gitrepository polyphone-config -n flux-system -o jsonpath='{.status.artifact.revision}' 2>/dev/null)
APPLIED=$(kubectl get kustomization apps -n flux-system -o jsonpath='{.status.lastAppliedRevision}' 2>/dev/null)
[ -n "$SRC" ] && [ "$SRC" = "$APPLIED" ] || { echo "apps applied ${APPLIED:-nothing}, the source holds ${SRC:-nothing}. Run:" >&2; echo "  flux reconcile kustomization apps" >&2; exit 1; }

REPLICAS=$(kubectl get deploy dialplan -n app-services -o jsonpath='{.spec.replicas}' 2>/dev/null)
[ "$REPLICAS" = "3" ] || { echo "dialplan wants ${REPLICAS:-no} replicas; the newest commit declares 3. Run:" >&2; echo "  flux reconcile kustomization apps --with-source" >&2; exit 1; }

echo "✓ apps applied $SRC; dialplan runs the 3 replicas the commit declares"
exit 0
