#!/bin/bash

echo "Waiting for Istio and the Polyphone fleet to start (about 3 to 5 minutes)..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Ready. Start with the pods in the meshed namespace:"
echo ""
echo "  kubectl get pods -n media"
echo ""
