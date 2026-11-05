#!/bin/bash
# Checks: the route no longer targets the empty `canary` subset, and an in-mesh call
# to session-broker returns 200.
SUBSET=$(kubectl get virtualservice session-broker -n media \
  -o jsonpath='{.spec.http[0].route[0].destination.subset}' 2>/dev/null)
if [ "$SUBSET" = "canary" ]; then
  echo "The route still targets subset 'canary', which selects no pods." >&2
  echo "Point it at 'stable':" >&2
  echo "  kubectl patch virtualservice session-broker -n media --type=json -p '[{\"op\":\"replace\",\"path\":\"/spec/http/0/route/0/destination/subset\",\"value\":\"stable\"}]'" >&2
  exit 1
fi
CODE=$(kubectl exec -n media deploy/mesh-client -c curl -- \
  curl -s -o /dev/null -w '%{http_code}' --max-time 6 http://session-broker.media/ 2>/dev/null)
if [ "$CODE" = "200" ]; then
  echo "✓ the route targets subset '$SUBSET', which has pods; mesh-client gets HTTP 200"
  exit 0
fi
echo "The route targets '$SUBSET', but mesh-client gets HTTP '$CODE' (expected 200)." >&2
echo "The push may still be in flight. Check: kubectl logs -n media deploy/mesh-client -c istio-proxy --tail=1" >&2
exit 1
