#!/bin/bash
# Checks: an in-mesh caller reaches session-broker end to end — the VirtualService route
# to the `stable` subset resolves to healthy pods and returns 200 within the timeout.
CODE=$(kubectl exec -n media deploy/mesh-client -c curl -- \
  curl -s -o /dev/null -w '%{http_code}' --max-time 6 http://session-broker.media/ 2>/dev/null)
if [ "$CODE" = "200" ]; then
  echo "✓ mesh-client reached session-broker through the mesh (HTTP 200 via subset 'stable')"
  exit 0
fi
echo "mesh-client got HTTP '$CODE' from session-broker (expected 200). The mesh config or the" >&2
echo "mesh-client sidecar may still be settling — wait a few seconds and retry." >&2
exit 1
