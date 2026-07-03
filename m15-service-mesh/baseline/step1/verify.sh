#!/bin/bash
# Checks: session-broker's pod carries the injected Envoy sidecar (istio-proxy),
# i.e. it actually joined the mesh — the precondition for every later step.
NAMES=$(kubectl get pod -n media -l app=session-broker \
  -o jsonpath='{.items[0].spec.containers[*].name}' 2>/dev/null)
if echo "$NAMES" | grep -qw istio-proxy; then
  echo "✓ session-broker has an istio-proxy sidecar — it's in the mesh (containers: $NAMES)"
  exit 0
fi
echo "session-broker has no istio-proxy sidecar yet (containers: '$NAMES'). Istio may still be" >&2
echo "installing or the pod may still be starting — wait for 2/2 and retry." >&2
exit 1
