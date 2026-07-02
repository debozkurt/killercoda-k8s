#!/bin/bash
# Checks: the healthy HPA on sip-router exists and points at the sip-router Deployment.
# Defensive baseline check — does not assert a live metric value (metrics-server may
# still be warming up), only that the autoscaler object is wired correctly.
REF=$(kubectl get hpa sip-router -n signaling -o jsonpath='{.spec.scaleTargetRef.name}' 2>/dev/null)
if [ "$REF" != "sip-router" ]; then
  echo "HPA sip-router not found or not targeting the sip-router Deployment (got '${REF:-none}'). The cluster may still be coming up — wait and retry." >&2
  exit 1
fi
echo "✓ HPA sip-router is present and targets Deployment sip-router"
exit 0
