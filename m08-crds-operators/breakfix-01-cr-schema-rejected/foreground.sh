#!/bin/bash

echo "Waiting for the Polyphone baseline + the MediaTenant operator to come up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Tenant vega is missing — only orion and lyra exist, and there's no vega-media."
echo "The manifest the team handed you is at /root/vega-tenant.yaml. Apply it and read"
echo "why the API server refuses it:"
echo ""
echo "  kubectl get mediatenants -A"
echo "  kubectl apply -f /root/vega-tenant.yaml"
echo ""
