#!/bin/bash

echo "Waiting for the Polyphone baseline and the MediaTenant operator to come up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "A new tenant, vega, never appeared. Its manifest is at /root/vega-tenant.yaml."
echo "Apply it and read what the API server says:"
echo ""
echo "  kubectl apply -f /root/vega-tenant.yaml"
echo ""
