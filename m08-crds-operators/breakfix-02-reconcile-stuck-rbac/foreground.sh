#!/bin/bash

echo "Waiting for the Polyphone baseline + the MediaTenant operator to come up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Both tenants are stuck at PHASE Provisioning with no child Deployments, yet the"
echo "operator Pod is Running. Read the stuck status, then the operator's logs:"
echo ""
echo "  kubectl get mediatenants -A"
echo "  kubectl get deployments -n media -l managed-by=tenant-operator"
echo "  kubectl logs deployment/tenant-operator -n platform --tail=10"
echo ""
