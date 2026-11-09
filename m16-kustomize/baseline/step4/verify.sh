#!/bin/bash
# Checks the hash contract: the Deployment references a ConfigMap with
# MAX_SESSIONS=6000, all 3 replicas are ready, and --prune removed the old
# generated ConfigMap.
NS=edge

READY=$(kubectl get deploy edge-relay -n "$NS" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${READY:-0}" -lt 3 ]; then
  echo "edge-relay has ${READY:-0}/3 ready replicas. Wait for the rollout:" >&2
  echo "  kubectl rollout status deployment/edge-relay -n edge" >&2
  exit 1
fi

REF=$(kubectl get deploy edge-relay -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].envFrom[0].configMapRef.name}' 2>/dev/null)
VAL=$(kubectl get configmap "$REF" -n "$NS" -o jsonpath='{.data.MAX_SESSIONS}' 2>/dev/null)
if [ "$VAL" != "6000" ]; then
  echo "The Deployment references ConfigMap '$REF' with MAX_SESSIONS='$VAL', not 6000. Edit the prod overlay and apply:" >&2
  echo "  sed -i 's/MAX_SESSIONS=5000/MAX_SESSIONS=6000/' /root/edge-relay/overlays/prod/kustomization.yaml" >&2
  echo "  kubectl apply -k /root/edge-relay/overlays/prod" >&2
  exit 1
fi

COUNT=$(kubectl get configmap -n "$NS" -l app=edge-relay --no-headers 2>/dev/null | wc -l | tr -d ' ')
if [ "$COUNT" != "1" ]; then
  echo "$COUNT edge-relay ConfigMaps exist; the old generated one is still there. Prune it:" >&2
  echo "  kubectl apply -k /root/edge-relay/overlays/prod --prune -l app=edge-relay" >&2
  exit 1
fi

echo "✓ edge-relay rolled to $REF (MAX_SESSIONS=6000), 3/3 ready, and the old ConfigMap is pruned"
exit 0
