#!/bin/bash

echo "Waiting for the Polyphone baseline and the MediaTenant operator to come up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "orion and lyra sit at Provisioning, and no child Deployments exist."
echo "The operator Pod is Running. Find why nothing progresses:"
echo ""
echo "  kubectl get mediatenants -A"
echo "  kubectl logs deployment/tenant-operator -n platform --tail=12"
echo ""
