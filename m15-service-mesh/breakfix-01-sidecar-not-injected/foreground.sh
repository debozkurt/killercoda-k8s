#!/bin/bash

echo "Waiting for the Polyphone baseline + Istio to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Calls to session-broker (media) are failing with 503, but its Pods are healthy."
echo "Reproduce it from the in-mesh client, then look at how many containers it has:"
echo ""
echo "  kubectl exec -n media deploy/mesh-client -c curl -- \\"
echo "    curl -s -o /dev/null -w 'HTTP %{http_code}\\n' --max-time 5 http://session-broker.media/"
echo "  kubectl get pods -n media"
echo ""
