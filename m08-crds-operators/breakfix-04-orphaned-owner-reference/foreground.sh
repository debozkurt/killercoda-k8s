#!/bin/bash

echo "Waiting for the Polyphone baseline and the MediaTenant operator to come up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "vega-media still runs, but no vega MediaTenant exists."
echo "Compare its owner references with a healthy child's:"
echo ""
echo "  kubectl get mediatenants -A"
echo "  kubectl get deployment vega-media  -n media -o yaml | head -n 30"
echo "  kubectl get deployment orion-media -n media -o yaml | head -n 30"
echo ""
