#!/bin/bash
# Checks: the prod render sets replicas: 3, and edge-relay runs 3 ready replicas.
DIR=/root/edge-relay
if ! kubectl kustomize "$DIR/overlays/prod" 2>/dev/null | grep -q 'replicas: 3'; then
  echo "The prod render does not set replicas: 3; the patch target still matches no Deployment." >&2
  echo "Set the target name to edge-relay in overlays/prod/kustomization.yaml, then:" >&2
  echo "  kubectl apply -k $DIR/overlays/prod" >&2
  exit 1
fi
READY=$(kubectl get deploy edge-relay -n edge -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${READY:-0}" -lt 3 ]; then
  echo "The render sets 3 replicas, and edge-relay has ${READY:-0} ready. Apply it:" >&2
  echo "  kubectl apply -k $DIR/overlays/prod" >&2
  exit 1
fi
echo "✓ The prod render sets 3 replicas, and edge-relay runs 3/3"
exit 0
