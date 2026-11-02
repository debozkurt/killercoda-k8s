#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "call-metrics (analytics) is Running 1/1, kubectl top works and its scrape"
echo "port is right, but its dashboards are flat. Start by proving the app is fine:"
echo ""
echo "  kubectl get pods -n analytics -l app=call-metrics"
echo "  kubectl describe service call-metrics -n analytics"
echo ""
