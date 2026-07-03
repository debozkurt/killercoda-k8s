#!/bin/bash

echo "Waiting for the Polyphone baseline + Istio to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "session-broker (media) is 503ing through the mesh — but its Pods are 2/2 and"
echo "healthy. A 503 with a healthy backend is a routing problem. Reproduce it, then"
echo "ask Envoy where the route actually goes:"
echo ""
echo "  kubectl exec -n media deploy/mesh-client -c curl -- \\"
echo "    curl -s -o /dev/null -w 'HTTP %{http_code}\\n' --max-time 5 http://session-broker.media/"
echo ""
