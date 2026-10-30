#!/bin/bash

echo "Waiting for the Polyphone baseline and the MediaTenant operator to come up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "orion and lyra exist, but PHASE and READY are blank and nothing is provisioned."
echo "The operator Pod is Running. Rule out RBAC, then read the logs:"
echo ""
echo "  kubectl logs deployment/tenant-operator -n platform --tail=8"
echo ""
