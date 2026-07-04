#!/bin/bash
# Checks: prod-us-east-1 no longer shadows the region standard — it RENDERS
# MAX_SESSIONS=8000 and the LIVE ConfigMap the Deployment references carries it.
# Asserts the outcome, not the method (delete the override or reconcile to 8000).
FLEET=/root/fleet
NS=edge

RENDER=$(kubectl kustomize "$FLEET/clusters/prod-us-east-1" 2>/dev/null)
if ! echo "$RENDER" | grep -q 'MAX_SESSIONS: "8000"'; then
  GOT=$(echo "$RENDER" | grep -E '^  MAX_SESSIONS:' | tr -d '"' | awk '{print $2}')
  echo "prod-us-east-1 still renders MAX_SESSIONS=${GOT:-<none>}. Remove the per-cluster override so the region's 8000 flows through." >&2
  exit 1
fi

REF=$(kubectl get deploy edge-relay -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].envFrom[0].configMapRef.name}' 2>/dev/null)
LIVE=$(kubectl get configmap "$REF" -n "$NS" -o jsonpath='{.data.MAX_SESSIONS}' 2>/dev/null)
if [ "$LIVE" != "8000" ]; then
  echo "Rendered value is fixed, but the live cluster still runs MAX_SESSIONS='${LIVE:-<none>}'. Re-apply: kubectl apply -k clusters/prod-us-east-1." >&2
  exit 1
fi

echo "✓ prod-us-east-1 renders and runs MAX_SESSIONS=8000 — the shadow is gone and the region standard reaches the cluster."
exit 0
