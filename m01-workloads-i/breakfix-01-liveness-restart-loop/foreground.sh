#!/bin/bash

echo "Waiting for the Polyphone baseline + scenario mutation..."
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is up. Alert fires:"
echo ""
echo "  +-----------------------------------------------+"
echo "  | ALERT: route-engine CrashLoopBackOff          |"
echo "  | namespace: call-routing                       |"
echo "  | impact:    call routing degraded              |"
echo "  +-----------------------------------------------+"
echo ""
echo "Is the app crashing, or is something killing it? Start with:"
echo ""
echo "  kubectl get pods -n call-routing"
echo ""
