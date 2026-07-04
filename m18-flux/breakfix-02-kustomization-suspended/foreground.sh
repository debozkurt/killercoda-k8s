#!/bin/bash

echo "Waiting for the Polyphone baseline + Flux (with a suspended consumer) to come up..."
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is up. dialplan is drifted at 5 replicas and Flux isn't reverting it:"
echo ""
echo "  kubectl get deploy dialplan -n app-services"
echo "  flux get kustomizations"
echo ""
