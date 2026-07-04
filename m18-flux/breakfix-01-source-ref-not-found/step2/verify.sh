#!/bin/bash
# Checks: the GitRepository is pointed at an existing branch and Ready again, and
# the downstream Kustomization applied dialplan. Accepts any path that lands a
# Ready source + a running dialplan (proves the source fed the consumers).
BRANCH=$(kubectl get gitrepository polyphone-config -n flux-system -o jsonpath='{.spec.ref.branch}' 2>/dev/null)
[ "$BRANCH" = "main" ] || { echo "GitRepository ref.branch is '${BRANCH:-none}', expected an existing branch (main)" >&2; exit 1; }

READY=$(kubectl get gitrepository polyphone-config -n flux-system \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
[ "$READY" = "True" ] || { echo "GitRepository is not Ready yet (got: ${READY:-none}). Run: flux reconcile source git polyphone-config" >&2; exit 1; }

KREADY=$(kubectl get kustomization apps -n flux-system \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
[ "$KREADY" = "True" ] || { echo "Kustomization apps not Ready yet (got: ${KREADY:-none}). Run: flux reconcile kustomization apps --with-source" >&2; exit 1; }

RR=$(kubectl get deploy dialplan -n app-services -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
[ "$RR" = "2" ] || { echo "Expected dialplan at 2 ready replicas after the source recovered, got ${RR:-none}" >&2; exit 1; }

echo "✓ Source pointed at main and Ready; apps reconciled; dialplan at $RR ready replicas"
exit 0
