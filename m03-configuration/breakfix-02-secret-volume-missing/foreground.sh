#!/bin/bash

echo "Spinning up the Polyphone fleet (one workload is misconfigured)..."
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. portal-ui in 'admin-portal' is stuck. Begin:"
echo ""
echo "  kubectl get pods -n admin-portal"
echo ""
