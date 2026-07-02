#!/bin/bash

echo "Waiting for the Polyphone baseline + the MediaTenant operator to come up..."
echo "(installs the fleet, then registers the MediaTenant CRD, starts the"
echo " tenant-operator, and reconciles two tenants into child media Deployments)"
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. Start by finding the new resource type in the API:"
echo ""
echo "  kubectl get crd | grep polyphone"
echo "  kubectl get mediatenants -A"
echo ""
