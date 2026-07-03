#!/bin/bash
# Checks: the client side no longer sends plaintext (DestinationRule tls mode != DISABLE),
# STRICT was kept on the server, and callers reach session-broker again (HTTP 200).
TLS=$(kubectl get destinationrule session-broker -n media \
  -o jsonpath='{.spec.trafficPolicy.tls.mode}' 2>/dev/null)
if [ "$TLS" = "DISABLE" ]; then
  echo "The DestinationRule still sends plaintext (tls.mode: DISABLE) into a STRICT server." >&2
  echo "Set it to ISTIO_MUTUAL (or remove the tls block for automatic mTLS) and retry." >&2
  exit 1
fi
MODE=$(kubectl get peerauthentication default -n media -o jsonpath='{.spec.mtls.mode}' 2>/dev/null)
if [ "$MODE" != "STRICT" ]; then
  echo "PeerAuthentication is now '$MODE', not STRICT. Fix the client's tls mode instead of" >&2
  echo "weakening the server — restore STRICT and set the DestinationRule to ISTIO_MUTUAL." >&2
  exit 1
fi
CODE=$(kubectl exec -n media deploy/mesh-client -c curl -- \
  curl -s -o /dev/null -w '%{http_code}' --max-time 6 http://session-broker.media/ 2>/dev/null)
if [ "$CODE" = "200" ]; then
  echo "✓ client and server agree on mTLS (DR tls='$TLS', PeerAuth STRICT); mesh-client gets HTTP 200"
  exit 0
fi
echo "tls mode is '$TLS' and PeerAuth STRICT, but callers still get HTTP '$CODE' — the config push" >&2
echo "may still be settling; wait a few seconds and retry." >&2
exit 1
