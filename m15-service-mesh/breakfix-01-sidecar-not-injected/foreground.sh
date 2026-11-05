#!/bin/bash

echo "Waiting for Istio and the Polyphone fleet to start (about 3 to 5 minutes)..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Alert: callers of session-broker (media) get 503. Reproduce it from the in-mesh client:"
echo ""
echo "  kubectl exec -n media deploy/mesh-client -c curl -- \\"
echo "    curl -s -w '\\nHTTP %{http_code}\\n' --max-time 5 http://session-broker.media/"
echo ""
