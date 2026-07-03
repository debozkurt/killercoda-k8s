#!/bin/bash
# Checks: session-broker is back in the mesh (has an istio-proxy sidecar) AND callers reach
# it again (HTTP 200) — and STRICT mTLS is untouched (fixed by re-enrolling, not by weakening).
NAMES=$(kubectl get pod -n media -l app=session-broker \
  -o jsonpath='{.items[0].spec.containers[*].name}' 2>/dev/null)
if ! echo "$NAMES" | grep -qw istio-proxy; then
  echo "session-broker still has no istio-proxy sidecar (containers: '$NAMES'). Set the pod-template" >&2
  echo "annotation sidecar.istio.io/inject to \"true\" (or remove it) and let it roll; then retry." >&2
  exit 1
fi
MODE=$(kubectl get peerauthentication default -n media -o jsonpath='{.spec.mtls.mode}' 2>/dev/null)
if [ "$MODE" != "STRICT" ]; then
  echo "PeerAuthentication is no longer STRICT (mode: '$MODE'). Fix this by re-enrolling session-broker" >&2
  echo "in the mesh, not by weakening mTLS — restore STRICT and re-inject the sidecar." >&2
  exit 1
fi
CODE=$(kubectl exec -n media deploy/mesh-client -c curl -- \
  curl -s -o /dev/null -w '%{http_code}' --max-time 6 http://session-broker.media/ 2>/dev/null)
if [ "$CODE" = "200" ]; then
  echo "✓ session-broker re-enrolled (2/2, in the mesh), callers get HTTP 200, and STRICT mTLS is intact"
  exit 0
fi
echo "session-broker has a sidecar now but callers still get HTTP '$CODE' — the new pod may still be" >&2
echo "syncing config; wait a few seconds and retry." >&2
exit 1
