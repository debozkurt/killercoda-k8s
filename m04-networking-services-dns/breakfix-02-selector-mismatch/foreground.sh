#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "route-engine (call-routing) is unreachable — but its Pods look healthy."
echo "Don't trust 'get svc'. Check what's actually behind the Service:"
echo ""
echo "  kubectl get endpointslice -n call-routing" \
  -l kubernetes.io/service-name=route-engine
echo ""
