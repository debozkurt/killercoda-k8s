#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "session-store (app-services) is stuck at READY 0/3 — and only Pod-0 exists."
echo "Confirm the stall, then look at why Pod-0 won't go Ready:"
echo ""
echo "  kubectl get statefulset session-store -n app-services"
echo "  kubectl get pods -n app-services -l app=session-store"
echo "  kubectl describe pod session-store-0 -n app-services | grep -A8 Conditions"
echo ""
