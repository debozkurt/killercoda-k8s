#!/bin/bash
# Checks: the prod overlay builds, and edge-relay runs 3 ready replicas.
DIR=/root/edge-relay
if ! kubectl kustomize "$DIR/overlays/prod" >/dev/null 2>&1; then
  echo "The prod overlay still fails to build: $(kubectl kustomize "$DIR/overlays/prod" 2>&1 | head -1)" >&2
  echo "Point overlays/prod/replicas-patch.yaml at metadata.name: edge-relay, then:" >&2
  echo "  kubectl apply -k $DIR/overlays/prod" >&2
  exit 1
fi
READY=$(kubectl get deploy edge-relay -n edge -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${READY:-0}" -lt 3 ]; then
  echo "The overlay builds, and edge-relay has ${READY:-0}/3 ready replicas. Apply it:" >&2
  echo "  kubectl apply -k $DIR/overlays/prod" >&2
  exit 1
fi
echo "✓ The prod overlay builds, and edge-relay runs 3/3"
exit 0
