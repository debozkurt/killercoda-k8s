#!/bin/bash
# Checks: the eu-central-1 region overlay now sets its own REGION, so
# prod-eu-central-1 RENDERS REGION=eu-central-1 and the LIVE ConfigMap the
# Deployment references carries it. Asserts the outcome, not the command.
FLEET=/root/fleet
NS=edge

RENDER=$(kubectl kustomize "$FLEET/clusters/prod-eu-central-1" 2>/dev/null)
if ! echo "$RENDER" | grep -q 'REGION: eu-central-1'; then
  GOT=$(echo "$RENDER" | grep -E '^  REGION:' | awk '{print $2}')
  echo "prod-eu-central-1 still renders REGION=${GOT:-<none>}. Set REGION=eu-central-1 in regions/eu-central-1/kustomization.yaml." >&2
  exit 1
fi

# Live: the ConfigMap the Deployment references must carry the corrected region.
REF=$(kubectl get deploy edge-relay -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].envFrom[0].configMapRef.name}' 2>/dev/null)
LIVE=$(kubectl get configmap "$REF" -n "$NS" -o jsonpath='{.data.REGION}' 2>/dev/null)
if [ "$LIVE" != "eu-central-1" ]; then
  echo "Rendered value is fixed, but the live cluster still runs REGION='${LIVE:-<none>}'. Re-apply: kubectl apply -k clusters/prod-eu-central-1." >&2
  exit 1
fi

echo "✓ prod-eu-central-1 renders and runs REGION=eu-central-1 — the stale cluster variable is fixed in its owning layer."
exit 0
