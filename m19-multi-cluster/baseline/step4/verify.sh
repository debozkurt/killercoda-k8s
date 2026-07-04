#!/bin/bash
# Checks: prod-us-east-1 is live — edge-relay Available with 3 replicas on the
# prod image nginx:1.25, and the Deployment's envFrom references a ConfigMap that
# actually exists (the hash reference resolved end to end across three layers).
NS=edge

kubectl get deploy edge-relay -n "$NS" >/dev/null 2>&1 || {
  echo "edge-relay Deployment not found in $NS — apply the cluster: kubectl apply -k /root/fleet/clusters/prod-us-east-1" >&2; exit 1; }

READY=$(kubectl get deploy edge-relay -n "$NS" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
[ "${READY:-0}" -ge 3 ] || { echo "Expected 3 ready replicas, got ${READY:-0}." >&2; exit 1; }

IMG=$(kubectl get deploy edge-relay -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
[ "$IMG" = "nginx:1.25" ] || { echo "Expected the prod image nginx:1.25 (1.27 not yet promoted to prod), got '$IMG'." >&2; exit 1; }

REF=$(kubectl get deploy edge-relay -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].envFrom[0].configMapRef.name}' 2>/dev/null)
kubectl get configmap "$REF" -n "$NS" >/dev/null 2>&1 || {
  echo "The Deployment references ConfigMap '$REF' but it does not exist in $NS." >&2; exit 1; }

echo "✓ prod-us-east-1 is live: edge-relay 3/3 on nginx:1.25, referencing ConfigMap '$REF' (which exists)."
exit 0
