#!/bin/bash
# Checks: the client no longer sends plaintext, the server is still STRICT, and an
# in-mesh call to session-broker returns 200.
TLS=$(kubectl get destinationrule session-broker -n media \
  -o jsonpath='{.spec.trafficPolicy.tls.mode}' 2>/dev/null)
if [ "$TLS" = "DISABLE" ]; then
  echo "The DestinationRule still sends plaintext (tls mode DISABLE) to a STRICT server." >&2
  echo "Set the client mode:" >&2
  echo "  kubectl patch destinationrule session-broker -n media --type=json -p '[{\"op\":\"replace\",\"path\":\"/spec/trafficPolicy/tls/mode\",\"value\":\"ISTIO_MUTUAL\"}]'" >&2
  exit 1
fi
MODE=$(kubectl get peerauthentication default -n media -o jsonpath='{.spec.mtls.mode}' 2>/dev/null)
if [ "$MODE" != "STRICT" ]; then
  echo "PeerAuthentication 'default' is now '$MODE', not STRICT." >&2
  echo "Restore STRICT and fix the client mode instead of weakening the server." >&2
  exit 1
fi
CODE=$(kubectl exec -n media deploy/mesh-client -c curl -- \
  curl -s -o /dev/null -w '%{http_code}' --max-time 6 http://session-broker.media/ 2>/dev/null)
if [ "$CODE" = "200" ]; then
  echo "✓ client and server agree on mTLS (client tls '${TLS:-automatic}', server STRICT); mesh-client gets HTTP 200"
  exit 0
fi
echo "Client tls is '${TLS:-automatic}' and the server is STRICT, but mesh-client gets HTTP '$CODE'." >&2
echo "The push may still be in flight. Wait a few seconds and retry." >&2
exit 1
