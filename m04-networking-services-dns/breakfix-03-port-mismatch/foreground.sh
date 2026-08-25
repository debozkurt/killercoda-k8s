#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "portal-ui (admin-portal) refuses connections — but its endpoints look fine."
echo "Start by confirming the endpoints ARE populated, then read the ports:"
echo ""
echo "  kubectl get endpointslice -n admin-portal" \
  -l kubernetes.io/service-name=portal-ui
echo "  kubectl get svc portal-ui -n admin-portal -o yaml | grep -A3 ports:"
echo ""
