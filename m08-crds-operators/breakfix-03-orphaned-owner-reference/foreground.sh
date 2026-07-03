#!/bin/bash

echo "Waiting for the Polyphone baseline + the MediaTenant operator to come up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "vega-media is still Running, but there's no vega MediaTenant. Compare its owner"
echo "references to a healthy child (orion-media) to see why it wasn't cleaned up:"
echo ""
echo "  kubectl get mediatenants -A"
echo "  kubectl get deployments -n media -l managed-by=tenant-operator"
echo "  kubectl get deployment vega-media  -n media -o jsonpath='{.metadata.ownerReferences}'; echo"
echo "  kubectl get deployment orion-media -n media -o jsonpath='{.metadata.ownerReferences}'; echo"
echo ""
