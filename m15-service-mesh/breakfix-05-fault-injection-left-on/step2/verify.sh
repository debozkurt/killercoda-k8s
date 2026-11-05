#!/bin/bash
# Checks: the VirtualService has no fault block and ten in-mesh calls all return 200.
FAULT=$(kubectl get virtualservice session-broker -n media -o jsonpath='{.spec.http[0].fault}' 2>/dev/null)
if [ -n "$FAULT" ]; then
  echo "The session-broker route still has a fault block: $FAULT" >&2
  echo "Remove it:" >&2
  echo "  kubectl patch virtualservice session-broker -n media --type=json -p '[{\"op\":\"remove\",\"path\":\"/spec/http/0/fault\"}]'" >&2
  exit 1
fi
CODES=$(kubectl exec -n media deploy/mesh-client -c curl -- sh -c \
  'for i in 1 2 3 4 5 6 7 8 9 10; do curl -s -o /dev/null -w "%{http_code} " --max-time 5 http://session-broker.media/; done' 2>/dev/null)
if [ "$(echo "$CODES" | tr ' ' '\n' | grep -c '^200$')" = "10" ]; then
  echo "✓ no fault in the route, and 10 of 10 calls return HTTP 200"
  exit 0
fi
echo "The fault block is gone, but the calls returned: $CODES" >&2
echo "The push may still be in flight. Wait a few seconds and retry." >&2
exit 1
