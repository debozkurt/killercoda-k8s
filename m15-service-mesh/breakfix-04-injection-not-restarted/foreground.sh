#!/bin/bash

echo "Waiting for Istio and the Polyphone fleet to start (about 3 to 5 minutes)..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Alert: session-dialer (signaling) cannot reach session-broker (media). Reproduce it:"
echo ""
echo "  kubectl exec -n signaling deploy/session-dialer -- \\"
echo "    curl -sS -o /dev/null -w 'HTTP %{http_code}\\n' --max-time 5 http://session-broker.media/"
echo ""
