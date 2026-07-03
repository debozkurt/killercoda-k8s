#!/bin/bash
# Checks: STRICT mTLS is in force for `media` AND the in-mesh path still works — i.e.
# enforcement is on, and a caller with a sidecar (mesh-client) is allowed through it.
MODE=$(kubectl get peerauthentication default -n media -o jsonpath='{.spec.mtls.mode}' 2>/dev/null)
if [ "$MODE" != "STRICT" ]; then
  echo "PeerAuthentication 'default' in media is mode '$MODE' (expected STRICT). The mesh config" >&2
  echo "may still be applying — wait and retry." >&2
  exit 1
fi
CODE=$(kubectl exec -n media deploy/mesh-client -c curl -- \
  curl -s -o /dev/null -w '%{http_code}' --max-time 6 http://session-broker.media/ 2>/dev/null)
if [ "$CODE" = "200" ]; then
  echo "✓ STRICT mTLS enforced in media, and the in-mesh mesh-client is authenticated through it (HTTP 200)"
  exit 0
fi
echo "STRICT is set but mesh-client got HTTP '$CODE' (expected 200) — sidecars may still be settling; retry." >&2
exit 1
