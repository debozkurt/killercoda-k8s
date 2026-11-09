#!/bin/bash
# Checks: the commits reached the cluster through Flux. apps applied the newest
# source revision, dialplan runs 3 replicas, and dialplan-routes was pruned.
SRC=$(kubectl get gitrepository polyphone-config -n flux-system -o jsonpath='{.status.artifact.revision}' 2>/dev/null)
APPLIED=$(kubectl get kustomization apps -n flux-system -o jsonpath='{.status.lastAppliedRevision}' 2>/dev/null)
[ -n "$SRC" ] && [ "$SRC" = "$APPLIED" ] || { echo "apps applied ${APPLIED:-nothing}, the source holds ${SRC:-nothing}. Run:" >&2; echo "  flux reconcile kustomization apps --with-source" >&2; exit 1; }

REPLICAS=$(kubectl get deploy dialplan -n app-services -o jsonpath='{.spec.replicas}' 2>/dev/null)
[ "$REPLICAS" = "3" ] || { echo "dialplan wants ${REPLICAS:-no} replicas, expected 3 from your commit. Push the replicas change, then run:" >&2; echo "  flux reconcile kustomization apps --with-source" >&2; exit 1; }

if kubectl get configmap dialplan-routes -n app-services >/dev/null 2>&1; then
  echo "ConfigMap dialplan-routes still exists. Remove it from git and push, then run:" >&2
  echo "  flux reconcile kustomization apps --with-source" >&2
  exit 1
fi

echo "✓ apps applied $SRC: dialplan at 3 replicas, dialplan-routes pruned"
exit 0
