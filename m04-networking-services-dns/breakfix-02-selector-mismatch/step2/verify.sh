#!/bin/bash
# Checks: route-engine's EndpointSlice is populated again — the selector matches
# the Pods, so the Service has backends. Asserts the outcome, not the command.
EP=$(kubectl get endpoints route-engine -n call-routing -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null)
if [ -z "$EP" ]; then
  SEL=$(kubectl get svc route-engine -n call-routing -o jsonpath='{.spec.selector.app}' 2>/dev/null)
  echo "route-engine still has no endpoints (selector app='$SEL'). Match it to the Pods' label, e.g.: kubectl patch svc route-engine -n call-routing -p '{\"spec\":{\"selector\":{\"app\":\"route-engine\"}}}'" >&2
  exit 1
fi
echo "✓ route-engine has a populated EndpointSlice again (first backend: $EP)"
exit 0
