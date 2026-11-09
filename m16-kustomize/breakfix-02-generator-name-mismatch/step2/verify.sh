#!/bin/bash
# Checks: edge-relay runs 3 ready replicas and references the hashed generator ConfigMap, which exists.
NS=edge
READY=$(kubectl get deploy edge-relay -n "$NS" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
REF=$(kubectl get deploy edge-relay -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].envFrom[0].configMapRef.name}' 2>/dev/null)
case "$REF" in
  edge-relay-config-*) : ;;
  *) echo "The Deployment references '$REF', not the hashed edge-relay-config-<hash>." >&2
     echo "Make base/deployment.yaml name the generator (edge-relay-config), then:" >&2
     echo "  kubectl apply -k /root/edge-relay/overlays/prod" >&2
     exit 1 ;;
esac
if ! kubectl get configmap "$REF" -n "$NS" >/dev/null 2>&1; then
  echo "The Deployment references ConfigMap '$REF', and it does not exist. Apply the overlay:" >&2
  echo "  kubectl apply -k /root/edge-relay/overlays/prod" >&2
  exit 1
fi
if [ "${READY:-0}" -lt 3 ]; then
  echo "edge-relay has ${READY:-0}/3 ready replicas. Wait for the rollout:" >&2
  echo "  kubectl rollout status deployment/edge-relay -n edge" >&2
  exit 1
fi
echo "✓ edge-relay runs 3/3 and references $REF, which exists"
exit 0
