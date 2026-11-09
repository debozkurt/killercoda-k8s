#!/bin/bash

echo "Waiting for the Polyphone fleet, Flux, the git server and the first reconcile..."
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. The latest commit asked for 3 dialplan replicas:"
echo ""
echo "  kubectl get deploy dialplan -n app-services"
echo ""
