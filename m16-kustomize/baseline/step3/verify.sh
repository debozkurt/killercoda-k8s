#!/bin/bash
# Checks: the prod overlay is live in the cluster — edge-relay Available with 3
# replicas and the prod image, and the Deployment's envFrom references a
# ConfigMap that actually exists (the reference resolved end to end).
NS=edge

kubectl get deploy edge-relay -n "$NS" >/dev/null 2>&1 || {
  echo "edge-relay Deployment not found in $NS — apply the prod overlay: kubectl apply -k /root/edge-relay/overlays/prod" >&2; exit 1; }

READY=$(kubectl get deploy edge-relay -n "$NS" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
[ "${READY:-0}" -ge 3 ] || { echo "Expected 3 ready replicas, got ${READY:-0}." >&2; exit 1; }

IMG=$(kubectl get deploy edge-relay -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
[ "$IMG" = "nginx:1.27" ] || { echo "Expected the prod image nginx:1.27, got '$IMG'." >&2; exit 1; }

REF=$(kubectl get deploy edge-relay -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].envFrom[0].configMapRef.name}' 2>/dev/null)
kubectl get configmap "$REF" -n "$NS" >/dev/null 2>&1 || {
  echo "The Deployment references ConfigMap '$REF' but it does not exist in $NS." >&2; exit 1; }

echo "✓ Prod overlay is live: edge-relay 3/3 on nginx:1.27, referencing ConfigMap '$REF' (which exists)."
exit 0
