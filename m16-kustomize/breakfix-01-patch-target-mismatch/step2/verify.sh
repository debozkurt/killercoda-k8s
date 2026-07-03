#!/bin/bash
# Checks: the prod overlay now BUILDS (patch target resolves) and edge-relay is
# live with the prod replica count. Asserts the outcome, not the command.
DIR=/root/edge-relay

if ! kubectl kustomize "$DIR/overlays/prod" >/dev/null 2>&1; then
  ERR=$(kubectl kustomize "$DIR/overlays/prod" 2>&1 | head -1)
  echo "prod overlay still fails to build: $ERR" >&2
  echo "Point overlays/prod/replicas-patch.yaml at metadata.name: edge-relay." >&2
  exit 1
fi

READY=$(kubectl get deploy edge-relay -n edge -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${READY:-0}" -lt 3 ]; then
  echo "edge-relay not at 3 ready replicas yet (got ${READY:-0}). Did you 'kubectl apply -k overlays/prod'?" >&2
  exit 1
fi

echo "✓ prod overlay builds and edge-relay is live at 3/3 — the patch found its target."
exit 0
