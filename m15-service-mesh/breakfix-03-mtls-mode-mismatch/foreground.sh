#!/bin/bash

echo "Waiting for the Polyphone baseline + Istio to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "session-broker (media) is 503ing — Pods 2/2, route correct, endpoints present."
echo "When the workload and the route are both fine, suspect the two mTLS settings."
echo "Reproduce it, then read the PeerAuthentication and the DestinationRule together:"
echo ""
echo "  kubectl exec -n media deploy/mesh-client -c curl -- \\"
echo "    curl -s -o /dev/null -w 'HTTP %{http_code}\\n' --max-time 5 http://session-broker.media/"
echo ""
