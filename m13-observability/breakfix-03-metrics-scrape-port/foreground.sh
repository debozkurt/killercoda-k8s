#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "call-metrics (analytics) is Running 1/1 and kubectl top works, but its"
echo "dashboards are flat. Start by proving the app really exposes metrics:"
echo ""
echo "  kubectl get pods -n analytics -l app=call-metrics"
echo "  kubectl top pod -n analytics -l app=call-metrics"
echo ""
