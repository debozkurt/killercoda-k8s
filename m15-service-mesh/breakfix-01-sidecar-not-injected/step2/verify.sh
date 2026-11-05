#!/bin/bash
# Checks: session-broker runs an istio-proxy sidecar again, STRICT mTLS and the
# ISTIO_MUTUAL client mode are unchanged, and an in-mesh call returns 200.
# Skip pods that are terminating: a replaced pod keeps phase Running during its grace period.
NAMES=$(kubectl get pods -n media -l app=session-broker \
  -o jsonpath='{range .items[*]}{.metadata.deletionTimestamp}|{.spec.containers[*].name}{"\n"}{end}' 2>/dev/null \
  | grep '^|' | cut -d'|' -f2)
if [ -z "$NAMES" ] || echo "$NAMES" | grep -vqw istio-proxy; then
  echo "A session-broker pod still has no istio-proxy sidecar (containers: '$NAMES')." >&2
  echo "Remove the pod-template label sidecar.istio.io/inject=false, then wait for the rollout:" >&2
  echo "  kubectl rollout status deployment session-broker -n media" >&2
  exit 1
fi
MODE=$(kubectl get peerauthentication default -n media -o jsonpath='{.spec.mtls.mode}' 2>/dev/null)
TLS=$(kubectl get destinationrule session-broker -n media -o jsonpath='{.spec.trafficPolicy.tls.mode}' 2>/dev/null)
if [ "$MODE" != "STRICT" ] || [ "$TLS" = "DISABLE" ]; then
  echo "mTLS was weakened (PeerAuthentication '$MODE', DestinationRule tls '$TLS')." >&2
  echo "Restore STRICT and ISTIO_MUTUAL; the fix is the sidecar, not the policy." >&2
  exit 1
fi
CODE=$(kubectl exec -n media deploy/mesh-client -c curl -- \
  curl -s -o /dev/null -w '%{http_code}' --max-time 6 http://session-broker.media/ 2>/dev/null)
if [ "$CODE" = "200" ]; then
  echo "✓ session-broker is 2/2 in the mesh, STRICT mTLS is intact, and mesh-client gets HTTP 200"
  exit 0
fi
echo "session-broker has a sidecar, but mesh-client gets HTTP '$CODE' (expected 200)." >&2
echo "The new sidecar may still be syncing. Check: istioctl proxy-status, then retry." >&2
exit 1
