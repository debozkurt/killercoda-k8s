#!/bin/bash
# Checks: session-dialer runs a sidecar, media is still STRICT, and session-dialer
# reaches session-broker with HTTP 200.
# Skip pods that are terminating: a replaced pod keeps phase Running during its grace period.
NAMES=$(kubectl get pods -n signaling -l app=session-dialer \
  -o jsonpath='{range .items[*]}{.metadata.deletionTimestamp}|{.spec.containers[*].name}{"\n"}{end}' 2>/dev/null \
  | grep '^|' | cut -d'|' -f2)
if [ -z "$NAMES" ] || echo "$NAMES" | grep -vqw istio-proxy; then
  echo "A session-dialer pod has no istio-proxy sidecar yet (containers: '$NAMES')." >&2
  echo "Recreate it so the webhook injects one:" >&2
  echo "  kubectl rollout restart deployment session-dialer -n signaling" >&2
  exit 1
fi
MODE=$(kubectl get peerauthentication default -n media -o jsonpath='{.spec.mtls.mode}' 2>/dev/null)
if [ "$MODE" != "STRICT" ]; then
  echo "PeerAuthentication 'default' in media is now '$MODE', not STRICT." >&2
  echo "Restore STRICT; the fix is a sidecar on the caller, not a weaker server." >&2
  exit 1
fi
CODE=$(kubectl exec -n signaling deploy/session-dialer -- \
  curl -s -o /dev/null -w '%{http_code}' --max-time 6 http://session-broker.media/ 2>/dev/null)
if [ "$CODE" = "200" ]; then
  echo "✓ session-dialer is in the mesh (2/2), media is still STRICT, and the call returns HTTP 200"
  exit 0
fi
echo "session-dialer has a sidecar, but the call returns HTTP '$CODE' (expected 200)." >&2
echo "The new sidecar may still be starting. Wait for 2/2 and retry." >&2
exit 1
