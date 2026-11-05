#!/bin/bash

echo "Waiting for Istio and the Polyphone fleet to start (about 3 to 5 minutes)..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Alert: about half the calls to session-broker (media) fail. Measure it:"
echo ""
echo "  kubectl exec -n media deploy/mesh-client -c curl -- sh -c \\"
echo "    'for i in 1 2 3 4 5 6 7 8 9 10; do curl -s -o /dev/null -w \"%{http_code} \" --max-time 5 http://session-broker.media/; done; echo'"
echo ""
